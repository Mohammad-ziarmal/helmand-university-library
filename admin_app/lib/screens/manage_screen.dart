// Faculties and departments management.

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';
import 'subjects_screen.dart';

class ManageScreen extends StatefulWidget {
  const ManageScreen({super.key});

  @override
  State<ManageScreen> createState() => _ManageScreenState();
}

class _ManageScreenState extends State<ManageScreen> {
  late Future<List<FacultyRow>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _future = SupabaseService.fetchFaculties());
  }

  Future<void> _addFaculty() async {
    final namePs = TextEditingController();
    final nameEn = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نوی پوهنځی'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namePs,
              decoration: const InputDecoration(labelText: 'نوم (پښتو)'),
            ),
            TextField(
              controller: nameEn,
              decoration: const InputDecoration(labelText: 'نوم (English)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لغوه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خوندي کول'),
          ),
        ],
      ),
    );
    if (ok == true && namePs.text.trim().isNotEmpty) {
      try {
        await SupabaseService.addFaculty(
          namePs.text.trim(),
          nameEn.text.trim(),
        );
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تېروتنه: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteFaculty(FacultyRow faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف؟'),
        content: Text(
          'د "${faculty.namePs}" پوهنځي سره به یې ټولې څانګې او کتابونه هم حذف شي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('نه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('هو، حذف یې کړه'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteFaculty(faculty.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تېروتنه: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('پوهنځي او څانګې')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFaculty,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<FacultyRow>>(
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('تر اوسه هېڅ پوهنځی نشته — د + تڼۍ وکاروئ.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final faculty = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.school)),
                  title: Text(faculty.namePs),
                  subtitle: Text(faculty.nameEn),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DepartmentManageScreen(
                                faculty: faculty,
                              ),
                            ),
                          );
                          _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteFaculty(faculty),
                      ),
                    ],
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

class DepartmentManageScreen extends StatefulWidget {
  const DepartmentManageScreen({super.key, required this.faculty});

  final FacultyRow faculty;

  @override
  State<DepartmentManageScreen> createState() =>
      _DepartmentManageScreenState();
}

class _DepartmentManageScreenState extends State<DepartmentManageScreen> {
  late Future<List<DepartmentRow>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(
      () => _future = SupabaseService.fetchDepartments(widget.faculty.id),
    );
  }

  Future<void> _addDepartment() async {
    final namePs = TextEditingController();
    final nameEn = TextEditingController();
    final code = TextEditingController();
    final semesters = TextEditingController(text: '8');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نوې څانګه'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namePs,
              decoration: const InputDecoration(labelText: 'نوم (پښتو)'),
            ),
            TextField(
              controller: nameEn,
              decoration: const InputDecoration(labelText: 'نوم (English)'),
            ),
            TextField(
              controller: code,
              decoration: const InputDecoration(
                labelText: 'کوډ (انګلیسي، لکه bio — یوازې a-z، 0-9، -)',
              ),
            ),
            TextField(
              controller: semesters,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'د سمسترونو شمېر (معمولاً ۸، وترنري ۱۰)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لغوه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خوندي کول'),
          ),
        ],
      ),
    );
    if (ok == true && namePs.text.trim().isNotEmpty) {
      // The code is the join key the student app uses (DESIGN §2):
      // required, lowercase letters/digits/dashes only, never edited
      // afterwards. The service validates it again and checks it is
      // unique.
      final deptCode = code.text.trim().toLowerCase();
      if (!RegExp(r'^[a-z0-9-]+$').hasMatch(deptCode)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'کوډ اړین دی او باید یوازې له a-z، 0-9 او - څخه جوړ وي (لکه bio).',
              ),
            ),
          );
        }
        return;
      }
      try {
        await SupabaseService.addDepartment(
          widget.faculty.id,
          namePs.text.trim(),
          nameEn.text.trim(),
          int.tryParse(semesters.text.trim()) ?? 8,
          code: deptCode,
        );
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تېروتنه: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteDepartment(DepartmentRow dept) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف؟'),
        content: Text(
          'د "${dept.namePs}" څانګې سره به یې کتابونه هم حذف شي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('نه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('هو، حذف یې کړه'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteDepartment(dept.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تېروتنه: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('څانګې — ${widget.faculty.namePs}')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDepartment,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<DepartmentRow>>(
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('تر اوسه هېڅ څانګه نشته — د + تڼۍ وکاروئ.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final dept = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.account_balance)),
                  title: Text(dept.namePs),
                  subtitle: Text(
                    '${dept.nameEn} — سمسترونه: ${dept.semesters}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.subject),
                        tooltip: 'مضمونونه',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SubjectsScreen(
                                department: dept,
                              ),
                            ),
                          );
                          _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month),
                        tooltip: 'سمسترونه',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SemesterManageScreen(
                                department: dept,
                              ),
                            ),
                          );
                          _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteDepartment(dept),
                      ),
                    ],
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

/// Semesters of one department (rows of the "semesters" table).
/// The department's semester count (8, or 10 for DVM) is the main
/// setting; these rows attach semesters to an academic year when needed.
class SemesterManageScreen extends StatefulWidget {
  const SemesterManageScreen({super.key, required this.department});

  final DepartmentRow department;

  @override
  State<SemesterManageScreen> createState() => _SemesterManageScreenState();
}

class _SemesterManageScreenState extends State<SemesterManageScreen> {
  late Future<List<SemesterRow>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(
      () => _future =
          SupabaseService.fetchSemesters(widget.department.id),
    );
  }

  Future<void> _addSemester() async {
    final number = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نوی سمستر'),
        content: TextField(
          controller: number,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'د سمستر شمېر (۱–۱۰)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('لغوه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('خوندي کول'),
          ),
        ],
      ),
    );
    final n = int.tryParse(number.text.trim());
    if (ok == true && n != null && n >= 1 && n <= 10) {
      try {
        await SupabaseService.addSemester(widget.department.id, n);
        _reload();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تېروتنه: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSemester(SemesterRow semester) async {
    try {
      await SupabaseService.deleteSemester(semester.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تېروتنه: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سمسترونه — ${widget.department.namePs}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSemester,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SemesterRow>>(
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
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'تر اوسه هېڅ سمستر نه دی ثبت شوی. د څانګې د سمسترونو شمېر (لکه ۸) د څانګې په ثبتولو کې ټاکل کېږي؛ دلته یې د علمي کال سره تړلی سمستر اضافه کولی شئ.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final semester = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${semester.semesterNumber}'),
                  ),
                  title: Text('سمستر ${semester.semesterNumber}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteSemester(semester),
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
