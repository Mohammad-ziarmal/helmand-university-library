// Setup & security screen. Shown first when Supabase is not connected,
// and reachable from the dashboard afterwards.
// It never shows the secret key — only whether the app is connected and
// to which project host.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_service.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminState>();
    final configured = SupabaseService.isConfigured;
    return Scaffold(
      appBar: AppBar(title: const Text('Setup او امنیت')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: configured
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    configured
                        ? 'Supabase وصل دی'
                        : 'Supabase لا نه دی وصل شوی',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (configured)
                    Text(
                      'پروژه: ${SupabaseService.projectHost}',
                    ),
                  if (!configured)
                    const Text(
                      'دا اپ د Setup له بشپړولو وروسته کار کوي. لاندې ګامونه په ترتیب تعقیب کړئ.',
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'د نښلولو ګامونه',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const _Step(
            number: 1,
            text: 'په خپل نوم په supabase.com کې وړیا حساب او پروژه جوړه کړئ.',
          ),
          const _Step(
            number: 2,
            text: 'په Supabase کې SQL Editor پرانیستئ او د پروژې supabase/schema.sql فایل وچلوئ.',
          ),
          const _Step(
            number: 3,
            text: 'په Storage کې د "books" په نوم یو Public Bucket جوړ کړئ (د PDF لپاره).',
          ),
          const _Step(
            number: 4,
            text: 'په Authentication کې د مدیر لپاره یو کارن (ایمیل + پټ نوم) جوړ کړئ.',
          ),
          const _Step(
            number: 5,
            text: 'په GitHub کې د Repository په Settings > Secrets کې SUPABASE_URL او SUPABASE_ANON_KEY اضافه کړئ.',
          ),
          const _Step(
            number: 6,
            text: 'په GitHub Actions کې د Build APKs کار وچلوئ او نوی APK ډاونلوډ کړئ.',
          ),
          const SizedBox(height: 16),
          Text(
            'امنیت',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const _Step(
            number: 1,
            text: 'دوه پړاوه تایید (2FA): په Supabase Dashboard کې Authentication > MFA کې TOTP فعال کړئ، او هر مدیر دې خپل TOTP ثبت کړي.',
          ),
          const _Step(
            number: 2,
            text: 'رولونه (RBAC): د roles جدول کې super_admin (محمد زیارمل)، content_admin او viewer رولونه دي؛ هر مدیر یوازې د خپل صلاحیت کار کوي.',
          ),
          const _Step(
            number: 3,
            text: 'Row Level Security (RLS) په ټولو جدولونو فعال دی: محصل یوازې لوستلی شي، یوازې ننوتی مدیر لیکلی او حذف کولی شي.',
          ),
          const _Step(
            number: 4,
            text: 'بیک اپ: هر بدلون په audit_logs کې ثبتېږي. د Database کاپي په منظم ډول په خوندي ځای کې وساتئ.',
          ),
          const _Step(
            number: 5,
            text: 'Secret Keys هېڅکله په کوډ، سکرین شاټ یا عامه Repository کې مه خپروئ — یوازې په GitHub Secrets کې یې وساتئ.',
          ),
          const SizedBox(height: 24),
          if (state.signedIn)
            OutlinedButton.icon(
              onPressed: () => state.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('وتل'),
            ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
