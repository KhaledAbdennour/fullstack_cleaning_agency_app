import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'app_locale';

  static Future<Locale?> getSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        return Locale(localeCode);
      }
    } catch (e) {
      print('Error loading saved locale: $e');
    }
    return null;
  }

  static Future<void> saveLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      print('Error saving locale: $e');
    }
  }

  static List<Locale> get supportedLocales => const [
        Locale('en', ''),
        Locale('fr', ''),
        Locale('ar', ''),
      ];

  static bool isRTL(Locale locale) {
    return locale.languageCode == 'ar';
  }
}
