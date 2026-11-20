// University Library flow:
// Faculties -> Departments -> Semesters -> Subjects.
// Tapping a subject opens THAT subject's books (the books of its
// semester). The books are NOT listed below the subjects any more.
// Tapping a book name opens that book's PDF directly.
//
// Card colours (the user's choice): red, yellow, blue, brown, green,
// cycled across the cards so neighbouring cards differ.

import 'package:flutter/material.dart';

import '../data/catalogue.dart';
import '../data/catalogue_helpers.dart';
import '../l10n/strings.dart';
import 'book_tile.dart';

/// Red, yellow, blue, brown, green.
const List<Color> cardPalette = [
  Color(0xFFC62828),
  Color(0xFFF9A825),
  Color(0xFF1565C0),
  Color(0xFF6D4C41),
  Color(0xFF2E7D32),
];

/// White text/icon on every palette colour except yellow, where dark
/// text reads better.
Color paletteOnColor(Color color) =>
    color == const Color(0xFFF9A825) ? const Color(0xFF3E2723) : Colors.white;

Color paletteFor(int index) => cardPalette[index % cardPalette.length];

class FacultiesScreen extends StatelessWidget {
  const FacultiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'faculties'))),
      body: ListView.builder(
        itemCount: faculties.length,
        itemBuilder: (context, index) {
          final faculty = faculties[index];
          final count = departmentsOfFaculty(faculty.id).length;
          final color = paletteFor(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Icon(Icons.school, color: paletteOnColor(color)),
              ),
              title: Text(
                context.watchAppStateIsPashto()
                    ? faculty.namePs
                    : faculty.nameEn,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text(
                '${tr(context, 'departments')}: $count',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DepartmentsScreen(faculty: faculty),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key, required this.faculty});

  final Faculty faculty;

  @override
  Widget build(BuildContext context) {
    final isPs = context.watchAppStateIsPashto();
    final list = departmentsOfFaculty(faculty.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(isPs ? faculty.namePs : faculty.nameEn),
      ),
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, index) {
          final dept = list[index];
          final color = paletteFor(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child:
                    Icon(Icons.account_balance, color: paletteOnColor(color)),
              ),
              title: Text(
                isPs ? dept.namePs : dept.nameEn,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text(
                dept.isService
                    ? tr(context, 'serviceDeptNote')
                    : '${tr(context, 'semesters')}: ${dept.semesters}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                if (dept.isService) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SemesterScreen(
                        department: dept,
                        semester: 0,
                      ),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SemestersScreen(department: dept),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class SemestersScreen extends StatelessWidget {
  const SemestersScreen({super.key, required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    final isPs = context.watchAppStateIsPashto();
    return Scaffold(
      appBar: AppBar(
        title: Text(isPs ? department.namePs : department.nameEn),
      ),
      body: ListView.builder(
        itemCount: department.semesters,
        itemBuilder: (context, index) {
          final semester = index + 1;
          final count =
              subjectsOf(department.id, semester).length;
          final color = paletteFor(index);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color,
                child: Text(
                  '$semester',
                  style: TextStyle(
                    color: paletteOnColor(color),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                '${tr(context, 'semester')} $semester',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Text('${tr(context, 'subjects')}: $count'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SemesterScreen(
                    department: department,
                    semester: semester,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One semester: ONLY its subjects. No books are listed below them.
/// Tap a subject to open its books.
class SemesterScreen extends StatelessWidget {
  const SemesterScreen({
    super.key,
    required this.department,
    required this.semester,
  });

  final Department department;
  final int semester;

  @override
  Widget build(BuildContext context) {
    final isPs = context.watchAppStateIsPashto();
    final subjectList = subjectsOf(department.id, semester);
    final title = semester == 0
        ? tr(context, 'generalSubjects')
        : '${tr(context, 'semester')} $semester';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${isPs ? department.namePs : department.nameEn} — $title',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              tr(context, 'subjects'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr(context, 'tapSubjectToOpenBook'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ...subjectList.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final s = entry.value;
              final color = paletteFor(index);
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      Icons.menu_book,
                      color: paletteOnColor(color),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  subtitle: s.code.isEmpty
                      ? null
                      : Text('${tr(context, 'code')}: ${s.code}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          '${s.credits} ${tr(context, 'credits')}',
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubjectBooksScreen(
                        department: department,
                        semester: semester,
                        subject: s,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The books of one subject: the books of its semester.
/// Tapping a book name opens that book's PDF directly (see BookTile).
class SubjectBooksScreen extends StatelessWidget {
  const SubjectBooksScreen({
    super.key,
    required this.department,
    required this.semester,
    required this.subject,
  });

  final Department department;
  final int semester;
  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final isPs = context.watchAppStateIsPashto();
    // Only this semester's own books. Semester 0 is the Islamic
    // Culture service department: it has no semesters, so its general
    // books still come from the whole department.
    final books = semester == 0
        ? booksOfDepartment(department.id)
        : booksOfSemester(department.id, semester);
    return Scaffold(
      appBar: AppBar(
        title: Text(subject.name),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              '${isPs ? department.namePs : department.nameEn}'
              '${semester == 0 ? '' : ' — ${tr(context, 'semester')} $semester'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              tr(context, 'tapBookToOpen'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (books.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(tr(context, 'noBooksNote')),
                ),
              ),
            )
          else
            ...books.map((book) => BookTile(book: book)),
        ],
      ),
    );
  }
}
