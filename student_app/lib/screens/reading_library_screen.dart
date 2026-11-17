// Reading Library: Pashto literary and general books.
// Only books with a real, legal PDF link are shown. Categories that have
// no book yet show a "coming soon" note instead of invented titles.

import 'package:flutter/material.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import 'book_tile.dart';

class ReadingLibraryScreen extends StatefulWidget {
  const ReadingLibraryScreen({super.key});

  @override
  State<ReadingLibraryScreen> createState() => _ReadingLibraryScreenState();
}

class _ReadingLibraryScreenState extends State<ReadingLibraryScreen> {
  String _selectedCategory = 'all';

  // Planned categories from the project plan. Only the categories that
  // already have real books show books; the rest show "coming soon".
  static const List<String> _plannedCategories = [
    'پښتو ادبیات',
    'شخصیت جوړونه',
    'مدیریت او رهبري',
    'د وخت مدیریت',
    'ارواپوهنه',
    'ساینس او ټکنالوژي',
    'تاریخ او ټولنیز ژوند',
    'عادتونه او بریالیتوب',
    'عمومي پوهه',
  ];

  @override
  Widget build(BuildContext context) {
    final shown = _selectedCategory == 'all'
        ? readingBooks
        : readingBooks
            .where((b) => b.category == _selectedCategory)
            .toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'readingLibrary'))),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              tr(context, 'categories'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _CategoryChip(
                  label: tr(context, 'allBooks'),
                  selected: _selectedCategory == 'all',
                  onSelected: () => setState(() => _selectedCategory = 'all'),
                ),
                ..._plannedCategories.map(
                  (c) => _CategoryChip(
                    label: c,
                    selected: _selectedCategory == c,
                    onSelected: () => setState(() => _selectedCategory = c),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${tr(context, 'comingSoon')} — ${tr(context, 'noBooksNote')}',
                  ),
                ),
              ),
            )
          else
            ...shown.map(
              (book) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF00796B),
                            child: Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tr(context, 'author')}: ${book.author}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  book.category,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => openReadingPdf(
                                context,
                                book,
                                download: false,
                              ),
                              icon: const Icon(Icons.visibility),
                              label: Text(tr(context, 'read')),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => openReadingPdf(
                                context,
                                book,
                                download: true,
                              ),
                              icon: const Icon(Icons.download),
                              label: Text(tr(context, 'download')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
