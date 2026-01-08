import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/agency_dashboard_cubit.dart';
import '../logic/cubits/available_jobs_cubit.dart';
import '../data/models/job_model.dart';
import '../data/models/cleaner_model.dart';
import '../data/models/booking_model.dart';
import 'job_details_bid_page.dart';
import 'jobdetails.dart';
import 'cleaner_profile_page.dart';
import 'add_cleaner_page.dart';
import 'login.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../data/repositories/bookings/bookings_repo.dart';
import '../utils/image_helper.dart';
import '../utils/age_helper.dart';
import '../widgets/notification_bell_widget.dart';





class AgencyDashboardPage extends StatefulWidget {
  final int? initialTab;
  final int? highlightJobId;
  
  const AgencyDashboardPage({
    super.key,
    this.initialTab,
    this.highlightJobId,
  });

  @override
  State<AgencyDashboardPage> createState() => _AgencyDashboardPageState();
}

class _AgencyDashboardPageState extends State<AgencyDashboardPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int? _agencyId;
  int _totalJobsCompleted = 0;
  final ScrollController _activeListingsScrollController = ScrollController();
  final ScrollController _pastBookingsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadAgencyId();
  }

  void _initializeTabController() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    
    final userType = _getUserType();
    final tabCount = userType == 'Individual Cleaner' ? 4 : 4; 
    _tabController = TabController(
      length: tabCount, 
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
    _tabController!.addListener(_handleTabChange);
    
    if (widget.initialTab != null && widget.initialTab! < tabCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController != null && !_tabController!.indexIsChanging) {
          _tabController!.animateTo(widget.initialTab!);
        }
      });
    }
  }

  String _getUserType() {
    final state = context.read<ProfilesCubit>().state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      return state.currentUser!['user_type'] as String? ?? 'Client';
    }
    return 'Client';
  }

  void _handleTabChange() {
    
    setState(() {});
    
    if (_tabController != null && !_tabController!.indexIsChanging && _agencyId != null) {
      final userType = _getUserType();
      
      if (userType == 'Individual Cleaner') {
        
        switch (_tabController!.index) {
          case 0: 
            context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
            break;
          case 1: 
            context.read<PastBookingsCubit>().loadPastBookings(_agencyId!);
            break;
          case 2: 
            context.read<AvailableJobsCubit>().loadAvailableJobs(_agencyId!);
            break;
          case 3: 
            break;
        }
      } else {
        
        switch (_tabController!.index) {
          case 0: 
            context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
            break;
          case 1: 
            context.read<PastBookingsCubit>().loadPastBookings(_agencyId!);
            break;
          case 2: 
            context.read<AvailableJobsCubit>().loadAvailableJobs(_agencyId!);
            break;
          case 3: 
            if (_agencyId != null) {
              context.read<CleanerTeamCubit>().loadCleaners(_agencyId!);
            }
            break;
        }
      }
    }
  }

  Future<void> _loadAgencyId() async {
    final cubit = context.read<ProfilesCubit>();
    await cubit.loadCurrentUser();
    if (!mounted) return;
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      setState(() {
        _agencyId = state.currentUser!['id'] as int?;
      });
      if (_agencyId != null && mounted) {
        
        context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
      }
    }
  }

  @override
  void dispose() {
    try {
      _tabController?.removeListener(_handleTabChange);
    } catch (_) {}
    
    _tabController?.dispose();
    _activeListingsScrollController.dispose();
    _pastBookingsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is ProfilesLoaded && profileState.currentUser != null) {
          final user = profileState.currentUser!;
          final agencyName = user['agency_name'] as String? ?? 
                            user['full_name'] as String? ?? 
                            'CleanSpace';
          
          
          final expectedTabCount = 4; 
          
          
          if (_tabController == null) {
            _initializeTabController();
          }
          
          else if (_tabController!.length != expectedTabCount) {
            _initializeTabController();
          }
          
          
          if (_tabController == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(agencyName),
            body: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController!,
                    children: _getTabViewsForRole(),
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  
  
  PreferredSizeWidget _buildAppBar(String agencyName) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.eco,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              agencyName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          BlocBuilder<ActiveListingsCubit, ActiveListingsState>(
            builder: (context, state) {
              if (state is ActiveListingsLoaded) {
                _totalJobsCompleted = state.totalJobsCompleted;
              }
              return Text(
                '$_totalJobsCompleted Jobs\nCompleted',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ],
      ),
      
      actions: [
        NotificationBellWidget(),
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF6B7280)),
          onPressed: _showLogoutDialog,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    final cubit = context.read<ProfilesCubit>();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 40, color: Color(0xFF3B82F6)),
              const SizedBox(height: 16),
              const Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of your CleanSpace account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    cubit.logout().then((_) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                        (route) => false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out successfully')),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Yes, Log Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

  List<Tab> _getTabsForRole() {
    final userType = _getUserType();
    if (userType == 'Individual Cleaner') {
      return const [
        Tab(text: 'Active Listings'),
        Tab(text: 'Past Bookings'),
        Tab(text: 'Available Jobs'),
        Tab(text: 'Profile'),
      ];
    } else {
      return const [
        Tab(text: 'Active Listings'),
        Tab(text: 'Past Bookings'),
        Tab(text: 'Available Jobs'),
        Tab(text: 'Cleaner Team'),
      ];
    }
  }

  List<Widget> _getTabViewsForRole() {
    final userType = _getUserType();
    if (userType == 'Individual Cleaner') {
      return [
        _buildActiveListingsTab(),
        _buildPastBookingsTab(),
        _buildAvailableJobsTab(),
        _buildCleanerProfileTab(),
      ];
    } else {
      return [
        _buildActiveListingsTab(),
        _buildPastBookingsTab(),
        _buildAvailableJobsTab(),
        _buildCleanerTeamTab(),
      ];
    }
  }

  Widget _buildCleanerProfileTab() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        
        if (state is ProfilesLoading || state is ProfilesInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is ProfilesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading profile',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    state.message,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProfilesCubit>().loadCurrentUser();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        
        if (state is! ProfilesLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        
        
        if (state.currentUser == null) {
          return const Center(
            child: Text(
              'No user data available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        
        try {
          final user = state.currentUser!;
          
          
          if (user['id'] == null) {
            return const Center(
              child: Text(
                'Error: User ID not found',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          
          
          final cleanerProfile = <String, dynamic>{
            'id': user['id'],
            'name': user['full_name'] as String? ?? 'Unknown',
            'image': user['picture'] as String?,
            'rating': (user['rating'] as num?)?.toDouble() ?? 4.5,
            'reviews': user['reviews_count'] as int? ?? 0,
            'isVerified': user['is_verified'] as bool? ?? false,
            'aboutMe': user['bio'] as String? ?? 'Professional cleaning service provider.',
            'experience': user['experience_years'] != null 
                ? '${user['experience_years']}+ Years'
                : '5+ Years',
            'age': AgeHelper.formatAge(user['birthdate'] as String?),
            'languages': user['languages'] as String? ?? 'Arabic, French',
            'location': _extractLocation(user['address'] as String?),
            'agency': user['agency_name'] as String?,
            'type': user['user_type'] == 'Agency' ? 'Agency' : 'Individual',
            'userType': user['user_type'],
            'profileData': user,
          };
          
          
          if (cleanerProfile['id'] == null || cleanerProfile['name'] == null) {
            return const Center(
              child: Text(
                'Error: Invalid profile data',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          
          
          return CleanerProfilePage(
            cleaner: cleanerProfile,
            isOwnProfile: true,
          );
        } catch (e, stackTrace) {
          print('Error building cleaner profile tab: $e');
          print('Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading profile',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<ProfilesCubit>().loadCurrentUser();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  String _extractLocation(String? address) {
    if (address == null || address.isEmpty) return 'Unknown';
    
    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  Widget _buildTabBar() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController!,
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF3B82F6),
        indicatorWeight: 3,
        tabs: _getTabsForRole(),
      ),
    );
  }

  Widget _buildActiveListingsTab() {
    if (_agencyId == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return BlocBuilder<ActiveListingsCubit, ActiveListingsState>(
      builder: (context, state) {
          if (state is ActiveListingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ActiveListingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ActiveListingsCubit>().refresh(_agencyId!);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ActiveListingsLoaded) {
            if (state.jobs.isEmpty) {
              return const Center(
                child: Text(
                  'No active listings yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<ActiveListingsCubit>().refresh(_agencyId!);
              },
              child: ListView.builder(
                controller: _activeListingsScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.jobs.length,
                itemBuilder: (context, index) {
                  final job = state.jobs[index];
                  final highlight = widget.highlightJobId != null && job.id == widget.highlightJobId;
                  // Check if this job has a pending booking or is assigned to this worker
                  // Use available job card design for pending/assigned jobs
                  if (_agencyId != null) {
                    final isAssigned = job.assignedWorkerId == _agencyId;
                    if (isAssigned) {
                      return _buildAvailableJobCard(job, showAssignedStatus: true);
                    }
                    return FutureBuilder<bool>(
                      future: _hasPendingBookingForJob(job.id!, _agencyId!),
                      builder: (context, snapshot) {
                        final isPending = snapshot.data ?? false;
                        if (isPending) {
                          return _buildAvailableJobCard(job, showPendingStatus: true);
                        }
                        return _buildJobCard(job, highlight: highlight);
                      },
                    );
                  }
                  return _buildJobCard(job, highlight: highlight);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
    );
  }

  Widget _buildPastBookingsTab() {
    if (_agencyId == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return Column(
      children: [
          _buildPastBookingsHeader(),
          Expanded(
            child: BlocBuilder<PastBookingsCubit, PastBookingsState>(
              builder: (context, state) {
                if (state is PastBookingsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PastBookingsError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<PastBookingsCubit>().refresh(_agencyId!);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is PastBookingsLoaded) {
                  if (state.jobs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No past bookings yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<PastBookingsCubit>().refresh(_agencyId!);
                    },
                    child: ListView.builder(
                      controller: _pastBookingsScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.jobs.length,
                      itemBuilder: (context, index) {
                        final job = state.jobs[index];
                        final highlight = widget.highlightJobId != null && job.id == widget.highlightJobId;
                        // Check if job is completed (both client_done and worker_done are true)
                        final isCompleted = job.clientDone && job.workerDone;
                        if (isCompleted) {
                          return _buildAvailableJobCard(job, showDoneStatus: true);
                        }
                        return _buildPastBookingCard(job, highlight: highlight);
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
    );
  }

  Widget _buildPastBookingsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          
          TextField(
            decoration: InputDecoration(
              hintText: 'Search my listings...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                    DropdownMenuItem(value: 'booked', child: Text('Booked')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Sort by Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest first')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
                  ],
                  onChanged: (value) {
                    
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableJobsTab() {
    if (_agencyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BlocBuilder<AvailableJobsCubit, AvailableJobsState>(
      builder: (context, state) {
        try {
          if (state is AvailableJobsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AvailableJobsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        context.read<AvailableJobsCubit>().refresh(_agencyId!);
                      } catch (e) {
                        print('Error refreshing available jobs: $e');
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is AvailableJobsLoaded) {
            if (state.jobs.isEmpty) {
              return const Center(
                child: Text(
                  'No available jobs at the moment.\nCheck back later!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                try {
                  await context.read<AvailableJobsCubit>().refresh(_agencyId!);
                } catch (e) {
                  print('Error refreshing: $e');
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.jobs.length,
                itemBuilder: (context, index) {
                  try {
                    if (index >= state.jobs.length || index < 0) {
                      return const SizedBox.shrink();
                    }
                    final job = state.jobs[index];
                    
                    if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildAvailableJobCard(job);
                  } catch (e, stackTrace) {
                    print('Error building job card at index $index: $e');
                    print('Stack trace: $stackTrace');
                    return const SizedBox.shrink();
                  }
                },
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        } catch (e, stackTrace) {
          print('Error in _buildAvailableJobsTab: $e');
          print('Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('An error occurred'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    try {
                      context.read<AvailableJobsCubit>().refresh(_agencyId!);
                    } catch (e) {
                      print('Error refreshing: $e');
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildAvailableJobCard(Job job, {bool showPendingStatus = false, bool showAssignedStatus = false, bool showDoneStatus = false}) {
    
    try {
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }
    } catch (e) {
      print('Error validating job: $e');
      return const SizedBox.shrink();
    }

    try {
      return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          try {
            // For assigned or completed jobs, use JobDetailsScreen
            // For pending jobs, use JobDetailsBidPage
            if (showAssignedStatus || showDoneStatus) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsScreen(job: job),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailsBidPage(job: job),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening job details: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              if (job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildJobImage(job.coverImageUrl!, height: 150),
                ),
              if (job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty)
                const SizedBox(height: 12),
              
              // Show Done status badge (green) if both parties confirmed completion
              if (showDoneStatus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Show Assigned status badge (blue) if assigned to this worker
              if (showAssignedStatus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Assigned',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // Show Pending status badge if in Active Listings
              if (showPendingStatus) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              Text(
                job.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${job.city}, ${job.country}',
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(job.postedDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (job.budgetMin != null || job.budgetMax != null)
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'DA ${job.budgetMin?.toStringAsFixed(0) ?? ''}${job.budgetMax != null && job.budgetMax != job.budgetMin ? ' - DA ${job.budgetMax!.toStringAsFixed(0)}' : ''}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building available job card: $e');
      print('Stack trace: $stackTrace');
      print('Job data: id=${job.id}, title=${job.title}, city=${job.city}, country=${job.country}');
      
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title.isNotEmpty ? job.title : 'Untitled Job',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${job.city.isNotEmpty ? job.city : "Unknown"}, ${job.country.isNotEmpty ? job.country : "Unknown"}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: ${e.toString()}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }


  Widget _buildCleanerTeamTab() {
    if (_agencyId == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return BlocBuilder<CleanerTeamCubit, CleanerTeamState>(
      builder: (context, state) {
          if (state is CleanerTeamLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CleanerTeamError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CleanerTeamCubit>().refresh(_agencyId!);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is CleanerTeamLoaded) {
            if (state.cleaners.isEmpty) {
              return const Center(
                child: Text(
                  'No cleaners in your team yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<CleanerTeamCubit>().refresh(_agencyId!);
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.cleaners.length,
                itemBuilder: (context, index) {
                  return _buildCleanerCard(state.cleaners[index]);
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
    );
  }

  Widget _buildJobCard(Job job, {bool highlight = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: highlight ? 8 : 2,
      color: highlight ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(job: job),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: job.coverImageUrl != null
                  ? _buildJobImage(job.coverImageUrl!, height: 200)
                  : _buildPlaceholderImage(),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.fullLocation,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(job.postedDate)} - ${job.statusLabel}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastBookingCard(Job job, {bool highlight = false}) {
    Color statusColor;
    switch (job.status) {
      case JobStatus.active:
        statusColor = Colors.green;
        break;
      case JobStatus.paused:
        statusColor = Colors.orange;
        break;
      case JobStatus.booked:
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: highlight ? 8 : 2,
      color: highlight ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlight ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                ? _buildJobImage(job.coverImageUrl!, height: 150)
                : _buildPlaceholderImage(height: 150),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                    Text(
                      'Posted on: ${_formatDate(job.postedDate)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  job.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: _buildActionButtons(job),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(Job job) {
    List<Widget> buttons = [];

    
    buttons.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () {
            
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: const Text('Edit'),
        ),
      ),
    );

    const SizedBox(width: 8);

    
    if (job.status == JobStatus.active) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (_agencyId != null && job.id != null) {
                context.read<PastBookingsCubit>().changeJobStatus(
                      job.id!,
                      JobStatus.paused,
                      _agencyId!,
                    );
              }
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text('Pause'),
          ),
        ),
      );
    } else if (job.status == JobStatus.paused) {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (_agencyId != null && job.id != null) {
                context.read<PastBookingsCubit>().changeJobStatus(
                      job.id!,
                      JobStatus.active,
                      _agencyId!,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Activate'),
          ),
        ),
      );
    }

    buttons.add(const SizedBox(width: 8));

    
    buttons.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () {
            _showDeleteConfirmation(job);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    );

    return buttons;
  }

  void _showDeleteConfirmation(Job job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to delete "${job.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (job.id != null && job.agencyId != null) {
                context.read<PastBookingsCubit>().deleteJob(job.id!, job.agencyId!);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          
          if (cleaner.id != null) {
            
            final profileRepo = AbstractProfileRepo.getInstance();
            try {
              final profile = await profileRepo.getProfileById(cleaner.id!);
              if (profile != null && mounted) {
                
                final cleanerProfile = {
                  'id': profile['id'],
                  'name': profile['full_name'] as String? ?? cleaner.name,
                  'image': profile['picture'] as String? ?? cleaner.avatarUrl,
                  'rating': cleaner.rating,
                  'reviews': profile['reviews_count'] as int? ?? 0,
                  'isVerified': profile['is_verified'] as bool? ?? false,
                  'aboutMe': profile['bio'] as String? ?? 'Professional cleaning service provider.',
                  'experience': profile['experience_years'] != null 
                      ? '${profile['experience_years']}+ Years'
                      : '5+ Years',
                  'age': AgeHelper.formatAge(profile['birthdate'] as String?),
                  'languages': profile['languages'] as String? ?? 'Arabic, French',
                  'location': _extractLocation(profile['address'] as String?),
                  'agency': profile['agency_name'] as String?,
                  'type': 'Individual',
                  'userType': profile['user_type'],
                  'profileData': profile,
                };
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CleanerProfilePage(cleaner: cleanerProfile),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading cleaner profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                child: cleaner.avatarUrl != null && cleaner.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: AppImage(
                          imageUrl: cleaner.avatarUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Text(
                              cleaner.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        cleaner.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleaner.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          if (index < cleaner.rating.floor()) {
                            return const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            );
                          } else if (index < cleaner.rating) {
                            return const Icon(
                              Icons.star_half,
                              color: Colors.amber,
                              size: 16,
                            );
                          } else {
                            return Icon(
                              Icons.star_border,
                              color: Colors.grey[400],
                              size: 16,
                            );
                          }
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '(${cleaner.rating.toStringAsFixed(1)})',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cleaner.jobsCompleted} Jobs Completed',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobImage(String imageUrl, {double? height, double? width}) {
    try {
      if (imageUrl.isEmpty) {
        return _buildPlaceholderImage(height: height ?? 150);
      }
      return AppImage(
        imageUrl: imageUrl,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        errorWidget: _buildPlaceholderImage(height: height ?? 150),
      );
    } catch (e) {
      print('Error building job image: $e');
      return _buildPlaceholderImage(height: height ?? 150);
    }
  }

  Widget _buildPlaceholderImage({double? height}) {
    return Container(
      height: height ?? 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image,
        size: 64,
        color: Colors.grey,
      ),
    );
  }

  
  
  
  
  
  Widget _buildFloatingActionButton() {
    
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    
    final userType = _getUserType();
    final currentTabIndex = _tabController!.index;
    
    
    if (userType == 'Client') {
      return const SizedBox.shrink();
    }
    
    
    
    if (userType == 'Agency' && currentTabIndex == 3) {
      return FloatingActionButton(
        onPressed: () {
          if (_agencyId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCleanerPage(agencyId: _agencyId!),
              ),
            ).then((_) {
              if (_agencyId != null) {
                context.read<CleanerTeamCubit>().refresh(_agencyId!);
              }
            });
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.person_add, color: Colors.white),
        tooltip: 'Add New Cleaner',
      );
    }
    
    
    
    
    
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) {
    try {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Date unavailable';
    }
  }

  void _scrollToJob(List<Job> jobs, int jobId, ScrollController controller) {
    final index = jobs.indexWhere((job) => job.id == jobId);
    if (index != -1 && controller.hasClients) {
      final itemHeight = 150.0; // Approximate height of a job card
      final offset = index * itemHeight;
      controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _hasPendingBookingForJob(int jobId, int providerId) async {
    try {
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final bookings = await bookingsRepo.getApplicationsForJob(jobId);
      return bookings.any((booking) => 
        booking.providerId == providerId && 
        booking.status == BookingStatus.pending
      );
    } catch (e) {
      return false;
    }
  }

}

