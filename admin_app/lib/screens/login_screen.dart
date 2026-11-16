// Admin login. Only accounts created in Supabase Auth can sign in.
// Two-factor authentication (2FA) is enabled in the Supabase dashboard
// (see the Setup screen); this login screen uses email + password, and
// the admin enrolls TOTP in Supabase Auth as the second step.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('اډمین — ننوتل'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.admin_panel_settings, size: 64),
          const SizedBox(height: 16),
          const Text(
            'د هلمند پوهنتون کتابتون — اډمین',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'یوازې باصلاحیته مدیران ننوتلای شي. که حساب نه لرئ، له اصلي مدیر (محمد زیارمل) سره اړیکه ونیسئ.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'ایمیل',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'پټ نوم (Password)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (state.error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.error!),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: state.busy
                ? null
                : () async {
                    final ok = await state.signIn(
                      _email.text.trim(),
                      _password.text,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ننوتل نه وشو — ایمیل او پټ نوم وګورئ.'),
                        ),
                      );
                    }
                  },
            child: state.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ننوتل'),
          ),
          const SizedBox(height: 16),
          const Text(
            'یادونه: دوه پړاوه تایید (2FA) دې په Supabase کې فعال وي؛ له ننوتلو وروسته د Setup په پاڼه کې لارښوونه ولولئ.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
