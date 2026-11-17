// App state: language (Pashto RTL / English LTR), theme (light/dark),
// favourite books and the local student account. Everything is stored
// on the phone with shared_preferences, so it works without internet.
// The account is local for now; it can switch to Supabase Auth later
// (see services/account.dart).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account.dart';

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
    _account = AccountService.load(_prefs);
    _loggedIn = AccountService.isLoggedIn(_prefs);
  }

  final SharedPreferences _prefs;

  bool _isPashto = true;
  bool get isPashto => _isPashto;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Set<String> _favorites = <String>{};
  Set<String> get favorites => _favorites;

  Account? _account;
  Account? get currentAccount => _account;

  bool _loggedIn = false;

  /// Logged in only when an account exists AND the session is active.
  /// After logout the account stays on the phone, so the student can
  /// log back in with the same email and password.
  bool get isLoggedIn => _account != null && _loggedIn;

  /// Save a new account (register) and log in.
  Future<void> setAccount(Account account, String password) async {
    await AccountService.save(_prefs, account, password);
    _account = account;
    _loggedIn = true;
    notifyListeners();
  }

  /// Log in with the account already on the phone (login screen).
  Future<void> login() async {
    await AccountService.setLoggedIn(_prefs, true);
    _loggedIn = true;
    notifyListeners();
  }

  /// Check the typed password against the stored hash (login).
  bool checkPassword(String password) =>
      AccountService.checkPassword(_prefs, password);

  /// Log out: only the session ends. The account, language, theme
  /// and favourites stay on the phone.
  Future<void> logout() async {
    await AccountService.setLoggedIn(_prefs, false);
    _loggedIn = false;
    notifyListeners();
  }

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
