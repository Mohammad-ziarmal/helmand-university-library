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

  /// Stable app id (e.g. 'bio'), the join key the student app uses
  /// (DESIGN §2). Set at creation, never edited afterwards. Empty for
  /// rows created before the Phase 1 migration added the column.
  final String code;
  final int semesters;
  final bool isActive;

  const DepartmentRow({
    required this.id,
    required this.facultyId,
    required this.namePs,
    required this.nameEn,
    this.code = '',
    this.semesters = 8,
    this.isActive = true,
  });

  factory DepartmentRow.fromMap(Map<String, dynamic> m) => DepartmentRow(
        id: m['id'] as String,
        facultyId: (m['faculty_id'] as String?) ?? '',
        namePs: (m['name_ps'] as String?) ?? '',
        nameEn: (m['name_en'] as String?) ?? '',
        code: (m['code'] as String?) ?? '',
        semesters: (m['semesters'] as num?)?.toInt() ?? 8,
        isActive: (m['is_active'] as bool?) ?? true,
      );
}

/// One row of the `subjects` table (Phase 1 migration, DESIGN §1).
/// A subject belongs to one department + semester; books link to it
/// by id through `book_subjects`, so renaming it never orphans a book.
class SubjectRow {
  final String id;
  final String departmentId;
  final int semesterNumber;
  final String name;
  final String code;
  final int credits;
  final int sortOrder;
  final bool isActive;

  const SubjectRow({
    this.id = '',
    required this.departmentId,
    required this.semesterNumber,
    required this.name,
    this.code = '',
    this.credits = 0,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory SubjectRow.fromMap(Map<String, dynamic> m) => SubjectRow(
        id: m['id'] as String? ?? '',
        departmentId: (m['department_id'] as String?) ?? '',
        semesterNumber: (m['semester_number'] as num?)?.toInt() ?? 0,
        name: (m['name'] as String?) ?? '',
        code: (m['code'] as String?) ?? '',
        credits: (m['credits'] as num?)?.toInt() ?? 0,
        sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
        isActive: (m['is_active'] as bool?) ?? true,
      );

  /// For insert / update. The id is never sent (the database
  /// generates the uuid); is_active is sent so archive/restore works.
  Map<String, dynamic> toMap() => {
        'department_id': departmentId,
        'semester_number': semesterNumber,
        'name': name,
        'code': code,
        'credits': credits,
        'sort_order': sortOrder,
        'is_active': isActive,
      };

  SubjectRow copyWith({
    int? semesterNumber,
    String? name,
    String? code,
    int? credits,
    int? sortOrder,
    bool? isActive,
  }) =>
      SubjectRow(
        id: id,
        departmentId: departmentId,
        semesterNumber: semesterNumber ?? this.semesterNumber,
        name: name ?? this.name,
        code: code ?? this.code,
        credits: credits ?? this.credits,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
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

  /// Stable app id ('b1'…'b287', DESIGN §3.4) — the key the student
  /// app maps the row back to. Null for rows from before the Phase 1
  /// migration; auto-generated on insert when missing.
  final String? appId;

  /// Pashto title, shown first in the student app (DESIGN §3.3).
  final String? titlePs;

  /// Publication year (DESIGN §3.3). Null = unknown; never guessed.
  final int? year;

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
    this.appId,
    this.titlePs,
    this.year,
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
        appId: m['app_id'] as String?,
        titlePs: m['title_ps'] as String?,
        year: (m['year'] as num?)?.toInt(),
      );

  /// app_id / title_ps / year are sent ONLY when set: before the
  /// Phase 1 migration those columns do not exist yet, and sending
  /// them would break every book insert/update. Omitting a null also
  /// means an edit never clears a value it did not load.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'subject': subject,
      'author': author,
      'pdf_url': pdfUrl,
      'department_id': departmentId,
      'semester_number': semesterNumber,
      'is_archived': isArchived,
    };
    if (appId != null) map['app_id'] = appId;
    if (titlePs != null) map['title_ps'] = titlePs;
    if (year != null) map['year'] = year;
    return map;
  }

  BookRow copyWith({String? appId, String? titlePs, int? year}) => BookRow(
        id: id,
        title: title,
        subject: subject,
        author: author,
        pdfUrl: pdfUrl,
        departmentId: departmentId,
        semesterNumber: semesterNumber,
        downloadCount: downloadCount,
        isArchived: isArchived,
        appId: appId ?? this.appId,
        titlePs: titlePs ?? this.titlePs,
        year: year ?? this.year,
      );
}

class ReadingBookRow {
  final String id;
  final String title;
  final String author;
  final String category;
  final String pdfUrl;
  final bool hasPermission;
  final bool isArchived;

  /// Stable app id ('r1'…'r56', DESIGN §3.4) and Pashto title /
  /// publication year (DESIGN §3.3). Same null rules as BookRow.
  final String? appId;
  final String? titlePs;
  final int? year;

  const ReadingBookRow({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.pdfUrl,
    this.hasPermission = false,
    this.isArchived = false,
    this.appId,
    this.titlePs,
    this.year,
  });

  factory ReadingBookRow.fromMap(Map<String, dynamic> m) => ReadingBookRow(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        author: (m['author'] as String?) ?? '',
        category: (m['category'] as String?) ?? '',
        pdfUrl: (m['pdf_url'] as String?) ?? '',
        hasPermission: (m['has_permission'] as bool?) ?? false,
        isArchived: (m['is_archived'] as bool?) ?? false,
        appId: m['app_id'] as String?,
        titlePs: m['title_ps'] as String?,
        year: (m['year'] as num?)?.toInt(),
      );

  /// app_id / title_ps / year are sent ONLY when set (see BookRow).
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'author': author,
      'category': category,
      'pdf_url': pdfUrl,
      'has_permission': hasPermission,
      'is_archived': isArchived,
    };
    if (appId != null) map['app_id'] = appId;
    if (titlePs != null) map['title_ps'] = titlePs;
    if (year != null) map['year'] = year;
    return map;
  }

  ReadingBookRow copyWith({String? appId, String? titlePs, int? year}) =>
      ReadingBookRow(
        id: id,
        title: title,
        author: author,
        category: category,
        pdfUrl: pdfUrl,
        hasPermission: hasPermission,
        isArchived: isArchived,
        appId: appId ?? this.appId,
        titlePs: titlePs ?? this.titlePs,
        year: year ?? this.year,
      );
}
