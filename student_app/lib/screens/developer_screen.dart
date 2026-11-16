// Developer Profile: Mohammad Ziarmal, founder of the project.
// Photo: add assets/images/creator-photo.jpg to show his photo here;
// until then a monogram avatar is shown (the photo is not in this repo).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  static const _phoneDisplay = '0700979657';
  static const _phoneIntl = '93700979657';
  static const _email = 'ziarmalsahabmohammadullah@gmail.com';

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
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'developerProfile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 56,
              child: Text(
                'MZ',
                style: TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'محمد زیارمل',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Center(
            child: Text(
              'Mohammad Ziarmal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(tr(context, 'developerRole'))),
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
            onPressed: () => _open(context, Uri.parse('tel:+$_phoneIntl')),
            icon: const Icon(Icons.call),
            label: Text('${tr(context, 'call')}: $_phoneDisplay'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _open(
              context,
              Uri.parse('https://wa.me/$_phoneIntl'),
            ),
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
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
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
