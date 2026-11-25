// Subjects management for one department (Admin App, Phase 3).
//
// Lists the department's subjects by semester; add / edit / archive.
// Books link to subjects by id (book_subjects), so renaming a subject
// never orphans a book (DESIGN §6).
//
// The subjects table is created by the Phase 1 migration. Until that
// migration has run in Supabase, this screen shows a clear "not set
// up yet" state instead of crashing.

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key, required this.department});

  final DepartmentRow department;

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  late Future<List<SubjectRow>> _future;

  /// Null = all semesters. Semester 0 is the Islamic Culture service
  /// department's general subjects (it has no semesters of its own).
  int? _semester;

  /// Last loaded list, used to pick the next sort_order for a new
  /// subject in the same semester.
  List<SubjectRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final future = SupabaseService.fetchSubjects(
      widget.department.id,
      semester: _semester,
    );
    future.then((list) => _items = list, onError: (_) {});
    setState(() => _future = future);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تېروتنه: $e')),
    );
  }

  /// Semester filter chips. A service department (0 semesters) has
  /// only its general subjects, so it gets no semester chips.
  List<int> get _semesterOptions {
    final n = widget.department.semesters;
    if (n <= 0) return const [];
    return List<int>.generate(n, (i) => i + 1);
  }

  Future<void> _editSubject(SubjectRow? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final credits = TextEditingController(
      text: existing == null ? '2' : '${existing.credits}',
    );
    final semester = TextEditingController(
      text: '${existing?.semesterNumber ?? _semester ?? 1}',
    );
    var isActive = existing?.isActive ?? true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'نوی مضمون' : 'مضمون بدلول'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'نوم (پښتو)'),
                ),
                TextField(
                  controller: code,
                  decoration: const InputDecoration(
                    labelText: 'کوډ (که وي، لکه SL.IC.0171)',
                  ),
                ),
                TextField(
                  controller: credits,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'کریدیتونه'),
                ),
                TextField(
                  controller: semester,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سمستر (۰–۱۰)',
                  ),
                ),
                if (existing != null)
                  SwitchListTile(
                    title: const Text('فعال (ښکاره)'),
                    subtitle: const Text(
                      'غیر فعال مضمون په محصل اپ کې نه ښکاري.',
                    ),
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v),
                  ),
              ],
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
      ),
    );
    if (ok != true) return;
    final subjectName = name.text.trim();
    final semesterNumber =
        int.tryParse(semester.text.trim()) ?? _semester ?? 1;
    final creditValue = int.tryParse(credits.text.trim());
    if (subjectName.isEmpty || creditValue == null) {
      _showError('نوم او کریدیتونه اړین دي.');
      return;
    }
    if (semesterNumber < 0 || semesterNumber > 10) {
      _showError('سمستر باید له ۰ تر ۱۰ پورې وي.');
      return;
    }
    try {
      if (existing == null) {
        // Next free position at the end of this semester's list.
        var sortOrder = 0;
        for (final s in _items) {
          if (s.semesterNumber == semesterNumber &&
              s.sortOrder >= sortOrder) {
            sortOrder = s.sortOrder + 1;
          }
        }
        await SupabaseService.addSubject(
          SubjectRow(
            departmentId: widget.department.id,
            semesterNumber: semesterNumber,
            name: subjectName,
            code: code.text.trim(),
            credits: creditValue,
            sortOrder: sortOrder,
          ),
        );
      } else {
        await SupabaseService.updateSubject(
          existing.copyWith(
            semesterNumber: semesterNumber,
            name: subjectName,
            code: code.text.trim(),
            credits: creditValue,
            isActive: isActive,
          ),
        );
      }
      _reload();
    } on SubjectsNotReadyError catch (e) {
      _showError(e);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteSubject(SubjectRow subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف؟'),
        content: Text(
          'د "${subject.name}" مضمون به حذف شي. که کتابونه ورسره تړلي وي، '
          'مضمون به یوازې پټ (آرشیف) شي، نه حذف — تر څو د کتابونو پاڼې کار وکړي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('نه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('هو'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final archived = await SupabaseService.deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? 'مضمون آرشیف شو (کتابونه ورسره تړلي وو).'
                  : 'مضمون حذف شو.',
            ),
          ),
        );
      }
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _restoreSubject(SubjectRow subject) async {
    try {
      await SupabaseService.updateSubject(
        subject.copyWith(isActive: true),
      );
      _reload();
    } catch (e) {
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department;
    return Scaffold(
      appBar: AppBar(title: Text('مضمونونه — ${dept.namePs}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editSubject(null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_semesterOptions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Row(
                children: [
                  _SemesterChip(
                    label: 'ټول',
                    selected: _semester == null,
                    onSelected: () {
                      setState(() => _semester = null);
                      _reload();
                    },
                  ),
                  for (final s in _semesterOptions)
                    _SemesterChip(
                      label: 'سمستر $s',
                      selected: _semester == s,
                      onSelected: () {
                        setState(() => _semester = s);
                        _reload();
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<SubjectRow>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error!;
                  if (error is SubjectsNotReadyError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.construction,
                              size: 48,
                              color: Color(0xFF1565C0),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'مضمونونه تر اوسه نه دي تنظیم شوي',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'د مضمونونو جدول (subjects) لا په Supabase کې نه دی جوړ شوی. '
                              'لومړی باید migration وچلول شي، له دې وروسته به دلته مضمونونه ښکاره شي.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh),
                              label: const Text('بیا هڅه وکړئ'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('تېروتنه: $error'),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('بیا هڅه وکړئ'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      _semester == null
                          ? 'تر اوسه هېڅ مضمون نشته — د + تڼۍ وکاروئ.'
                          : 'په ${_semester} سمستر کې هېڅ مضمون نشته.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final subject = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${subject.semesterNumber}'),
                        ),
                        title: Text(
                          subject.name,
                          style: subject.isActive
                              ? null
                              : const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                        ),
                        subtitle: Text(
                          [
                            if (subject.code.isNotEmpty)
                              'کوډ: ${subject.code}',
                            'کریدیتونه: ${subject.credits}',
                            if (_semester == null)
                              'سمستر ${subject.semesterNumber}',
                            if (!subject.isActive) 'آرشیف شوی',
                          ].join(' • '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!subject.isActive)
                              IconButton(
                                icon: const Icon(Icons.restore),
                                tooltip: 'بیرته فعالول',
                                onPressed: () =>
                                    _restoreSubject(subject),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'بدلول',
                              onPressed: () => _editSubject(subject),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'حذف / آرشیف',
                              onPressed: () => _deleteSubject(subject),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterChip extends StatelessWidget {
  const _SemesterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
