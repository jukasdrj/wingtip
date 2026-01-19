import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    });

    return JobState.idle();
  }

  /// Upload an image to Talaria for analysis
  ///
  /// Adds a new job to the queue and starts processing
  Future<void> uploadImage(String imagePath) async {
    try {
      // Create new job in uploading state
      final job = ScanJob.uploading(imagePath);

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
    } catch (e) {
      debugPrint('[JobStateNotifier] Upload failed: $e');
      // Update the job to error state if it exists
      final jobs = state.jobs;
      if (jobs.isNotEmpty) {
        final lastJob = jobs.last;
        _updateJob(
          lastJob.id,
          lastJob.copyWith(
            status: JobStatus.error,
            errorMessage: e.toString(),
          ),
        );
      }
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
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.processing,
            progress: progress.toDouble(),
          ),
        );

      case SseEventType.result:
        // Intermediate result - save to database and update state
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Received result for job $jobId: $resultData');
        await _saveBookResult(resultData);
        _updateJob(
          jobId,
          job.copyWith(result: resultData),
        );

      case SseEventType.complete:
        // Job completed successfully
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Job $jobId completed: $resultData');
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
        _updateJob(
          jobId,
          job.copyWith(
            status: JobStatus.error,
            errorMessage: errorMessage,
          ),
        );
        _sseSubscriptions[jobId]?.cancel();
        _sseSubscriptions.remove(jobId);
    }
  }

  /// Save book result to database
  Future<void> _saveBookResult(Map<String, dynamic> resultData) async {
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
