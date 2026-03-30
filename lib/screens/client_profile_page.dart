import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/notification_bell_widget.dart';
import 'data_doctor_page.dart';
import 'EditProfilePage.dart';
import 'login.dart';
import 'support_page.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../core/services/locale_service.dart';
import '../utils/image_helper.dart';
import '../core/debug/debug_logger.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class ClientProfilePage extends StatefulWidget {
  const ClientProfilePage({super.key});

  @override
  State<ClientProfilePage> createState() => _ClientProfilePageState();
}

class _ClientProfilePageState extends State<ClientProfilePage> {
  int? _clientId;
  String? _avatarUrl;
  bool _isUploadingImage = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();

    DebugLogger.log(
      'ClientProfilePage',
      'initState',
      data: {
        'hypothesisId': 'H1',
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    _loadClientId();
  }

  Future<void> _loadClientId() async {
    DebugLogger.log(
      'ClientProfilePage',
      '_loadClientId_START',
      data: {
        'hypothesisId': 'H1',
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    final cubit = context.read<ProfilesCubit>();

    final currentState = cubit.state;
    if (currentState is ProfilesLoaded && currentState.currentUser != null) {
      final userId = currentState.currentUser!['id'] as int?;
      final userType = currentState.currentUser!['user_type'] as String?;

      DebugLogger.log(
        'ClientProfilePage',
        '_loadClientId_USE_EXISTING',
        data: {
          'hypothesisId': 'H1',
          'userId': userId,
          'userType': userType,
          'isClient': userType == 'Client',
          'sessionId': 'debug-session',
          'runId': 'run1',
        },
      );

      if (userId != null && userType == 'Client') {
        setState(() {
          _clientId = userId;
          _avatarUrl = currentState.currentUser!['picture'] as String?;
        });

        DebugLogger.log(
          'ClientProfilePage',
          '_loadClientId_SET_CLIENT_ID',
          data: {
            'hypothesisId': 'H1',
            'clientId': _clientId,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );
      } else {
        DebugLogger.log(
          'ClientProfilePage',
          '_loadClientId_NOT_CLIENT',
          data: {
            'hypothesisId': 'H1',
            'userId': userId,
            'userType': userType,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );
      }
      return;
    }

    await cubit.loadCurrentUser();
    if (!mounted) return;
    final state = cubit.state;
    if (state is ProfilesLoaded && state.currentUser != null) {
      final userId = state.currentUser!['id'] as int?;
      final userType = state.currentUser!['user_type'] as String?;

      DebugLogger.log(
        'ClientProfilePage',
        '_loadClientId_USER_DATA',
        data: {
          'hypothesisId': 'H1',
          'userId': userId,
          'userType': userType,
          'isClient': userType == 'Client',
          'sessionId': 'debug-session',
          'runId': 'run1',
        },
      );

      if (userId != null && userType == 'Client') {
        setState(() {
          _clientId = userId;
          _avatarUrl = state.currentUser!['picture'] as String?;
        });

        DebugLogger.log(
          'ClientProfilePage',
          '_loadClientId_SET_CLIENT_ID',
          data: {
            'hypothesisId': 'H1',
            'clientId': _clientId,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );
      } else {
        DebugLogger.log(
          'ClientProfilePage',
          '_loadClientId_NOT_CLIENT',
          data: {
            'hypothesisId': 'H1',
            'userId': userId,
            'userType': userType,
            'sessionId': 'debug-session',
            'runId': 'run1',
          },
        );
      }
    } else {
      DebugLogger.log(
        'ClientProfilePage',
        '_loadClientId_NO_USER',
        data: {
          'hypothesisId': 'H1',
          'stateType': state.runtimeType.toString(),
          'sessionId': 'debug-session',
          'runId': 'run1',
        },
      );
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
          'description':
              'I have 5 years of experience and can bring my own supplies...',
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    DebugLogger.log(
      'ClientProfilePage',
      'didChangeDependencies',
      data: {
        'hypothesisId': 'H1',
        'clientId': _clientId,
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );
  }

  @override
  void didUpdateWidget(ClientProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    DebugLogger.log(
      'ClientProfilePage',
      'didUpdateWidget',
      data: {
        'hypothesisId': 'H1',
        'clientId': _clientId,
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );
  }

  @override
  void dispose() {
    DebugLogger.log(
      'ClientProfilePage',
      'dispose',
      data: {
        'hypothesisId': 'H1',
        'clientId': _clientId,
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DebugLogger.log(
      'ClientProfilePage',
      'build_CALLED',
      data: {
        'hypothesisId': 'H1',
        'clientId': _clientId,
        'sessionId': 'debug-session',
        'runId': 'run1',
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onLongPress: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DataDoctorPage()));
          },
          child: const SizedBox.shrink(),
        ),
        actions: [const NotificationBellWidget()],
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
                      : const Icon(Icons.person, size: 65, color: Colors.white),
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
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
              MaterialPageRoute(builder: (context) => const SupportPage()),
            );
          },
        ),
        const SizedBox(height: 16),
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
      {
        'locale': const Locale('en', ''),
        'name': 'English',
        'native': 'English',
      },
      {
        'locale': const Locale('fr', ''),
        'name': 'French',
        'native': 'Français',
      },
      {'locale': const Locale('ar', ''), 'name': 'Arabic', 'native': 'العربية'},
    ];

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(AppLocalizations.of(context)!.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              final locale = lang['locale'] as Locale;
              final isSelected =
                  locale.languageCode == currentLocale.languageCode;
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
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );

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
      activeThumbColor: const Color(0xFF3B82F6),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
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
