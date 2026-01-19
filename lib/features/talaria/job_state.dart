/// Represents a single Talaria scan job
class ScanJob {
  final String id; // Unique client-side ID
  final String? jobId; // Server-side job ID
  final String? streamUrl;
  final String imagePath;
  final JobStatus status;
  final String? errorMessage;
  final double? progress;
  final Map<String, dynamic>? result;
  final DateTime createdAt;

  const ScanJob({
    required this.id,
    this.jobId,
    this.streamUrl,
    required this.imagePath,
    required this.status,
    this.errorMessage,
    this.progress,
    this.result,
    required this.createdAt,
  });

  factory ScanJob.uploading(String imagePath) {
    return ScanJob(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: JobStatus.uploading,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
  }

  ScanJob copyWith({
    String? jobId,
    String? streamUrl,
    JobStatus? status,
    String? errorMessage,
    double? progress,
    Map<String, dynamic>? result,
  }) {
    return ScanJob(
      id: id,
      jobId: jobId ?? this.jobId,
      streamUrl: streamUrl ?? this.streamUrl,
      imagePath: imagePath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      createdAt: createdAt,
    );
  }
}

/// Represents the state of all Talaria scan jobs
class JobState {
  final List<ScanJob> jobs;

  const JobState({
    this.jobs = const [],
  });

  factory JobState.idle() {
    return const JobState(jobs: []);
  }

  JobState copyWith({
    List<ScanJob>? jobs,
  }) {
    return JobState(
      jobs: jobs ?? this.jobs,
    );
  }

  /// Get active jobs (not completed or error)
  List<ScanJob> get activeJobs {
    return jobs
        .where((job) =>
            job.status != JobStatus.completed && job.status != JobStatus.error)
        .toList();
  }

  /// Get job by ID
  ScanJob? getJobById(String id) {
    try {
      return jobs.firstWhere((job) => job.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get job by server job ID
  ScanJob? getJobByJobId(String jobId) {
    try {
      return jobs.firstWhere((job) => job.jobId == jobId);
    } catch (e) {
      return null;
    }
  }
}

enum JobStatus {
  uploading,
  listening,
  processing,
  completed,
  error,
}
