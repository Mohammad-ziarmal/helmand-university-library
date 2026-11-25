// Small read-only helpers over the CURRENT catalogue.
//
// The student app works fully offline from the bundled catalogue
// (data/catalogue.dart). When the Admin App has published the catalogue
// to Supabase, the sync (services/catalogue_sync.dart) swaps the
// current catalogue for the remote one. Every screen reads through
// the getters and functions below, so a sync updates the whole app
// without touching the screens — and a failed or empty sync leaves
// the bundled catalogue exactly as it was.
//
// The top-level getters keep the old names (faculties, departments,
// libraryBooks, readingBooks) so existing screens keep working.

import '../models/book.dart';
import 'catalogue_data.dart';

export '../models/book.dart';

/// The catalogue every screen reads. Starts as the bundled catalogue;
/// [setCatalogue] replaces it after a successful Supabase sync (or a
/// cache load). Only [AppState] calls [setCatalogue], and it calls
/// notifyListeners right after so the screens rebuild.
CatalogueData _current = CatalogueData.bundled();

CatalogueData get currentCatalogue => _current;

void setCatalogue(CatalogueData data) {
  _current = data;
}

List<Faculty> get faculties => _current.faculties;
List<Department> get departments => _current.departments;
List<LibraryBook> get libraryBooks => _current.libraryBooks;
List<ReadingBook> get readingBooks => _current.readingBooks;
Map<String, Map<int, List<Subject>>> get subjectsByDepartment =>
    _current.subjectsByDepartment;
Map<String, List<String>> get subjectBooks => _current.subjectBooks;

/// Only the book(s) that cover exactly this subject — from the
/// subject→books map (bundled subject_books.dart, or the remote
/// book_subjects join table after a sync). A subject with no entry
/// has no book yet; the app shows the 'upload soon' message.
List<LibraryBook> booksOfSubject(
        String departmentId, int semester, String subjectName) {
  final ids =
      subjectBooks['$departmentId|$semester|$subjectName'] ?? const <String>[];
  final byId = {for (final b in libraryBooks) b.id: b};
  return [for (final id in ids) if (byId[id] != null) byId[id]!];
}

List<Department> departmentsOfFaculty(String facultyId) =>
    departments.where((d) => d.facultyId == facultyId).toList();

Department departmentById(String id) =>
    departments.firstWhere((d) => d.id == id);

Faculty facultyById(String id) => faculties.firstWhere((f) => f.id == id);

/// All real books mapped to one department.
List<LibraryBook> booksOfDepartment(String departmentId) => libraryBooks
    .where((b) => b.departmentIds.contains(departmentId))
    .toList();

/// Only the books of one semester: the books whose subject is taught
/// in that semester of that department. Books that match no named
/// subject have an empty map and appear on no semester page.
List<LibraryBook> booksOfSemester(String departmentId, int semester) =>
    libraryBooks
    .where((b) =>
        (b.semestersByDepartment[departmentId] ?? const <int>[])
            .contains(semester))
    .toList();

/// Subjects of one semester. For the Islamic Culture service department
/// pass semester 0 to get its general subjects.
List<Subject> subjectsOf(String departmentId, int semester) =>
    subjectsByDepartment[departmentId]?[semester] ?? const <Subject>[];

/// All subjects of a department across its semesters (used by search).
List<Subject> allSubjectsOf(String departmentId) {
  final map = subjectsByDepartment[departmentId];
  if (map == null) return const <Subject>[];
  return map.values.expand((list) => list).toList();
}

/// Simple search across book titles, authors and subject names.
List<LibraryBook> searchBooks(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const <LibraryBook>[];
  return libraryBooks
      .where((b) =>
          b.title.toLowerCase().contains(q) ||
          b.titlePs.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q))
      .toList();
}
