// Admin dashboard: quick stats and navigation to each management area.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_service.dart';
import 'books_screen.dart';
import 'manage_screen.dart';
import 'setup_screen.dart';
import 'stats_screen.dart';
import 'students_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AdminState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('اډمین — ډشبورډ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'وتل',
            onPressed: () => state.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<Map<String, int>>(
            future: SupabaseService.fetchStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ??
                  {
                    'books': 0,
                    'readingBooks': 0,
                    'faculties': 0,
                    'departments': 0,
                    'subjects': 0,
                    'downloads': 0,
                    'students': 0,
                  };
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _Stat(label: 'کتابونه', value: stats['books']!),
                      _Stat(
                        label: 'د مطالعې کتابونه',
                        value: stats['readingBooks']!,
                      ),
                      _Stat(label: 'پوهنځي', value: stats['faculties']!),
                      _Stat(label: 'څانګې', value: stats['departments']!),
                      _Stat(label: 'مضمونونه', value: stats['subjects']!),
                      _Stat(label: 'ډاونلوډونه', value: stats['downloads']!),
                      _Stat(label: 'محصلین', value: stats['students']!),
                    ],
                  ),
                ),
              );
            },
          ),
          _NavCard(
            icon: Icons.people,
            title: 'محصلین',
            subtitle: 'د ثبت شویو محصلینو لېست — نوم، ایمیل، پوهنځی، څانګه',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudentsScreen()),
            ),
          ),
          _NavCard(
            icon: Icons.menu_book,
            title: 'درسي کتابونه',
            subtitle: 'اضافه کول، بدلول، حذفول، PDF اپلوډ، آرشیف',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BooksScreen(kind: BookKind.university),
              ),
            ),
          ),
          _NavCard(
            icon: Icons.auto_stories,
            title: 'د مطالعې کتابتون',
            subtitle: 'ادبي او عمومي کتابونه — یوازې هغه چې قانوني اجازه لري',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BooksScreen(kind: BookKind.reading),
              ),
            ),
          ),
          _NavCard(
            icon: Icons.school,
            title: 'پوهنځي او څانګې',
            subtitle: 'پوهنځی او څانګه اضافه / حذف کړئ، سمسترونه وټاکئ',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageScreen()),
            ),
          ),
          _NavCard(
            icon: Icons.bar_chart,
            title: 'احصائیه',
            subtitle: 'د کتابونو او ډاونلوډونو شمېر',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
          _NavCard(
            icon: Icons.settings,
            title: 'Setup او امنیت',
            subtitle: 'Supabase اتصال، 2FA، رولونه، بیک اپ',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SetupScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(label),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
