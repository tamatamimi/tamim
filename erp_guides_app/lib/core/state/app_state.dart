import 'package:flutter/material.dart';

/// Global, lightweight app state: active language and theme mode.
///
/// Offline-first: no persistence backend required. This can later be backed by
/// `shared_preferences` to remember the user's choice across launches.
class AppState extends ChangeNotifier {
  Locale _locale = const Locale('ar');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isArabic => _locale.languageCode == 'ar';

  void toggleLanguage() {
    _locale = isArabic ? const Locale('en') : const Locale('ar');
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
