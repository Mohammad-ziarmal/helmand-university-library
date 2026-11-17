// Helmand University Digital Library — Admin App (SEPARATE app).
// Only Mohammad Ziarmal and authorised admins use it.
// It never contains secret keys: Supabase URL and anon key come from
// --dart-define SUPABASE_URL / SUPABASE_ANON_KEY (GitHub Secrets in CI).
// Without them the app opens the setup screen, not a broken dashboard.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseService.init();
  } catch (_) {
    // Setup screen will explain how to connect.
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => AdminState(),
      child: const HelmandAdminApp(),
    ),
  );
}

class HelmandAdminApp extends StatelessWidget {
  const HelmandAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helmand University Library — Admin',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ps'),
      supportedLocales: const [Locale('ps'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2535),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2535),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2535),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B2535),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const RootScreen(),
    );
  }
}

/// Decides what the admin sees first:
///
/// * Supabase not connected -> setup instructions.
/// * Not signed in -> login.
/// * Signed in -> dashboard.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AdminState>();
    if (!state.configured) return const SetupScreen();
    if (!state.signedIn) return const LoginScreen();
    return const DashboardScreen();
  }
}
