import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'EditProfilePage.dart';
import '../widgets/notification_bell_widget.dart';
import 'data_doctor_page.dart';
import 'settings_page.dart';
import 'manage_job_page.dart';
import 'add-post.dart';
import 'jobdetails.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../logic/cubits/client_jobs_cubit.dart';
import '../data/models/job_model.dart';
import '../utils/image_helper.dart';
import '../core/debug/debug_logger.dart';
import '../data/repositories/storage/storage_repo.dart';
import '../data/repositories/profiles/profile_repo.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({Key? key}) : super(key: key);

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  int _selectedTabIndex = 0;
  int? _clientId;
  String? _avatarUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // #region agent log
    DebugLogger.log('ClientProfilePage', 'initState', data: {
      'hypothesisId': 'H1',
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    _loadClientId();
  }


  Future<void> _loadClientId() async {
    // #region agent log
    DebugLogger.log('ClientProfilePage', '_loadClientId_START', data: {
      'hypothesisId': 'H1',
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    final cubit = context.read<ProfilesCubit>();
    
    // Check current state first - avoid reloading if already loaded
    final currentState = cubit.state;
    if (currentState is ProfilesLoaded && currentState.currentUser != null) {
      // User already loaded, use existing state
      final userId = currentState.currentUser!['id'] as int?;
      final userType = currentState.currentUser!['user_type'] as String?;
      
      // #region agent log
      DebugLogger.log('ClientProfilePage', '_loadClientId_USE_EXISTING', data: {
        'hypothesisId': 'H1',
        'userId': userId,
        'userType': userType,
        'isClient': userType == 'Client',
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
      
      if (userId != null && userType == 'Client') {
        setState(() {
          _clientId = userId;
          _avatarUrl = currentState.currentUser!['picture'] as String?;
        });
        
        // #region agent log
        DebugLogger.log('ClientProfilePage', '_loadClientId_SET_CLIENT_ID', data: {
          'hypothesisId': 'H1',
          'clientId': _clientId,
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
        
        if (mounted) {
          context.read<ClientJobsCubit>().loadClientJobs(userId);
        }
      } else {
        // #region agent log
        DebugLogger.log('ClientProfilePage', '_loadClientId_NOT_CLIENT', data: {
          'hypothesisId': 'H1',
          'userId': userId,
          'userType': userType,
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
      }
      return;
    }
    
    // Only load if not already loaded
    await cubit.loadCurrentUser();
    if (!mounted) return;
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      final userId = state.currentUser!['id'] as int?;
      final userType = state.currentUser!['user_type'] as String?;
      
      // #region agent log
      DebugLogger.log('ClientProfilePage', '_loadClientId_USER_DATA', data: {
        'hypothesisId': 'H1',
        'userId': userId,
        'userType': userType,
        'isClient': userType == 'Client',
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
      
      if (userId != null && userType == 'Client') {
        setState(() {
          _clientId = userId;
          _avatarUrl = state.currentUser!['picture'] as String?;
        });
        
        // #region agent log
        DebugLogger.log('ClientProfilePage', '_loadClientId_SET_CLIENT_ID', data: {
          'hypothesisId': 'H1',
          'clientId': _clientId,
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
        
        if (mounted) {
          context.read<ClientJobsCubit>().loadClientJobs(userId);
        }
      } else {
        // #region agent log
        DebugLogger.log('ClientProfilePage', '_loadClientId_NOT_CLIENT', data: {
          'hypothesisId': 'H1',
          'userId': userId,
          'userType': userType,
          'sessionId': 'debug-session',
          'runId': 'run1',
        });
        // #endregion
      }
    } else {
      // #region agent log
      DebugLogger.log('ClientProfilePage', '_loadClientId_NO_USER', data: {
        'hypothesisId': 'H1',
        'stateType': state.runtimeType.toString(),
        'sessionId': 'debug-session',
        'runId': 'run1',
      });
      // #endregion
    }
  }

  
  final List<Map<String, dynamic>> jobPosts = [
    {
      'title': 'Apartment Cleaning',
      'description': 'Looking for a cleaner for a 2-bedroom apartment.',
      'postedDaysAgo': 2,
      'price': '5000 DZD',
      'date': 'October 26, 2024, 10:00 AM',
      'location': '123 Rue Didouche Mourad, Algiers, Algeria',
      'notes': 'Please focus on the kitchen and bathroom.',
      'client': 'Fatima Zohra',
      'status': 'InProgress',
      'image':
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=400',
      'hasApplications': true,
      'applications': [
        {
          'name': "Fatima's Cleaning",
          'price': '5000 DZD',
          'description': 'I have 5 years of experience and can bring my own supplies...',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=fatima',
        },
        {
          'name': 'Ahmed Belkacem',
          'price': '4500 DZD',
          'description': 'Available immediately. I have excellent references.',
          'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=ahmed',
        },
      ],
    },
    {
      'title': 'Office Cleaning',
      'description': 'Weekly cleaning for a small office space.',
      'postedDaysAgo': 5,
      'price': '6500 DZD',
      'date': 'November 2, 2024, 2:00 PM',
      'location': 'Boulevard Amirouche, Algiers, Algeria',
      'notes': 'Focus on meeting rooms and pantry.',
      'client': 'TechHub SARL',
      'status': 'Pending',
      'image':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400',
      'hasApplications': false,
      'applications': [],
    },
  ];

  void _handleEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
    // No context usage after Navigator.push - safe
    
    if (mounted) {
      context.read<ProfilesCubit>().loadCurrentUser();
    }
  }

  void _handleSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _handleViewDetails(Map<String, dynamic> job) {
    
    
  }

  Future<void> _changePhoto() async {
    if (_clientId == null || _isUploadingImage) return;

    try {
      // Show options to pick from gallery or camera
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null || !mounted) return;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _isUploadingImage = true;
      });

      String? newImageUrl;
      
      try {
        // Upload new image
        final storageRepo = AbstractStorageRepo.getInstance();
        newImageUrl = await storageRepo.uploadProfileImage(
          _clientId!,
          image.path,
        );

        if (!mounted) return;

        // Delete old image if it exists (fail silently if file doesn't exist)
        // Note: deleteProfileImage should not throw, but wrap in try-catch just in case
        if (_avatarUrl != null && _avatarUrl!.isNotEmpty && _avatarUrl!.startsWith('http')) {
          try {
            await storageRepo.deleteProfileImage(_avatarUrl!);
          } catch (e) {
            // Ignore all errors from delete - it's not critical if old file can't be deleted
            // This is expected if the file doesn't exist (e.g., first upload or file was already deleted)
          }
        }

        // Update profile with new avatar URL
        final profileRepo = AbstractProfileRepo.getInstance();
        final success = await profileRepo.updateAvatarUrl(_clientId!, newImageUrl!);

        if (!mounted) return;

        if (success) {
          // Update local state first
          setState(() {
            _avatarUrl = newImageUrl;
            _isUploadingImage = false;
          });

          // Refresh profile state to ensure UI updates with new picture
          final cubit = context.read<ProfilesCubit>();
          await cubit.loadCurrentUser();

          // Wait a bit to ensure state is updated
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            // Force rebuild to show new image
            setState(() {});
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile picture'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        
        // Check if it's an object-not-found error (file doesn't exist)
        // This is expected and should be handled silently
        final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('object-not-found') || 
          errorStr.contains('no object exists') ||
          errorStr.contains('[firebase_storage/object-not-found]')) {
        // Silently handle - this is expected when old file doesn't exist
        setState(() {
          _isUploadingImage = false;
        });
        // Still try to update the profile if we have the new image URL from upload
        // The upload should have succeeded, only the delete failed
        if (newImageUrl != null && newImageUrl.isNotEmpty) {
          // Try to update profile with the new image URL (upload succeeded)
          try {
            final profileRepo = AbstractProfileRepo.getInstance();
            final success = await profileRepo.updateAvatarUrl(_clientId!, newImageUrl);
            
            if (success) {
              // Update local state
              setState(() {
                _avatarUrl = newImageUrl;
                _isUploadingImage = false;
              });
              
              // Refresh profile state to show new image
              final cubit = context.read<ProfilesCubit>();
              await cubit.loadCurrentUser();
              
              if (mounted) {
                // Force rebuild to show new image
                setState(() {});
              }
            } else {
              setState(() {
                _isUploadingImage = false;
              });
            }
          } catch (updateError) {
            // If profile update also fails, just reset the uploading state
            setState(() {
              _isUploadingImage = false;
            });
          }
        } else {
          setState(() {
            _isUploadingImage = false;
          });
        }
        return; // Don't show error message for expected errors
      }
      
        // If it's not an object-not-found error, show error message
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (outerError) {
      // Handle any errors from showing bottom sheet or picking image
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // #region agent log
    DebugLogger.log('ClientProfilePage', 'didChangeDependencies', data: {
      'hypothesisId': 'H1',
      'clientId': _clientId,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
  }

  @override
  void didUpdateWidget(ClientProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // #region agent log
    DebugLogger.log('ClientProfilePage', 'didUpdateWidget', data: {
      'hypothesisId': 'H1',
      'clientId': _clientId,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    if (_clientId != null) {
      context.read<ClientJobsCubit>().loadClientJobs(_clientId!);
    }
  }
  
  @override
  void dispose() {
    // #region agent log
    DebugLogger.log('ClientProfilePage', 'dispose', data: {
      'hypothesisId': 'H1',
      'clientId': _clientId,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // #region agent log
    DebugLogger.log('ClientProfilePage', 'build_CALLED', data: {
      'hypothesisId': 'H1',
      'clientId': _clientId,
      'selectedTabIndex': _selectedTabIndex,
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    // Return full Scaffold so profile page can be used standalone or in HomeScreen
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DataDoctorPage()),
            );
          },
          child: const SizedBox.shrink(),
        ),
        actions: [
          const NotificationBellWidget(),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF6B7280)),
            onPressed: _handleSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildProfileInfo(),
              const SizedBox(height: 24),
              _buildTabBar(),
              const SizedBox(height: 16),
              _buildTabContent(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildProfileInfo() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        String displayName = 'New User';
        String? avatarUrl;
        
        if (state is ProfilesLoaded && state.currentUser != null) {
          displayName = state.currentUser!['full_name'] as String? ?? 
                       state.currentUser!['username'] as String? ?? 
                       'New User';
          avatarUrl = state.currentUser!['picture'] as String?;
          
          // Update local avatar URL if different
          if (avatarUrl != _avatarUrl) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _avatarUrl = avatarUrl;
                });
              }
            });
          }
        }

        return Column(
          children: [
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isUploadingImage ? null : _changePhoto,
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: AppImage(
                              imageUrl: _avatarUrl!,
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorWidget: const Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.white,
                          ),
                  ),
                  if (_isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: const CircularProgressIndicator(
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return BlocBuilder<ProfilesCubit, ProfilesState>(
      builder: (context, state) {
        bool isClient = true;
        if (state is ProfilesLoaded && state.currentUser != null) {
          final userType = state.currentUser!['user_type'] as String?;
          isClient = userType == 'Client';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              _buildTab('My Posts', 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        
        if (index == 0 && _clientId != null) {
          context.read<ClientJobsCubit>().refresh(_clientId!);
        }
      },
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildTabContent() {
    return _buildJobPostsList();
  }

  Widget _buildJobPostsList() {
    if (_clientId == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }

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
                    context.read<ClientJobsCubit>().refresh(_clientId!);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (state is ClientJobsLoaded) {
          if (state.jobs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No posts yet. Create your first job posting!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }

          // Sort jobs by most recent first (postedDate descending) - same as homepage
          final sortedJobs = List<Job>.from(state.jobs);
          sortedJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

          return Column(
            children: sortedJobs.map((job) {
              try {
                
                if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _buildJobPostCardFromJob(job);
              } catch (e, stackTrace) {
                print('Error building job post card: $e');
                print('Stack trace: $stackTrace');
                return const SizedBox.shrink();
              }
            }).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  
  final List<Map<String, dynamic>> cleaningHistory = [
    {
      'title': 'Office Building',
      'date': 'June 5, 2024',
      'description': 'Standard office cleaning, completed successfully.',
      'icon': Icons.business,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Apartment',
      'date': 'May 20, 2024',
      'description': 'Deep cleaning service for a 3-bedroom apartment.',
      'icon': Icons.apartment,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
    {
      'title': 'Villa',
      'date': 'May 10, 2024',
      'description': 'Full-day cleaning for a large villa, including windows.',
      'icon': Icons.villa,
      'iconColor': const Color(0xFF3B82F6),
      'bgColor': const Color(0xFFDBEAFE),
    },
  ];

  Widget _buildHistoryList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cleaning History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...cleaningHistory.map(_buildHistoryCard).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                
              },
              child: const Text(
                'Load More',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> history) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: history['bgColor'] as Color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              history['icon'] as IconData,
              color: history['iconColor'] as Color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  history['date'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  history['description'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'Amina K.',
      'date': 'June 10, 2024',
      'rating': 5,
      'text': 'Fatima was amazing! She left my apartment sparkling clean. Very professional and friendly.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=amina',
    },
    {
      'name': 'Karim B.',
      'date': 'May 28, 2024',
      'rating': 4,
      'text': 'Great service, very thorough. Would hire again.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=karim',
    },
    {
      'name': 'Yasmine L.',
      'date': 'May 15, 2024',
      'rating': 5,
      'text': 'Excellent work! My house has never been cleaner. Fatima paid attention to every detail.',
      'avatar': 'https://api.dicebear.com/7.x/avataaars/png?seed=yasmine',
      'hasPhotos': true,
    },
  ];

  Widget _buildReviewsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Reviews',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...reviews.map(_buildReviewCard).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                
              },
              child: const Text(
                'Load More',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage: NetworkImage(review['avatar'] as String),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['date'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < (review['rating'] as int)
                    ? Icons.star
                    : Icons.star_border,
                size: 16,
                color: index < (review['rating'] as int)
                    ? Colors.amber
                    : const Color(0xFFD1D5DB),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            review['text'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
          if (review['hasPhotos'] == true) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobPostCardFromJob(Job job) {
    try {
      
      if (job.title.isEmpty || job.city.isEmpty || job.country.isEmpty) {
        return const SizedBox.shrink();
      }

      final daysAgo = DateTime.now().difference(job.postedDate).inDays;
      final daysAgoText = daysAgo == 0 
          ? 'Today' 
          : daysAgo == 1 
              ? 'Yesterday' 
              : '$daysAgo days ago';

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
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted $daysAgoText',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${job.city}, ${job.country}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: job.coverImageUrl != null && job.coverImageUrl!.isNotEmpty
                  ? AppImage(
                      imageUrl: job.coverImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      print('Error building job post card from job: $e');
      print('Stack trace: $stackTrace');
      return const SizedBox.shrink();
    }
  }

  Widget _buildJobPostCard(Map<String, dynamic> job) {
    
    
    return InkWell(
      onTap: () {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please use the new job card format')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Posted ${job['postedDaysAgo']} days ago',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                job['image'],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.image,
                      color: Color(0xFF9CA3AF),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


