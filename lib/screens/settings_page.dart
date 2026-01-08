import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login.dart';
import 'EditProfilePage.dart';
import '../logic/cubits/profiles_cubit.dart';
import '../core/services/locale_service.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E7EB),
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.settingsPage,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFE5E7EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
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
                onTap: () {},
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
                onTap: () {},
              ),
              const Spacer(),

              
              SizedBox(
                height: 48,
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
          ),
        ),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        );
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
                    style: TextStyle(
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
                    style: TextStyle(
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
