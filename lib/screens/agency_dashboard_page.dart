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
import 'login.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../data/repositories/bookings/bookings_repo.dart';
import '../utils/image_helper.dart';
import '../utils/age_helper.dart';
import '../widgets/notification_bell_widget.dart';
import '../l10n/app_localizations.dart';
import 'settings_page.dart';
import 'cleaner_team_page.dart';
import '../utils/algerian_addresses.dart';

class AgencyDashboardPage extends StatefulWidget {
  final int? initialTab;
  final int? highlightJobId;

  const AgencyDashboardPage({super.key, this.initialTab, this.highlightJobId});

  @override
  State<AgencyDashboardPage> createState() => _AgencyDashboardPageState();
}

class _AgencyDashboardPageState extends State<AgencyDashboardPage> {
  int _currentIndex = 0;
  int? _agencyId;
  final int _totalJobsCompleted = 0;
  final ScrollController _activeListingsScrollController = ScrollController();
  final ScrollController _pastBookingsScrollController = ScrollController();

  // Filter state for available jobs
  Set<String> _selectedWilayas = {};
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    _loadAgencyId();
  }

  String _getUserType() {
    final state = context.read<ProfilesCubit>().state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      return state.currentUser!['user_type'] as String? ?? 'Client';
    }
    return 'Client';
  }

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (_agencyId != null) {
      final userType = _getUserType();

      if (userType == 'Individual Cleaner') {
        switch (index) {
          case 0:
            context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
            break;
          case 1:
            context.read<AvailableJobsCubit>().loadAvailableJobs(
              _agencyId!,
              wilayas: _selectedWilayas.isEmpty
                  ? null
                  : _selectedWilayas.toList(),
              minPrice: _minPrice,
              maxPrice: _maxPrice,
            );
            break;
          case 2:
            context.read<PastBookingsCubit>().loadPastBookings(_agencyId!);
            break;
          case 3:
            break;
        }
      } else {
        switch (index) {
          case 0:
            context.read<ActiveListingsCubit>().loadActiveListings(_agencyId!);
            break;
          case 1:
            context.read<AvailableJobsCubit>().loadAvailableJobs(_agencyId!);
            break;
          case 2:
            context.read<PastBookingsCubit>().loadPastBookings(_agencyId!);
            break;
          case 3:
            // Profile tab - will show agency profile page
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
    _activeListingsScrollController.dispose();
    _pastBookingsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, profileState) {
        if (profileState is ProfilesLoaded &&
            profileState.currentUser != null) {
          final user = profileState.currentUser!;
          final agencyName =
              user['agency_name'] as String? ??
              user['full_name'] as String? ??
              'CleanSpace';

          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: _buildAppBar(agencyName),
            body: _getCurrentView(),
            bottomNavigationBar: _buildBottomNavigationBar(),
            floatingActionButton: _buildFloatingActionButton(),
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ),
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
              child: Icon(Icons.eco, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'CleanSpace',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),

      actions: [
        NotificationBellWidget(),
        if (_getUserType() == 'Agency')
          IconButton(
            icon: const Icon(Icons.people, color: Color(0xFF6B7280)),
            onPressed: () {
              if (_agencyId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CleanerTeamPage(agencyId: _agencyId!),
                  ),
                );
              }
            },
            tooltip: AppLocalizations.of(context)!.cleanerTeam,
          ),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF6B7280)),
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
          },
          tooltip: AppLocalizations.of(context)!.settings,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
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
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
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
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.loggedOutSuccessfully,
                          ),
                        ),
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

  Widget _getCurrentView() {
    final userType = _getUserType();
    if (userType == 'Individual Cleaner') {
      switch (_currentIndex) {
        case 0:
          return _buildActiveListingsTab();
        case 1:
          return _buildAvailableJobsTab();
        case 2:
          return _buildPastBookingsTab();
        case 3:
          return _buildCleanerProfileTab();
        default:
          return _buildActiveListingsTab();
      }
    } else {
      switch (_currentIndex) {
        case 0:
          return _buildActiveListingsTab();
        case 1:
          return _buildAvailableJobsTab();
        case 2:
          return _buildPastBookingsTab();
        case 3:
          return _buildAgencyProfileTab();
        default:
          return _buildActiveListingsTab();
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _handleTabChange,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey[600],
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.work_outline),
          label: AppLocalizations.of(context)!.active,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.search),
          label: AppLocalizations.of(context)!.available,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: AppLocalizations.of(context)!.history,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: AppLocalizations.of(context)!.profile,
        ),
      ],
    );
  }

  Widget _buildAgencyProfileTab() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        if (state is ProfilesLoading || state is ProfilesInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (state is ProfilesError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingProfile,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        if (state is! ProfilesLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (state.currentUser == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noUserDataAvailable,
              style: const TextStyle(color: Colors.grey),
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

          final agencyProfile = <String, dynamic>{
            'id': user['id'],
            'name':
                user['agency_name'] as String? ??
                user['full_name'] as String? ??
                'Unknown',
            'image': user['picture'] as String?,
            'rating': (user['rating'] as num?)?.toDouble() ?? 4.5,
            'reviews': user['reviews_count'] as int? ?? 0,
            'isVerified': user['is_verified'] as bool? ?? false,
            'aboutMe':
                user['bio'] as String? ??
                'Professional cleaning service provider.',
            'experience': user['experience_years'] != null
                ? '${user['experience_years']}+ Years'
                : '5+ Years',
            'age': AgeHelper.formatAge(user['birthdate'] as String?),
            'languages': user['languages'] as String? ?? 'Arabic, French',
            'location': _extractLocation(user['address'] as String?),
            'agency': null, // Agency doesn't belong to another agency
            'type': 'Agency',
            'userType': 'Agency',
            'profileData': user,
          };

          if (agencyProfile['id'] == null || agencyProfile['name'] == null) {
            return const Center(
              child: Text(
                'Error: Invalid profile data',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          return CleanerProfilePage(cleaner: agencyProfile, isOwnProfile: true);
        } catch (e, stackTrace) {
          print('Error building agency profile tab: $e');
          print('Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.errorLoadingProfile,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCleanerProfileTab() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        if (state is ProfilesLoading || state is ProfilesInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        if (state is! ProfilesLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }

        if (state.currentUser == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noUserDataAvailable,
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
            'aboutMe':
                user['bio'] as String? ??
                'Professional cleaning service provider.',
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  String _extractLocation(String? address) {
    if (address == null || address.isEmpty)
      return AppLocalizations.of(context)!.unknown;

    final parts = address.split(',');
    return parts.isNotEmpty ? parts.first.trim() : address;
  }

  Widget _buildActiveListingsTab() {
    if (_agencyId == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return BlocBuilder<ActiveListingsCubit, ActiveListingsState>(
      builder: (context, state) {
        if (state is ActiveListingsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is ActiveListingsLoaded) {
          if (state.jobs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noActiveListings,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                final highlight =
                    widget.highlightJobId != null &&
                    job.id == widget.highlightJobId;
                // Check if this job has a pending booking or is assigned to this worker
                // Use available job card design for pending/assigned jobs
                if (_agencyId != null) {
                  final isAssigned = job.assignedWorkerId == _agencyId;
                  if (isAssigned) {
                    return _buildAvailableJobCard(
                      job,
                      showAssignedStatus: true,
                    );
                  }
                  return FutureBuilder<bool>(
                    future: _hasPendingBookingForJob(job.id!, _agencyId!),
                    builder: (context, snapshot) {
                      final isPending = snapshot.data ?? false;
                      if (isPending) {
                        return _buildAvailableJobCard(
                          job,
                          showPendingStatus: true,
                        );
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return Column(
      children: [
        _buildPastBookingsHeader(),
        Expanded(
          child: BlocBuilder<PastBookingsCubit, PastBookingsState>(
            builder: (context, state) {
              if (state is PastBookingsLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                );
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
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                );
              } else if (state is PastBookingsLoaded) {
                if (state.jobs.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noPastBookingsYet,
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
                      final highlight =
                          widget.highlightJobId != null &&
                          job.id == widget.highlightJobId;
                      // Use the same card builder for all jobs in history
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
    return const SizedBox.shrink();
  }

  Widget _buildAvailableJobsTab() {
    if (_agencyId == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return Column(
      children: [
        // Filter buttons
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  label: AppLocalizations.of(context)!.location,
                  icon: Icons.location_on_outlined,
                  value: _selectedWilayas.isEmpty
                      ? AppLocalizations.of(context)!.all
                      : _selectedWilayas.length == 1
                      ? _selectedWilayas.first
                      : '${_selectedWilayas.length} ${AppLocalizations.of(context)!.all.toLowerCase()}',
                  onTap: () {
                    _showLocationFilter();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  label: AppLocalizations.of(context)!.price,
                  icon: Icons.attach_money,
                  value: _minPrice == null && _maxPrice == null
                      ? AppLocalizations.of(context)!.all
                      : '${_minPrice ?? 0}-${_maxPrice ?? "∞"} DZD',
                  onTap: () {
                    _showPriceFilter();
                  },
                ),
              ),
            ],
          ),
        ),
        // Jobs list
        Expanded(
          child: BlocBuilder<AvailableJobsCubit, AvailableJobsState>(
            builder: (context, state) {
              try {
                if (state is AvailableJobsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  );
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
                              context.read<AvailableJobsCubit>().refresh(
                                _agencyId!,
                                wilayas: _selectedWilayas.isEmpty
                                    ? null
                                    : _selectedWilayas.toList(),
                                minPrice: _minPrice,
                                maxPrice: _maxPrice,
                              );
                            } catch (e) {
                              print('Error refreshing available jobs: $e');
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.retry),
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
                        await context.read<AvailableJobsCubit>().refresh(
                          _agencyId!,
                          wilayas: _selectedWilayas.isEmpty
                              ? null
                              : _selectedWilayas.toList(),
                          minPrice: _minPrice,
                          maxPrice: _maxPrice,
                        );
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

                          if (job.title.isEmpty ||
                              job.city.isEmpty ||
                              job.country.isEmpty) {
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
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                );
              } catch (e, stackTrace) {
                print('Error in _buildAvailableJobsTab: $e');
                print('Stack trace: $stackTrace');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.anErrorOccurred),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            context.read<AvailableJobsCubit>().refresh(
                              _agencyId!,
                              wilayas: _selectedWilayas.isEmpty
                                  ? null
                                  : _selectedWilayas.toList(),
                              minPrice: _minPrice,
                              maxPrice: _maxPrice,
                            );
                          } catch (e) {
                            print('Error refreshing: $e');
                          }
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableJobCard(
    Job job, {
    bool showPendingStatus = false,
    bool showAssignedStatus = false,
    bool showDoneStatus = false,
  }) {
    try {
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }
    } catch (e) {
      print('Error validating job: $e');
      return const SizedBox.shrink();
    }

    // Get status color and label
    Color statusColor;
    String statusLabel;
    if (showDoneStatus) {
      statusColor = Colors.green;
      statusLabel = 'Done';
    } else if (showAssignedStatus) {
      statusColor = Colors.blue;
      statusLabel = AppLocalizations.of(context)!.assigned;
    } else if (showPendingStatus) {
      statusColor = Colors.orange;
      statusLabel = AppLocalizations.of(context)!.pending;
    } else {
      // For open jobs, use green; otherwise use grey
      if (job.status == JobStatus.open) {
        statusColor = Colors.green;
      } else {
        statusColor = Colors.grey;
      }
      statusLabel = job.statusLabel;
    }

    // Calculate time ago from postedDate
    final dateToUse = job.postedDate;
    final now = DateTime.now();
    final difference = now.difference(dateToUse);
    String timeAgoText;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          timeAgoText = AppLocalizations.of(context)!.justNow;
        } else {
          timeAgoText = AppLocalizations.of(
            context,
          )!.minutesAgo(difference.inMinutes);
        }
      } else {
        timeAgoText = AppLocalizations.of(
          context,
        )!.hoursAgo(difference.inHours);
      }
    } else if (difference.inDays == 1) {
      timeAgoText = AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      timeAgoText = AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      timeAgoText = '${dateToUse.day}/${dateToUse.month}/${dateToUse.year}';
    }

    try {
      return InkWell(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child:
                    job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                    ? _buildJobImage(job.coverImageUrl!, height: 180)
                    : _buildPlaceholderImage(height: 180),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
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
                    // Budget (Min - Max) with blue icon and bid
                    FutureBuilder<double?>(
                      future: _getWorkerBidPriceForJob(job.id),
                      builder: (context, snapshot) {
                        final bidPrice = snapshot.data;
                        final budgetText =
                            job.budgetMin != null && job.budgetMax != null
                            ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
                            : job.budgetMin != null
                            ? 'DA ${job.budgetMin!.toStringAsFixed(0)}'
                            : job.budgetMax != null
                            ? 'DA ${job.budgetMax!.toStringAsFixed(0)}'
                            : AppLocalizations.of(context)!.budgetNegotiable;
                        final displayText = bidPrice != null
                            ? '$budgetText (${AppLocalizations.of(context)!.bid}: DA ${bidPrice.toStringAsFixed(0)})'
                            : budgetText;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 16,
                                color: Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Location with blue icon
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
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
                    // Date with blue icon and time ago
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${dateToUse.day}/${dateToUse.month}/${dateToUse.year} ($timeAgoText)',
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
      print('Error building available job card: $e');
      print('Stack trace: $stackTrace');
      print(
        'Job data: id=${job.id}, title=${job.title}, city=${job.city}, country=${job.country}',
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title.isNotEmpty
                    ? job.title
                    : AppLocalizations.of(context)!.untitledJob,
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      );
    }

    return BlocBuilder<CleanerTeamCubit, CleanerTeamState>(
      builder: (context, state) {
        if (state is CleanerTeamLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
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
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        } else if (state is CleanerTeamLoaded) {
          if (state.cleaners.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.noCleanersInTeamYet,
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
    // Get status color
    Color statusColor;
    switch (job.status) {
      case JobStatus.open:
        statusColor = Colors.green;
        break;
      case JobStatus.completed:
        statusColor = Colors.green;
        break;
      case JobStatus.completedPendingConfirmation:
        statusColor = Colors.purple;
        break;
      case JobStatus.inProgress:
        statusColor = const Color(0xFF3B82F6);
        break;
      case JobStatus.assigned:
        statusColor = Colors.blue;
        break;
      case JobStatus.pending:
        statusColor = Colors.orange;
        break;
      case JobStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Calculate time ago from postedDate
    final dateToUse = job.postedDate;
    final now = DateTime.now();
    final difference = now.difference(dateToUse);
    String timeAgoText;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          timeAgoText = AppLocalizations.of(context)!.justNow;
        } else {
          timeAgoText = AppLocalizations.of(
            context,
          )!.minutesAgo(difference.inMinutes);
        }
      } else {
        timeAgoText = AppLocalizations.of(
          context,
        )!.hoursAgo(difference.inHours);
      }
    } else if (difference.inDays == 1) {
      timeAgoText = AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      timeAgoText = AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      timeAgoText = '${dateToUse.day}/${dateToUse.month}/${dateToUse.year}';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailsScreen(job: job)),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                  ? _buildJobImage(job.coverImageUrl!, height: 180)
                  : _buildPlaceholderImage(height: 180),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                  // Budget (Min - Max) with blue icon and bid
                  FutureBuilder<double?>(
                    future: _getWorkerBidPriceForJob(job.id),
                    builder: (context, snapshot) {
                      final bidPrice = snapshot.data;
                      final budgetText =
                          job.budgetMin != null && job.budgetMax != null
                          ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
                          : job.budgetMin != null
                          ? 'DA ${job.budgetMin!.toStringAsFixed(0)}'
                          : job.budgetMax != null
                          ? 'DA ${job.budgetMax!.toStringAsFixed(0)}'
                          : AppLocalizations.of(context)!.budgetNegotiable;
                      final displayText = bidPrice != null
                          ? '$budgetText (Bid: DA ${bidPrice.toStringAsFixed(0)})'
                          : budgetText;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                displayText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Location with blue icon
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
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
                  // Date with blue icon and time ago
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${dateToUse.day}/${dateToUse.month}/${dateToUse.year} ($timeAgoText)',
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
  }

  Widget _buildPastBookingCard(Job job, {bool highlight = false}) {
    // Get status color
    Color statusColor;
    switch (job.status) {
      case JobStatus.completed:
        statusColor = Colors.green;
        break;
      case JobStatus.completedPendingConfirmation:
        statusColor = Colors.purple;
        break;
      case JobStatus.inProgress:
        statusColor = const Color(0xFF3B82F6);
        break;
      case JobStatus.assigned:
        statusColor = Colors.blue;
        break;
      case JobStatus.pending:
        statusColor = Colors.orange;
        break;
      case JobStatus.cancelled:
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Use updatedAt (when job was done) or postedDate as fallback
    final dateToUse = job.updatedAt ?? job.postedDate;

    // Calculate time ago
    final now = DateTime.now();
    final difference = now.difference(dateToUse);
    String timeAgoText;
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          timeAgoText = AppLocalizations.of(context)!.justNow;
        } else {
          timeAgoText = AppLocalizations.of(
            context,
          )!.minutesAgo(difference.inMinutes);
        }
      } else {
        timeAgoText = AppLocalizations.of(
          context,
        )!.hoursAgo(difference.inHours);
      }
    } else if (difference.inDays == 1) {
      timeAgoText = AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      timeAgoText = AppLocalizations.of(context)!.daysAgo(difference.inDays);
    } else {
      timeAgoText = '${dateToUse.day}/${dateToUse.month}/${dateToUse.year}';
    }

    // Status label - use "Done" for completed jobs
    String statusLabel = job.statusLabel;
    if (job.status == JobStatus.completed ||
        (job.clientDone && job.workerDone)) {
      statusLabel = 'Done';
    }

    return FutureBuilder<Booking?>(
      future: _getAcceptedBidForJob(job.id),
      builder: (context, snapshot) {
        final acceptedBid = snapshot.data;
        final bidPrice = acceptedBid?.bidPrice;

        return InkWell(
          onTap: () {
            // Navigate to job details if needed
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child:
                      job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                      ? _buildJobImage(job.coverImageUrl!, height: 180)
                      : _buildPlaceholderImage(height: 180),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
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
                      // Budget with bid in parentheses
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _buildBudgetWithBidText(job, bidPrice),
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
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
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
                      // Date with blue icon and time ago (using updatedAt)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${dateToUse.day}/${dateToUse.month}/${dateToUse.year} ($timeAgoText)',
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
      },
    );
  }

  Future<Booking?> _getAcceptedBidForJob(int? jobId) async {
    if (jobId == null) return null;
    try {
      final bookingsRepo = AbstractBookingsRepo.getInstance();
      final applications = await bookingsRepo.getApplicationsForJob(jobId);
      // Find the accepted booking (status is inProgress or completed)
      for (final booking in applications) {
        if (booking.status == BookingStatus.inProgress ||
            booking.status == BookingStatus.completed) {
          return booking;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<double?> _getWorkerBidPriceForJob(int? jobId) async {
    if (jobId == null) return null;
    try {
      final booking = await _getAcceptedBidForJob(jobId);
      return booking?.bidPrice;
    } catch (e) {
      return null;
    }
  }

  String _buildBudgetWithBidText(Job job, double? bidPrice) {
    final budgetText = job.budgetMin != null && job.budgetMax != null
        ? 'DA ${job.budgetMin!.toStringAsFixed(0)} - DA ${job.budgetMax!.toStringAsFixed(0)}'
        : job.budgetMin != null
        ? 'DA ${job.budgetMin!.toStringAsFixed(0)}'
        : job.budgetMax != null
        ? 'DA ${job.budgetMax!.toStringAsFixed(0)}'
        : 'Budget negotiable';

    if (bidPrice != null) {
      return '$budgetText (${AppLocalizations.of(context)!.bid}: DA ${bidPrice.toStringAsFixed(0)})';
    }
    return budgetText;
  }

  List<Widget> _buildActionButtons(Job job) {
    List<Widget> buttons = [];

    buttons.add(
      Expanded(
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Text(AppLocalizations.of(context)!.edit),
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
            child: Text(AppLocalizations.of(context)!.pause),
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
            child: Text(AppLocalizations.of(context)!.activate),
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
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ),
    );

    return buttons;
  }

  void _showDeleteConfirmation(Job job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteJob),
        content: Text(
          AppLocalizations.of(context)!.areYouSureDeleteJob(job.title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (job.id != null && job.agencyId != null) {
                context.read<PastBookingsCubit>().deleteJob(
                  job.id!,
                  job.agencyId!,
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                  'aboutMe':
                      profile['bio'] as String? ??
                      'Professional cleaning service provider.',
                  'experience': profile['experience_years'] != null
                      ? '${profile['experience_years']}+ Years'
                      : '5+ Years',
                  'age': AgeHelper.formatAge(profile['birthdate'] as String?),
                  'languages':
                      profile['languages'] as String? ?? 'Arabic, French',
                  'location': _extractLocation(profile['address'] as String?),
                  'agency': profile['agency_name'] as String?,
                  'type': 'Individual',
                  'userType': profile['user_type'],
                  'profileData': profile,
                };

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CleanerProfilePage(cleaner: cleanerProfile),
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
                child:
                    cleaner.avatarUrl != null && cleaner.avatarUrl!.isNotEmpty
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
      child: const Icon(Icons.image, size: 64, color: Colors.grey),
    );
  }

  Widget _buildFloatingActionButton() {
    final userType = _getUserType();
    final currentTabIndex = _currentIndex;

    if (userType == 'Client') {
      return const SizedBox.shrink();
    }

    // Floating action button removed from profile tab - now accessible via person icon in AppBar

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
      return bookings.any(
        (booking) =>
            booking.providerId == providerId &&
            booking.status == BookingStatus.pending,
      );
    } catch (e) {
      return false;
    }
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Color(0xFF3B82F6),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationFilter() {
    final allWilayas = AlgerianAddresses.getAllWilayas();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectWilayasMultiple,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedWilayas.length == allWilayas.length) {
                            _selectedWilayas.clear();
                          } else {
                            _selectedWilayas = allWilayas.toSet();
                          }
                        });
                        setModalState(() {}); // Update modal UI
                        _reloadAvailableJobs();
                      },
                      child: Text(
                        _selectedWilayas.length == allWilayas.length
                            ? AppLocalizations.of(context)!.deselectAll
                            : AppLocalizations.of(context)!.selectAll,
                        style: const TextStyle(color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: allWilayas.length,
                    itemBuilder: (context, index) {
                      final wilaya = allWilayas[index];
                      final isSelected = _selectedWilayas.contains(wilaya);
                      return CheckboxListTile(
                        title: Text(wilaya),
                        value: isSelected,
                        activeColor: const Color(0xFF3B82F6),
                        checkColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedWilayas.add(wilaya);
                            } else {
                              _selectedWilayas.remove(wilaya);
                            }
                          });
                          setModalState(() {}); // Update modal UI immediately
                          _reloadAvailableJobs();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.done,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPriceFilter() {
    final minController = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.priceRangeDzd,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.minPrice,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      prefixText: 'DZD ',
                      prefixStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.maxPrice,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      prefixText: 'DZD ',
                      prefixStyle: const TextStyle(color: Colors.grey),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = null;
                        _maxPrice = null;
                        minController.clear();
                        maxController.clear();
                      });
                      _reloadAvailableJobs();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.clear,
                      style: const TextStyle(color: Color(0xFF3B82F6)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minPrice = double.tryParse(minController.text);
                        _maxPrice = double.tryParse(maxController.text);
                        // Validate range
                        if (_minPrice != null && _minPrice! < 0) {
                          _minPrice = null;
                        }
                        if (_maxPrice != null && _maxPrice! < 0) {
                          _maxPrice = null;
                        }
                        if (_minPrice != null &&
                            _maxPrice != null &&
                            _minPrice! > _maxPrice!) {
                          // Swap if min > max
                          final temp = _minPrice;
                          _minPrice = _maxPrice;
                          _maxPrice = temp;
                        }
                      });
                      _reloadAvailableJobs();
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.apply,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reloadAvailableJobs() {
    if (_agencyId != null) {
      context.read<AvailableJobsCubit>().loadAvailableJobs(
        _agencyId!,
        wilayas: _selectedWilayas.isEmpty ? null : _selectedWilayas.toList(),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    }
  }
}
