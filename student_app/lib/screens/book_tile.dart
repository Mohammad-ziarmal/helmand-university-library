// Shared book card + PDF opening helpers used by several screens.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import '../services/store.dart';

/// Open a book PDF. "Read" opens it in an in-app browser view;
/// "Download" opens it in the external browser / PDF viewer so the
/// student can save it on the phone.
Future<void> openBookPdf(
  BuildContext context,
  LibraryBook book, {
  required bool download,
}) async {
  final uri = Uri.parse(book.pdfUrl);
  final ok = await launchUrl(
    uri,
    mode: download
        ? LaunchMode.externalApplication
        : LaunchMode.inAppBrowserView,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Strings.t('openError', context.read<AppState>().isPashto),
        ),
      ),
    );
  }
}

Future<void> openReadingPdf(
  BuildContext context,
  ReadingBook book, {
  required bool download,
}) async {
  final uri = Uri.parse(book.pdfUrl);
  final ok = await launchUrl(
    uri,
    mode: download
        ? LaunchMode.externalApplication
        : LaunchMode.inAppBrowserView,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Strings.t('openError', context.read<AppState>().isPashto),
        ),
      ),
    );
  }
}

class BookTile extends StatelessWidget {
  const BookTile({super.key, required this.book});

  final LibraryBook book;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.isFavorite(book.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF1565C0).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 26,
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
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (book.viaPcbPage) ...[
                        const SizedBox(height: 4),
                        Text(
                          tr(context, 'pcbNote'),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                  ),
                  onPressed: () => state.toggleFavorite(book.id),
                  tooltip: tr(context, 'favorites'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        openBookPdf(context, book, download: false),
                    icon: const Icon(Icons.visibility),
                    label: Text(tr(context, 'read')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        openBookPdf(context, book, download: true),
                    icon: const Icon(Icons.download),
                    label: Text(tr(context, 'download')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
