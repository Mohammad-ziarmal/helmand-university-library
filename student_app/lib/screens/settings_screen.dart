// Settings: language (Pashto / English) and theme (light / dark / system),
// plus a short About text.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            tr(context, 'language'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('پښتو')),
              ButtonSegment(value: false, label: Text('English')),
            ],
            selected: {state.isPashto},
            onSelectionChanged: (values) =>
                state.setPashto(values.first),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'theme'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(tr(context, 'light')),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(tr(context, 'dark')),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(tr(context, 'system')),
              ),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (values) =>
                state.setThemeMode(values.first),
          ),
          const SizedBox(height: 24),
          Text(
            tr(context, 'about'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(tr(context, 'aboutText')),
          const SizedBox(height: 8),
          Text(
            tr(context, 'version'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
