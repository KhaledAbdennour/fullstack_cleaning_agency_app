import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_model.dart';
import '../data/repositories/reviews/reviews_repo.dart';
import '../data/repositories/jobs/jobs_repo.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../core/debug/debug_logger.dart';

class ReviewPage extends StatefulWidget {
  final String bookingTitle;
  final int? jobId;
  final int? cleanerId;

  const ReviewPage({
    super.key,
    required this.bookingTitle,
    this.jobId,
    this.cleanerId,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingJob = true;
  String? _jobStatusError;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    if (widget.jobId == null) {
      setState(() {
        _isLoadingJob = false;
        _jobStatusError = 'Job ID not provided';
      });
      return;
    }

    setState(() {
      _isLoadingJob = true;
      _jobStatusError = null;
    });

    try {
      final jobsRepo = AbstractJobsRepo.getInstance();
      final job = await jobsRepo.getJobById(widget.jobId!);

      if (mounted) {
        setState(() {
          _isLoadingJob = false;
          if (job == null) {
            _jobStatusError = 'Job not found';
          } else if (job.status != JobStatus.completed) {
            _jobStatusError =
                'Job is not completed yet. Current status: ${job.status.name}. Please wait until both parties confirm completion.';
          } else if (!job.clientDone || !job.workerDone) {
            _jobStatusError =
                'Job is not fully completed yet. Both parties must confirm completion before leaving a review.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingJob = false;
          _jobStatusError = 'Error loading job: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Leave a Review',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE5E7EB),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Review for ${widget.bookingTitle}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoadingJob)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                )
              else if (_jobStatusError != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _jobStatusError!,
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text(
                "How would you rate your experience?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: index < _rating
                          ? const Color(0xFFFFB800)
                          : Colors.grey.shade400,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                "Share your feedback",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Tell us about your experience...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isSubmitting ||
                          _rating == 0 ||
                          widget.cleanerId == null ||
                          _isLoadingJob ||
                          _jobStatusError != null)
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);

                          try {
                            final profilesCubit = context.read<ProfilesCubit>();
                            await profilesCubit.loadCurrentUser();
                            final state = profilesCubit.state;

                            if (state is ProfilesLoaded &&
                                state.currentUser != null) {
                              final reviewerId =
                                  state.currentUser!['id'] as int?;

                              if (reviewerId == null) {
                                throw Exception('User ID not found');
                              }

                              if (widget.jobId != null) {
                                final jobsRepo = AbstractJobsRepo.getInstance();
                                final job = await jobsRepo.getJobById(
                                  widget.jobId!,
                                );
                                if (job == null) {
                                  throw Exception('Job not found');
                                }
                                DebugLogger.log(
                                  'ReviewPage',
                                  'PRE_SUBMIT_JOB_STATUS',
                                  data: {
                                    'jobId': widget.jobId,
                                    'status': job.status.name,
                                    'client_done': job.clientDone,
                                    'worker_done': job.workerDone,
                                  },
                                );
                                if (job.status != JobStatus.completed) {
                                  throw Exception(
                                    'Reviews can only be added for completed jobs. Current job status: ${job.status.name}. Please wait until both parties confirm completion.',
                                  );
                                }
                                if (!job.clientDone || !job.workerDone) {
                                  throw Exception(
                                    'Job is not fully completed yet. Both parties must confirm completion before leaving a review.',
                                  );
                                }
                              }

                              if (widget.cleanerId == null ||
                                  widget.jobId == null) {
                                throw Exception(
                                  'Cleaner ID or Job ID is missing',
                                );
                              }

                              final reviewsRepo =
                                  AbstractReviewsRepo.getInstance();
                              await reviewsRepo.addReview(
                                jobId: widget.jobId!,
                                revieweeId: widget.cleanerId!.toString(),
                                rating: _rating,
                                comment: _feedbackController.text.trim(),
                              );

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Review submitted successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                Navigator.pop(
                                  context,
                                  true,
                                );
                              }
                            } else {
                              throw Exception('User not logged in');
                            }
                          } catch (e) {
                            if (mounted) {
                              String errorMsg = 'Error submitting review';
                              try {
                                final errorStr = e.toString();
                                if (errorStr.contains(
                                  'is not a subtype of type',
                                )) {
                                  errorMsg =
                                      'Data type error. Please try again or contact support.';
                                } else if (errorStr.contains('FieldValue')) {
                                  errorMsg =
                                      'Invalid data format. Please try again.';
                                } else {
                                  errorMsg = errorStr.length > 100
                                      ? '${errorStr.substring(0, 100)}...'
                                      : errorStr;
                                }
                              } catch (_) {
                                errorMsg = 'An unexpected error occurred';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : const Text(
                          "Submit Review",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
