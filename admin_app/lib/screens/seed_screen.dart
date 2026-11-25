// One-time catalogue seed screen (Admin App, Build 38).
//
// Uploads the whole bundled catalogue (subjects 1,230, books 227,
// book_subjects 670, book_placements 616, reading books 22) to
// Supabase with the signed-in admin's own session, in batches, with
// a progress display and a verified count at the end.
//
// Safe to run twice: rows that already exist are skipped, nothing is
// ever overwritten, so admin edits are never clobbered. If the Phase 1
// migration has not run yet, the screen says so clearly
// («جدولونه لا نه دي جوړ شوي — لومړی migration چلوئ») and does nothing.

import 'package:flutter/material.dart';

import '../services/seed_service.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  bool _running = false;
  String _phase = '';
  int _done = 0;
  int _total = 0;
  final List<String> _log = [];
  SeedResult? _result;
  String? _error;

  static const _labels = {
    'subjects': 'مضمونونه',
    'books': 'کتابونه',
    'book_subjects': 'د کتابونو تړنې',
    'book_placements': 'د کتابونو ځایونه',
    'reading_books': 'د مطالعې کتابونه',
  };

  Future<void> _runSeed() async {
    setState(() {
      _running = true;
      _phase = 'پیل کېږي…';
      _done = 0;
      _total = 0;
      _log.clear();
      _result = null;
      _error = null;
    });
    try {
      final result = await SeedService.runSeed(
        onProgress: (phase, done, total) {
          if (!mounted) return;
          setState(() {
            if (phase != _phase && _phase.isNotEmpty) {
              _log.add('✓ $_phase');
            }
            _phase = phase;
            _done = done;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _running = false;
        _result = result;
        _log.add('✓ $_phase');
        _phase = result.verified ? 'بشپړ شو — تایید شو' : 'بشپړ شو — شمېرې سمې نه دي';
        if (result.skippedLinks > 0) {
          _log.add(
            'خبرتیا: ${result.skippedLinks} تړنې ونه موندل شوې او ونه پورته شوې.',
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = e.toString();
        _phase = 'پاتې راغی';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total > 0 ? (_done / _total).clamp(0.0, 1.0) : 0.0;
    return Scaffold(
      appBar: AppBar(title: const Text('ډېټا پورته کړه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'یو ځل — د کتابتون ټوله ډېټا ډیټابیس ته پورته کړئ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'دا تڼۍ ټول مضمونونه (۱٬۲۳۰)، کتابونه (۲۲۷)، د کتابونو تړنې (۶۷۰)، '
                    'د کتابونو ځایونه (۶۱۶) او د مطالعې کتابونه (۲۲) په ډیټابیس کې اچوي. '
                    'له دې وروسته به محصل اپ له ډیټابیس څخه ولولي، او ستاسو بدلونونه به پکې ښکاري.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'دا کار یوازې یو ځل کېږي. که بیا یې ووهئ، هېڅ به نه بدلیږي — '
                    'هغه څه چې مخکې پورته شوي، نه بدلیږي او ستاسو بدلونونه نه خرابیږي.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'یادونه: که جدولونه لا نه وي جوړ شوي، دا تڼۍ به ووايي چې لومړی migration چلوئ.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _running ? null : _runSeed,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('ډېټا پورته کړه'),
          ),
          if (_running || _phase.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(_phase, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: _total > 0 ? progress : null),
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$_done / $_total'),
              ),
          ],
          if (_log.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in _log) Text(line),
                  ],
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تېروتنه',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(_error!),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _running ? null : _runSeed,
                      icon: const Icon(Icons.refresh),
                      label: const Text('بیا هڅه وکړئ'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Card(
              color: _result!.verified
                  ? Colors.green.shade50
                  : Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.verified
                          ? '✓ ډېټا پورته شوه او تایید شوه'
                          : 'خبرتیا — شمېرې سمې نه دي، وګورئ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Text('',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('پورته شوي',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('په ډیټابیس کې',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        for (final entry in _result!.expected.entries)
                          TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(_labels[entry.key] ?? entry.key),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                    '${_result!.inserted[entry.key] ?? 0}'),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '${_result!.actual[entry.key] ?? 0} / ${entry.value}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _result!.actual[entry.key] ==
                                            entry.value
                                        ? Colors.green.shade800
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (_result!.verified) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'اوس په محصل اپ کې به ټوله ډېټا له ډیټابیس څخه راشي. '
                        'په محصل اپ کې کتابتون تازه (Refresh) کړئ.',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
