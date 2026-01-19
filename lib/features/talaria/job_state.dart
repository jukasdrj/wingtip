/// Represents the state of a Talaria scan job
class JobState {
  final String? jobId;
  final String? streamUrl;
  final String? imagePath;
  final JobStatus status;
  final String? errorMessage;
  final double? progress;
  final Map<String, dynamic>? result;

  const JobState({
    this.jobId,
    this.streamUrl,
    this.imagePath,
    required this.status,
    this.errorMessage,
    this.progress,
    this.result,
  });

  factory JobState.idle() {
    return const JobState(status: JobStatus.idle);
  }

  factory JobState.uploading(String imagePath) {
    return JobState(
      status: JobStatus.uploading,
      imagePath: imagePath,
    );
  }

  factory JobState.listening({
    required String jobId,
    required String streamUrl,
    required String imagePath,
  }) {
    return JobState(
      status: JobStatus.listening,
      jobId: jobId,
      streamUrl: streamUrl,
      imagePath: imagePath,
    );
  }

  factory JobState.processing({
    required String jobId,
    required String streamUrl,
    required String imagePath,
    required double progress,
  }) {
    return JobState(
      status: JobStatus.processing,
      jobId: jobId,
      streamUrl: streamUrl,
      imagePath: imagePath,
      progress: progress,
    );
  }

  factory JobState.completed({
    required String jobId,
    required String imagePath,
    required Map<String, dynamic> result,
  }) {
    return JobState(
      status: JobStatus.completed,
      jobId: jobId,
      imagePath: imagePath,
      result: result,
    );
  }

  factory JobState.error(String message) {
    return JobState(
      status: JobStatus.error,
      errorMessage: message,
    );
  }

  JobState copyWith({
    String? jobId,
    String? streamUrl,
    String? imagePath,
    JobStatus? status,
    String? errorMessage,
    double? progress,
    Map<String, dynamic>? result,
  }) {
    return JobState(
      jobId: jobId ?? this.jobId,
      streamUrl: streamUrl ?? this.streamUrl,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      result: result ?? this.result,
    );
  }
}

enum JobStatus {
  idle,
  uploading,
  listening,
  processing,
  completed,
  error,
}
