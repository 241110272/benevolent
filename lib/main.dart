import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'screens/app.dart';
import 'screens/onboarding.dart';
import 'screens/account.dart';
import 'screens/detail.dart';
import 'services/app_scope.dart';
import 'services/cloud.dart';
import 'services/job_api.dart';
import 'services/job_store.dart';
import 'services/persistence.dart';
import 'services/reminders.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/OFL-Manrope.txt'));
  });
  runApp(const Bootstrap());
}

const plum = Color(0xFF281531);
const ink = Color(0xFF21122A);
const lavender = Color(0xFFE8DFFA);
const muted = Color(0xFF71677E);
const canvas = Color(0xFFFAF9F7);
const line = Color(0xFFECE8EF);
const lime = Color(0xFFEAF3B4);

class LangkahKerjaApp extends StatelessWidget {
  const LangkahKerjaApp({super.key, required this.store, this.cloud});
  final JobStore store;
  final CloudController? cloud;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LangkahKerja',
    debugShowCheckedModeBanner: false,
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
    builder: (context, child) => AppScope(
      cloud: cloud,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) return child!;
          final height = constraints.maxHeight - 32;
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1ECF9),
                  Color(0xFFE2D7F1),
                  Color(0xFFF4EFF8),
                ],
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
                  data: MediaQuery.of(
                    context,
                  ).copyWith(size: Size(430, height)),
                  child: child!,
                ),
              ),
            ),
          );
        },
      ),
    ),
    home: AppRoot(store: store, cloud: cloud),
  );
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<(JobStore, CloudController)> future = prepare();
  Future<(JobStore, CloudController)> prepare() async {
    final prefs = await SharedPreferences.getInstance();
    final persistence = await AppPersistence.open(prefs);
    SupabaseClient? client;
    if (AppConfig.backendConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: kIsWeb
              ? SharedPreferencesLocalStorage(
                  persistSessionKey: 'langkahkerja.auth.web',
                )
              : const SecureSessionStorage(),
        ),
      );
      client = Supabase.instance.client;
    }
    final store = JobStore(
      prefs,
      persistence: persistence,
      api: IndonesiaJobApi(client),
    )..restore();
    return (store, CloudController(store, client));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return LangkahKerjaApp(
          store: snapshot.data!.$1,
          cloud: snapshot.data!.$2,
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: canvas,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.folder_off_outlined,
                          color: plum,
                          size: 42,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Data belum dapat dibuka. Coba lagi; data yang tersimpan tidak dihapus.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() => future = prepare()),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(color: plum),
            ),
          ),
        ),
      );
    },
  );
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.store, this.cloud});
  final JobStore store;
  final CloudController? cloud;
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  bool started = false;
  bool openingReminder = false;
  String? previousUserId;

  void accountChanged() {
    final current = widget.cloud?.user?.id;
    final previous = previousUserId;
    previousUserId = current;
    if (previous == null || previous == current) return;
    // Routes may hold private job/note snapshots even after the store is cleared.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void openPendingReminder() {
    if (openingReminder || ReminderService.instance.pendingOpen.value == null) {
      return;
    }
    openingReminder = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openingReminder = false;
      if (!mounted ||
          !widget.store.onboardingComplete ||
          widget.cloud?.locked == true) {
        return;
      }
      final target = ReminderService.instance.pendingOpen.value;
      ReminderService.instance.pendingOpen.value = null;
      if (target == null) return;
      final job = widget.store.applicationJobs[target.jobId];
      if (job == null || !target.matches(widget.store.followUps)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agenda ini sudah diubah atau dihapus.'),
          ),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JobDetail(job: job, store: widget.store),
        ),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void reconcileReminders() {
    ReminderService.instance
        .reconcile(widget.store.followUps)
        .catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    previousUserId = widget.cloud?.user?.id;
    widget.cloud?.addListener(accountChanged);
    ReminderService.instance.pendingOpen.addListener(openPendingReminder);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.cloud?.removeListener(accountChanged);
    ReminderService.instance.pendingOpen.removeListener(openPendingReminder);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.store.onboardingComplete) {
      reconcileReminders();
      widget.cloud?.sync();
      if (!widget.store.demoMode &&
          (widget.store.lastFetched == null ||
              DateTime.now().difference(widget.store.lastFetched!).inMinutes >=
                  30)) {
        widget.store.load();
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.store,
      if (widget.cloud != null) widget.cloud!,
    ]),
    builder: (context, _) {
      if (!widget.store.onboardingComplete) {
        return Onboarding(store: widget.store);
      }
      if (!started) {
        started = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          reconcileReminders();
          widget.cloud?.start();
          if (!widget.store.demoMode) widget.store.load();
        });
      }
      if (widget.cloud?.locked == true) {
        return AccountPage(
          store: widget.store,
          cloud: widget.cloud,
          locked: true,
        );
      }
      openPendingReminder();
      return AppShell(store: widget.store, cloud: widget.cloud);
    },
  );
}
