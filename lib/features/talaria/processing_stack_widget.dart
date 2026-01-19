import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wingtip/features/talaria/job_state.dart';
import 'package:wingtip/features/talaria/job_state_provider.dart';

/// Processing stack UI showing active jobs as a horizontal queue above the shutter button
class ProcessingStackWidget extends ConsumerStatefulWidget {
  const ProcessingStackWidget({super.key});

  @override
  ConsumerState<ProcessingStackWidget> createState() => _ProcessingStackWidgetState();
}

class _ProcessingStackWidgetState extends ConsumerState<ProcessingStackWidget> {
  final Map<String, bool> _removingJobs = {};

  @override
  Widget build(BuildContext context) {
    final jobState = ref.watch(jobStateProvider);
    final jobs = jobState.jobs;

    if (jobs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 140, // 40px (bottom margin) + 80px (shutter button) + 20px (spacing)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${jobs.length} ${jobs.length == 1 ? 'job' : 'jobs'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal job list
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final isRemoving = _removingJobs[job.id] ?? false;

                // Schedule auto-remove for completed jobs
                if (job.status == JobStatus.completed && !isRemoving) {
                  _scheduleRemoval(job.id);
                }

                return AnimatedOpacity(
                  opacity: isRemoving ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: EdgeInsets.only(right: index < jobs.length - 1 ? 8 : 0),
                    child: JobCardWidget(job: job),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleRemoval(String jobId) {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _removingJobs[jobId] = true;
        });
        // Wait for fade animation to complete before clearing from removal tracking
        Future.delayed(const Duration(milliseconds: 300), () {
          _removingJobs.remove(jobId);
        });
      }
    });
  }
}

/// Individual job card showing thumbnail with status-colored border
class JobCardWidget extends StatelessWidget {
  final ScanJob job;

  const JobCardWidget({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = _getBorderColor(job.status);

    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: _buildThumbnail(),
      ),
    );
  }

  Widget _buildThumbnail() {
    final imageFile = File(job.imagePath);

    if (!imageFile.existsSync()) {
      return Container(
        color: Colors.grey[900],
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.white54,
          size: 20,
        ),
      );
    }

    return Image.file(
      imageFile,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.broken_image,
            color: Colors.white54,
            size: 20,
          ),
        );
      },
    );
  }

  Color _getBorderColor(JobStatus status) {
    switch (status) {
      case JobStatus.uploading:
        return Colors.yellow;
      case JobStatus.listening:
      case JobStatus.processing:
        return Colors.blue;
      case JobStatus.completed:
        return Colors.green;
      case JobStatus.error:
        return Colors.red;
    }
  }
}
