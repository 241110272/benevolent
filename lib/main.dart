import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/app.dart';
import 'services/job_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = JobStore(await SharedPreferences.getInstance())..restore();
  runApp(LangkahKerjaApp(store: store));
  store.load();
}

const plum = Color(0xFF281531);
const ink = Color(0xFF21122A);
const lavender = Color(0xFFE8DFFA);
const muted = Color(0xFF71677E);
const canvas = Color(0xFFFAF9F7);
const line = Color(0xFFECE8EF);
const lime = Color(0xFFEAF3B4);

class LangkahKerjaApp extends StatelessWidget {
  const LangkahKerjaApp({super.key, required this.store});
  final JobStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LangkahKerja',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: plum,
        primary: plum,
        secondary: lavender,
        surface: canvas,
      ),
      fontFamily: 'Manrope',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, height: 1.5),
        bodyLarge: TextStyle(color: ink),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: .88),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: muted, fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: plum),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: line),
        selectedColor: lavender,
      ),
      dividerTheme: const DividerThemeData(color: line),
    ),
    builder: (context, child) => LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return child!;
        final height = constraints.maxHeight - 32;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1ECF9), Color(0xFFE2D7F1), Color(0xFFF4EFF8)],
            ),
          ),
          child: Center(
            child: Container(
              width: 430,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: plum.withValues(alpha: .12),
                    blurRadius: 45,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(size: Size(430, height)),
                child: child!,
              ),
            ),
          ),
        );
      },
    ),
    home: AppShell(store: store),
  );
}
