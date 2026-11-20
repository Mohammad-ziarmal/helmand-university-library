// Downloaded books: save a book PDF on the phone so the student can
// read it again without internet, and remember where it was saved.
//
// Only real PDF links are downloaded. Books that point at a web page
// (viaPcbPage) are NOT downloaded here — they still open online.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedBooks {
  static const String _key = 'downloaded_books_json';

  static Future<Map<String, String>> _loadMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> _saveMap(Map<String, String> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  /// Local file path of a downloaded book, or null when it was never
  /// downloaded (or the file was deleted from the phone).
  static Future<String?> localPath(String bookId) async {
    final map = await _loadMap();
    final path = map[bookId];
    if (path == null) return null;
    if (!await File(path).exists()) return null;
    return path;
  }

  static Future<bool> isDownloaded(String bookId) async =>
      await localPath(bookId) != null;

  /// Download the PDF to the phone and remember its path.
  /// Returns the local path on success, null on failure.
  static Future<String?> download(String bookId, String pdfUrl) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloads = Directory('${dir.path}/downloads');
      if (!await downloads.exists()) {
        await downloads.create(recursive: true);
      }
      final safeId = bookId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${downloads.path}/$safeId.pdf');
      if (await file.exists()) {
        final map = await _loadMap();
        map[bookId] = file.path;
        await _saveMap(map);
        return file.path;
      }
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(pdfUrl));
        final response = await request.close();
        if (response.statusCode != 200) return null;
        final sink = file.openWrite();
        await sink.addStream(response);
        await sink.close();
      } finally {
        client.close();
      }
      if (!await file.exists()) return null;
      if (await file.length() < 1024) {
        // Too small to be a real book PDF — do not keep it.
        await file.delete();
        return null;
      }
      final map = await _loadMap();
      map[bookId] = file.path;
      await _saveMap(map);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
