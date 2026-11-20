// Developer Profile: Mohammad Ziarmal, founder of the project.
// Photo: assets/images/creator-photo.jpg (his own photo, shown in the
// gold-bordered circle; an "MZ" monogram is the fallback if the asset
// is missing).
// The page is always light — white background with gold accents —
// whatever the app theme is.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  static const _phoneDisplay = '0700979657';
  static const _phoneIntl = '93700979657';
  static const _email = 'ziarmalsahabmohammadullah@gmail.com';

  // Gold theme for this page.
  static const _gold = Color(0xFFC9A227);
  static const _darkGold = Color(0xFF8D6E00);
  // Dark navy for the name — explicit, so it stays dark and readable
  // on the white background in both light and dark mode.
  static const _navy = Color(0xFF0B2535);

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'openError'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always light: white and gold, whatever the app theme is.
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkGold,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _gold.withOpacity(0.5)),
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(tr(context, 'developerProfile'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/creator-photo.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const CircleAvatar(
                      backgroundColor: _gold,
                      child: Text(
                        'MZ',
                        style: TextStyle(fontSize: 36, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'محمد زیارمل',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ),
            Center(
              child: Text(
                'Mohammad Ziarmal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _navy,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                tr(context, 'developerRole'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _navy,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.school,
                      label: 'هلمند پوهنتون — Helmand University',
                    ),
                    _InfoRow(
                      icon: Icons.account_balance,
                      label: 'ښوونې او روزنې پوهنځی — Faculty of Education',
                    ),
                    _InfoRow(
                      icon: Icons.science,
                      label: 'بیولوژي څانګه — Biology Department',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr(context, 'developerMessage')),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _open(context, Uri.parse('tel:+$_phoneIntl')),
              icon: const Icon(Icons.call),
              label: Text('${tr(context, 'call')}: $_phoneDisplay'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _open(
                context,
                Uri.parse('https://wa.me/$_phoneIntl'),
              ),
              icon: const Icon(Icons.chat),
              label: const Text('WhatsApp'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkGold,
                side: const BorderSide(color: _gold),
              ),
              onPressed: () =>
                  _open(context, Uri.parse('mailto:$_email')),
              icon: const Icon(Icons.email),
              label: Text('${tr(context, 'email')}: $_email'),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                tr(context, 'version'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DeveloperScreen._darkGold),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
