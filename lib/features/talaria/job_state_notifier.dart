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
  StreamSubscription<SseEvent>? _sseSubscription;

  @override
  JobState build() {
    // Clean up subscription when notifier is disposed
    ref.onDispose(() {
      _sseSubscription?.cancel();
    });

    return JobState.idle();
  }

  /// Upload an image to Talaria for analysis
  ///
  /// Transitions state: idle -> uploading -> listening -> processing -> completed
  /// On error, transitions to error state with error message
  Future<void> uploadImage(String imagePath) async {
    try {
      // Update state to uploading
      state = JobState.uploading(imagePath);

      debugPrint('[JobStateNotifier] Uploading image: $imagePath');

      // Get TalariaClient from provider
      final client = await ref.read(talariaClientProvider.future);

      // Upload to Talaria
      final response = await client.uploadImage(imagePath);

      debugPrint('[JobStateNotifier] Upload successful:');
      debugPrint('  - Job ID: ${response.jobId}');
      debugPrint('  - Stream URL: ${response.streamUrl}');

      // Update state to listening
      state = JobState.listening(
        jobId: response.jobId,
        streamUrl: response.streamUrl,
        imagePath: imagePath,
      );

      // Start listening to SSE stream
      await _listenToStream(response.jobId, response.streamUrl, imagePath);
    } catch (e) {
      debugPrint('[JobStateNotifier] Upload failed: $e');
      state = JobState.error(e.toString());
    }
  }

  /// Listen to SSE stream for job updates
  Future<void> _listenToStream(
    String jobId,
    String streamUrl,
    String imagePath,
  ) async {
    try {
      // Cancel any existing subscription
      await _sseSubscription?.cancel();

      // Get SSE client from provider
      final sseClient = ref.read(sseClientProvider);

      debugPrint('[JobStateNotifier] Starting SSE stream for job: $jobId');

      // Listen to the stream
      _sseSubscription = sseClient.listen(streamUrl).listen(
        (event) {
          _handleSseEvent(event, jobId, streamUrl, imagePath);
        },
        onError: (error) {
          debugPrint('[JobStateNotifier] SSE stream error: $error');
          state = JobState.error(error.toString());
        },
        onDone: () {
          debugPrint('[JobStateNotifier] SSE stream closed');
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[JobStateNotifier] Failed to start SSE stream: $e');
      state = JobState.error(e.toString());
    }
  }

  /// Handle individual SSE events
  Future<void> _handleSseEvent(
    SseEvent event,
    String jobId,
    String streamUrl,
    String imagePath,
  ) async {
    debugPrint('[JobStateNotifier] Handling SSE event: ${event.type}');

    switch (event.type) {
      case SseEventType.progress:
        final progress = event.data['progress'] as num? ?? 0.0;
        state = JobState.processing(
          jobId: jobId,
          streamUrl: streamUrl,
          imagePath: imagePath,
          progress: progress.toDouble(),
        );

      case SseEventType.result:
        // Intermediate result - save to database and update state
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Received result: $resultData');
        await _saveBookResult(resultData);
        state = state.copyWith(result: resultData);

      case SseEventType.complete:
        // Job completed successfully
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Job completed: $resultData');
        state = JobState.completed(
          jobId: jobId,
          imagePath: imagePath,
          result: resultData,
        );
        await _sseSubscription?.cancel();

        // Perform cleanup
        await _cleanupJob(jobId, imagePath);

      case SseEventType.error:
        // Job failed with error
        final errorMessage = event.data['message'] as String? ?? 'Unknown error';
        debugPrint('[JobStateNotifier] Job error: $errorMessage');
        state = JobState.error(errorMessage);
        _sseSubscription?.cancel();
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
    _sseSubscription?.cancel();
    _sseSubscription = null;
    state = JobState.idle();
  }
}
