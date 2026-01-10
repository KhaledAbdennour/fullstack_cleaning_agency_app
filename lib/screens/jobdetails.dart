import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_model.dart';
import '../data/models/booking_model.dart';
import '../data/repositories/jobs/jobs_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../data/repositories/bookings/bookings_repo.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/agency_dashboard_cubit.dart';
import '../utils/image_helper.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job? job; 
  final Map<String, dynamic>? jobMap; 
  
  const JobDetailsScreen({super.key, this.job, this.jobMap});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  final PageController _pageController = PageController();
  Job? _currentJob;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    if (_currentJob?.id != null) {
      _refreshJob();
    }
  }
  
  Future<void> _refreshJob() async {
    if (_currentJob?.id != null) {
      final updatedJob = await AbstractJobsRepo.getInstance().getJobById(_currentJob!.id!);
      if (updatedJob != null && mounted) {
        setState(() {
          _currentJob = updatedJob;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _currentJob ?? widget.job;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job?.title ?? widget.jobMap?['title'] ?? 'Job Details',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (job?.clientId != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: AbstractJobsRepo.getInstance().getJobById(job!.id!)
                          .then((job) => job?.clientId)
                          .then((clientId) => clientId != null 
                              ? AbstractProfileRepo.getInstance().getProfileById(clientId)
                              : null),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final client = snapshot.data!;
                          final clientName = client['full_name'] as String? ?? 'Client';
                          final clientPhoto = client['picture'] as String?;
                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: const Color(0xFF3B82F6),
                                child: clientPhoto != null && clientPhoto.isNotEmpty
                                    ? ClipOval(
                                        child: AppImage(
                                          imageUrl: clientPhoto,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorWidget: Container(
                                            width: 70,
                                            height: 70,
                                            color: const Color(0xFF3B82F6),
                                            child: const Icon(Icons.person, color: Colors.white, size: 40),
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.person, color: Colors.white, size: 40),
                              ),
                              const SizedBox(width: 12),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14, color: Colors.black),
                                  children: [
                                    const TextSpan(text: 'Posted by '),
                                    TextSpan(
                                      text: clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    Icons.location_on_outlined, 
                    job?.fullLocation ?? widget.jobMap?['location'] ?? 'Algiers, Hydra'
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    job != null
                        ? '${_formatDate(job.postedDate)} ${_formatTime(job.postedDate)} (Est. ${job.estimatedHours ?? 4} hours)'
                        : widget.jobMap?['date'] ?? '15 Nov 2023, 10:00 AM (Est. 4 hours)',
                  ),
                  const SizedBox(height: 12),
                  if (job?.id != null)
                    FutureBuilder<double?>(
                      future: _getWorkerBidForJob(job!.id!),
                      builder: (context, snapshot) {
                        final bidPrice = snapshot.data;
                        final budgetText = job.budgetMin != null && job.budgetMax != null 
                            ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
                            : 'Negotiable';
                        final displayText = bidPrice != null
                            ? 'Budget: $budgetText (Bid: DA ${bidPrice.toStringAsFixed(0)})'
                            : 'Budget: $budgetText';
                        return _buildDetailRow(
                          Icons.account_balance_wallet_outlined,
                          displayText,
                        );
                      },
                    )
                  else
                    _buildDetailRow(
                      Icons.account_balance_wallet_outlined,
                      widget.jobMap?['price'] ?? 'Budget: DA 5,000 - DA 7,000',
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job?.description ?? widget.jobMap?['description'] ?? 'No description available.',
                    style: const TextStyle(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Required Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: job?.requiredServices != null && job!.requiredServices!.isNotEmpty
                        ? job.requiredServices!.map((service) => _buildChip(service)).toList()
                        : [
                            const Text(
                              'No specific services listed',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                  ),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black))),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildActionButtons() {
    final job = _currentJob ?? widget.job;
    if (job == null) return const SizedBox.shrink();
    
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        if (state is! ProfilesLoaded || state.currentUser == null) {
          return const SizedBox.shrink();
        }
        
        final currentUser = state.currentUser!;
        final userId = currentUser['id'] as int?;
        final userType = currentUser['user_type'] as String? ?? '';
        final isCleaner = userType == 'Individual Cleaner' || userType == 'Worker';
        final isAssignedWorker = job.assignedWorkerId == userId;
        // Allow marking as done if: assigned, inProgress, or completedPendingConfirmation (if worker hasn't confirmed yet)
        final canMarkDone = isCleaner && isAssignedWorker && 
            (job.status == JobStatus.assigned || 
             job.status == JobStatus.inProgress || 
             job.status == JobStatus.completedPendingConfirmation) &&
            !job.workerDone;
        
        if (canMarkDone) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          const TextSpan(text: 'Status: '),
                          TextSpan(
                            text: job.statusLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () async {
                          setState(() => _isLoading = true);
                          try {
                            await AbstractJobsRepo.getInstance().markWorkerDone(job.id!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job marked as done! Waiting for client confirmation.'),
                                  backgroundColor: Color(0xFF3B82F6),
                                ),
                              );
                              await _refreshJob();
                              // Refresh active listings
                              if (userId != null) {
                                context.read<ActiveListingsCubit>().refresh(userId);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              String errorMessage = 'Error marking job as done';
                              if (e.toString().contains('not found')) {
                                errorMessage = 'Job not found. Please refresh and try again.';
                              } else if (e.toString().contains('already marked')) {
                                errorMessage = 'This job has already been marked as done.';
                              } else {
                                errorMessage = 'Error: ${e.toString()}';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Marking...' : 'Mark as Done',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        // For non-assigned workers or clients, show job info only
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildImageCarousel() {
    final job = _currentJob ?? widget.job;
    
    // Get all images from job_images field, or fallback to cover_image_url
    List<String> images = [];
    if (job?.jobImages != null && job!.jobImages!.isNotEmpty) {
      images = job.jobImages!;
    } else if (job?.coverImageUrl != null && job!.coverImageUrl!.isNotEmpty) {
      images = [job.coverImageUrl!];
    }
    
    if (images.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return AppImage(
                    imageUrl: images[index],
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<double?> _getWorkerBidForJob(int jobId) async {
    try {
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final applications = await bookingsRepo.getApplicationsForJob(jobId);
      // Find the accepted booking (status is inProgress or completed)
      for (final booking in applications) {
        if (booking.status == BookingStatus.inProgress || booking.status == BookingStatus.completed) {
          return booking.bidPrice;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}
