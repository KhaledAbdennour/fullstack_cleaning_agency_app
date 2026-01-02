import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cleaner_profile_page.dart';
import '../data/models/job_model.dart';
import '../data/models/booking_model.dart';
import '../logic/cubits/job_applications_cubit.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../utils/image_helper.dart';

class ManageJobPage extends StatefulWidget {
  final Job job; 
  
  const ManageJobPage({super.key, required this.job});

  @override
  State<ManageJobPage> createState() => _ManageJobPageState();
}

class _ManageJobPageState extends State<ManageJobPage> {
  @override
  void initState() {
    super.initState();
    
    context.read<JobApplicationsCubit>().loadApplicationsForJob(widget.job.id!);
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
            const SizedBox(height: 24),
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
                    child: CircularProgressIndicator(),
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
                  return Column(
                    children: validApplications.map((booking) => _buildApplicationCard(booking)).toList(),
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
            child: widget.job.coverImageUrl != null
                ? AppImage(
                    imageUrl: widget.job.coverImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      width: double.infinity,
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.image, size: 50, color: Color(0xFF9CA3AF)),
                    ),
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(Icons.image, size: 50, color: Color(0xFF9CA3AF)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.job.title,
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
                  widget.job.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.job.fullLocation} - ${_formatDate(widget.job.jobDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final cleanerProfile = snapshot.data;
        final cleanerName = cleanerProfile?['full_name'] as String? ?? 
                           cleanerProfile?['agency_name'] as String? ?? 
                           'Unknown';
        final cleanerAvatar = cleanerProfile?['avatar_url'] as String?;
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
                    backgroundColor: Colors.grey[200],
                    backgroundImage: cleanerAvatar != null && cleanerAvatar.startsWith('http')
                        ? NetworkImage(cleanerAvatar)
                        : null,
                    child: cleanerAvatar == null || !cleanerAvatar.startsWith('http')
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
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
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Rejected',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
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
                            final state = profilesCubit.state;
                            if (state is ProfilesLoaded && state.currentUser != null) {
                              final clientId = state.currentUser!['id'] as int?;
                              if (clientId != null) {
                                context.read<ClientJobsCubit>().refresh(clientId);
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                            borderRadius: BorderRadius.circular(10),
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
                child: OutlinedButton(
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
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
