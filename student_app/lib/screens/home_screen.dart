// Home screen: three main sections (University Library, Reading Library,
// Developer Profile), quick search, favourites and settings, and a list
// of new books.

import 'package:flutter/material.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import 'book_tile.dart';
import 'developer_screen.dart';
import 'favorites_screen.dart';
import 'library_screens.dart';
import 'reading_library_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: tr(context, 'search'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: tr(context, 'favorites'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: tr(context, 'settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Header with counts.
          Card(
            margin: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'appTitle'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(tr(context, 'appSubtitle')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(
                        label: tr(context, 'totalFaculties'),
                        value: faculties.length,
                      ),
                      _CountChip(
                        label: tr(context, 'totalDepartments'),
                        value: departments.length,
                      ),
                      _CountChip(
                        label: tr(context, 'totalBooks'),
                        value: libraryBooks.length,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'savedOfflineNote'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // Three main sections.
          _SectionCard(
            icon: Icons.school,
            title: tr(context, 'universityLibrary'),
            subtitle: tr(context, 'universityLibraryDesc'),
            color: Colors.blue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FacultiesScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.auto_stories,
            title: tr(context, 'readingLibrary'),
            subtitle: tr(context, 'readingLibraryDesc'),
            color: Colors.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingLibraryScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.person,
            title: tr(context, 'developerProfile'),
            subtitle: tr(context, 'developerProfileDesc'),
            color: Colors.amber.shade800,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeveloperScreen()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              tr(context, 'newBooks'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              tr(context, 'freeBooksNote'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          // New books: the first books of the catalogue.
          ...libraryBooks.take(8).map((book) => BookTile(book: book)),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
