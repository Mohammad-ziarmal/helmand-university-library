// Runtime catalogue for the student app.
//
// The app ships with a bundled catalogue (data/catalogue.dart) that
// works fully offline. When the Admin App has published the catalogue
// to Supabase (Phase 1 migration + seeds), the student app fetches it
// (see services/catalogue_sync.dart) and rebuilds the SAME in-memory
// model from the remote rows. CatalogueData is that model: the helpers
// in catalogue_helpers.dart always read the current instance, so every
// screen shows the remote catalogue once it arrives and the bundled
// one before that (or whenever the fetch fails or comes back empty).
//
// The JSON form is what is cached in SharedPreferences, so a cached
// remote catalogue survives an offline restart.

import '../models/book.dart';
import 'catalogue.dart' as bundled;
import 'subject_books.dart' as bundled_map;

class CatalogueData {
  final List<Faculty> faculties;
  final List<Department> departments;
  final Map<String, Map<int, List<Subject>>> subjectsByDepartment;
  final List<LibraryBook> libraryBooks;
  final Map<String, List<String>> subjectBooks;
  final List<ReadingBook> readingBooks;

  /// True when this catalogue came from Supabase (live fetch or the
  /// cache of one). False for the bundled catalogue in the app binary.
  final bool isRemote;

  const CatalogueData({
    required this.faculties,
    required this.departments,
    required this.subjectsByDepartment,
    required this.libraryBooks,
    required this.subjectBooks,
    required this.readingBooks,
    this.isRemote = false,
  });

  int get totalSubjects => subjectsByDepartment.values.fold(
        0,
        (n, bySemester) =>
            n + bySemester.values.fold(0, (a, list) => a + list.length),
      );

  /// The acceptance rule (DESIGN §5.2): a remote catalogue is only
  /// usable when it actually holds faculties, departments, subjects
  /// AND books. Anything less is treated exactly like a failed fetch
  /// — the app keeps the catalogue it already has. An empty Supabase
  /// result must NEVER wipe the library.
  bool get isUsable =>
      faculties.isNotEmpty &&
      departments.isNotEmpty &&
      totalSubjects > 0 &&
      libraryBooks.isNotEmpty;

  /// The bundled catalogue shipped in the app binary. Always
  /// available, even with no internet and no Supabase configured.
  factory CatalogueData.bundled() => CatalogueData(
        faculties: bundled.faculties,
        departments: bundled.departments,
        subjectsByDepartment: bundled.subjectsByDepartment,
        libraryBooks: bundled.libraryBooks,
        subjectBooks: bundled_map.subjectBooks,
        readingBooks: bundled.readingBooks,
        isRemote: false,
      );

  // ------------------------------------------------------------ remote
  /// Rebuild the catalogue from Supabase rows (DESIGN §5.4).
  ///
  /// Departments are addressed by their `code` (the app id, e.g.
  /// 'bio'); rows with a NULL/empty code are skipped because the app
  /// cannot address them. Faculties have no `code` column (DESIGN §2),
  /// so a remote faculty is matched to the bundled faculty with the
  /// same English name and keeps that bundled id ('agri', 'edu', …);
  /// a faculty with no bundled match (added later by an admin) keeps
  /// its uuid as its id so it still shows. Subjects are grouped by
  /// (department code, semester) in `sort_order`; books come from the
  /// `book_subjects` join table (subject links) and the
  /// `book_placements` table (departments + semesters per book).
  factory CatalogueData.fromRemote({
    required List<Map<String, dynamic>> facultyRows,
    required List<Map<String, dynamic>> departmentRows,
    required List<Map<String, dynamic>> subjectRows,
    required List<Map<String, dynamic>> bookRows,
    required List<Map<String, dynamic>> bookSubjectRows,
    required List<Map<String, dynamic>> placementRows,
    required List<Map<String, dynamic>> readingRows,
  }) {
    // --- faculties ---------------------------------------------------
    final facultyIdByUuid = <String, String>{};
    final faculties = <Faculty>[];
    for (final row in facultyRows) {
      final uuid = row['id'] as String?;
      if (uuid == null || uuid.isEmpty) continue;
      if (row['is_active'] == false) continue;
      final namePs = (row['name_ps'] as String?) ?? '';
      final nameEn = (row['name_en'] as String?) ?? '';
      if (namePs.isEmpty && nameEn.isEmpty) continue;
      // Match by English name so the app keeps its stable faculty ids.
      String? bundledId;
      for (final f in bundled.faculties) {
        if (f.nameEn == nameEn) {
          bundledId = f.id;
          break;
        }
      }
      final id = bundledId ?? uuid;
      if (facultyIdByUuid.containsValue(id)) continue;
      facultyIdByUuid[uuid] = id;
      faculties.add(Faculty(id: id, namePs: namePs, nameEn: nameEn));
    }

    // --- departments (first pass: keep usable rows) ------------------
    final deptCodeByUuid = <String, String>{};
    final keptDeptRows = <Map<String, dynamic>>[];
    for (final row in departmentRows) {
      final uuid = row['id'] as String?;
      final code = (row['code'] as String?)?.trim() ?? '';
      if (uuid == null || uuid.isEmpty || code.isEmpty) continue;
      if (row['is_active'] == false) continue;
      final facultyUuid = row['faculty_id'] as String?;
      final facultyId =
          facultyUuid == null ? null : facultyIdByUuid[facultyUuid];
      if (facultyId == null) continue;
      if (deptCodeByUuid.containsValue(code)) continue;
      deptCodeByUuid[uuid] = code;
      keptDeptRows.add(row);
    }

    // --- subjects ----------------------------------------------------
    final subjectKeyById = <String, String>{};
    final subjectsByDepartment = <String, Map<int, List<Subject>>>{};
    for (final row in subjectRows) {
      final id = row['id'] as String?;
      final deptUuid = row['department_id'] as String?;
      if (id == null || deptUuid == null) continue;
      final deptCode = deptCodeByUuid[deptUuid];
      if (deptCode == null) continue;
      if (row['is_active'] == false) continue;
      final semester = (row['semester_number'] as num?)?.toInt() ?? 0;
      final name = (row['name'] as String?) ?? '';
      if (name.isEmpty) continue;
      final code = (row['code'] as String?) ?? '';
      final credits = (row['credits'] as num?)?.toInt() ?? 0;
      subjectKeyById[id] = '$deptCode|$semester|$name';
      (subjectsByDepartment[deptCode] ??= {})[semester] ??= [];
      subjectsByDepartment[deptCode]![semester]!
          .add(Subject(name: name, code: code, credits: credits));
    }

    // --- books (first pass: keep usable rows) ------------------------
    final bookIdByUuid = <String, String>{};
    final keptBookRows = <Map<String, dynamic>>[];
    for (final row in bookRows) {
      final uuid = row['id'] as String?;
      if (uuid == null || uuid.isEmpty) continue;
      if (row['is_archived'] == true) continue;
      final title = (row['title'] as String?) ?? '';
      if (title.isEmpty) continue;
      final appId = (row['app_id'] as String?)?.trim() ?? '';
      final id = appId.isNotEmpty ? appId : uuid;
      if (bookIdByUuid.containsValue(id)) continue;
      bookIdByUuid[uuid] = id;
      keptBookRows.add(row);
    }

    // --- placements: department ids + semesters per book -------------
    // book uuid -> department code -> semester numbers. A row with
    // semester 0 means "this department, no semester" (DESIGN §3.2).
    final placements = <String, Map<String, Set<int>>>{};
    void addPlacement(String bookUuid, String deptUuid, int semester) {
      final deptCode = deptCodeByUuid[deptUuid];
      if (deptCode == null) return;
      final byDept = placements[bookUuid] ??= {};
      if (semester == 0) {
        byDept[deptCode] ??= <int>{};
      } else {
        (byDept[deptCode] ??= <int>{}).add(semester);
      }
    }

    for (final row in placementRows) {
      final bookUuid = row['book_id'] as String?;
      final deptUuid = row['department_id'] as String?;
      if (bookUuid == null || deptUuid == null) continue;
      if (!bookIdByUuid.containsKey(bookUuid)) continue;
      addPlacement(
        bookUuid,
        deptUuid,
        (row['semester_number'] as num?)?.toInt() ?? 0,
      );
    }
    // The book row's own primary placement (DESIGN §3.2: display-only
    // there, but it is the only placement an admin-added book may
    // have, so merge it in rather than dropping the book from its
    // department page).
    for (final row in keptBookRows) {
      final bookUuid = row['id'] as String;
      final deptUuid = row['department_id'] as String?;
      if (deptUuid == null) continue;
      addPlacement(
        bookUuid,
        deptUuid,
        (row['semester_number'] as num?)?.toInt() ?? 0,
      );
    }

    // --- subject links ------------------------------------------------
    final subjectBooks = <String, List<String>>{};
    for (final row in bookSubjectRows) {
      final bookUuid = row['book_id'] as String?;
      final subjectUuid = row['subject_id'] as String?;
      if (bookUuid == null || subjectUuid == null) continue;
      final bookId = bookIdByUuid[bookUuid];
      final key = subjectKeyById[subjectUuid];
      if (bookId == null || key == null) continue;
      final ids = subjectBooks[key] ??= <String>[];
      if (!ids.contains(bookId)) ids.add(bookId);
    }

    // --- books ---------------------------------------------------------
    final deptCodesWithBooks = <String>{};
    final libraryBooks = <LibraryBook>[];
    for (final row in keptBookRows) {
      final uuid = row['id'] as String;
      final id = bookIdByUuid[uuid]!;
      final title = (row['title'] as String?) ?? '';
      final titlePsRaw = (row['title_ps'] as String?)?.trim() ?? '';
      final pdfUrl = (row['pdf_url'] as String?) ?? '';
      final byDept = placements[uuid] ?? const <String, Set<int>>{};
      final departmentIds = byDept.keys.toList();
      deptCodesWithBooks.addAll(departmentIds);
      final semestersByDepartment = <String, List<int>>{};
      for (final entry in byDept.entries) {
        if (entry.value.isNotEmpty) {
          final semesters = entry.value.toList()..sort();
          semestersByDepartment[entry.key] = semesters;
        }
      }
      libraryBooks.add(
        LibraryBook(
          id: id,
          title: title,
          // Pashto title first, exactly as the bundled app shows it;
          // fall back to the English title when none was entered.
          titlePs: titlePsRaw.isNotEmpty ? titlePsRaw : title,
          author: (row['author'] as String?) ?? '',
          departmentIds: departmentIds,
          semestersByDepartment: semestersByDepartment,
          pdfUrl: pdfUrl,
          // The books table has no via_pcb_page column (DESIGN does not
          // define one). All 227 seeded books point at real PDFs, so a
          // link that is NOT a PDF is a web (PCB) page, as before.
          viaPcbPage: !_looksLikePdf(pdfUrl),
        ),
      );
    }

    // --- departments (second pass: hasBooks is known now) ------------
    final departments = <Department>[];
    for (final row in keptDeptRows) {
      final uuid = row['id'] as String;
      final code = deptCodeByUuid[uuid]!;
      final facultyId = facultyIdByUuid[row['faculty_id'] as String]!;
      final semesters = (row['semesters'] as num?)?.toInt() ?? 8;
      departments.add(
        Department(
          id: code,
          facultyId: facultyId,
          namePs: (row['name_ps'] as String?) ?? '',
          nameEn: (row['name_en'] as String?) ?? '',
          semesters: semesters,
          isService: semesters == 0,
          hasBooks: deptCodesWithBooks.contains(code),
        ),
      );
    }

    // --- reading books -------------------------------------------------
    final readingBooks = <ReadingBook>[];
    final seenReadingIds = <String>{};
    for (final row in readingRows) {
      final uuid = row['id'] as String?;
      if (uuid == null || uuid.isEmpty) continue;
      if (row['is_archived'] == true) continue;
      final title = (row['title'] as String?) ?? '';
      if (title.isEmpty) continue;
      final appId = (row['app_id'] as String?)?.trim() ?? '';
      final id = appId.isNotEmpty ? appId : uuid;
      if (!seenReadingIds.add(id)) continue;
      final titlePsRaw = (row['title_ps'] as String?)?.trim() ?? '';
      readingBooks.add(
        ReadingBook(
          id: id,
          title: title,
          // Null when the title itself is already Pashto (DESIGN §3.3).
          titlePs: titlePsRaw.isNotEmpty ? titlePsRaw : null,
          author: (row['author'] as String?) ?? '',
          category: (row['category'] as String?) ?? '',
          pdfUrl: (row['pdf_url'] as String?) ?? '',
        ),
      );
    }

    return CatalogueData(
      faculties: faculties,
      departments: departments,
      subjectsByDepartment: subjectsByDepartment,
      libraryBooks: libraryBooks,
      subjectBooks: subjectBooks,
      readingBooks: readingBooks,
      isRemote: true,
    );
  }

  // ------------------------------------------------------------- cache
  Map<String, dynamic> toJson() => {
        'faculties': [
          for (final f in faculties)
            {'id': f.id, 'namePs': f.namePs, 'nameEn': f.nameEn},
        ],
        'departments': [
          for (final d in departments)
            {
              'id': d.id,
              'facultyId': d.facultyId,
              'namePs': d.namePs,
              'nameEn': d.nameEn,
              'semesters': d.semesters,
              'isService': d.isService,
              'hasBooks': d.hasBooks,
            },
        ],
        'subjectsByDepartment': {
          for (final dept in subjectsByDepartment.entries)
            dept.key: {
              for (final sem in dept.value.entries)
                '${sem.key}': [
                  for (final s in sem.value)
                    {'name': s.name, 'code': s.code, 'credits': s.credits},
                ],
            },
        },
        'libraryBooks': [
          for (final b in libraryBooks)
            {
              'id': b.id,
              'title': b.title,
              'titlePs': b.titlePs,
              'author': b.author,
              'departmentIds': b.departmentIds,
              'semestersByDepartment': {
                for (final e in b.semestersByDepartment.entries)
                  e.key: e.value,
              },
              'pdfUrl': b.pdfUrl,
              'viaPcbPage': b.viaPcbPage,
            },
        ],
        'subjectBooks': subjectBooks,
        'readingBooks': [
          for (final b in readingBooks)
            {
              'id': b.id,
              'title': b.title,
              'titlePs': b.titlePs,
              'author': b.author,
              'category': b.category,
              'pdfUrl': b.pdfUrl,
            },
        ],
      };

  /// Throws [FormatException] on a corrupt cache; the caller treats
  /// that exactly like "no cache" and keeps the bundled catalogue.
  factory CatalogueData.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> asMaps(dynamic value, String key) {
      final list = value as List?;
      if (list == null) throw FormatException('missing $key');
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final faculties = asMaps(json['faculties'], 'faculties')
        .map(
          (m) => Faculty(
            id: m['id'] as String? ?? '',
            namePs: (m['namePs'] as String?) ?? '',
            nameEn: (m['nameEn'] as String?) ?? '',
          ),
        )
        .where((f) => f.id.isNotEmpty)
        .toList();
    final departments = asMaps(json['departments'], 'departments')
        .map(
          (m) => Department(
            id: m['id'] as String? ?? '',
            facultyId: (m['facultyId'] as String?) ?? '',
            namePs: (m['namePs'] as String?) ?? '',
            nameEn: (m['nameEn'] as String?) ?? '',
            semesters: (m['semesters'] as num?)?.toInt() ?? 8,
            isService: (m['isService'] as bool?) ?? false,
            hasBooks: (m['hasBooks'] as bool?) ?? false,
          ),
        )
        .where((d) => d.id.isNotEmpty)
        .toList();

    final subjectsByDepartment = <String, Map<int, List<Subject>>>{};
    final subjectsRaw = json['subjectsByDepartment'];
    if (subjectsRaw is! Map) throw const FormatException('missing subjects');
    for (final dept in subjectsRaw.entries) {
      final bySemester = <int, List<Subject>>{};
      final semestersRaw = dept.value;
      if (semestersRaw is! Map) continue;
      for (final sem in semestersRaw.entries) {
        final semester = int.tryParse('${sem.key}');
        if (semester == null) continue;
        final list = sem.value as List?;
        if (list == null) continue;
        bySemester[semester] = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .map(
              (m) => Subject(
                name: (m['name'] as String?) ?? '',
                code: (m['code'] as String?) ?? '',
                credits: (m['credits'] as num?)?.toInt() ?? 0,
              ),
            )
            .where((s) => s.name.isNotEmpty)
            .toList();
      }
      if (bySemester.isNotEmpty) {
        subjectsByDepartment['${dept.key}'] = bySemester;
      }
    }

    final libraryBooks = asMaps(json['libraryBooks'], 'libraryBooks')
        .map((m) {
          final semestersRaw = m['semestersByDepartment'];
          final semestersByDepartment = <String, List<int>>{};
          if (semestersRaw is Map) {
            for (final e in semestersRaw.entries) {
              final list = e.value as List?;
              if (list == null) continue;
              semestersByDepartment['${e.key}'] =
                  list.map((v) => (v as num).toInt()).toList();
            }
          }
          return LibraryBook(
            id: m['id'] as String? ?? '',
            title: (m['title'] as String?) ?? '',
            titlePs: (m['titlePs'] as String?) ?? '',
            author: (m['author'] as String?) ?? '',
            departmentIds: ((m['departmentIds'] as List?) ?? [])
                .map((v) => '$v')
                .toList(),
            semestersByDepartment: semestersByDepartment,
            pdfUrl: (m['pdfUrl'] as String?) ?? '',
            viaPcbPage: (m['viaPcbPage'] as bool?) ?? false,
          );
        })
        .where((b) => b.id.isNotEmpty)
        .toList();

    final subjectBooks = <String, List<String>>{};
    final subjectBooksRaw = json['subjectBooks'];
    if (subjectBooksRaw is Map) {
      for (final e in subjectBooksRaw.entries) {
        final list = e.value as List?;
        if (list == null) continue;
        subjectBooks['${e.key}'] = list.map((v) => '$v').toList();
      }
    }

    final readingBooks = asMaps(json['readingBooks'], 'readingBooks')
        .map(
          (m) => ReadingBook(
            id: m['id'] as String? ?? '',
            title: (m['title'] as String?) ?? '',
            titlePs: m['titlePs'] as String?,
            author: (m['author'] as String?) ?? '',
            category: (m['category'] as String?) ?? '',
            pdfUrl: (m['pdfUrl'] as String?) ?? '',
          ),
        )
        .where((b) => b.id.isNotEmpty)
        .toList();

    return CatalogueData(
      faculties: faculties,
      departments: departments,
      subjectsByDepartment: subjectsByDepartment,
      libraryBooks: libraryBooks,
      subjectBooks: subjectBooks,
      readingBooks: readingBooks,
      isRemote: true,
    );
  }
}

/// A link is a real PDF when its path ends in .pdf (query strings
/// ignored). Anything else is a web page, as the old viaPcbPage books
/// were. An empty link is not a PDF either, but it never reaches the
/// PDF reader: the book tile shows the open error instead.
bool _looksLikePdf(String url) {
  if (url.isEmpty) return false;
  final path = url.split('?').first.split('#').first;
  return path.toLowerCase().endsWith('.pdf');
}
