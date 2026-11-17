// Helmand University Digital Library — Student App
// Owner: Mohammad Ziarmal, Helmand University, Faculty of Education, Biology.
// The app works fully offline from the bundled catalogue
// (lib/data/catalogue.dart). Supabase is optional: if the
// SUPABASE_URL / SUPABASE_ANON_KEY dart-defines are given (from GitHub
// Secrets in CI), the app connects; otherwise it simply uses the bundled
// data. No secret is ever written in this code.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'services/store.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional backend. A missing or wrong key must never stop the app:
  // students can still use all bundled books offline.
  if (_supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
    } catch (_) {
      // Offline mode: bundled catalogue is used.
    }
  }

  final prefs = await SharedPreferences.getInstance();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const HelmandLibraryApp(),
    ),
  );
}

class HelmandLibraryApp extends StatelessWidget {
  const HelmandLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'Helmand University Digital Library',
      debugShowCheckedModeBanner: false,
      locale: state.isPashto ? const Locale('ps') : const Locale('en'),
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
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        // Brand: deep navy app bar, soft rounded cards.
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
          seedColor: const Color(0xFF1565C0),
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
      themeMode: state.themeMode,
      home: const HomeScreen(),
    );
  }
}
