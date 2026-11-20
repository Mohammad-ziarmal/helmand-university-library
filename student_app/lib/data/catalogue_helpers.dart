// Small read-only helpers over the bundled catalogue.
// The student app works fully offline from this data; Supabase is only
// needed later for live updates from the Admin App.

import '../data/catalogue.dart';
import '../data/subject_books.dart';

/// Only the book(s) that cover exactly this subject — matched by name
/// against the book title (see subject_books.dart). A subject with no
/// entry has no book yet; the app shows the 'upload soon' message.
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
          b.author.toLowerCase().contains(q))
      .toList();
}
