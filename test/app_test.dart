import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langkah_kerja/main.dart';
import 'package:langkah_kerja/services/job_store.dart';
import 'package:langkah_kerja/models/job.dart';
import 'package:langkah_kerja/models/reminder_target.dart';
import 'package:langkah_kerja/services/reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  testWidgets('onboarding menjelaskan privasi dan menyimpan penyelesaian', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = JobStore(prefs);
    await tester.pumpWidget(LangkahKerjaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai melangkah'), findsOneWidget);
    await tester.tap(find.text('Mulai melangkah'));
    await tester.pumpAndSettle();
    expect(store.onboardingComplete, isTrue);
    expect((JobStore(prefs)..restore()).onboardingComplete, isTrue);
    expect(find.text('Eksplorasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('lamaran manual tersimpan tanpa membutuhkan akun atau feed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = JobStore(await SharedPreferences.getInstance())
      ..onboardingComplete = true
      ..useDemo();
    await tester.pumpWidget(LangkahKerjaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lamaran'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat lowongan sendiri'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('manual-title')),
      'Flutter Engineer',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manual-company')),
      'Perusahaan Contoh',
    );
    await tester.scrollUntilVisible(
      find.text('Simpan catatan lamaran'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Simpan catatan lamaran'));
    await tester.pumpAndSettle();
    expect(store.applications.length, 1);
    expect(store.applicationJobs.values.single.title, 'Flutter Engineer');
    expect(store.applicationJobs.values.single.demo, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('ketukan pengingat membuka lamaran dan menolak agenda lama', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = JobStore(await SharedPreferences.getInstance())
      ..onboardingComplete = true
      ..useDemo();
    final job = demoJobs.first;
    final at = DateTime.now().add(const Duration(days: 1));
    await store.track(job, ApplicationStatus.interview);
    await store.setFollowUp(job.id, at);
    final pending = ReminderService.instance.pendingOpen;
    addTearDown(() => pending.value = null);
    await tester.pumpWidget(LangkahKerjaApp(store: store));
    await tester.pumpAndSettle();
    pending.value = ReminderTarget(job.id, at.millisecondsSinceEpoch);
    await tester.pumpAndSettle();
    expect(find.text('Detail lowongan'), findsOneWidget);
    expect(find.text(job.title), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await store.setFollowUp(job.id, at.add(const Duration(hours: 1)));
    pending.value = ReminderTarget(job.id, at.millisecondsSinceEpoch);
    await tester.pumpAndSettle();
    expect(find.text('Detail lowongan'), findsNothing);
    expect(find.text('Agenda ini sudah diubah atau dihapus.'), findsOneWidget);
    expect(pending.value, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('kategori dan filter remote tetap bekerja pada layar kecil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = JobStore(await SharedPreferences.getInstance())
      ..onboardingComplete = true
      ..useDemo();
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(LangkahKerjaApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eksplorasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desain'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Junior UI/UX Designer'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Junior UI/UX Designer'), findsOneWidget);
    expect(find.text('Flutter Developer Intern'), findsNothing);
    await tester.tap(find.text('Teknologi'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter lowongan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kerja remote'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Kerja remote'));
    await tester.tap(find.text('Tampilkan lowongan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Belum ada yang cocok'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Belum ada yang cocok'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nama panggilan'), findsOneWidget);
    await tester.tap(find.text('Lamaran'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Langkahmu dimulai di sini'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Langkahmu dimulai di sini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('teks besar tetap dapat digunakan pada layar 320 piksel', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = JobStore(await SharedPreferences.getInstance())..useDemo();
    await tester.pumpWidget(LangkahKerjaApp(store: store));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai melangkah'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in ['Eksplorasi', 'Lamaran', 'Profil']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });
  testWidgets(
    'alur demo: buka lowongan, simpan favorit, lalu catat interview',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = JobStore(await SharedPreferences.getInstance())
        ..onboardingComplete = true
        ..useDemo();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(LangkahKerjaApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eksplorasi'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Junior UI/UX Designer'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Junior UI/UX Designer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Simpan favorit'));
      await tester.pumpAndSettle();
      expect(store.saved.length, 1);
      await tester.scrollUntilVisible(
        find.text('Status lamaran'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byType(DropdownButtonFormField<ApplicationStatus>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Interview').last);
      await tester.pumpAndSettle();
      expect(store.applications.values.single.label, 'Interview');
      expect(tester.takeException(), isNull);
    },
  );
}
