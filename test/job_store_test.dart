import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:langkah_kerja/models/job.dart';
import 'package:langkah_kerja/services/job_store.dart';
import 'package:langkah_kerja/services/job_api.dart';
import 'package:langkah_kerja/models/user_data.dart';

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
      expect(restored.saved, isEmpty);
      expect(restored.applicationJobs, contains(demoJobs.first.id));
      await restored.untrack(demoJobs.first.id);
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
  test(
    'batas karakter Unicode sesuai input dan tetap dapat dipulihkan',
    () async {
      String repeat(int count) => List.filled(count, '👨‍👩‍👧‍👦').join();
      final prefs = await SharedPreferences.getInstance();
      final store = JobStore(prefs);
      final job = Job(
        id: 'manual-unicode',
        title: repeat(200),
        company: repeat(200),
        location: 'Medan',
        description: '',
        url: '',
        source: 'Catatan pribadi',
      );
      await store.preferences(repeat(80), repeat(500), repeat(150));
      await store.track(job, ApplicationStatus.applied, note: repeat(10000));
      await store.rememberSearch(repeat(250));
      await store.saveSearch(SavedSearch(name: repeat(60), query: repeat(250)));
      final restored = JobStore(prefs)..restore();
      expect(restored.storageError, isNull);
      expect(restored.name, store.name);
      expect(restored.notes[job.id], repeat(10000));
      expect(restored.applicationJobs[job.id]?.title, job.title);
      final imported = JobStore(prefs);
      await imported.importBackup(restored.exportBackup());
      expect(imported.skills, store.skills);
      expect(imported.savedSearches.single.query, repeat(250));
    },
  );
  test(
    'pencarian terlalu panjang tidak merusak data yang dapat dipulihkan',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final store = JobStore(prefs);
      await store.track(
        demoJobs.first,
        ApplicationStatus.applied,
        note: 'Tetap tersimpan',
      );
      final longQuery = List.filled(251, 'x').join();
      await store.rememberSearch(longQuery);
      await expectLater(
        store.saveSearch(SavedSearch(name: 'Uji', query: longQuery)),
        throwsFormatException,
      );
      final restored = JobStore(prefs)..restore();
      expect(restored.storageError, isNull);
      expect(restored.notes[demoJobs.first.id], 'Tetap tersimpan');
      expect(restored.recentSearches, isEmpty);
      expect(restored.savedSearches, isEmpty);
    },
  );
  test('status dan catatan yang rusak ditangani tanpa crash', () async {
    SharedPreferences.setMockInitialValues({'langkahkerja.v1': '{broken'});
    final store = JobStore(await SharedPreferences.getInstance())..restore();
    expect(store.storageError, isNotNull);
    expect(store.saved, isEmpty);
  });
  test(
    'riwayat hanya bertambah saat status berubah dan agenda ikut cadangan',
    () async {
      final store = JobStore(await SharedPreferences.getInstance());
      await store.track(demoJobs.first, ApplicationStatus.applied);
      await store.track(
        demoJobs.first,
        ApplicationStatus.applied,
        note: 'Catatan baru',
      );
      await store.track(demoJobs.first, ApplicationStatus.interview);
      await store.setFollowUp(demoJobs.first.id, DateTime(2027, 1, 1, 9));
      await store.saveSearch(
        const SavedSearch(
          name: 'Design Jakarta',
          query: 'design',
          location: 'Jakarta',
          remote: true,
        ),
      );
      final restored = JobStore(await SharedPreferences.getInstance());
      await restored.importBackup(store.exportBackup());
      expect(restored.timeline[demoJobs.first.id]?.length, 2);
      expect(restored.followUps[demoJobs.first.id], DateTime(2027, 1, 1, 9));
      expect(restored.savedSearches.single.remote, isTrue);
      expect(restored.ownerId, isNull);
      expect(restored.notes[demoJobs.first.id], 'Catatan baru');
    },
  );
  test('cadangan rusak ditolak secara atomik', () async {
    final store = JobStore(await SharedPreferences.getInstance());
    await store.toggleSave(demoJobs.first);
    final before = store.exportBackup();
    await expectLater(
      store.importBackup(
        '{"app":"LangkahKerja","schema":2,"saved":[{"slug":"bad"}]}',
      ),
      throwsFormatException,
    );
    expect(store.saved.keys, [demoJobs.first.id]);
    expect(
      store.exportBackup().split('exportedAt').first,
      before.split('exportedAt').first,
    );
  });
  test(
    'cache berhasil dimuat saat jaringan putus dan pagination deduplikasi',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final api = FakeApi();
      final store = JobStore(prefs, api: api);
      await store.load();
      await store.load(more: true);
      expect(store.jobs.length, 2);
      final restored = JobStore(prefs, api: api)..restore();
      expect(restored.jobs.length, 2);
      api.offline = true;
      await restored.load();
      expect(restored.jobs.length, 2);
      expect(restored.error, contains('Data terakhir'));
    },
  );
  test('hapus data menghapus cadangan internal dan metadata pemilik', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = JobStore(prefs);
    await store.track(
      demoJobs.first,
      ApplicationStatus.interview,
      note: 'Rahasia',
    );
    store.ownerId = 'owner';
    await store.clearPersonal();
    final restored = JobStore(prefs)..restore();
    expect(restored.applicationJobs, isEmpty);
    expect(restored.ownerId, isNull);
    expect(prefs.getString('langkahkerja.v1'), isNull);
    expect(store.exportBackup(), isNot(contains('Rahasia')));
  });
}

class FakeApi implements JobApi {
  bool offline = false;
  @override
  Future<JobPage> fetch(int page) async {
    if (offline) throw Exception('Offline');
    return JobPage(
      page == 1 ? [demoJobs.first] : [demoJobs.first, demoJobs[1]],
      page == 1,
    );
  }
}
