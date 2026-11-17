// Local student account for the student app.
//
// For now the account lives ONLY on the phone: the profile (name,
// faculty, department, email, photo path) and a SHA-256 hash of the
// password are stored in SharedPreferences. The plain password is
// NEVER stored. The picked photo is copied into the app documents
// directory (path_provider) and only its path is kept in the profile.
//
// Later this can switch to Supabase Auth: keep every account call
// inside AccountService and AppState, so only this file changes.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account {
  const Account({
    required this.firstName,
    required this.surname,
    required this.facultyId,
    required this.departmentId,
    required this.email,
    this.photoPath,
  });

  final String firstName;
  final String surname;
  final String facultyId;
  final String departmentId;
  final String email;
  final String? photoPath;

  String get fullName => '$firstName $surname';

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'surname': surname,
        'facultyId': facultyId,
        'departmentId': departmentId,
        'email': email,
        'photoPath': photoPath,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        firstName: json['firstName'] as String? ?? '',
        surname: json['surname'] as String? ?? '',
        facultyId: json['facultyId'] as String? ?? '',
        departmentId: json['departmentId'] as String? ?? '',
        email: json['email'] as String? ?? '',
        photoPath: json['photoPath'] as String?,
      );
}

class AccountService {
  static const _accountKey = 'account';
  static const _passwordHashKey = 'accountPasswordHash';

  /// SHA-256 hash of the password. The plain password is never saved.
  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  /// The account stored on this phone, or null if nobody registered yet.
  static Account? load(SharedPreferences prefs) {
    final raw = prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Account.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    SharedPreferences prefs,
    Account account,
    String password,
  ) async {
    await prefs.setString(_accountKey, jsonEncode(account.toJson()));
    await prefs.setString(_passwordHashKey, hashPassword(password));
  }

  static bool checkPassword(SharedPreferences prefs, String password) {
    final stored = prefs.getString(_passwordHashKey);
    if (stored == null) return false;
    return stored == hashPassword(password);
  }

  /// Remove the account (logout). Language, theme and favourites stay.
  static Future<void> clear(SharedPreferences prefs) async {
    await prefs.remove(_accountKey);
    await prefs.remove(_passwordHashKey);
  }

  /// Copy a picked photo into the app documents directory and return
  /// the path to store in the profile.
  static Future<String> storePhoto(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File('${dir.path}/profile_photo.jpg');
    return (await source.copy(target.path)).path;
  }
}
