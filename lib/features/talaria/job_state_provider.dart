import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/job_state_notifier.dart';

/// Provider for the current Talaria scan job state
///
/// Manages the lifecycle of image upload and SSE listening.
/// The notifier uses talariaClientProvider internally via ref.read().
final jobStateProvider = NotifierProvider<JobStateNotifier, JobState>(
  JobStateNotifier.new,
);
