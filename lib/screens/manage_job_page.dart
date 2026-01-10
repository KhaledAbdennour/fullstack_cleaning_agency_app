import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cleaner_profile_page.dart';
import 'review_page.dart';
import '../data/models/job_model.dart';
import '../data/models/booking_model.dart';
import '../logic/cubits/job_applications_cubit.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../data/repositories/jobs/jobs_repo.dart';
import '../utils/image_helper.dart';

class ManageJobPage extends StatefulWidget {
  final Job job; 
  
  const ManageJobPage({super.key, required this.job});

  @override
  State<ManageJobPage> createState() => _ManageJobPageState();
}

class _ManageJobPageState extends State<ManageJobPage> {
  Job? _currentJob;
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    context.read<JobApplicationsCubit>().loadApplicationsForJob(widget.job.id!);
    _refreshJob();
  }
  
  Future<void> _refreshJob() async {
    if (_currentJob?.id != null) {
      final updatedJob = await AbstractJobsRepo.getInstance().getJobById(_currentJob!.id!);
      if (updatedJob != null && mounted) {
        setState(() {
          _currentJob = updatedJob;
        });
      }
    } else if (widget.job.id != null) {
      // Fallback: refresh from widget.job if _currentJob is null
      final updatedJob = await AbstractJobsRepo.getInstance().getJobById(widget.job.id!);
      if (updatedJob != null && mounted) {
        setState(() {
          _currentJob = updatedJob;
        });
      }
    }
  }

  /// Fetches ratings for all applications to enable sorting
  Future<Map<int, double>> _fetchRatingsForApplications(List<Booking> applications) async {
    final ratingsMap = <int, double>{};
    final profileRepo = AbstractProfileRepo.getInstance();
    
    // Fetch all profiles in parallel
    final futures = applications.map((booking) async {
      if (booking.providerId == null) return;
      try {
        final profile = await profileRepo.getProfileById(booking.providerId!);
        if (profile != null) {
          final rating = (profile['rating'] as num?)?.toDouble() ?? 0.0;
          ratingsMap[booking.providerId!] = rating;
        }
      } catch (e) {
        // If profile fetch fails, default to 0.0
        ratingsMap[booking.providerId!] = 0.0;
      }
    }).toList();
    
    await Future.wait(futures);
    return ratingsMap;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Manage Job',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobDetailsCard(),
            const SizedBox(height: 16),
            _buildJobActionsCard(),
            const SizedBox(height: 24),
            if (_currentJob?.assignedWorkerId != null) _buildAssignedWorkerCard(),
            if (_currentJob?.assignedWorkerId != null) const SizedBox(height: 24),
            const Text(
              'Applications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<JobApplicationsCubit, JobApplicationsState>(
              builder: (context, state) {
                if (state is JobApplicationsLoading) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: const CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ));
                } else if (state is JobApplicationsError) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                } else if (state is JobApplicationsLoaded) {
                  if (state.applications.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Text(
                          'No applications yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final validApplications = state.applications.where((booking) => booking.providerId != null).toList();
                  if (validApplications.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Text(
                          'No applications yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Sort applications by rating (highest to lowest)
                  return FutureBuilder<Map<int, double>>(
                    future: _fetchRatingsForApplications(validApplications),
                    builder: (context, ratingsSnapshot) {
                      if (ratingsSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                          ),
                        );
                      }
                      
                      final ratingsMap = ratingsSnapshot.data ?? {};
                      final sortedApplications = List<Booking>.from(validApplications);
                      sortedApplications.sort((a, b) {
                        final ratingA = ratingsMap[a.providerId] ?? 0.0;
                        final ratingB = ratingsMap[b.providerId] ?? 0.0;
                        // Sort descending (highest rating first)
                        return ratingB.compareTo(ratingA);
                      });
                      
                      return Column(
                        children: sortedApplications.map((booking) => _buildApplicationCard(booking)).toList(),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetailsCard() {
    final job = _currentJob ?? widget.job;
    
    // Calculate time ago
    final now = DateTime.now();
    final difference = now.difference(job.postedDate);
    String timeAgoText;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          timeAgoText = 'Just now';
        } else {
          timeAgoText = '${difference.inMinutes}m ago';
        }
      } else {
        timeAgoText = '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      timeAgoText = 'Yesterday';
    } else if (difference.inDays < 7) {
      timeAgoText = '${difference.inDays}d ago';
    } else {
      timeAgoText = '${job.postedDate.day}/${job.postedDate.month}/${job.postedDate.year}';
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImageCarousel(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Budget (Min - Max) with blue icon - under description, above location
                if (job.budgetMin != null || job.budgetMax != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.budgetMin != null && job.budgetMax != null
                                ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
                                : job.budgetMin != null
                                    ? 'DA ${job.budgetMin!.toStringAsFixed(0)}'
                                    : job.budgetMax != null
                                        ? 'DA ${job.budgetMax!.toStringAsFixed(0)}'
                                        : 'Budget negotiable',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Location with blue icon
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${job.city}, ${job.country}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Date with blue icon and time ago in parentheses - under location
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${job.postedDate.day}/${job.postedDate.month}/${job.postedDate.year} ($timeAgoText)',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Booking booking) {
    final bool isAccepted = booking.status == BookingStatus.inProgress;
    final bool isRejected = booking.status == BookingStatus.cancelled;
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: AbstractProfileRepo.getInstance().getProfileById(booking.providerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          );
        }
        
        final cleanerProfile = snapshot.data;
        final cleanerName = cleanerProfile?['full_name'] as String? ?? 
                           cleanerProfile?['agency_name'] as String? ?? 
                           'Unknown';
        // Try multiple fields for profile picture: picture, image, avatar_url, or profileData.picture
        final profileData = cleanerProfile?['profileData'] as Map<String, dynamic>?;
        final cleanerAvatar = cleanerProfile?['picture'] as String? ?? 
                             cleanerProfile?['image'] as String? ?? 
                             cleanerProfile?['avatar_url'] as String? ??
                             profileData?['picture'] as String? ??
                             profileData?['image'] as String? ??
                             profileData?['avatar_url'] as String?;
        final cleanerRating = (cleanerProfile?['rating'] as num?)?.toDouble() ?? 0.0;
        final cleanerReviewsCount = cleanerProfile?['reviews_count'] as int? ?? 0;
        final priceText = booking.bidPrice != null 
            ? 'DA ${booking.bidPrice!.toStringAsFixed(0)}'
            : 'Price negotiable';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3B82F6),
                    backgroundImage: cleanerAvatar != null && (cleanerAvatar.startsWith('http') || cleanerAvatar.startsWith('data:image'))
                        ? (cleanerAvatar.startsWith('data:image')
                            ? MemoryImage(base64Decode(cleanerAvatar.split(',').last))
                            : NetworkImage(cleanerAvatar))
                        : null,
                    child: cleanerAvatar == null || (!cleanerAvatar.startsWith('http') && !cleanerAvatar.startsWith('data:image'))
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                cleanerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            // Rating display next to name
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cleanerRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          priceText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (booking.message != null && booking.message!.isNotEmpty)
                Text(
                  booking.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              const SizedBox(height: 16),

              
              if (isAccepted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Accepted',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else if (isRejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Rejected',
                      style: TextStyle(
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await context.read<JobApplicationsCubit>().acceptApplication(
                            booking.id!,
                            widget.job.id!,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Accepted $cleanerName for this job!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            final profilesCubit = context.read<ProfilesCubit>();
                            await profilesCubit.loadCurrentUser();
                            if (!mounted) return;
                            final state = profilesCubit.state;
                            if (state is ProfilesLoaded && state.currentUser != null) {
                              final clientId = state.currentUser!['id'] as int?;
                              if (clientId != null && mounted) {
                                context.read<ClientJobsCubit>().refresh(clientId);
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accept',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await context.read<JobApplicationsCubit>().rejectApplication(
                            booking.id!,
                            widget.job.id!,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Rejected $cleanerName'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),

              
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    if (cleanerProfile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CleanerProfilePage(cleaner: cleanerProfile),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobActionsCard() {
    // Always use the most up-to-date job
    final job = _currentJob ?? widget.job;
    final canActivate = job.status == JobStatus.paused || job.status == JobStatus.cancelled;
    final canDelete = job.status != JobStatus.completed;
    final canConfirmCompletion = job.workerDone && !job.clientDone && 
        (job.status == JobStatus.completedPendingConfirmation || job.status == JobStatus.inProgress);
    
    // Only allow review when job is FULLY completed:
    // 1. Status must be 'completed' (not 'completedPendingConfirmation')
    // 2. Both clientDone AND workerDone must be true
    final isFullyCompleted = job.status == JobStatus.completed && 
        job.clientDone == true && 
        job.workerDone == true;
    
    final canLeaveReview = isFullyCompleted && job.assignedWorkerId != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Job Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          if (canConfirmCompletion)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await AbstractJobsRepo.getInstance().markClientDone(job.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job completion confirmed! You can now leave a review.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      
                      // Wait a moment for Firestore to update
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Refresh job to get updated status
                      await _refreshJob();
                      
                      // Force rebuild to show review button
                      if (mounted) {
                        setState(() {});
                      }
                      
                      // Refresh client jobs
                      final profilesCubit = context.read<ProfilesCubit>();
                      await profilesCubit.loadCurrentUser();
                      if (mounted) {
                        final state = profilesCubit.state;
                        if (state is ProfilesLoaded && state.currentUser != null) {
                          final clientId = state.currentUser!['id'] as int?;
                          if (clientId != null) {
                            context.read<ClientJobsCubit>().refresh(clientId);
                          }
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      // Safely format error message (avoid encoding FieldValue or showing type cast errors)
                      String errorMsg = 'Error confirming completion';
                      try {
                        final errorStr = e.toString();
                        if (errorStr.contains('is not a subtype of type')) {
                          errorMsg = 'Data type error. Please try again or contact support.';
                        } else if (errorStr.contains('FieldValue')) {
                          errorMsg = 'Invalid data format. Please try again.';
                        } else {
                          errorMsg = errorStr.length > 100 ? '${errorStr.substring(0, 100)}...' : errorStr;
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
                  }
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Confirm Completion',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (canLeaveReview)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Always fetch fresh job data from database before opening review
                  if (job.id == null) return;
                  
                  final freshJob = await AbstractJobsRepo.getInstance().getJobById(job.id!);
                  if (freshJob == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job not found.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Triple-check: job must be fully completed
                  if (freshJob.status != JobStatus.completed || 
                      freshJob.clientDone != true || 
                      freshJob.workerDone != true) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Job is not fully completed yet. Current status: ${freshJob.status.name}. Please wait until both parties confirm completion.'),
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      // Refresh UI to update button visibility
                      await _refreshJob();
                    }
                    return;
                  }
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewPage(
                        bookingTitle: freshJob.title,
                        jobId: freshJob.id,
                        cleanerId: freshJob.assignedWorkerId,
                      ),
                    ),
                  );
                  
                  // Refresh job after review submission
                  await _refreshJob();
                  
                  // If review was submitted successfully, refresh client jobs
                  if (result == true && mounted) {
                    final profilesCubit = context.read<ProfilesCubit>();
                    await profilesCubit.loadCurrentUser();
                    if (mounted) {
                      final state = profilesCubit.state;
                      if (state is ProfilesLoaded && state.currentUser != null) {
                        final clientId = state.currentUser!['id'] as int?;
                        if (clientId != null) {
                          context.read<ClientJobsCubit>().refresh(clientId);
                        }
                      }
                    }
                  }
                },
                icon: const Icon(Icons.star, color: Colors.white),
                label: const Text('Leave a Review', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (canActivate || canDelete) const SizedBox(height: 8),
          if (canActivate)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await AbstractJobsRepo.getInstance().changeJobStatus(job.id!, JobStatus.open);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Job activated')),
                      );
                      await _refreshJob();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Activate Job'),
              ),
            ),
          if (canDelete)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Job'),
                      content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      // Show loading indicator
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Deleting job...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                      
                      // Delete the job and wait for it to complete
                      await AbstractJobsRepo.getInstance().deleteJob(job.id!);
                      
                      // Wait a bit more to ensure Firestore has committed the change
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Job deleted successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                        
                        // Wait before refreshing to ensure deletion is committed
                        await Future.delayed(const Duration(milliseconds: 300));
                        
                        // Refresh client jobs after deletion (only after deletion is confirmed)
                        final profilesCubit = context.read<ProfilesCubit>();
                        final profileState = profilesCubit.state;
                        if (profileState is ProfilesLoaded && profileState.currentUser != null) {
                          final userId = profileState.currentUser!['id'] as int?;
                          if (userId != null) {
                            context.read<ClientJobsCubit>().refresh(userId);
                          }
                        }
                        
                        Navigator.pop(context);
                      }
                    } catch (e, stackTrace) {
                      if (mounted) {
                        print('❌ Error deleting job: $e');
                        print('❌ Stack trace: $stackTrace');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting job: ${e.toString()}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                label: const Text('Delete Job', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAssignedWorkerCard() {
    final job = _currentJob ?? widget.job;
    if (job.assignedWorkerId == null) return const SizedBox.shrink();
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: AbstractProfileRepo.getInstance().getProfileById(job.assignedWorkerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
        }
        
        final worker = snapshot.data;
        if (worker == null) return const SizedBox.shrink();
        
        final workerName = worker['full_name'] as String? ?? worker['agency_name'] as String? ?? 'Unknown';
        // Try multiple fields for profile picture: picture, image, avatar_url, or profileData.picture
        final profileData = worker['profileData'] as Map<String, dynamic>?;
        final workerAvatar = worker['picture'] as String? ?? 
                           worker['image'] as String? ?? 
                           worker['avatar_url'] as String? ??
                           profileData?['picture'] as String? ??
                           profileData?['image'] as String? ??
                           profileData?['avatar_url'] as String?;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned Worker',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF3B82F6),
                    backgroundImage: workerAvatar != null && (workerAvatar.startsWith('http') || workerAvatar.startsWith('data:image'))
                        ? (workerAvatar.startsWith('data:image')
                            ? MemoryImage(base64Decode(workerAvatar.split(',').last))
                            : NetworkImage(workerAvatar))
                        : null,
                    child: workerAvatar == null || (!workerAvatar.startsWith('http') && !workerAvatar.startsWith('data:image'))
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      workerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CleanerProfilePage(cleaner: worker),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Profile', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageCarousel() {
    final job = _currentJob ?? widget.job;
    
    // Get all images from job_images field, or fallback to cover_image_url
    List<String> images = [];
    if (job.jobImages != null && job.jobImages!.isNotEmpty) {
      images = job.jobImages!;
    } else if (job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty) {
      images = [job.coverImageUrl!];
    }
    
    if (images.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFFE5E7EB),
        child: const Icon(Icons.image, size: 50, color: Color(0xFF9CA3AF)),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return AppImage(
                    imageUrl: images[index],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      width: double.infinity,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.image, size: 50, color: Color(0xFF9CA3AF)),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
