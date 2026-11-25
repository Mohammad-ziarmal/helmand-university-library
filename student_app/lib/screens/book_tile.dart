// Shared book card + PDF opening helpers used by several screens.
//
// Tapping the book NAME opens that book's PDF directly.
// "Read" opens the PDF (from the phone when it was downloaded, so it
// works without internet). "Download" saves the PDF on the phone, so
// the student can read it again later, offline.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/book.dart';
import '../l10n/strings.dart';
import '../services/downloaded_books.dart';
import '../services/store.dart';
import 'pdf_reader_screen.dart';

/// Card colours the user asked for: red, yellow, blue, brown, green.
/// One pair per colour, cycled by book id so neighbouring cards differ.
const List<(Color, Color, Color)> bookCoverColours = [
  (Color(0xFFC62828), Color(0xFFEF5350), Colors.white),
  (Color(0xFFF9A825), Color(0xFFFFCA28), Color(0xFF3E2723)),
  (Color(0xFF1565C0), Color(0xFF29B6F6), Colors.white),
  (Color(0xFF6D4C41), Color(0xFFA1887F), Colors.white),
  (Color(0xFF2E7D32), Color(0xFF66BB6A), Colors.white),
];

(Color, Color, Color) coverColourFor(String id) {
  var h = 0;
  for (var i = 0; i < id.length; i++) {
    h = (h * 31 + id.codeUnitAt(i)) & 0x7fffffff;
  }
  return bookCoverColours[h % bookCoverColours.length];
}

void _showMessage(BuildContext context, String key) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(context, key))),
  );
}

/// Open a book PDF INSIDE the app (Build 33): the in-app reader opens
/// the file saved on the phone — even without internet — and downloads
/// it first when it was never downloaded. Only a web-page entry
/// (viaPcbPage) still opens in the external browser.
Future<void> openBookPdf(
  BuildContext context,
  LibraryBook book, {
  required bool download,
}) async {
  if (download) {
    if (book.viaPcbPage) {
      // This entry points at a web page, not a PDF file.
      await launchUrl(Uri.parse(book.pdfUrl),
          mode: LaunchMode.externalApplication);
      return;
    }
    final path = await DownloadedBooks.download(book.id, book.pdfUrl);
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'savedOnPhone'))),
      );
    } else {
      _showMessage(context, 'downloadFailed');
    }
    return;
  }
  if (book.viaPcbPage) {
    final ok = await launchUrl(Uri.parse(book.pdfUrl),
        mode: LaunchMode.externalApplication);
    if (!ok) _showMessage(context, 'openError');
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PdfReaderScreen(
        bookId: book.id,
        displayTitle: book.titlePs,
        pdfUrl: book.pdfUrl,
      ),
    ),
  );
}

Future<void> openReadingPdf(
  BuildContext context,
  ReadingBook book, {
  required bool download,
}) async {
  if (download) {
    final path = await DownloadedBooks.download(book.id, book.pdfUrl);
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'savedOnPhone'))),
      );
    } else {
      _showMessage(context, 'downloadFailed');
    }
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PdfReaderScreen(
        bookId: book.id,
        displayTitle: book.titlePs ?? book.title,
        pdfUrl: book.pdfUrl,
      ),
    ),
  );
}

/// Share a book (title, author, PDF link) with the system share sheet,
/// so a student can send it to a friend on WhatsApp or anywhere else.
Future<void> shareBookLink(
  BuildContext context, {
  required String title,
  required String author,
  required String pdfUrl,
}) async {
  final text =
      '$title\n${tr(context, 'author')}: $author\n${tr(context, 'appTitle')}\n$pdfUrl';
  await SharePlus.instance.share(ShareParams(text: text, subject: title));
}

class BookTile extends StatefulWidget {
  const BookTile({super.key, required this.book});

  final LibraryBook book;

  @override
  State<BookTile> createState() => _BookTileState();
}

class _BookTileState extends State<BookTile> {
  bool _downloaded = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _refreshDownloaded();
  }

  Future<void> _refreshDownloaded() async {
    final value = await DownloadedBooks.isDownloaded(widget.book.id);
    if (mounted) setState(() => _downloaded = value);
  }

  Future<void> _onDownload() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    await openBookPdf(context, widget.book, download: true);
    await _refreshDownloaded();
    if (mounted) setState(() => _downloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isFav = state.isFavorite(widget.book.id);
    final book = widget.book;
    final cover = coverColourFor(book.id);
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cover.$1, cover.$2],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: cover.$1.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: cover.$3,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tapping the book name opens its PDF directly,
                      // inside the app. Pashto name first, English below.
                      InkWell(
                        onTap: () =>
                            openBookPdf(context, book, download: false),
                        child: Text(
                          book.titlePs,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (book.titlePs != book.title) ...[
                        const SizedBox(height: 2),
                        Text(
                          book.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${tr(context, 'author')}: ${book.author}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (_downloaded) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tr(context, 'downloaded'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => shareBookLink(
                        context,
                        title: book.titlePs,
                        author: book.author,
                        pdfUrl: book.pdfUrl,
                      ),
                      tooltip: tr(context, 'share'),
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
                    label: Text(
                      _downloaded
                          ? tr(context, 'readOffline')
                          : tr(context, 'read'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _downloading ? null : _onDownload,
                    icon: _downloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _downloaded
                                ? Icons.check_circle
                                : Icons.download,
                          ),
                    label: Text(
                      _downloading
                          ? tr(context, 'downloading')
                          : _downloaded
                              ? tr(context, 'downloaded')
                              : tr(context, 'download'),
                    ),
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
