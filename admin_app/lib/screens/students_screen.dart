// Students who registered in the student app (build 35+).
// The student app writes one row per registration into the `students`
// table; this screen lists them, newest first. Students who registered
// before build 35 (local accounts only) do not appear here.

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  late Future<_StudentsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentsData> _load() async {
    final results = await Future.wait([
      SupabaseService.fetchStudents(),
      SupabaseService.fetchFaculties(),
      SupabaseService.fetchAllDepartments(),
    ]);
    return _StudentsData(
      students: results[0] as List<Map<String, dynamic>>,
      faculties: results[1] as List<FacultyRow>,
      departments: results[2] as List<DepartmentRow>,
    );
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _delete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('محصل حذف کړم؟'),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لغوه'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await SupabaseService.deleteStudent(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محصلین'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تازه کول',
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<_StudentsData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تېروتنه: ${snapshot.error}'),
              ),
            );
          }
          final data = snapshot.data;
          final students = data?.students ?? [];
          if (students.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا هېڅ محصل نه دی ثبت شوی — کله چې یو محصل په محصل اپ کې حساب جوړ کړي، دلته به ښکاره شي.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final facultyById = {
            for (final f in data!.faculties) f.id: f.namePs,
          };
          final departmentById = {
            for (final d in data.departments) d.id: d.namePs,
          };
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              final faculty =
                  facultyById[s['faculty_id'] as String?] ?? '';
              final department =
                  departmentById[s['department_id'] as String?] ?? '';
              final created = (s['created_at'] as String?) ?? '';
              final date =
                  created.length >= 10 ? created.substring(0, 10) : created;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text((s['full_name'] as String?) ?? ''),
                  subtitle: Text(
                    '${s['email'] ?? ''}\n$faculty — $department\n$date',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'حذف',
                    onPressed: () => _delete(
                      s['id'] as String,
                      (s['full_name'] as String?) ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentsData {
  const _StudentsData({
    required this.students,
    required this.faculties,
    required this.departments,
  });

  final List<Map<String, dynamic>> students;
  final List<FacultyRow> faculties;
  final List<DepartmentRow> departments;
}
