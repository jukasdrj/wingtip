import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/core/talaria_client_provider.dart';
import 'package:wingtip/features/talaria/job_state.dart';

/// Notifier for managing Talaria scan job state
class JobStateNotifier extends Notifier<JobState> {
  @override
  JobState build() => JobState.idle();

  /// Upload an image to Talaria for analysis
  ///
  /// Transitions state: idle -> uploading -> listening
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
    } catch (e) {
      debugPrint('[JobStateNotifier] Upload failed: $e');
      state = JobState.error(e.toString());
    }
  }

  /// Reset state to idle
  void reset() {
    state = JobState.idle();
  }
}
