import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/error_messages.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:wingtip/core/failure_categorizer.dart';
import 'package:wingtip/core/performance_metrics_provider.dart';
import 'package:wingtip/core/sse_client.dart';
import 'package:wingtip/core/sse_client_provider.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/services/failed_scan_retention_service.dart';
import 'package:wingtip/services/widget_data_service.dart';

/// Notifier for managing Talaria scan job state
class JobStateNotifier extends Notifier<JobState> {
  final Map<String, StreamSubscription<SseEvent>> _sseSubscriptions = {};
  final Map<String, Timer> _autoRemoveTimers = {};
  Timer? _rateLimitTimer;

  @override
  JobState build() {
    // Clean up subscriptions when notifier is disposed
    ref.onDispose(() {
      for (final subscription in _sseSubscriptions.values) {
        subscription.cancel();
      }
      _sseSubscriptions.clear();
      for (final timer in _autoRemoveTimers.values) {
        timer.cancel();
      }
      _autoRemoveTimers.clear();
      _rateLimitTimer?.cancel();
    });

    return JobState.idle();
  }

  /// Retry a failed scan by job ID
  ///
  /// Reads the image from failed_scans directory and re-uploads it
  /// Returns true if the retry was successful, false otherwise
  Future<bool> retryFailedScan(String failedScanJobId) async {
    ScanJob? job;
    String? imagePath;

    try {
      debugPrint('[JobStateNotifier] Retrying failed scan: $failedScanJobId');

      // Get the failed scan from database
      final database = ref.read(databaseProvider);
      final failedScan = await database.getFailedScan(failedScanJobId);

      if (failedScan == null) {
        debugPrint('[JobStateNotifier] Failed scan not found: $failedScanJobId');
        return false;
      }

      // Store image path for error handlers
      imagePath = failedScan.imagePath;

      // Verify image exists
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('[JobStateNotifier] Image file not found: $imagePath');

        // Get retention duration from settings
        final retentionService = ref.read(failedScanRetentionServiceProvider);
        final retentionDuration = retentionService.getRetentionDuration();

        // Update error message
        await database.saveFailedScan(
          jobId: failedScanJobId,
          imagePath: imagePath,
          errorMessage: 'Image file missing - cannot retry',
          failureReason: FailureReason.unknown,
          retentionPeriod: retentionDuration,
        );
        return false;
      }

      debugPrint('[JobStateNotifier] Uploading image for retry: $imagePath');

      // Create new job in uploading state
      job = ScanJob.uploading(imagePath);

      // Add job to queue
      state = state.copyWith(
        jobs: [...state.jobs, job],
      );

      debugPrint('[JobStateNotifier] Created retry job ${job.id}: $imagePath');

      // Get TalariaClient from provider
      final client = await ref.read(talariaClientProvider.future);

      // Upload to Talaria
      final response = await client.uploadImage(imagePath);

      debugPrint('[JobStateNotifier] Upload successful for retry job ${job.id}:');
      debugPrint('  - Job ID: ${response.jobId}');
      debugPrint('  - Stream URL: ${response.streamUrl}');

      // Update job to listening state with timestamp
      _updateJob(
        job.id,
        job.copyWith(
          jobId: response.jobId,
          streamUrl: response.streamUrl,
          status: JobStatus.listening,
          sseListeningStartedAt: DateTime.now(),
        ),
      );

      // Start listening to SSE stream
      // Use the original failedScanJobId for cleanup tracking
      await _listenToStream(job.id, failedScanJobId, response.streamUrl);

      return true;
    } on DioException catch (e) {
      debugPrint('[JobStateNotifier] DioException during retry upload: ${e.type}');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
      return false;
    } on SocketException catch (e) {
      debugPrint('[JobStateNotifier] SocketException during retry upload: $e');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
      return false;
    } on TimeoutException catch (e) {
      debugPrint('[JobStateNotifier] TimeoutException during retry upload: $e');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
      return false;
    } catch (e) {
      debugPrint('[JobStateNotifier] Retry upload failed: $e');

      // Check if this is a rate limit exception
      if (e.toString().contains('RateLimitException')) {
        _handleRateLimitError(e);
      } else {
        // Trigger error haptic feedback
        HapticFeedback.heavyImpact();

        // Update the job to error state if it exists
        if (job != null) {
          _updateJob(
            job.id,
            job.copyWith(
              status: JobStatus.error,
              errorMessage: e.toString(),
            ),
          );
        }

        // Update the failed scan with new error info
        await _updateFailedScanError(failedScanJobId, e.toString());
      }
      return false;
    }
  }

  /// Retry all failed scans sequentially with throttling
  ///
  /// Processes all failed scans with 1 second delay between each upload
  /// Returns a map with 'succeeded' and 'failed' counts
  ///
  /// Callback function is called after each retry with progress information
  Future<Map<String, int>> retryAllFailedScans({
    required void Function(int current, int total) onProgress,
  }) async {
    debugPrint('[JobStateNotifier] Starting batch retry of all failed scans');

    // Get all failed scans
    final database = ref.read(databaseProvider);
    final failedScans = await database.select(database.failedScans).get();

    if (failedScans.isEmpty) {
      debugPrint('[JobStateNotifier] No failed scans to retry');
      return {'succeeded': 0, 'failed': 0};
    }

    int succeeded = 0;
    int failed = 0;
    final total = failedScans.length;

    debugPrint('[JobStateNotifier] Retrying $total failed scans with throttling');

    for (int i = 0; i < failedScans.length; i++) {
      final scan = failedScans[i];
      final current = i + 1;

      debugPrint('[JobStateNotifier] Retrying scan $current of $total: ${scan.jobId}');

      // Notify progress
      onProgress(current, total);

      // Retry the scan
      final success = await retryFailedScan(scan.jobId);

      if (success) {
        succeeded++;
        debugPrint('[JobStateNotifier] Retry $current succeeded');
      } else {
        failed++;
        debugPrint('[JobStateNotifier] Retry $current failed');
      }

      // Throttle: wait 1 second before next retry (except after last one)
      if (i < failedScans.length - 1) {
        debugPrint('[JobStateNotifier] Throttling: waiting 1 second before next retry');
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    debugPrint('[JobStateNotifier] Batch retry completed: $succeeded succeeded, $failed failed');

    return {'succeeded': succeeded, 'failed': failed};
  }

  /// Upload an image to Talaria for analysis
  ///
  /// Adds a new job to the queue and starts processing
  Future<void> uploadImage(String imagePath) async {
    ScanJob? job;
    try {
      // Create new job in uploading state
      job = ScanJob.uploading(imagePath);

      // Add job to queue
      state = state.copyWith(
        jobs: [...state.jobs, job],
      );

      debugPrint('[JobStateNotifier] Created job ${job.id}: $imagePath');

      // Get TalariaClient from provider
      final client = await ref.read(talariaClientProvider.future);

      // Track upload time
      final uploadStartTime = DateTime.now();

      // Upload to Talaria
      final response = await client.uploadImage(imagePath);

      // Record upload time
      final uploadDuration = DateTime.now().difference(uploadStartTime);
      try {
        final metricsService = ref.read(performanceMetricsServiceProvider);
        await metricsService.recordUploadTime(uploadDuration.inMilliseconds);
      } catch (e) {
        debugPrint('[JobStateNotifier] Failed to record upload time: $e');
      }

      debugPrint('[JobStateNotifier] Upload successful for job ${job.id}:');
      debugPrint('  - Job ID: ${response.jobId}');
      debugPrint('  - Stream URL: ${response.streamUrl}');

      // Update job to listening state with timestamp
      _updateJob(
        job.id,
        job.copyWith(
          jobId: response.jobId,
          streamUrl: response.streamUrl,
          status: JobStatus.listening,
          sseListeningStartedAt: DateTime.now(),
        ),
      );

      // Start listening to SSE stream
      await _listenToStream(job.id, response.jobId, response.streamUrl);
    } on DioException catch (e) {
      debugPrint('[JobStateNotifier] DioException during upload: ${e.type}');
      await _handleNetworkError(e, job, imagePath);
    } on SocketException catch (e) {
      debugPrint('[JobStateNotifier] SocketException during upload: $e');
      await _handleNetworkError(e, job, imagePath);
    } on TimeoutException catch (e) {
      debugPrint('[JobStateNotifier] TimeoutException during upload: $e');
      await _handleNetworkError(e, job, imagePath);
    } catch (e) {
      debugPrint('[JobStateNotifier] Upload failed: $e');

      // Check if this is a rate limit exception
      if (e.toString().contains('RateLimitException')) {
        _handleRateLimitError(e);
      } else {
        // Trigger error haptic feedback
        HapticFeedback.heavyImpact();

        // Update the job to error state if it exists
        if (job != null) {
          _updateJob(
            job.id,
            job.copyWith(
              status: JobStatus.error,
              errorMessage: e.toString(),
            ),
          );
        }
      }
    }
  }

  /// Handle rate limit error
  void _handleRateLimitError(dynamic error) {
    debugPrint('[JobStateNotifier] Rate limit hit: $error');
    HapticFeedback.heavyImpact();

    // Extract retryAfterMs from error message
    int retryAfterMs = 60000; // Default 60 seconds

    // Try to parse retryAfterMs from error string
    final errorStr = error.toString();
    final match = RegExp(r'retry after (\d+)ms').firstMatch(errorStr);
    if (match != null) {
      retryAfterMs = int.tryParse(match.group(1) ?? '') ?? 60000;
    }

    // Set rate limit state
    final expiresAt = DateTime.now().add(Duration(milliseconds: retryAfterMs));
    state = state.copyWith(
      rateLimit: RateLimitInfo(
        expiresAt: expiresAt,
        retryAfterMs: retryAfterMs,
      ),
    );

    // Remove the failed job from the queue
    if (state.jobs.isNotEmpty) {
      final lastJob = state.jobs.last;
      _removeJob(lastJob.id);
    }

    // Schedule rate limit clear
    _rateLimitTimer?.cancel();
    _rateLimitTimer = Timer(Duration(milliseconds: retryAfterMs), () {
      debugPrint('[JobStateNotifier] Rate limit expired, clearing');
      state = state.clearRateLimit();
    });
  }

  /// Handle retry upload errors
  ///
  /// Updates the existing failed scan entry with new error information
  Future<void> _handleRetryError(
    dynamic error,
    ScanJob? job,
    String imagePath,
    String failedScanJobId,
  ) async {
    // Trigger error haptic feedback
    HapticFeedback.heavyImpact();

    // Map exception to user-friendly error message
    final errorMessage = ErrorMessages.fromException(error);

    debugPrint('[JobStateNotifier] Retry error: $errorMessage');

    // Update job to error state if it exists
    if (job != null) {
      _updateJob(
        job.id,
        job.copyWith(
          status: JobStatus.error,
          errorMessage: errorMessage,
        ),
      );
    }

    // Update the failed scan with new error information
    await _updateFailedScanError(failedScanJobId, errorMessage);
  }

  /// Update a failed scan entry with new error message
  Future<void> _updateFailedScanError(String jobId, String errorMessage) async {
    try {
      final database = ref.read(databaseProvider);
      final failedScan = await database.getFailedScan(jobId);

      if (failedScan != null) {
        // Prepend retry attempt info to error message
        final updatedMessage = 'Retry failed: $errorMessage';

        // Get retention duration from settings
        final retentionService = ref.read(failedScanRetentionServiceProvider);
        final retentionDuration = retentionService.getRetentionDuration();

        // Categorize the failure
        final failureReason = FailureCategorizer.categorize(null, errorMessage);

        await database.saveFailedScan(
          jobId: jobId,
          imagePath: failedScan.imagePath,
          errorMessage: updatedMessage,
          failureReason: failureReason,
          retentionPeriod: retentionDuration,
        );
        debugPrint('[JobStateNotifier] Updated failed scan error: $jobId');
      }
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to update failed scan error: $e');
    }
  }

  /// Handle network upload errors
  ///
  /// Maps exception types to user-friendly error messages and saves to failed scans
  Future<void> _handleNetworkError(
    dynamic error,
    ScanJob? job,
    String imagePath,
  ) async {
    // Trigger error haptic feedback
    HapticFeedback.heavyImpact();

    // Map exception to user-friendly error message
    final errorMessage = ErrorMessages.fromException(error);
    String? serverJobId;

    debugPrint('[JobStateNotifier] Network error: $errorMessage');

    // Update job to error state if it exists
    if (job != null) {
      _updateJob(
        job.id,
        job.copyWith(
          status: JobStatus.error,
          errorMessage: errorMessage,
        ),
      );

      // Use job's ID as server job ID for failed scans
      // This allows us to track and retry the failed upload
      serverJobId = job.id;
    }

    // Save failed scan to database with persistent image storage
    if (serverJobId != null) {
      await _saveFailedScan(serverJobId, imagePath, errorMessage);
    }
  }

  /// Update a job in the state
  void _updateJob(String jobId, ScanJob updatedJob) {
    final jobs = state.jobs;
    final index = jobs.indexWhere((job) => job.id == jobId);
    if (index != -1) {
      final updatedJobs = List<ScanJob>.from(jobs);
      updatedJobs[index] = updatedJob;
      state = state.copyWith(jobs: updatedJobs);
    }
  }

  /// Remove a job from the state
  void _removeJob(String jobId) {
    final jobs = state.jobs.where((job) => job.id != jobId).toList();
    state = state.copyWith(jobs: jobs);

    // Cancel any timers for this job
    _autoRemoveTimers[jobId]?.cancel();
    _autoRemoveTimers.remove(jobId);
  }

  /// Schedule auto-remove for a completed job
  void _scheduleAutoRemove(String jobId) {
    // Cancel any existing timer for this job
    _autoRemoveTimers[jobId]?.cancel();

    // Schedule removal after 5 seconds
    _autoRemoveTimers[jobId] = Timer(const Duration(seconds: 5), () {
      debugPrint('[JobStateNotifier] Auto-removing job $jobId');
      _removeJob(jobId);
    });
  }

  /// Listen to SSE stream for job updates
  Future<void> _listenToStream(
    String jobId,
    String serverJobId,
    String streamUrl,
  ) async {
    try {
      // Cancel any existing subscription for this job
      await _sseSubscriptions[jobId]?.cancel();

      // Get SSE client from provider
      final sseClient = ref.read(sseClientProvider);

      debugPrint('[JobStateNotifier] Starting SSE stream for job: $jobId');

      // Listen to the stream
      _sseSubscriptions[jobId] = sseClient.listen(streamUrl).listen(
        (event) {
          _handleSseEvent(event, jobId, serverJobId);
        },
        onError: (error) {
          debugPrint('[JobStateNotifier] SSE stream error for job $jobId: $error');
          HapticFeedback.heavyImpact();
          final job = state.getJobById(jobId);
          if (job != null) {
            _updateJob(
              jobId,
              job.copyWith(
                status: JobStatus.error,
                errorMessage: error.toString(),
              ),
            );
          }
        },
        onDone: () {
          debugPrint('[JobStateNotifier] SSE stream closed for job $jobId');
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to start SSE stream: $e');
      HapticFeedback.heavyImpact();
      final job = state.getJobById(jobId);
      if (job != null) {
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  /// Handle individual SSE events
  Future<void> _handleSseEvent(
    SseEvent event,
    String jobId,
    String serverJobId,
  ) async {
    debugPrint('[JobStateNotifier] Handling SSE event for job $jobId: ${event.type}');

    final job = state.getJobById(jobId);
    if (job == null) {
      debugPrint('[JobStateNotifier] Job $jobId not found, ignoring event');
      return;
    }

    switch (event.type) {
      case SseEventType.progress:
        final progress = event.data['progress'] as num? ?? 0.0;
        final message = event.data['message'] as String?;
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.processing,
            progress: progress.toDouble(),
            progressMessage: message,
          ),
        );

      case SseEventType.result:
        // Intermediate result - save to database and update state
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Received result for job $jobId: $resultData');

        // Track SSE first result time if this is the first result for this job
        if (job.result == null && job.sseListeningStartedAt != null) {
          final sseFirstResultDuration = DateTime.now().difference(job.sseListeningStartedAt!);
          try {
            final metricsService = ref.read(performanceMetricsServiceProvider);
            await metricsService.recordSseFirstResultTime(sseFirstResultDuration.inMilliseconds);
          } catch (e) {
            debugPrint('[JobStateNotifier] Failed to record SSE first result time: $e');
          }
        }

        await _saveBookResult(resultData, serverJobId);
        _updateJob(
          jobId,
          job.copyWith(result: resultData),
        );

      case SseEventType.complete:
        // Job completed successfully
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Job $jobId completed: $resultData');

        // Check if no books were detected
        final results = resultData['results'] as List?;
        final booksFound = resultData['booksFound'] as int? ?? results?.length ?? 0;

        if (booksFound == 0) {
          // No books detected - treat as a failed scan
          debugPrint('[JobStateNotifier] No books detected in job $jobId');
          HapticFeedback.heavyImpact();
          const errorMessage = 'No books detected. Try closer zoom or clearer angle.';
          _updateJob(
            jobId,
            job.copyWith(
              status: JobStatus.error,
              errorMessage: errorMessage,
            ),
          );
          await _sseSubscriptions[jobId]?.cancel();
          _sseSubscriptions.remove(jobId);

          // Save failed scan to database with specific failure reason
          await _saveFailedScan(
            serverJobId,
            job.imagePath,
            errorMessage,
            failureReason: FailureReason.noBooksFound,
          );
          return;
        }

        // Books were found - normal completion
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.completed,
            result: resultData,
          ),
        );
        await _sseSubscriptions[jobId]?.cancel();
        _sseSubscriptions.remove(jobId);

        // Perform cleanup
        await _cleanupJob(serverJobId, job.imagePath);

        // Schedule auto-remove after 5 seconds
        _scheduleAutoRemove(jobId);

      case SseEventType.error:
        // Job failed with error
        final errorMessage = event.data['message'] as String? ?? 'Unknown error';
        debugPrint('[JobStateNotifier] Job $jobId error: $errorMessage');
        HapticFeedback.heavyImpact();
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.error,
            errorMessage: errorMessage,
          ),
        );
        _sseSubscriptions[jobId]?.cancel();
        _sseSubscriptions.remove(jobId);

        // Categorize and save failed scan to database
        final failureReason = FailureCategorizer.categorize(null, errorMessage);
        await _saveFailedScan(
          serverJobId,
          job.imagePath,
          errorMessage,
          failureReason: failureReason,
        );
    }
  }

  /// Save failed scan to database and move image to persistent storage
  Future<void> _saveFailedScan(
    String jobId,
    String imagePath,
    String errorMessage, {
    FailureReason? failureReason,
  }) async {
    try {
      // Move image from temp to persistent failed_scans directory
      final persistentPath = await FailedScansDirectory.moveImage(imagePath, jobId);
      debugPrint('[JobStateNotifier] Moved failed scan image to: $persistentPath');

      // Get retention duration from settings
      final retentionService = ref.read(failedScanRetentionServiceProvider);
      final retentionDuration = retentionService.getRetentionDuration();

      // Use provided reason or categorize based on error message
      final reason = failureReason ?? FailureCategorizer.categorize(null, errorMessage);

      final database = ref.read(databaseProvider);
      await database.saveFailedScan(
        jobId: jobId,
        imagePath: persistentPath,
        errorMessage: errorMessage,
        failureReason: reason,
        retentionPeriod: retentionDuration,
      );
      debugPrint('[JobStateNotifier] Failed scan saved: $jobId (reason: ${reason.label})');
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to save failed scan: $e');
    }
  }

  /// Save book result to database
  /// If this is a retry of a failed scan, delete the failed scan entry and image
  Future<void> _saveBookResult(Map<String, dynamic> resultData, String serverJobId) async {
    try {
      // Extract book data from result
      final isbn = resultData['isbn'] as String?;
      final title = resultData['title'] as String?;
      final author = resultData['author'] as String?;
      final coverUrl = resultData['coverUrl'] as String?;
      final format = resultData['format'] as String?;
      final spineConfidence = resultData['spineConfidence'] as num?;

      // Validate required fields
      if (isbn == null || isbn.isEmpty) {
        debugPrint('[JobStateNotifier] Missing ISBN, skipping save');
        return;
      }
      if (title == null || title.isEmpty) {
        debugPrint('[JobStateNotifier] Missing title, skipping save');
        return;
      }
      if (author == null || author.isEmpty) {
        debugPrint('[JobStateNotifier] Missing author, skipping save');
        return;
      }

      // Get the image path from the job
      final job = state.getJobByJobId(serverJobId);
      final spineImagePath = job?.imagePath;

      // Create book companion for insert
      final book = BooksCompanion.insert(
        isbn: isbn,
        title: title,
        author: author,
        coverUrl: coverUrl != null && coverUrl.isNotEmpty
            ? Value(coverUrl)
            : const Value.absent(),
        format: format != null && format.isNotEmpty
            ? Value(format)
            : const Value.absent(),
        addedDate: DateTime.now().millisecondsSinceEpoch,
        spineConfidence: spineConfidence != null
            ? Value(spineConfidence.toDouble())
            : const Value.absent(),
        spineImagePath: spineImagePath != null && spineImagePath.isNotEmpty
            ? Value(spineImagePath)
            : const Value.absent(),
      );

      // Get database and insert (INSERT OR REPLACE)
      final database = ref.read(databaseProvider);
      await database.into(database.books).insertOnConflictUpdate(book);

      debugPrint('[JobStateNotifier] Book saved: $isbn - $title');

      // Check if this was a retry of a failed scan and clean it up
      await _cleanupFailedScanIfExists(serverJobId);

      // Trigger haptic feedback
      await HapticFeedback.mediumImpact();

      // Prefetch cover image if available
      if (coverUrl != null && coverUrl.isNotEmpty) {
        await _prefetchCoverImage(coverUrl);
      }

      // Update widget data after saving a book
      await WidgetDataService.updateWidgetData(database);
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to save book: $e');
    }
  }

  /// Clean up a failed scan entry and its image if it exists
  Future<void> _cleanupFailedScanIfExists(String jobId) async {
    try {
      final database = ref.read(databaseProvider);
      final failedScan = await database.getFailedScan(jobId);

      if (failedScan != null) {
        debugPrint('[JobStateNotifier] Cleaning up failed scan for job: $jobId');

        // Delete the image file
        await FailedScansDirectory.deleteImage(jobId);
        debugPrint('[JobStateNotifier] Deleted failed scan image');

        // Delete the database entry
        await database.deleteFailedScan(jobId);
        debugPrint('[JobStateNotifier] Deleted failed scan database entry');
      }
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to cleanup failed scan: $e');
      // Don't throw - this is a cleanup operation and shouldn't fail the save
    }
  }

  /// Prefetch cover image to cache
  Future<void> _prefetchCoverImage(String imageUrl) async {
    try {
      debugPrint('[JobStateNotifier] Prefetching cover image: $imageUrl');
      await DefaultCacheManager().downloadFile(imageUrl);
      debugPrint('[JobStateNotifier] Cover image prefetched successfully');
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to prefetch cover image: $e');
    }
  }

  /// Clean up resources after job completion
  Future<void> _cleanupJob(String jobId, String imagePath) async {
    try {
      debugPrint('[JobStateNotifier] Starting cleanup for job: $jobId');

      // Send cleanup request to server
      final client = await ref.read(talariaClientProvider.future);
      await client.cleanupJob(jobId);
      debugPrint('[JobStateNotifier] Server cleanup successful');

      // Delete local temporary file
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('[JobStateNotifier] Deleted temporary file: $imagePath');
      } else {
        debugPrint('[JobStateNotifier] Temporary file not found: $imagePath');
      }

      debugPrint('[JobStateNotifier] Cleanup completed successfully');
    } catch (e) {
      debugPrint('[JobStateNotifier] Cleanup failed: $e');
      // Don't fail the job if cleanup fails - it's already completed
    }
  }

  /// Reset state to idle
  void reset() {
    for (final subscription in _sseSubscriptions.values) {
      subscription.cancel();
    }
    _sseSubscriptions.clear();
    for (final timer in _autoRemoveTimers.values) {
      timer.cancel();
    }
    _autoRemoveTimers.clear();
    state = JobState.idle();
  }
}
