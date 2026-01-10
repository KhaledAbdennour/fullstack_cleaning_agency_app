import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/models/job_model.dart';
import 'manage_job_page.dart';
import '../utils/image_helper.dart';

class ActivePostsPage extends StatelessWidget {
  const ActivePostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Active Posts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ProfilesCubit, ProfilesState>(
        builder: (context, profileState) {
          if (profileState is! ProfilesLoaded || profileState.currentUser == null) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
          }

          final userId = profileState.currentUser!['id'] as int?;
          final userType = profileState.currentUser!['user_type'] as String?;

          if (userId == null || userType != 'Client') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Active Posts is only available for clients.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }

          // Load client jobs when Active Posts page is first built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<ClientJobsCubit>().loadClientJobs(userId);
            }
          });

          return BlocBuilder<ClientJobsCubit, ClientJobsState>(
            builder: (context, state) {
              if (state is ClientJobsLoading && state is! ClientJobsLoaded) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
              } else if (state is ClientJobsError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<ClientJobsCubit>().refresh(userId);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              } else if (state is ClientJobsLoaded) {
                // Filter out completed jobs and deleted jobs - ONLY show active posts
                final activeJobs = state.jobs.where((job) => 
                  job.status != JobStatus.completed && 
                  !job.isDeleted
                ).toList();

                if (activeJobs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No active posts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort jobs by most recent first (postedDate descending)
                final sortedJobs = List<Job>.from(activeJobs);
                sortedJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: sortedJobs.map((job) {
                      try {
                        if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildJobPostCard(context, job);
                      } catch (e, stackTrace) {
                        print('Error building job post card: $e');
                        print('Stack trace: $stackTrace');
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildJobPostCard(BuildContext context, Job job) {
    try {
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }

      // Calculate time ago with better precision
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

      // Get status color
      Color statusColor;
      switch (job.status) {
        case JobStatus.open:
          statusColor = Colors.green;
          break;
        case JobStatus.pending:
          statusColor = Colors.orange;
          break;
        case JobStatus.assigned:
          statusColor = Colors.blue;
          break;
        case JobStatus.inProgress:
          statusColor = const Color(0xFF3B82F6);
          break;
        case JobStatus.completedPendingConfirmation:
          statusColor = Colors.purple;
          break;
        case JobStatus.completed:
          statusColor = Colors.green;
          break;
        case JobStatus.cancelled:
          statusColor = Colors.red;
          break;
        default:
          statusColor = Colors.grey;
      }

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageJobPage(job: job),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                    ? AppImage(
                        imageUrl: job.coverImageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 48, color: Colors.grey),
                      ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            job.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Text(
                      job.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Budget (Min - Max) with blue icon - under description, above location
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
        ),
      );
    } catch (e, stackTrace) {
      print('Error building job post card: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }
}
