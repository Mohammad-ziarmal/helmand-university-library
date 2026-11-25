// Supabase-first catalogue sync for the student app (Phase 3).
//
// On app open the app uses the cached remote catalogue immediately
// (if there is one), then refreshes in the background. A manual
// refresh is offered in Settings. The bundled catalogue
// (data/catalogue.dart) is the last resort and always stays in the
// binary.
//
// HARD RULE (DESIGN §5.2): the Supabase data is used ONLY when the
// fetch succeeds AND the result holds faculties, departments,
// subjects AND books. Offline, a failed fetch, a missing table (the
// migration has not run yet), or an EMPTY result (tables not seeded
// yet) all return null here — and null means "keep the catalogue you
// already have". An empty Supabase result must NEVER wipe the library.
//
// Supabase is already initialised in main.dart (optional, try/catch);
// this file reuses that client and adds no secret or key.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/catalogue_data.dart';

class CatalogueSync {
  CatalogueSync._();

  static const _cacheKey = 'remote_catalogue_v1';
  static const _cacheTimeKey = 'remote_catalogue_updated_at';

  /// True when Supabase was initialised in main.dart. False when the
  /// app runs without SUPABASE_URL / SUPABASE_ANON_KEY (offline
  /// build) — the app then simply keeps the bundled catalogue.
  static bool get isAvailable {
    try {
      // Throws when Supabase was never initialised.
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The last good remote catalogue saved on the phone, or null when
  /// there is no cache, it is corrupt, or it is unusable (empty).
  static Future<CatalogueData?> loadCached(SharedPreferences prefs) async {
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = CatalogueData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      return data.isUsable ? data : null;
    } catch (_) {
      // Corrupt cache: ignore it, the bundled catalogue is used.
      return null;
    }
  }

  /// When the cached catalogue was saved, if there is one.
  static DateTime? cachedAt(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheTimeKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// Fetch the whole catalogue from Supabase and rebuild the
  /// in-memory model. Returns null on ANY failure — no network,
  /// Supabase not configured, a table missing, or an empty result.
  static Future<CatalogueData?> fetchRemote() async {
    if (!isAvailable) return null;
    try {
      final client = Supabase.instance.client;
      // PostgREST caps a response at 1,000 rows unless a limit is set;
      // subjects alone are 1,230 rows, so every query asks for more.
      final facultyRows = await client
          .from('faculties')
          .select()
          .order('sort_order', ascending: true)
          .limit(5000);
      final departmentRows = await client
          .from('departments')
          .select()
          .order('sort_order', ascending: true)
          .limit(5000);
      final subjectRows = await client
          .from('subjects')
          .select()
          .order('semester_number', ascending: true)
          .order('sort_order', ascending: true)
          .limit(5000);
      final bookRows = await client
          .from('books')
          .select()
          .order('created_at', ascending: true)
          .limit(5000);
      final bookSubjectRows = await client
          .from('book_subjects')
          .select()
          .limit(5000);
      final placementRows = await client
          .from('book_placements')
          .select()
          .limit(5000);
      final readingRows = await client
          .from('reading_books')
          .select()
          .order('created_at', ascending: true)
          .limit(5000);
      final data = CatalogueData.fromRemote(
        facultyRows: _rows(facultyRows),
        departmentRows: _rows(departmentRows),
        subjectRows: _rows(subjectRows),
        bookRows: _rows(bookRows),
        bookSubjectRows: _rows(bookSubjectRows),
        placementRows: _rows(placementRows),
        readingRows: _rows(readingRows),
      );
      // Empty (or half-empty) result: keep the current catalogue.
      return data.isUsable ? data : null;
    } catch (_) {
      // No network, table missing, RLS misconfigured, anything else:
      // the app keeps working from the catalogue it already has.
      return null;
    }
  }

  /// Fetch, and on success save the cache. Returns the new catalogue,
  /// or null when the fetch failed or was empty (cache untouched).
  static Future<CatalogueData?> refresh(SharedPreferences prefs) async {
    final data = await fetchRemote();
    if (data == null) return null;
    try {
      await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
      await prefs.setString(
        _cacheTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // A cache write failure must not lose the fresh catalogue.
    }
    return data;
  }

  static List<Map<String, dynamic>> _rows(dynamic result) =>
      (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
}
