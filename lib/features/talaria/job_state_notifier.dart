import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/sse_client.dart';
import 'package:wingtip/core/sse_client_provider.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
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
  void _handleSseEvent(
    SseEvent event,
    String jobId,
    String streamUrl,
    String imagePath,
  ) {
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
        // Intermediate result - update state but keep processing
        final resultData = event.data;
        debugPrint('[JobStateNotifier] Received result: $resultData');
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
        _sseSubscription?.cancel();

      case SseEventType.error:
        // Job failed with error
        final errorMessage = event.data['message'] as String? ?? 'Unknown error';
        debugPrint('[JobStateNotifier] Job error: $errorMessage');
        state = JobState.error(errorMessage);
        _sseSubscription?.cancel();
    }
  }

  /// Reset state to idle
  void reset() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    state = JobState.idle();
  }
}
