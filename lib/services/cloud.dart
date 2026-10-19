import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'job_store.dart';
import 'reminders.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();
  static const _storage = FlutterSecureStorage();
  static const _key = 'langkahkerja.auth.session';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await _storage.containsKey(key: _key);
  @override
  Future<String?> accessToken() => _storage.read(key: _key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}

class CloudController extends ChangeNotifier {
  CloudController(this.store, this.client, {Stream<AuthState>? authEvents}) {
    store.addListener(_localChanged);
    _auth = (authEvents ?? client?.auth.onAuthStateChange)?.listen(
      (_) {
        // Notify route guards immediately, before asynchronous local cleanup.
        notifyListeners();
        unawaited(start());
      },
      onError: (Object _, StackTrace _) {
        error = 'Sesi belum dapat diperbarui. Periksa koneksi lalu coba lagi.';
        notifyListeners();
      },
    );
  }
  final JobStore store;
  final SupabaseClient? client;
  StreamSubscription<AuthState>? _auth;
  Timer? _timer;
  bool busy = false, conflict = false;
  bool _disposed = false;
  bool _sameAccount(String uid) => !_disposed && user?.id == uid;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  String? error;
  bool get configured => client != null;
  User? get user => client?.auth.currentUser;
  bool get needsChoice => user != null && store.ownerId != user!.id;
  bool get locked => store.ownerId != null && user?.id != store.ownerId;

  Future<void> start() async {
    try {
      await _accountChanged();
    } catch (_) {
      error = 'Belum dapat membuka data akun. Data lokal tetap disimpan.';
      notifyListeners();
    }
  }

  Future<void> _accountChanged() async {
    if (user != null && store.ownerId != null && store.ownerId != user!.id) {
      // Never expose or upload another account's local records.
      await store.clearPersonal();
      try {
        await ReminderService.instance.cancelAll();
      } catch (_) {
        /* Retry cleanup when the app resumes. */
      }
    }
    if (user != null && !needsChoice) await sync();
    notifyListeners();
  }

  void _localChanged() {
    if (user == null ||
        needsChoice ||
        busy ||
        conflict ||
        !store.cloudDirty ||
        store.storageError != null) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), () => unawaited(sync()));
  }

  Future<void> sendCode(String email) async {
    if (client == null) throw StateError('Layanan akun belum tersedia.');
    await client!.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<void> verifyCode(String email, String code) async {
    if (client == null) throw StateError('Layanan akun belum tersedia.');
    await client!.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _remote() => client!
      .from('user_state')
      .select('payload,revision,updated_at')
      .eq('user_id', user!.id)
      .maybeSingle()
      .timeout(const Duration(seconds: 20));

  Future<void> useCloud() async {
    if (user == null || busy) return;
    final uid = user!.id;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final remote = await _remote();
      if (!_sameAccount(uid)) return;
      await store.applyCloud(
        Map<String, dynamic>.from(remote?['payload'] as Map? ?? {}),
        (remote?['revision'] as num?)?.toInt() ?? 0,
        uid,
      );
      conflict = false;
    } catch (_) {
      error = 'Tidak dapat memulihkan data akun. Data perangkat belum diganti.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> useDevice() async {
    if (user == null || busy) return;
    final uid = user!.id;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final remote = await _remote();
      if (!_sameAccount(uid)) return;
      final payload = store.userPayload;
      final response = await client!
          .rpc(
            'sync_user_state',
            params: {
              'expected_revision': (remote?['revision'] as num?)?.toInt() ?? 0,
              'new_payload': payload,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!_sameAccount(uid)) return;
      store.ownerId = uid;
      store.cloudRevision = (response['revision'] as num).toInt();
      store.cloudDirty = jsonEncode(payload) != jsonEncode(store.userPayload);
      store.lastCloudSync = DateTime.now();
      conflict = false;
      await store.persist(markDirty: false);
    } on PostgrestException catch (e) {
      conflict = e.code == '40001';
      error = conflict
          ? 'Data akun baru berubah di perangkat lain. Pilih ulang data yang ingin dipakai.'
          : 'Belum bisa mengunggah data. Coba lagi.';
    } catch (_) {
      error = 'Tidak bisa menghubungkan akun. Data perangkat tetap tersimpan.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> sync() async {
    if (user == null || needsChoice || busy || store.storageError != null) {
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    final uid = user!.id;
    try {
      if (store.cloudDirty) {
        final payload = store.userPayload;
        final response = await client!
            .rpc(
              'sync_user_state',
              params: {
                'expected_revision': store.cloudRevision,
                'new_payload': payload,
              },
            )
            .timeout(const Duration(seconds: 20));
        if (!_sameAccount(uid)) return;
        store.cloudRevision = (response['revision'] as num).toInt();
        store.cloudDirty = jsonEncode(payload) != jsonEncode(store.userPayload);
        store.lastCloudSync = DateTime.now();
        await store.persist(markDirty: false);
      } else {
        final remote = await _remote();
        if (remote != null && _sameAccount(uid) && !store.cloudDirty) {
          await store.applyCloud(
            Map<String, dynamic>.from(remote['payload'] as Map),
            (remote['revision'] as num).toInt(),
            uid,
          );
        }
      }
      conflict = false;
    } on PostgrestException catch (e) {
      conflict = e.code == '40001';
      error = conflict
          ? 'Ada perubahan dari perangkat lain. Pilih versi data sebelum melanjutkan.'
          : 'Sinkronisasi belum berhasil. Data lokal tetap tersimpan.';
    } catch (_) {
      error =
          'Sedang offline atau layanan belum tersedia. Perubahan tetap tersimpan di perangkat.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (client == null) return;
    _timer?.cancel();
    String? revokeError;
    try {
      await client!.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      revokeError =
          'Perangkat sudah keluar. Pencabutan sesi di server belum dikonfirmasi.';
    } finally {
      await store.clearPersonal();
    }
    error = revokeError;
    conflict = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (client == null || user == null) {
      throw StateError('Masuk terlebih dahulu.');
    }
    final response = await client!.functions
        .invoke('delete-account', body: {})
        .timeout(const Duration(seconds: 30));
    if (response.status != 200 || (response.data as Map?)?['deleted'] != true) {
      throw StateError(
        'Penghapusan belum dikonfirmasi server. Masuk ulang lalu coba lagi.',
      );
    }
    await signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    store.removeListener(_localChanged);
    _timer?.cancel();
    _auth?.cancel();
    super.dispose();
  }
}
