// Home screen: three main sections (University Library, Reading Library,
// Developer Profile), quick search, favourites and settings, and a list
// of new books.
//
// Design: branded hero header with the university logo on a deep navy
// gradient, large gradient section cards, soft rounded cards everywhere.

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
          // Hero header: university logo, title, subtitle, counts.
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF0B2535), Color(0xFF1565C0)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B2535).withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 60,
                        height: 60,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(context, 'appTitle'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(context, 'appSubtitle'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                Text(
                  tr(context, 'savedOfflineNote'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Three main sections.
          _SectionCard(
            icon: Icons.school,
            title: tr(context, 'universityLibrary'),
            subtitle: tr(context, 'universityLibraryDesc'),
            gradient: const [Color(0xFF1565C0), Color(0xFF1E88D6)],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FacultiesScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.auto_stories,
            title: tr(context, 'readingLibrary'),
            subtitle: tr(context, 'readingLibraryDesc'),
            gradient: const [Color(0xFF00695C), Color(0xFF26A69A)],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingLibraryScreen()),
            ),
          ),
          _SectionCard(
            icon: Icons.person,
            title: tr(context, 'developerProfile'),
            subtitle: tr(context, 'developerProfileDesc'),
            gradient: const [Color(0xFF8D6E00), Color(0xFFC9A227)],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DeveloperScreen()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              tr(context, 'newBooks'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
