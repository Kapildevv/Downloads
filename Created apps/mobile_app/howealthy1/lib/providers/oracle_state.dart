import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- HIVE PERSISTENCE BOX ---
late Box oracleBox;

// --- THEME STATE PROVIDER ---
// Persists the theme across app uninstalls and hard resets using Hive.
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  final isDarkMode = oracleBox.get('isDarkMode', defaultValue: true);
  return ThemeNotifier(isDarkMode);
});

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier(super.state);

  void toggleTheme() {
    state = !state;
    oracleBox.put('isDarkMode', state); // Instantaneous persistence
  }
}

// --- LOCALE STATE PROVIDER ---
// Persists the user's language preference in Hive for offline-first locale switching.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final savedLocale = oracleBox.get('locale', defaultValue: 'en');
  return LocaleNotifier(Locale(savedLocale));
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.state);

  void setLocale(Locale locale) {
    state = locale;
    oracleBox.put('locale', locale.languageCode);
  }

  /// Returns the list of supported locales with display names for the language selector.
  static List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English'},
        {'code': 'hi', 'name': 'हिन्दी'},
        {'code': 'ta', 'name': 'தமிழ்'},
        {'code': 'te', 'name': 'తెలుగు'},
        {'code': 'kn', 'name': 'ಕನ್ನಡ'},
      ];
}
