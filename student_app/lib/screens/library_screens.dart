// University Library flow:
// Faculties -> Departments -> Semesters -> Subjects + Books.
// Departments with no eCampus book show a note instead of an empty list.

import 'package:flutter/material.dart';

import '../data/catalogue.dart';
import '../data/catalogue_helpers.dart';
import '../l10n/strings.dart';
import 'book_tile.dart';

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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.school, color: Colors.white),
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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF00796B),
                child: Icon(Icons.account_balance, color: Colors.white),
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
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFC9A227),
                child: Text(
                  '$semester',
                  style: const TextStyle(
                    color: Colors.white,
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

/// One semester: its subjects, then the department's real books.
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
    // Only this semester's own subjects' books. Semester 0 is the
    // Islamic Culture service department: it has no semesters, so its
    // general books still come from the whole department.
    final books = semester == 0
        ? booksOfDepartment(department.id)
        : booksOfSemester(department.id, semester);
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
          ...subjectList.map(
            (s) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading:
                    const Icon(Icons.book_outlined, color: Color(0xFF1565C0)),
                title: Text(
                  s.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: s.code.isEmpty
                    ? null
                    : Text('${tr(context, 'code')}: ${s.code}'),
                trailing: Chip(
                  label: Text(
                    '${s.credits} ${tr(context, 'credits')}',
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              tr(context, 'books'),
              style: Theme.of(context).textTheme.titleLarge,
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
