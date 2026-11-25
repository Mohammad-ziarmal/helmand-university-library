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

/// Thrown when the `subjects` table does not exist yet — the Phase 1
/// migration has not been run in Supabase. The Subjects screen shows a
/// "not set up yet" state for this instead of crashing.
class SubjectsNotReadyError implements Exception {
  const SubjectsNotReadyError();
  @override
  String toString() =>
      'Subjects are not set up yet (run the Supabase migration first).';
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
    int semesters, {
    required String code,
  }) async {
    _requireConfigured();
    // The code is the join key the student app uses (DESIGN §2), so it
    // is required and must be lowercase letters, digits and dashes.
    final clean = code.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(clean)) {
      throw ArgumentError(
        'Department code must use only a-z, 0-9 and - (e.g. bio).',
      );
    }
    // Friendly duplicate check; the database unique index enforces it
    // too. If the code column does not exist yet (migration not run),
    // this check fails and is ignored — the insert below then reports
    // the missing column.
    try {
      final existing = await client
          .from('departments')
          .select('id')
          .eq('code', clean)
          .limit(1);
      if ((existing as List).isNotEmpty) {
        throw ArgumentError(
          'A department with code "$clean" already exists.',
        );
      }
    } on ArgumentError {
      rethrow;
    } catch (_) {}
    final inserted = await client.from('departments').insert({
      'faculty_id': facultyId,
      'name_ps': namePs,
      'name_en': nameEn,
      'semesters': semesters,
      'code': clean,
    }).select('id');
    await _audit('insert', 'departments',
        (inserted as List).first['id'] as String?);
  }

  /// Update a department's names / semester count. The `code` is NEVER
  /// updated here: it is the join key the student app uses, so changing
  /// it after subjects/books exist would orphan them (DESIGN §2).
  static Future<void> updateDepartment(DepartmentRow dept) async {
    _requireConfigured();
    await client.from('departments').update({
      'name_ps': dept.namePs,
      'name_en': dept.nameEn,
      'semesters': dept.semesters,
    }).eq('id', dept.id);
    await _audit('update', 'departments', dept.id);
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

  // ------------------------------------------------------------ subjects
  /// True when the error means the table does not exist yet (Postgres
  /// 42P01: the Phase 1 migration has not been run).
  static bool _isMissingTable(Object e) =>
      e is PostgrestException &&
      (e.code == '42P01' ||
          e.message.contains('does not exist') ||
          e.message.contains('Could not find the table'));

  /// Subjects of one department, optionally one semester. Active
  /// subjects first, then by semester and catalog order. Admins see
  /// inactive (archived) rows too — the public student policy hides
  /// them, the admin policy does not.
  /// Throws [SubjectsNotReadyError] when the migration has not run.
  static Future<List<SubjectRow>> fetchSubjects(
    String departmentId, {
    int? semester,
  }) async {
    _requireConfigured();
    try {
      var query = client
          .from('subjects')
          .select()
          .eq('department_id', departmentId);
      if (semester != null) {
        query = query.eq('semester_number', semester);
      }
      final rows = await query
          .order('is_active', ascending: false)
          .order('semester_number', ascending: true)
          .order('sort_order', ascending: true);
      return (rows as List)
          .map((e) => SubjectRow.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingTable(e)) throw const SubjectsNotReadyError();
      rethrow;
    }
  }

  static Future<void> addSubject(SubjectRow subject) async {
    _requireConfigured();
    try {
      final inserted = await client
          .from('subjects')
          .insert(subject.toMap())
          .select('id');
      await _audit('insert', 'subjects',
          (inserted as List).first['id'] as String?);
    } on PostgrestException catch (e) {
      if (_isMissingTable(e)) throw const SubjectsNotReadyError();
      rethrow;
    }
  }

  static Future<void> updateSubject(SubjectRow subject) async {
    _requireConfigured();
    await client
        .from('subjects')
        .update(subject.toMap())
        .eq('id', subject.id);
    await _audit('update', 'subjects', subject.id);
  }

  /// Archive, not hard delete (DESIGN §6): when books are linked to
  /// this subject, the subject is only hidden (is_active = false) so
  /// the books' subject pages keep working. Hard delete happens only
  /// when nothing links to it. Returns true when the subject was
  /// archived, false when it was deleted outright.
  static Future<bool> deleteSubject(String id) async {
    _requireConfigured();
    final links = await client
        .from('book_subjects')
        .select('subject_id')
        .eq('subject_id', id)
        .limit(1);
    if ((links as List).isNotEmpty) {
      await client
          .from('subjects')
          .update({'is_active': false})
          .eq('id', id);
      await _audit('update', 'subjects', id);
      return true;
    }
    await client.from('subjects').delete().eq('id', id);
    await _audit('delete', 'subjects', id);
    return false;
  }

  // -------------------------------------------------------- book links
  /// Subject ids linked to one book (the authoritative subject links,
  /// DESIGN §3.2 — never match books to subjects by name).
  static Future<List<String>> fetchBookSubjects(String bookId) async {
    _requireConfigured();
    final rows = await client
        .from('book_subjects')
        .select('subject_id')
        .eq('book_id', bookId);
    return (rows as List)
        .map((e) => (e as Map)['subject_id'] as String)
        .toList();
  }

  static Future<void> linkBookToSubject(
    String bookId,
    String subjectId,
  ) async {
    _requireConfigured();
    try {
      await client.from('book_subjects').insert({
        'book_id': bookId,
        'subject_id': subjectId,
      });
    } on PostgrestException catch (e) {
      // 23505 = already linked: treat as success.
      if (e.code != '23505') rethrow;
    }
    await _audit('insert', 'book_subjects', subjectId);
  }

  static Future<void> unlinkBookFromSubject(
    String bookId,
    String subjectId,
  ) async {
    _requireConfigured();
    await client
        .from('book_subjects')
        .delete()
        .eq('book_id', bookId)
        .eq('subject_id', subjectId);
    await _audit('delete', 'book_subjects', subjectId);
  }

  /// A book's departments + semesters, as (departmentId, semester)
  /// pairs. Semester 0 means "this department, no semester".
  static Future<List<({String departmentId, int semesterNumber})>>
      fetchBookPlacements(String bookId) async {
    _requireConfigured();
    final rows = await client
        .from('book_placements')
        .select('department_id, semester_number')
        .eq('book_id', bookId);
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return (
        departmentId: (m['department_id'] as String?) ?? '',
        semesterNumber: (m['semester_number'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  /// Replace a book's `book_placements` rows (delete + insert in one
  /// admin action). An empty list clears all placements.
  static Future<void> setBookPlacements(
    String bookId,
    List<({String departmentId, int semesterNumber})> placements,
  ) async {
    _requireConfigured();
    await client.from('book_placements').delete().eq('book_id', bookId);
    if (placements.isNotEmpty) {
      await client.from('book_placements').insert([
        for (final p in placements)
          {
            'book_id': bookId,
            'department_id': p.departmentId,
            'semester_number': p.semesterNumber,
          },
      ]);
    }
    await _audit('update', 'book_placements', bookId);
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
    // New books need a stable app id (DESIGN §3.4) so the student app
    // can map the row back to a bundled id. Generated when missing.
    final toInsert = book.appId == null || book.appId!.isEmpty
        ? book.copyWith(appId: 'b${DateTime.now().millisecondsSinceEpoch}')
        : book;
    final inserted = await client
        .from('books')
        .insert(toInsert.toMap())
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
    final toInsert = book.appId == null || book.appId!.isEmpty
        ? book.copyWith(appId: 'r${DateTime.now().millisecondsSinceEpoch}')
        : book;
    final inserted = await client
        .from('reading_books')
        .insert(toInsert.toMap())
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
    // file_picker 12: static API, no FilePicker.platform; pickFile()
    // returns one PlatformFile, and bytes are read on demand.
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) {
      throw Exception('No PDF was selected.');
    }
    final bytes = await file.readAsBytes();
    if (bytes == null) {
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

  // ------------------------------------------------------------ students
  /// Students who registered in the student app, newest first.
  static Future<List<Map<String, dynamic>>> fetchStudents() async {
    _requireConfigured();
    final rows = await client
        .from('students')
        .select('id, full_name, email, faculty_id, department_id, created_at')
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// All departments (for mapping a student's department id to a name).
  static Future<List<DepartmentRow>> fetchAllDepartments() async {
    _requireConfigured();
    final rows = await client
        .from('departments')
        .select()
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((e) => DepartmentRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> deleteStudent(String id) async {
    _requireConfigured();
    await client.from('students').delete().eq('id', id);
    await _audit('delete', 'students', id);
  }

  // -------------------------------------------------------------- stats
  static Future<Map<String, int>> fetchStats() async {
    _requireConfigured();
    final stats = <String, int>{
      'books': 0,
      'readingBooks': 0,
      'faculties': 0,
      'departments': 0,
      'subjects': 0,
      'downloads': 0,
      'students': 0,
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
    try {
      // 0 until the Phase 1 migration creates the subjects table.
      final subjects = await client.from('subjects').select('id');
      stats['subjects'] = (subjects as List).length;
    } catch (_) {}
    try {
      final students = await client.from('students').select('id');
      stats['students'] = (students as List).length;
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

  /// One audit entry for a whole catalogue seed (Build 38). The
  /// record id carries "inserted N, verified true/false".
  static Future<void> logSeed({
    required int inserted,
    required bool verified,
  }) async {
    await _audit(
      'seed',
      'catalogue',
      'inserted $inserted, verified $verified',
    );
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
