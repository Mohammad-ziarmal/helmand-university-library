// In-app PDF reader (Build 33).
//
// The book opens INSIDE the app, fast, from the file saved on the phone —
// no external PDF viewer and no browser, so it works even when the phone
// has no PDF viewer app and even without internet (when the book was
// already downloaded). When the book was never downloaded, it is
// downloaded first (with a spinner) and then opened here; the download
// also saves it on the phone, so the next open is instant and offline.
//
// Books that point at a web page (viaPcbPage) never reach this screen —
// they still open in the external browser (see book_tile.dart).

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../l10n/strings.dart';
import '../services/downloaded_books.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.bookId,
    required this.displayTitle,
    required this.pdfUrl,
  });

  final String bookId;
  final String displayTitle;
  final String pdfUrl;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? _path;
  String? _error;
  int _pages = 0;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var path = await DownloadedBooks.localPath(widget.bookId);
    path ??= await DownloadedBooks.download(widget.bookId, widget.pdfUrl);
    if (!mounted) return;
    setState(() {
      _path = path;
      if (path == null) _error = tr(context, 'openError');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayTitle),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
          : _path == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    PDFView(
                      filePath: _path!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: false,
                      pageFling: true,
                      pageSnap: true,
                      onRender: (pages) {
                        if (mounted) setState(() => _pages = pages ?? 0);
                      },
                      onError: (error) {
                        if (mounted) {
                          setState(() => _error = tr(context, 'openError'));
                        }
                      },
                      onPageChanged: (page, total) {
                        if (mounted) {
                          setState(() {
                            _page = page ?? 0;
                            _pages = total ?? _pages;
                          });
                        }
                      },
                    ),
                    if (_pages > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${_page + 1} / $_pages',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
