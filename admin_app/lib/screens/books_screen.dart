// Books management: list, add, edit, archive and delete.
// Two kinds share this screen: university textbooks (table "books") and
// reading-library books (table "reading_books").
// A PDF can be picked from the phone and uploaded to Supabase Storage
// (bucket "books"), or a PDF URL can be pasted instead.

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

enum BookKind { university, reading }

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key, required this.kind});

  final BookKind kind;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = widget.kind == BookKind.university
          ? SupabaseService.fetchBooks()
          : SupabaseService.fetchReadingBooks();
    });
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف؟'),
        content: const Text('آیا واقعاً دا کتاب حذف کړئ؟'),
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
      if (widget.kind == BookKind.university) {
        await SupabaseService.deleteBook(id);
      } else {
        await SupabaseService.deleteReadingBook(id);
      }
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
    final isUniversity = widget.kind == BookKind.university;
    return Scaffold(
      appBar: AppBar(
        title: Text(isUniversity ? 'درسي کتابونه' : 'د مطالعې کتابونه'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final changed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => BookFormScreen(kind: widget.kind),
            ),
          );
          if (changed == true) _reload();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
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
              child: Text('تر اوسه هېڅ کتاب نشته — د + تڼۍ وکاروئ.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final title = item is BookRow ? item.title : (item as ReadingBookRow).title;
              final author =
                  item is BookRow ? item.author : (item as ReadingBookRow).author;
              final id = item is BookRow ? item.id : (item as ReadingBookRow).id;
              final archived = item is BookRow
                  ? item.isArchived
                  : (item as ReadingBookRow).isArchived;
              final downloads =
                  item is BookRow ? item.downloadCount : null;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                  title: Text(title),
                  subtitle: Text(
                    '$author${downloads != null ? ' — ډاونلوډ: $downloads' : ''}${archived ? ' — آرشیف' : ''}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final changed =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => BookFormScreen(
                                kind: widget.kind,
                                existing: item,
                              ),
                            ),
                          );
                          if (changed == true) _reload();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(id),
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

/// Add / edit form for one book.
class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, required this.kind, this.existing});

  final BookKind kind;
  final dynamic existing; // BookRow or ReadingBookRow, or null for new.

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _author = TextEditingController();
  final _pdfUrl = TextEditingController();
  final _category = TextEditingController();
  bool _hasPermission = false;
  bool _isArchived = false;
  bool _busy = false;
  String? _departmentId;
  int? _semesterNumber;
  List<DepartmentRow> _departments = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e is BookRow) {
      _title.text = e.title;
      _subject.text = e.subject;
      _author.text = e.author;
      _pdfUrl.text = e.pdfUrl;
      _departmentId = e.departmentId;
      _semesterNumber = e.semesterNumber;
      _isArchived = e.isArchived;
    } else if (e is ReadingBookRow) {
      _title.text = e.title;
      _author.text = e.author;
      _pdfUrl.text = e.pdfUrl;
      _category.text = e.category;
      _hasPermission = e.hasPermission;
      _isArchived = e.isArchived;
    }
    if (widget.kind == BookKind.university) {
      // Departments for the dropdown. A failure here only leaves the
      // dropdown empty; the admin can still save with no department.
      SupabaseService.fetchFaculties().then((faculties) async {
        final all = <DepartmentRow>[];
        for (final f in faculties) {
          try {
            all.addAll(await SupabaseService.fetchDepartments(f.id));
          } catch (_) {}
        }
        if (mounted) setState(() => _departments = all);
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _author.dispose();
    _pdfUrl.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    setState(() => _busy = true);
    try {
      final url = await SupabaseService.pickAndUploadPdf();
      _pdfUrl.text = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF اپلوډ شو.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تېروتنه: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _pdfUrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نوم او PDF لینک اړین دي.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.kind == BookKind.university) {
        final existing = widget.existing as BookRow?;
        final book = BookRow(
          id: existing?.id ?? '',
          title: _title.text.trim(),
          subject: _subject.text.trim(),
          author: _author.text.trim(),
          pdfUrl: _pdfUrl.text.trim(),
          departmentId: _departmentId,
          semesterNumber: _semesterNumber,
          downloadCount: existing?.downloadCount ?? 0,
          isArchived: _isArchived,
          // Keep the stable app id / Pashto title / year on edit; the
          // service only sends them when set (pre-migration safe).
          appId: existing?.appId,
          titlePs: existing?.titlePs,
          year: existing?.year,
        );
        if (existing == null) {
          await SupabaseService.addBook(book);
        } else {
          await SupabaseService.updateBook(book);
        }
      } else {
        if (!_hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'یوازې هغه کتابونه اضافه کړئ چې قانوني اجازه لري.',
                ),
              ),
            );
          }
          setState(() => _busy = false);
          return;
        }
        final existing = widget.existing as ReadingBookRow?;
        final book = ReadingBookRow(
          id: existing?.id ?? '',
          title: _title.text.trim(),
          author: _author.text.trim(),
          category: _category.text.trim(),
          pdfUrl: _pdfUrl.text.trim(),
          hasPermission: _hasPermission,
          isArchived: _isArchived,
          // Keep the stable app id / Pashto title / year on edit
          // (reading-book edit is delete + add, so without these the
          // new row would get a fresh generated app id).
          appId: existing?.appId,
          titlePs: existing?.titlePs,
          year: existing?.year,
        );
        if (existing == null) {
          await SupabaseService.addReadingBook(book);
        } else {
          // Reading-book edit is done as delete + add to keep this
          // first version simple; the record keeps the same title.
          await SupabaseService.deleteReadingBook(book.id);
          await SupabaseService.addReadingBook(book);
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تېروتنه: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUniversity = widget.kind == BookKind.university;
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (isUniversity ? 'کتاب بدلول' : 'د مطالعې کتاب بدلول')
              : (isUniversity ? 'نوی درسي کتاب' : 'نوی د مطالعې کتاب'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'د کتاب نوم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (isUniversity)
            TextField(
              controller: _subject,
              decoration: const InputDecoration(
                labelText: 'مضمون',
                border: OutlineInputBorder(),
              ),
            ),
          if (isUniversity) const SizedBox(height: 12),
          TextField(
            controller: _author,
            decoration: const InputDecoration(
              labelText: 'لیکوال',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (!isUniversity)
            TextField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'کټګوري (لکه: پښتو ادبیات)',
                border: OutlineInputBorder(),
              ),
            ),
          if (!isUniversity) const SizedBox(height: 12),
          if (isUniversity && _departments.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _departmentId,
              decoration: const InputDecoration(
                labelText: 'څانګه',
                border: OutlineInputBorder(),
              ),
              items: _departments
                  .map(
                    (d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(d.namePs),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _departmentId = v),
            ),
          if (isUniversity && _departments.isNotEmpty)
            const SizedBox(height: 12),
          if (isUniversity)
            DropdownButtonFormField<int>(
              initialValue: _semesterNumber,
              decoration: const InputDecoration(
                labelText: 'سمستر',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                10,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('سمستر ${i + 1}'),
                ),
              ),
              onChanged: (v) => setState(() => _semesterNumber = v),
            ),
          if (isUniversity) const SizedBox(height: 12),
          TextField(
            controller: _pdfUrl,
            decoration: const InputDecoration(
              labelText: 'PDF لینک',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: const Text('له ټېلېفون څخه PDF اپلوډ کړئ'),
          ),
          if (!isUniversity)
            CheckboxListTile(
              title: const Text('قانوني اجازه لري'),
              value: _hasPermission,
              onChanged: (v) =>
                  setState(() => _hasPermission = v ?? false),
            ),
          CheckboxListTile(
            title: const Text('آرشیف (پټ)'),
            value: _isArchived,
            onChanged: (v) => setState(() => _isArchived = v ?? false),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('خوندي کول'),
          ),
        ],
      ),
    );
  }
}
