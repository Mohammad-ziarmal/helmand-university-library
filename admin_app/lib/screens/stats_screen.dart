// Simple statistics: counts from Supabase.
// Download counts come from the books table (download_count), which the
// student app updates when a student opens a book.

import 'package:flutter/material.dart';

import '../services/supabase_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('احصائیه')),
      body: FutureBuilder<Map<String, int>>(
        future: SupabaseService.fetchStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('تېروتنه: ${snapshot.error}'),
              ),
            );
          }
          final stats = snapshot.data ?? {};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                label: 'ټول درسي کتابونه',
                value: stats['books'] ?? 0,
              ),
              _StatCard(
                label: 'د مطالعې کتابونه',
                value: stats['readingBooks'] ?? 0,
              ),
              _StatCard(
                label: 'پوهنځي',
                value: stats['faculties'] ?? 0,
              ),
              _StatCard(
                label: 'څانګې',
                value: stats['departments'] ?? 0,
              ),
              _StatCard(
                label: 'ټول ډاونلوډونه',
                value: stats['downloads'] ?? 0,
              ),
              const SizedBox(height: 16),
              const Text(
                'یادونه: د ډاونلوډ شمېر هغه وخت زیاتېږي چې محصل یو کتاب پرانیزي. که شمېر صفر ښکاري، نو یا خو لا هېڅ کتاب نه دی پرانیستل شوی، یا د downloads جدول لا نه دی ډک شوی.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
