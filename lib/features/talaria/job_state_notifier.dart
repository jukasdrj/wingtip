import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/failed_scans_directory.dart';
import 'package:wingtip/core/sse_client.dart';
import 'package:wingtip/core/sse_client_provider.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
import 'package:wingtip/data/database.dart';
import 'package:wingtip/data/database_provider.dart';
import 'package:wingtip/features/talaria/job_state.dart';

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
  Future<void> retryFailedScan(String failedScanJobId) async {
    ScanJob? job;
    String? imagePath;

    try {
      debugPrint('[JobStateNotifier] Retrying failed scan: $failedScanJobId');

      // Get the failed scan from database
      final database = ref.read(databaseProvider);
      final failedScan = await database.getFailedScan(failedScanJobId);

      if (failedScan == null) {
        debugPrint('[JobStateNotifier] Failed scan not found: $failedScanJobId');
        return;
      }

      // Store image path for error handlers
      imagePath = failedScan.imagePath;

      // Verify image exists
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('[JobStateNotifier] Image file not found: $imagePath');
        // Update error message
        await database.saveFailedScan(
          jobId: failedScanJobId,
          imagePath: imagePath,
          errorMessage: 'Image file missing - cannot retry',
        );
        return;
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

      // Update job to listening state
      _updateJob(
        job.id,
        job.copyWith(
          jobId: response.jobId,
          streamUrl: response.streamUrl,
          status: JobStatus.listening,
        ),
      );

      // Start listening to SSE stream
      // Use the original failedScanJobId for cleanup tracking
      await _listenToStream(job.id, failedScanJobId, response.streamUrl);
    } on DioException catch (e) {
      debugPrint('[JobStateNotifier] DioException during retry upload: ${e.type}');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
    } on SocketException catch (e) {
      debugPrint('[JobStateNotifier] SocketException during retry upload: $e');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
    } on TimeoutException catch (e) {
      debugPrint('[JobStateNotifier] TimeoutException during retry upload: $e');
      await _handleRetryError(e, job, imagePath ?? '', failedScanJobId);
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
    }
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

      // Upload to Talaria
      final response = await client.uploadImage(imagePath);

      debugPrint('[JobStateNotifier] Upload successful for job ${job.id}:');
      debugPrint('  - Job ID: ${response.jobId}');
      debugPrint('  - Stream URL: ${response.streamUrl}');

      // Update job to listening state
      _updateJob(
        job.id,
        job.copyWith(
          jobId: response.jobId,
          streamUrl: response.streamUrl,
          status: JobStatus.listening,
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
    String errorMessage;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Upload timed out after 30s';
        case DioExceptionType.connectionError:
          errorMessage = 'Server unreachable';
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${error.response?.statusCode ?? "unknown"}';
        case DioExceptionType.cancel:
          errorMessage = 'Upload cancelled';
        default:
          errorMessage = 'No internet connection';
      }
    } else if (error is SocketException) {
      errorMessage = 'No internet connection';
    } else if (error is TimeoutException) {
      errorMessage = 'Upload timed out after 30s';
    } else {
      errorMessage = error.toString();
    }

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

        await database.saveFailedScan(
          jobId: jobId,
          imagePath: failedScan.imagePath,
          errorMessage: updatedMessage,
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
    String errorMessage;
    String? serverJobId;

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage = 'Upload timed out after 30s';
        case DioExceptionType.connectionError:
          errorMessage = 'Server unreachable';
        case DioExceptionType.badResponse:
          errorMessage = 'Server error: ${error.response?.statusCode ?? "unknown"}';
        case DioExceptionType.cancel:
          errorMessage = 'Upload cancelled';
        default:
          errorMessage = 'No internet connection';
      }
    } else if (error is SocketException) {
      errorMessage = 'No internet connection';
    } else if (error is TimeoutException) {
      errorMessage = 'Upload timed out after 30s';
    } else {
      errorMessage = error.toString();
    }

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
          _updateJob(
            jobId,
            job.copyWith(
              status: JobStatus.error,
              errorMessage: 'No books detected in this image',
            ),
          );
          await _sseSubscriptions[jobId]?.cancel();
          _sseSubscriptions.remove(jobId);

          // Save failed scan to database
          await _saveFailedScan(serverJobId, job.imagePath, 'No books detected in this image');
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

        // Save failed scan to database
        await _saveFailedScan(serverJobId, job.imagePath, errorMessage);
    }
  }

  /// Save failed scan to database and move image to persistent storage
  Future<void> _saveFailedScan(
    String jobId,
    String imagePath,
    String errorMessage,
  ) async {
    try {
      // Move image from temp to persistent failed_scans directory
      final persistentPath = await FailedScansDirectory.moveImage(imagePath, jobId);
      debugPrint('[JobStateNotifier] Moved failed scan image to: $persistentPath');

      final database = ref.read(databaseProvider);
      await database.saveFailedScan(
        jobId: jobId,
        imagePath: persistentPath,
        errorMessage: errorMessage,
      );
      debugPrint('[JobStateNotifier] Failed scan saved: $jobId');
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
