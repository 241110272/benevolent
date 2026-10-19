import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:characters/characters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job.dart';
import '../models/user_data.dart';
import 'job_api.dart';
import 'persistence.dart';

class JobStore extends ChangeNotifier {
  JobStore(this.prefs, {AppPersistence? persistence, JobApi? api})
    : persistence = persistence ?? AppPersistence(prefs),
      api = api ?? IndonesiaJobApi(null);
  final SharedPreferences prefs;
  final AppPersistence persistence;
  final JobApi api;
  List<Job> jobs = [];
  final Map<String, Job> saved = {}, applicationJobs = {};
  final Map<String, ApplicationStatus> applications = {};
  final Map<String, String> notes = {};
  final Map<String, List<StatusChange>> timeline = {};
  final Map<String, DateTime> followUps = {};
  final List<String> recentSearches = [];
  final List<SavedSearch> savedSearches = [];
  final Set<String> completedChecklist = {};
  bool loading = false,
      demoMode = false,
      hasMore = false,
      onboardingComplete = false;
  bool cloudDirty = false;
  int page = 0, cloudRevision = 0;
  String? error, storageError, ownerId;
  DateTime? lastFetched, lastCloudSync;
  String name = '', skills = '', location = '';
  Future<void> _writes = Future.value();
  String? _corruptSnapshot;
  static const _cacheKey = 'langkahkerja.indonesia-cache.v1';

  bool get hasPersonalData =>
      saved.isNotEmpty ||
      applications.isNotEmpty ||
      name.isNotEmpty ||
      savedSearches.isNotEmpty;
  bool get fromCache => lastFetched != null && !demoMode;

  void restore() {
    final raw =
        persistence.initialState ??
        prefs.getString(AppPersistence.stateKey) ??
        prefs.getString('langkahkerja.v1');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _apply(data);
        ownerId = data['ownerId'] as String?;
        cloudRevision = (data['cloudRevision'] as num?)?.toInt() ?? 0;
        cloudDirty = data['cloudDirty'] == true;
        lastCloudSync = DateTime.tryParse('${data['lastCloudSync']}');
        onboardingComplete =
            data['onboardingComplete'] == true || !data.containsKey('schema');
      } catch (_) {
        _corruptSnapshot = raw;
        storageError =
            'Data lokal tidak dapat dibaca. Data asli tetap disimpan; coba pulihkan dari cadangan.';
      }
    }
    try {
      final cache = jsonDecode(prefs.getString(_cacheKey) ?? '{}') as Map;
      jobs = _readJobs(cache['jobs']).values.toList();
      page = (cache['page'] as num?)?.toInt() ?? 0;
      hasMore = cache['hasMore'] == true;
      lastFetched = DateTime.tryParse('${cache['at']}');
    } catch (_) {
      /* A corrupt public cache must not affect personal records. */
    }
  }

  Map<String, Job> _readJobs(dynamic values) {
    final result = <String, Job>{};
    if (values is! List) return result;
    if (values.length > 2000) {
      throw const FormatException('Terlalu banyak lowongan');
    }
    for (final value in values) {
      if (value is! Map) throw const FormatException('Format lowongan salah');
      final job = Job.fromJson(Map<String, dynamic>.from(value));
      if (job.description.length > 200000) {
        throw const FormatException('Deskripsi terlalu besar');
      }
      result[job.id] = job;
    }
    return result;
  }

  void _apply(Map<String, dynamic> data) {
    final newSaved = _readJobs(data['saved']);
    final newRecords = _readJobs(data['applicationJobs']);
    final statuses = <String, ApplicationStatus>{};
    for (final entry in (data['applications'] as Map? ?? {}).entries) {
      final status = ApplicationStatus.values
          .where((s) => s.name == entry.value)
          .firstOrNull;
      if (status != null &&
          (newSaved.containsKey(entry.key) ||
              newRecords.containsKey(entry.key))) {
        statuses[entry.key as String] = status;
        newRecords[entry.key as String] ??= newSaved[entry.key]!;
      }
    }
    final newNotes = Map<String, String>.from(data['notes'] as Map? ?? {});
    if (newNotes.values.any((n) => n.characters.length > 10000)) {
      throw const FormatException('Catatan terlalu panjang');
    }
    final newTimeline = <String, List<StatusChange>>{};
    for (final entry in (data['timeline'] as Map? ?? {}).entries) {
      if (entry.value is! List) {
        throw const FormatException('Format riwayat salah');
      }
      newTimeline[entry.key as String] = (entry.value as List)
          .map(StatusChange.parse)
          .whereType<StatusChange>()
          .take(100)
          .toList();
    }
    final newFollowUps = <String, DateTime>{};
    for (final entry in (data['followUps'] as Map? ?? {}).entries) {
      final at = DateTime.tryParse('${entry.value}');
      if (at != null && statuses.containsKey(entry.key)) {
        newFollowUps[entry.key as String] = at.toLocal();
      }
    }
    final newSearches = (data['savedSearches'] as List? ?? [])
        .map((e) => SavedSearch.fromJson(e as Map))
        .take(20)
        .toList();
    final newRecent = (data['recentSearches'] as List? ?? [])
        .whereType<String>()
        .take(10)
        .toList();
    if (newSearches.any(
      (s) =>
          s.name.characters.length > 60 ||
          s.query.characters.length > 250 ||
          s.location.characters.length > 150 ||
          s.jobType.characters.length > 300,
    )) {
      throw const FormatException('Pencarian tersimpan terlalu panjang');
    }
    if (newRecent.any((q) => q.characters.length > 250)) {
      throw const FormatException('Kata pencarian terlalu panjang');
    }
    final checklist = (data['checklist'] as List? ?? [])
        .whereType<String>()
        .toSet();
    final newName = '${data['name'] ?? ''}',
        newSkills = '${data['skills'] ?? ''}',
        newLocation = '${data['location'] ?? ''}';
    if (newName.characters.length > 80 ||
        newSkills.characters.length > 500 ||
        newLocation.characters.length > 150) {
      throw const FormatException('Preferensi terlalu panjang');
    }
    saved
      ..clear()
      ..addAll(newSaved);
    applicationJobs
      ..clear()
      ..addAll(newRecords);
    applications
      ..clear()
      ..addAll(statuses);
    notes
      ..clear()
      ..addAll(newNotes);
    timeline
      ..clear()
      ..addAll(newTimeline);
    followUps
      ..clear()
      ..addAll(newFollowUps);
    savedSearches
      ..clear()
      ..addAll(newSearches);
    recentSearches
      ..clear()
      ..addAll(newRecent);
    completedChecklist
      ..clear()
      ..addAll(checklist);
    name = newName;
    skills = newSkills;
    location = newLocation;
  }

  Map<String, dynamic> get userPayload => {
    'app': 'LangkahKerja',
    'schema': 2,
    'name': name,
    'skills': skills,
    'location': location,
    'saved': saved.values.map((j) => j.toJson()).toList(),
    'applicationJobs': applicationJobs.values.map((j) => j.toJson()).toList(),
    'applications': applications.map((k, v) => MapEntry(k, v.name)),
    'notes': Map.of(notes),
    'timeline': timeline.map(
      (k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()),
    ),
    'followUps': followUps.map(
      (k, v) => MapEntry(k, v.toUtc().toIso8601String()),
    ),
    'recentSearches': List.of(recentSearches),
    'savedSearches': savedSearches.map((e) => e.toJson()).toList(),
    'checklist': completedChecklist.toList(),
  };

  Future<void> persist({bool markDirty = true}) {
    if (markDirty) cloudDirty = true;
    final document = jsonEncode({
      ...userPayload,
      'ownerId': ownerId,
      'cloudRevision': cloudRevision,
      'cloudDirty': cloudDirty,
      'onboardingComplete': onboardingComplete,
      'lastCloudSync': lastCloudSync?.toUtc().toIso8601String(),
    });
    final next = _writes.then((_) async {
      try {
        if (_corruptSnapshot != null) {
          final ok = await prefs.setString(
            'langkahkerja.recovery',
            _corruptSnapshot!,
          );
          if (!ok) throw StateError('Cannot preserve recovery copy');
          _corruptSnapshot = null;
        }
        await persistence.write(document);
        storageError = null;
      } catch (_) {
        storageError =
            'Belum tersimpan di perangkat. Coba simpan lagi atau ekspor cadangan sebelum menutup aplikasi.';
      }
      notifyListeners();
    });
    _writes = next;
    return next;
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    final target = more && !demoMode ? page + 1 : 1;
    try {
      final result = await api.fetch(target);
      jobs = {
        for (final j in [
          ...(more && !demoMode ? jobs : <Job>[]),
          ...result.jobs,
        ])
          j.id: j,
      }.values.toList();
      page = target;
      hasMore = result.hasMore;
      demoMode = false;
      lastFetched = DateTime.now();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'jobs': jobs.take(40).map((j) => j.toJson()).toList(),
          'page': 1,
          'hasMore': hasMore || jobs.length > 40,
          'at': lastFetched!.toUtc().toIso8601String(),
        }),
      );
    } on FeedNotConfigured {
      error =
          'Sumber lowongan Indonesia belum terhubung. Mode demo tersedia untuk mencoba fitur; data demo bukan lowongan aktif.';
    } catch (_) {
      error = jobs.isNotEmpty && !demoMode
          ? 'Tidak bisa memperbarui lowongan. Data terakhir masih bisa dibaca; status lowongan dapat berubah di sumber aslinya.'
          : 'Tidak dapat memuat lowongan. Periksa koneksi lalu coba lagi.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void useDemo() {
    jobs = List.of(demoJobs);
    demoMode = true;
    hasMore = false;
    error = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await persist(markDirty: false);
  }

  Future<void> toggleSave(Job job) async {
    if (saved.containsKey(job.id)) {
      saved.remove(job.id);
    } else {
      saved[job.id] = job;
    }
    notifyListeners();
    await persist();
  }

  Future<void> track(Job job, ApplicationStatus status, {String? note}) async {
    applicationJobs[job.id] = job;
    if (applications[job.id] != status) {
      timeline
          .putIfAbsent(job.id, () => [])
          .insert(0, StatusChange(status, DateTime.now()));
    }
    if ((timeline[job.id]?.length ?? 0) > 100) timeline[job.id]!.removeLast();
    applications[job.id] = status;
    if (note != null) notes[job.id] = note;
    notifyListeners();
    await persist();
  }

  Future<void> untrack(String id) async {
    applications.remove(id);
    applicationJobs.remove(id);
    notes.remove(id);
    timeline.remove(id);
    followUps.remove(id);
    notifyListeners();
    await persist();
  }

  Future<void> setFollowUp(String id, DateTime? date) async {
    if (!applications.containsKey(id)) return;
    if (date == null) {
      followUps.remove(id);
    } else {
      followUps[id] = date;
    }
    notifyListeners();
    await persist();
  }

  Future<void> preferences(
    String newName,
    String newSkills,
    String newLocation,
  ) async {
    name = newName.trim();
    skills = newSkills.trim();
    location = newLocation.trim();
    notifyListeners();
    await persist();
  }

  Future<void> rememberSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty || query.characters.length > 250) return;
    recentSearches
      ..remove(query)
      ..insert(0, query);
    if (recentSearches.length > 10) recentSearches.removeLast();
    await persist();
  }

  Future<void> saveSearch(SavedSearch value) async {
    if (value.name.characters.length > 60 ||
        value.query.characters.length > 250 ||
        value.location.characters.length > 150 ||
        value.jobType.characters.length > 300) {
      throw const FormatException(
        'Nama atau parameter pencarian terlalu panjang.',
      );
    }
    savedSearches.removeWhere((s) => s.name == value.name);
    savedSearches.insert(0, value);
    if (savedSearches.length > 20) savedSearches.removeLast();
    await persist();
  }

  Future<void> removeSearch(SavedSearch value) async {
    savedSearches.remove(value);
    await persist();
  }

  Future<void> toggleChecklist(String id) async {
    if (!completedChecklist.add(id)) completedChecklist.remove(id);
    await persist();
  }

  String exportBackup() => const JsonEncoder.withIndent('  ').convert({
    ...userPayload,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
  });
  Future<void> importBackup(String raw) async {
    if (utf8.encode(raw).length > 8 * 1024 * 1024) {
      throw const FormatException('Maksimal ukuran cadangan 8 MB.');
    }
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['app'] != 'LangkahKerja' ||
        data['schema'] != 2) {
      throw const FormatException(
        'Berkas bukan cadangan LangkahKerja yang didukung.',
      );
    }
    _apply(data);
    notifyListeners();
    await persist();
  }

  Future<void> applyCloud(
    Map<String, dynamic> payload,
    int revision,
    String uid,
  ) async {
    _apply(payload);
    ownerId = uid;
    cloudRevision = revision;
    cloudDirty = false;
    lastCloudSync = DateTime.now();
    notifyListeners();
    await persist(markDirty: false);
  }

  Future<void> clearPersonal({bool forgetAccount = true}) async {
    await _writes;
    await persistence.clear();
    _corruptSnapshot = null;
    _apply({});
    if (forgetAccount) {
      ownerId = null;
      cloudRevision = 0;
      cloudDirty = false;
      lastCloudSync = null;
    }
    await persist(markDirty: !forgetAccount);
    notifyListeners();
  }

  Future<void> clearCache() async {
    await prefs.remove(_cacheKey);
    jobs = [];
    lastFetched = null;
    page = 0;
    hasMore = false;
    demoMode = false;
    notifyListeners();
  }

  List<Job> search(
    String query, {
    bool remote = false,
    bool matching = false,
    String city = '',
    String type = '',
    int days = 0,
  }) {
    final words = skills
        .toLowerCase()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final terms = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((q) => q.isNotEmpty);
    final cutoff = days == 0
        ? null
        : DateTime.now()
                  .subtract(Duration(days: days))
                  .millisecondsSinceEpoch ~/
              1000;
    return jobs.where((j) {
      final text = j.searchableText;
      return terms.every(text.contains) &&
          (!remote || j.remote) &&
          (city.isEmpty ||
              j.location.toLowerCase().contains(city.toLowerCase())) &&
          (type.isEmpty ||
              j.jobTypes.any(
                (t) => t.toLowerCase().contains(type.toLowerCase()),
              )) &&
          (cutoff == null || (j.createdAt != null && j.createdAt! >= cutoff)) &&
          (!matching ||
              ((words.isEmpty || words.any(text.contains)) &&
                  (location.isEmpty ||
                      j.location.toLowerCase().contains(
                        location.toLowerCase(),
                      ))));
    }).toList();
  }
}
