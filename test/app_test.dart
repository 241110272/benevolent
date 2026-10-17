import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langkah_kerja/main.dart';
import 'package:langkah_kerja/services/job_store.dart';
import 'package:langkah_kerja/models/job.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  testWidgets('kategori dan filter remote tetap bekerja pada layar kecil', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = JobStore(await SharedPreferences.getInstance())..useDemo();
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
    await tester.tap(find.byTooltip('Filter lowongan'));
    await tester.pumpAndSettle();
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
    expect(find.text('Langkahmu dimulai di sini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'alur demo: buka lowongan, simpan favorit, lalu catat interview',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = JobStore(await SharedPreferences.getInstance())..useDemo();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(LangkahKerjaApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eksplorasi'));
      await tester.pumpAndSettle();
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
