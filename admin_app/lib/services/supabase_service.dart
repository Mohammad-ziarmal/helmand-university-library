// Supabase access for the Admin App.
//
// SECURITY: the URL and anon key are NEVER written in this code. They come
// from --dart-define SUPABASE_URL / SUPABASE_ANON_KEY (in GitHub Actions
// they come from repository Secrets). Without them the app shows the
// setup screen instead of crashing or pretending to work.
//
// Row Level Security (see supabase/schema.sql) makes sure only signed-in
// admins can write. The student app uses only the public anon key for
// reading, and this admin app uses the signed-in admin's session.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

class NotConfiguredError implements Exception {
  const NotConfiguredError();
  @override
  String toString() => 'Supabase is not connected yet.';
}

class SupabaseService {
  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  /// The public host of the Supabase project (safe to display; the key
  /// itself is never shown).
  static String get projectHost {
    if (!isConfigured) return '';
    final uri = Uri.tryParse(_supabaseUrl);
    return uri?.host ?? '';
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }

  static void _requireConfigured() {
    if (!isConfigured) throw const NotConfiguredError();
  }

  static bool get isSignedIn {
    try {
      return client.auth.currentSession != null;
    } catch (_) {
      // Supabase was not initialised (bad URL/key): treat as signed out.
      return false;
    }
  }

  static Future<void> signIn(String email, String password) async {
    _requireConfigured();
    await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() async {
    _requireConfigured();
    await client.auth.signOut();
  }

  // ---------------------------------------------------------- faculties
  static Future<List<FacultyRow>> fetchFaculties() async {
    _requireConfigured();
    final rows = await client
        .from('faculties')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => FacultyRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addFaculty(String namePs, String nameEn) async {
    _requireConfigured();
    final inserted = await client.from('faculties').insert({
      'name_ps': namePs,
      'name_en': nameEn,
    }).select('id');
    await _audit('insert', 'faculties',
        (inserted as List).first['id'] as String?);
  }

  static Future<void> deleteFaculty(String id) async {
    _requireConfigured();
    await client.from('faculties').delete().eq('id', id);
    await _audit('delete', 'faculties', id);
  }

  // -------------------------------------------------------- departments
  static Future<List<DepartmentRow>> fetchDepartments(
    String facultyId,
  ) async {
    _requireConfigured();
    final rows = await client
        .from('departments')
        .select()
        .eq('faculty_id', facultyId)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => DepartmentRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addDepartment(
    String facultyId,
    String namePs,
    String nameEn,
    int semesters,
  ) async {
    _requireConfigured();
    final inserted = await client.from('departments').insert({
      'faculty_id': facultyId,
      'name_ps': namePs,
      'name_en': nameEn,
      'semesters': semesters,
    }).select('id');
    await _audit('insert', 'departments',
        (inserted as List).first['id'] as String?);
  }

  static Future<void> deleteDepartment(String id) async {
    _requireConfigured();
    await client.from('departments').delete().eq('id', id);
    await _audit('delete', 'departments', id);
  }

  // ---------------------------------------------------------- semesters
  static Future<List<SemesterRow>> fetchSemesters(
    String departmentId,
  ) async {
    _requireConfigured();
    final rows = await client
        .from('semesters')
        .select()
        .eq('department_id', departmentId)
        .order('semester_number', ascending: true);
    return (rows as List)
        .map((e) => SemesterRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addSemester(
    String departmentId,
    int semesterNumber,
  ) async {
    _requireConfigured();
    final inserted = await client.from('semesters').insert({
      'department_id': departmentId,
      'semester_number': semesterNumber,
    }).select('id');
    await _audit(
        'insert', 'semesters', (inserted as List).first['id'] as String?);
  }

  static Future<void> deleteSemester(String id) async {
    _requireConfigured();
    await client.from('semesters').delete().eq('id', id);
    await _audit('delete', 'semesters', id);
  }

  // -------------------------------------------------------------- books
  static Future<List<BookRow>> fetchBooks() async {
    _requireConfigured();
    final rows = await client
        .from('books')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => BookRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addBook(BookRow book) async {
    _requireConfigured();
    final inserted = await client
        .from('books')
        .insert(book.toMap())
        .select('id');
    await _audit(
        'insert', 'books', (inserted as List).first['id'] as String?);
  }

  static Future<void> updateBook(BookRow book) async {
    _requireConfigured();
    await client.from('books').update(book.toMap()).eq('id', book.id);
    await _audit('update', 'books', book.id);
  }

  static Future<void> deleteBook(String id) async {
    _requireConfigured();
    await client.from('books').delete().eq('id', id);
    await _audit('delete', 'books', id);
  }

  // ------------------------------------------------------- reading books
  static Future<List<ReadingBookRow>> fetchReadingBooks() async {
    _requireConfigured();
    final rows = await client
        .from('reading_books')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => ReadingBookRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addReadingBook(ReadingBookRow book) async {
    _requireConfigured();
    final inserted = await client
        .from('reading_books')
        .insert(book.toMap())
        .select('id');
    await _audit('insert', 'reading_books',
        (inserted as List).first['id'] as String?);
  }

  static Future<void> deleteReadingBook(String id) async {
    _requireConfigured();
    await client.from('reading_books').delete().eq('id', id);
    await _audit('delete', 'reading_books', id);
  }

  // ------------------------------------------------------- PDF upload
  /// Pick a PDF on the phone and upload it to the Supabase Storage
  /// bucket "books". Returns the public URL of the uploaded file.
  static Future<String> pickAndUploadPdf() async {
    _requireConfigured();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      throw Exception('No PDF was selected.');
    }
    final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    await client.storage.from('books').uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
    return client.storage.from('books').getPublicUrl(path);
  }

  // -------------------------------------------------------------- stats
  static Future<Map<String, int>> fetchStats() async {
    _requireConfigured();
    final stats = <String, int>{
      'books': 0,
      'readingBooks': 0,
      'faculties': 0,
      'departments': 0,
      'downloads': 0,
    };
    try {
      final books = await client.from('books').select('download_count');
      stats['books'] = (books as List).length;
      stats['downloads'] = (books as List).fold<int>(
        0,
        (sum, e) =>
            sum + ((e as Map)['download_count'] as num? ?? 0).toInt(),
      );
    } catch (_) {}
    try {
      final reading = await client.from('reading_books').select('id');
      stats['readingBooks'] = (reading as List).length;
    } catch (_) {}
    try {
      final faculties = await client.from('faculties').select('id');
      stats['faculties'] = (faculties as List).length;
    } catch (_) {}
    try {
      final departments = await client.from('departments').select('id');
      stats['departments'] = (departments as List).length;
    } catch (_) {}
    return stats;
  }

  // --------------------------------------------------------- audit log
  /// Change history. A failure here must never break the main action,
  /// so it is always swallowed.
  static Future<void> _audit(
    String action,
    String table,
    String? recordId,
  ) async {
    try {
      await client.from('audit_logs').insert({
        'admin_id': client.auth.currentUser?.id,
        'action': action,
        'table_name': table,
        'record_id': recordId,
      });
    } catch (_) {}
  }
}

/// Login / connection state for the Admin App.
class AdminState extends ChangeNotifier {
  bool get configured => SupabaseService.isConfigured;

  bool _signedIn = false;
  bool get signedIn => _signedIn;

  String? _error;
  String? get error => _error;

  bool _busy = false;
  bool get busy => _busy;

  AdminState() {
    try {
      _signedIn = SupabaseService.isConfigured &&
          SupabaseService.isSignedIn;
      if (SupabaseService.isConfigured) {
        SupabaseService.client.auth.onAuthStateChange.listen((event) {
          _signedIn = event.session != null;
          notifyListeners();
        });
      }
    } catch (_) {
      _signedIn = false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await SupabaseService.signIn(email, password);
      _signedIn = true;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseService.signOut();
    } catch (_) {}
    _signedIn = false;
    notifyListeners();
  }
}
