// Data models for the Helmand University Digital Library student app.
// These classes describe the bundled catalogue (see data/catalogue.dart).

class Faculty {
  final String id;
  final String namePs;
  final String nameEn;
  const Faculty({required this.id, required this.namePs, required this.nameEn});
}

class Department {
  final String id;
  final String facultyId;
  final String namePs;
  final String nameEn;
  /// Number of semesters. 0 means a service department with no own degree.
  final int semesters;
  final bool isService;
  /// True when at least one real eCampus book is mapped to this department.
  final bool hasBooks;
  const Department({required this.id, required this.facultyId, required this.namePs,
    required this.nameEn, required this.semesters, required this.isService, required this.hasBooks});
}

class Subject {
  final String name;
  final String code;
  final int credits;
  const Subject({required this.name, required this.code, required this.credits});
}

class LibraryBook {
  final String id;
  final String title;
  /// Pashto title, shown as the main title in the app.
  final String titlePs;
  final String author;
  final List<String> departmentIds;
  /// Which semesters of each department teach the subject this book
  /// covers: department id -> semester numbers. Empty when the book
  /// matches no named subject of that department; such books stay in
  /// the catalogue (and in search) but appear on no semester page.
  final Map<String, List<int>> semestersByDepartment;
  final String pdfUrl;
  /// True when the book is found through the eCampus PCB textbooks page
  /// rather than a direct PDF link.
  final bool viaPcbPage;
  const LibraryBook({required this.id, required this.title, required this.titlePs, required this.author,
    required this.departmentIds, required this.semestersByDepartment,
    required this.pdfUrl, required this.viaPcbPage});
}

class ReadingBook {
  final String id;
  final String title;
  /// Pashto title when the book's own title is English (e.g. Aesop).
  /// Null when the title itself is already Pashto.
  final String? titlePs;
  final String author;
  final String category;
  final String pdfUrl;
  const ReadingBook({required this.id, required this.title, this.titlePs,
    required this.author, required this.category, required this.pdfUrl});
}
