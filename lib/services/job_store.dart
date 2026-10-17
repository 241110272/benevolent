import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/job.dart';

class JobStore extends ChangeNotifier {
  JobStore(this.prefs);
  final SharedPreferences prefs;
  List<Job> jobs = [];
  final Map<String, Job> saved = {};
  final Map<String, ApplicationStatus> applications = {};
  final Map<String, String> notes = {};
  bool loading = false, demoMode = false, hasMore = false;
  int page = 0;
  String? error, storageError;
  String name = '', skills = '', location = '';

  void restore() {
    try {
      final data =
          jsonDecode(prefs.getString('langkahkerja.v1') ?? '{}')
              as Map<String, dynamic>;
      name = data['name'] as String? ?? '';
      skills = data['skills'] as String? ?? '';
      location = data['location'] as String? ?? '';
      for (final value in data['saved'] as List? ?? []) {
        final job = Job.fromJson(Map<String, dynamic>.from(value as Map));
        saved[job.id] = job;
      }
      (data['applications'] as Map? ?? {}).forEach((key, value) {
        final status = ApplicationStatus.values
            .where((s) => s.name == value)
            .firstOrNull;
        if (status != null && saved.containsKey(key)) {
          applications[key as String] = status;
        }
      });
      notes.addAll(Map<String, String>.from(data['notes'] as Map? ?? {}));
    } catch (_) {
      storageError =
          'Data lokal tidak dapat dibaca. Perubahan baru akan disimpan ulang.';
    }
  }

  Future<void> persist() async {
    try {
      final ok = await prefs.setString(
        'langkahkerja.v1',
        jsonEncode({
          'name': name,
          'skills': skills,
          'location': location,
          'saved': saved.values.map((j) => j.toJson()).toList(),
          'applications': applications.map((k, v) => MapEntry(k, v.name)),
          'notes': notes,
        }),
      );
      storageError = ok
          ? null
          : 'Penyimpanan gagal. Coba lagi sebelum menutup aplikasi.';
    } catch (_) {
      storageError = 'Penyimpanan gagal. Coba lagi sebelum menutup aplikasi.';
    }
    notifyListeners();
  }

  Future<void> load({bool more = false}) async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    final target = more ? page + 1 : 1;
    try {
      final response = await http
          .get(
            Uri.https('www.arbeitnow.com', '/api/job-board-api', {
              'page': '$target',
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final incoming = (data['data'] as List)
          .map((j) => Job.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      jobs = {
        for (final j in [...(more ? jobs : <Job>[]), ...incoming]) j.id: j,
      }.values.toList();
      page = target;
      hasMore = (data['links'] as Map?)?['next'] != null;
      demoMode = false;
    } catch (_) {
      error =
          'Belum bisa mengambil lowongan. Periksa koneksi lalu coba lagi, atau gunakan mode demo.';
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

  Future<void> toggleSave(Job job) async {
    if (saved.containsKey(job.id)) {
      if (applications.containsKey(job.id)) return;
      saved.remove(job.id);
    } else {
      saved[job.id] = job;
    }
    notifyListeners();
    await persist();
  }

  Future<void> track(Job job, ApplicationStatus status, {String? note}) async {
    saved[job.id] = job;
    applications[job.id] = status;
    if (note != null) notes[job.id] = note;
    notifyListeners();
    await persist();
  }

  Future<void> untrack(String id) async {
    applications.remove(id);
    notes.remove(id);
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

  List<Job> search(String query, {bool remote = false, bool matching = false}) {
    final words = skills
        .toLowerCase()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return jobs.where((j) {
      final text =
          '${j.title} ${j.company} ${j.location} ${j.tags.join(' ')} ${j.description}'
              .toLowerCase();
      return text.contains(query.toLowerCase().trim()) &&
          (!remote || j.remote) &&
          (!matching ||
              ((words.isEmpty || words.any(text.contains)) &&
                  (location.isEmpty ||
                      j.location.toLowerCase().contains(
                        location.toLowerCase(),
                      ))));
    }).toList();
  }
}
