import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../widgets/notification_bell_widget.dart';
import 'data_doctor_page.dart';
import 'EditProfilePage.dart';
import 'login.dart';
import 'support_page.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../core/services/locale_service.dart';
import '../utils/image_helper.dart';
import '../core/debug/debug_logger.dart';
import '../data/repositories/profiles/profile_repo.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({Key? key}) : super(key: key);

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  int? _clientId;
  String? _avatarUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();
  bool _notificationsEnabled = true;

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

      try {
        // Convert image to base64 data URL (same approach as post images)
        final imageFile = File(image.path);
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        final extension = image.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg'; 
        if (extension == 'png') {
          mimeType = 'image/png';
        } else if (extension == 'gif') {
          mimeType = 'image/gif';
        } else if (extension == 'webp') {
          mimeType = 'image/webp';
        }
        
        final imageDataUrl = 'data:$mimeType;base64,$base64Image';

        if (!mounted) return;

        // Update profile with base64 data URL
        final profileRepo = AbstractProfileRepo.getInstance();
        print('Updating picture field for user $_clientId with base64 data URL');
        print('Data URL length: ${imageDataUrl.length}');
        
        final success = await profileRepo.updateAvatarUrl(_clientId!, imageDataUrl);
        print('Update picture field result: $success');

        if (!success) {
          setState(() {
            _isUploadingImage = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save picture to database. Please try again.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        if (!mounted) return;

        // Refresh profile state to get updated picture from database
        final cubit = context.read<ProfilesCubit>();
        await cubit.loadCurrentUser();

        // Wait a bit to ensure state is updated
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          // Get updated user data from cubit state
          final updatedState = cubit.state;
          if (updatedState is ProfilesLoaded && updatedState.currentUser != null) {
            final updatedPicture = updatedState.currentUser!['picture'] as String?;
            setState(() {
              _avatarUrl = updatedPicture;
              _isUploadingImage = false;
            });
          } else {
            // Fallback: use the imageDataUrl if state doesn't have it
            setState(() {
              _avatarUrl = imageDataUrl;
              _isUploadingImage = false;
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        print('Error processing image: $error');
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process image: ${error.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (outerError) {
      // Handle any errors from showing bottom sheet or picking image
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${outerError.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
      'sessionId': 'debug-session',
      'runId': 'run1',
    });
    // #endregion
    
    // Return full Scaffold so profile page can be used standalone or in HomeScreen
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
              _buildProfileHeader(),
              _buildProfileInfo(),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                child: _buildSettingsContent(),
              ),
              const SizedBox(height: 16),
          ],
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
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
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
                            width: 130,
                            height: 130,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(
                              Icons.person,
                              size: 65,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 65,
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
            const SizedBox(height: 8),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Account Section
        Text(
          AppLocalizations.of(context)!.account,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        _buildLanguageTile(),
        _buildEditProfileTile(),
        _buildNotificationTile(),
        const SizedBox(height: 16),
        // Payment Section
        Text(
          AppLocalizations.of(context)!.payment,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        _buildTile(
          icon: Icons.credit_card,
          title: AppLocalizations.of(context)!.paymentMethods,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This functionality is coming soon'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Support Section
        Text(
          AppLocalizations.of(context)!.support,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        _buildTile(
          icon: Icons.help_outline,
          title: AppLocalizations.of(context)!.helpSupport,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SupportPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Logout Button
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.logout, color: Color(0xFF3B82F6)),
            label: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageTile() {
    final currentLocale = Localizations.localeOf(context);
    final localeNames = {
      const Locale('en', ''): 'English',
      const Locale('fr', ''): 'Français',
      const Locale('ar', ''): 'العربية',
    };

    return ListTile(
      leading: const Icon(Icons.language, color: Color(0xFF3B82F6)),
      title: Text(
        AppLocalizations.of(context)!.language,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        localeNames[currentLocale] ?? 'English',
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF3B82F6),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _showLanguageDialog(),
    );
  }

  void _showLanguageDialog() {
    final currentLocale = Localizations.localeOf(context);
    final languages = [
      {'locale': const Locale('en', ''), 'name': 'English', 'native': 'English'},
      {'locale': const Locale('fr', ''), 'name': 'French', 'native': 'Français'},
      {'locale': const Locale('ar', ''), 'name': 'Arabic', 'native': 'العربية'},
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppLocalizations.of(context)!.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final locale = lang['locale'] as Locale;
              final isSelected = locale.languageCode == currentLocale.languageCode;
              return ListTile(
                title: Text(lang['native'] as String),
                subtitle: Text(lang['name'] as String),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _changeLanguage(locale);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _changeLanguage(Locale locale) async {
    await LocaleService.saveLocale(locale);
    if (!mounted) return;
    // Find the MyApp widget and update its locale
    final appState = MyApp.of(context);
    if (appState != null) {
      appState.changeLocale(locale);
    }
  }

  Widget _buildEditProfileTile() {
    return ListTile(
      leading: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
      title: Text(
        AppLocalizations.of(context)!.editProfile,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
        // Refresh profile after editing
        if (mounted) {
          context.read<ProfilesCubit>().loadCurrentUser();
        }
      },
    );
  }

  Widget _buildNotificationTile() {
    return SwitchListTile(
      secondary: const Icon(Icons.notifications_none, color: Color(0xFF3B82F6)),
      title: Text(
        AppLocalizations.of(context)!.notifications,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      value: _notificationsEnabled,
      activeColor: const Color(0xFF3B82F6),
      onChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
        });
      },
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF3B82F6)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w500,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              Text(
                AppLocalizations.of(context)!.logOut,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.logOutMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                        SnackBar(content: Text(AppLocalizations.of(context)!.loggedOutSuccessfully)),
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
                  child: Text(
                    AppLocalizations.of(context)!.yesLogOut,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF9FAFB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(
                      color: Color(0xFF111827),
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
}


