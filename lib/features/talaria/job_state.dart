/// Represents the state of a Talaria scan job
class JobState {
  final String? jobId;
  final String? streamUrl;
  final String? imagePath;
  final JobStatus status;
  final String? errorMessage;

  const JobState({
    this.jobId,
    this.streamUrl,
    this.imagePath,
    required this.status,
    this.errorMessage,
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
  }) {
    return JobState(
      jobId: jobId ?? this.jobId,
      streamUrl: streamUrl ?? this.streamUrl,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

enum JobStatus {
  idle,
  uploading,
  listening,
  error,
}
