// Search across book titles and authors, and across semester subject
// names (so a student can search a subject and find its books).

import 'package:flutter/material.dart';

import '../data/catalogue.dart';
import '../data/catalogue_helpers.dart';
import '../l10n/strings.dart';
import 'book_tile.dart';
import 'library_screens.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isPs = context.watchAppStateIsPashto();
    final books = searchBooks(_query);
    final matchedSubjects = _query.trim().isEmpty
        ? const <({Department dept, Subject subject})>[]
        : departments
            .expand(
              (d) => allSubjectsOf(d.id).map(
                (s) => (dept: d, subject: s),
              ),
            )
            .where(
              (e) => e.subject.name.toLowerCase().contains(
                    _query.trim().toLowerCase(),
                  ),
            )
            .take(20)
            .toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'search'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: tr(context, 'searchHint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? Center(child: Text(tr(context, 'searchHint')))
                : books.isEmpty && matchedSubjects.isEmpty
                    ? Center(child: Text(tr(context, 'noResults')))
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (books.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 4),
                              child: Text(
                                tr(context, 'books'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ...books.map((b) => BookTile(book: b)),
                          ],
                          if (matchedSubjects.isNotEmpty) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 4),
                              child: Text(
                                tr(context, 'subjects'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            ...matchedSubjects.map(
                              (e) => Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading:
                                      const Icon(Icons.book_outlined),
                                  title: Text(e.subject.name),
                                  subtitle: Text(
                                    isPs ? e.dept.namePs : e.dept.nameEn,
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    final dept = e.dept;
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
                                          builder: (_) => SemestersScreen(
                                            department: dept,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
