// App state: language (Pashto RTL / English LTR), theme (light/dark) and
// favourite books. Everything is stored on the phone with
// shared_preferences, so it works without internet and without an account.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _isPashto = _prefs.getBool('isPashto') ?? true;
    final theme = _prefs.getString('themeMode') ?? 'system';
    _themeMode = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _favorites = _prefs.getStringList('favorites')?.toSet() ?? <String>{};
  }

  final SharedPreferences _prefs;

  bool _isPashto = true;
  bool get isPashto => _isPashto;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Set<String> _favorites = <String>{};
  Set<String> get favorites => _favorites;

  Future<void> setPashto(bool value) async {
    _isPashto = value;
    await _prefs.setBool('isPashto', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(
      'themeMode',
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
    notifyListeners();
  }

  bool isFavorite(String bookId) => _favorites.contains(bookId);

  Future<void> toggleFavorite(String bookId) async {
    if (_favorites.contains(bookId)) {
      _favorites.remove(bookId);
    } else {
      _favorites.add(bookId);
    }
    await _prefs.setStringList('favorites', _favorites.toList());
    notifyListeners();
  }
}
