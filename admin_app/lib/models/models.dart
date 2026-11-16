// Small row models for the Supabase tables used by the Admin App.

class FacultyRow {
  final String id;
  final String namePs;
  final String nameEn;
  final bool isActive;

  const FacultyRow({
    required this.id,
    required this.namePs,
    required this.nameEn,
    this.isActive = true,
  });

  factory FacultyRow.fromMap(Map<String, dynamic> m) => FacultyRow(
        id: m['id'] as String,
        namePs: (m['name_ps'] as String?) ?? '',
        nameEn: (m['name_en'] as String?) ?? '',
        isActive: (m['is_active'] as bool?) ?? true,
      );
}

class DepartmentRow {
  final String id;
  final String facultyId;
  final String namePs;
  final String nameEn;
  final int semesters;
  final bool isActive;

  const DepartmentRow({
    required this.id,
    required this.facultyId,
    required this.namePs,
    required this.nameEn,
    this.semesters = 8,
    this.isActive = true,
  });

  factory DepartmentRow.fromMap(Map<String, dynamic> m) => DepartmentRow(
        id: m['id'] as String,
        facultyId: (m['faculty_id'] as String?) ?? '',
        namePs: (m['name_ps'] as String?) ?? '',
        nameEn: (m['name_en'] as String?) ?? '',
        semesters: (m['semesters'] as num?)?.toInt() ?? 8,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}

class SemesterRow {
  final String id;
  final String departmentId;
  final int semesterNumber;
  final String? academicYearId;

  const SemesterRow({
    required this.id,
    required this.departmentId,
    required this.semesterNumber,
    this.academicYearId,
  });

  factory SemesterRow.fromMap(Map<String, dynamic> m) => SemesterRow(
        id: m['id'] as String,
        departmentId: (m['department_id'] as String?) ?? '',
        semesterNumber: (m['semester_number'] as num?)?.toInt() ?? 0,
        academicYearId: m['academic_year_id'] as String?,
      );
}

class BookRow {
  final String id;
  final String title;
  final String subject;
  final String author;
  final String pdfUrl;
  final String? departmentId;
  final int? semesterNumber;
  final int downloadCount;
  final bool isArchived;

  const BookRow({
    required this.id,
    required this.title,
    required this.subject,
    required this.author,
    required this.pdfUrl,
    this.departmentId,
    this.semesterNumber,
    this.downloadCount = 0,
    this.isArchived = false,
  });

  factory BookRow.fromMap(Map<String, dynamic> m) => BookRow(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        subject: (m['subject'] as String?) ?? '',
        author: (m['author'] as String?) ?? '',
        pdfUrl: (m['pdf_url'] as String?) ?? '',
        departmentId: m['department_id'] as String?,
        semesterNumber: (m['semester_number'] as num?)?.toInt(),
        downloadCount: (m['download_count'] as num?)?.toInt() ?? 0,
        isArchived: (m['is_archived'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'subject': subject,
        'author': author,
        'pdf_url': pdfUrl,
        'department_id': departmentId,
        'semester_number': semesterNumber,
        'is_archived': isArchived,
      };
}

class ReadingBookRow {
  final String id;
  final String title;
  final String author;
  final String category;
  final String pdfUrl;
  final bool hasPermission;
  final bool isArchived;

  const ReadingBookRow({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
    this.hasPermission = false,
    this.isArchived = false,
  });

  factory ReadingBookRow.fromMap(Map<String, dynamic> m) => ReadingBookRow(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        author: (m['author'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        pdfUrl: (m['pdf_url'] as String?) ?? '',
        hasPermission: (m['has_permission'] as bool?) ?? false,
        isArchived: (m['is_archived'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'author': author,
        'category': category,
        'pdf_url': pdfUrl,
        'has_permission': hasPermission,
        'is_archived': isArchived,
      };
}
