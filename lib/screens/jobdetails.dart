import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/job_model.dart';
import '../data/repositories/jobs/jobs_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.job?.coverImageUrl != null && widget.job!.coverImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppImage(
                    imageUrl: widget.job!.coverImageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 50),
                    ),
                  ),
                )
              else if (widget.job?.coverImageUrl == null || widget.job!.coverImageUrl!.isEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              const SizedBox(height: 20),
              Text(
                widget.job?.title ?? widget.jobMap?['title'] ?? 'Job Details',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (widget.job?.clientId != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: AbstractJobsRepo.getInstance().getJobById(widget.job!.id!)
                      .then((job) => job?.clientId)
                      .then((clientId) => clientId != null 
                          ? AbstractProfileRepo.getInstance().getProfileById(clientId)
                          : null),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final client = snapshot.data!;
                      final clientName = client['full_name'] as String? ?? 'Client';
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.person, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Posted by $clientName',
                            style: const TextStyle(fontSize: 14),
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
                widget.job?.fullLocation ?? widget.jobMap?['location'] ?? 'Algiers, Hydra'
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                widget.job != null
                    ? '${_formatDate(widget.job!.postedDate)} ${_formatTime(widget.job!.postedDate)} (Est. ${widget.job!.estimatedHours ?? 4} hours)'
                    : widget.jobMap?['date'] ?? '15 Nov 2023, 10:00 AM (Est. 4 hours)',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                Icons.account_balance_wallet_outlined,
                widget.job != null
                    ? 'Budget: ${widget.job!.budgetMin != null && widget.job!.budgetMax != null 
                        ? 'DA ${widget.job!.budgetMin!.toStringAsFixed(0)} - DA ${widget.job!.budgetMax!.toStringAsFixed(0)}'
                        : 'Negotiable'}'
                    : widget.jobMap?['price'] ?? 'Budget: DA 5,000 - DA 7,000',
              ),
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.job?.description ?? widget.jobMap?['description'] ?? 'No description available.',
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
                children: widget.job?.requiredServices != null && widget.job!.requiredServices!.isNotEmpty
                    ? widget.job!.requiredServices!.map((service) => _buildChip(service)).toList()
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
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, String title, String subtitle) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Job Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${job.statusLabel}',
                      style: const TextStyle(fontSize: 14),
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
                                  backgroundColor: Colors.green,
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
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                              )
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: Text(_isLoading ? 'Marking...' : 'Mark as Done'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
