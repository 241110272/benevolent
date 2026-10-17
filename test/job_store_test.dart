import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langkah_kerja/models/job.dart';
import 'package:langkah_kerja/services/job_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'favorit, status, catatan, dan preferensi bertahan setelah dimuat ulang',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = JobStore(prefs)..restore();
      await store.toggleSave(demoJobs.first);
      await store.track(
        demoJobs.first,
        ApplicationStatus.interview,
        note: 'Jumat 10.00',
      );
      await store.preferences('Sastra', 'Design, Figma', 'Jakarta');
      final restored = JobStore(prefs)..restore();
      expect(restored.saved[demoJobs.first.id]?.title, demoJobs.first.title);
      expect(
        restored.applications[demoJobs.first.id],
        ApplicationStatus.interview,
      );
      expect(restored.notes[demoJobs.first.id], 'Jumat 10.00');
      expect(restored.skills, 'Design, Figma');
      await restored.toggleSave(demoJobs.first);
      expect(restored.saved, contains(demoJobs.first.id));
      await restored.untrack(demoJobs.first.id);
      await restored.toggleSave(demoJobs.first);
      expect(restored.saved, isEmpty);
    },
  );
  test('pencarian menggabungkan query, remote, dan preferensi', () async {
    final store = JobStore(await SharedPreferences.getInstance())..useDemo();
    expect(store.search('flutter').single.id, 'demo-flutter');
    expect(store.search('', remote: true).length, 2);
    await store.preferences('', 'Figma, SQL', 'Jakarta');
    expect(store.search('', matching: true).single.id, 'demo-design');
    expect(store.search('flutter', remote: true), isEmpty);
  });
  test('status dan catatan yang rusak ditangani tanpa crash', () async {
    SharedPreferences.setMockInitialValues({'langkahkerja.v1': '{broken'});
    final store = JobStore(await SharedPreferences.getInstance())..restore();
    expect(store.storageError, isNotNull);
    expect(store.saved, isEmpty);
  });
}
