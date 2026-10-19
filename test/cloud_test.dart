import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:langkah_kerja/models/job.dart';
import 'package:langkah_kerja/services/cloud.dart';
import 'package:langkah_kerja/services/job_store.dart';
import 'package:langkah_kerja/main.dart';
import 'package:langkah_kerja/screens/detail.dart';

void main() {
  testWidgets(
    'pergantian akun menutup route detail yang menyimpan snapshot pribadi',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const uidA = '11111111-1111-4111-8111-111111111111';
      const uidB = '22222222-2222-4222-8222-222222222222';
      final store = JobStore(await SharedPreferences.getInstance())
        ..ownerId = uidA
        ..onboardingComplete = true
        ..useDemo();
      const privateJob = Job(
        id: 'manual-private-a',
        title: 'Catatan pribadi akun A',
        company: 'Perusahaan catatan A',
        location: 'Medan',
        description: '',
        url: '',
        source: 'Catatan pribadi',
      );
      await store.track(
        privateJob,
        ApplicationStatus.interview,
        note: 'Rahasia A',
      );
      final cloud = TestAccountController(store)..current = testUser(uidA);
      await tester.pumpWidget(LangkahKerjaApp(store: store, cloud: cloud));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Beranda'))).push(
        MaterialPageRoute<void>(
          builder: (_) => JobDetail(job: privateJob, store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(privateJob.title), findsOneWidget);
      cloud.current = testUser(uidB);
      cloud.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(JobDetail), findsNothing);
      expect(find.text(privateJob.title), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      cloud.dispose();
      store.dispose();
    },
  );
  test(
    'error stream autentikasi tidak menghapus data atau menjadi crash',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = JobStore(await SharedPreferences.getInstance());
      await store.track(
        demoJobs.first,
        ApplicationStatus.applied,
        note: 'Tetap ada',
      );
      final events = StreamController<AuthState>(sync: true);
      final cloud = CloudController(store, null, authEvents: events.stream);
      events.addError(StateError('Offline token refresh'));
      expect(cloud.error, contains('Sesi belum dapat diperbarui'));
      expect(store.notes[demoJobs.first.id], 'Tetap ada');
      cloud.dispose();
      await events.close();
      store.dispose();
    },
  );

  for (final useDevice in [true, false]) {
    test(
      'respons akun lama ditolak saat ${useDevice ? 'unggah' : 'pulihkan'} setelah sesi berganti',
      () async {
        SharedPreferences.setMockInitialValues({});
        final remote = Completer<http.Response>();
        final requested = Completer<http.Request>();
        var uploads = 0;
        final client = SupabaseClient(
          'https://example.supabase.co',
          'public-test-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/user_state')) {
              requested.complete(request);
              return remote.future;
            }
            uploads++;
            return http.Response(
              '{"revision":1}',
              200,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }),
        );
        const uidA = '11111111-1111-4111-8111-111111111111';
        const uidB = '22222222-2222-4222-8222-222222222222';
        await setTestSession(client, uidA);
        final store = JobStore(await SharedPreferences.getInstance())
          ..ownerId = uidA;
        await store.preferences('Data perangkat A', '', '');
        final cloud = CloudController(
          store,
          client,
          authEvents: const Stream.empty(),
        );
        final action = useDevice ? cloud.useDevice() : cloud.useCloud();
        final request = await requested.future;
        await setTestSession(client, uidB);
        remote.complete(
          http.Response(
            jsonEncode({
              'payload': {...store.userPayload, 'name': 'Respons akun A'},
              'revision': 9,
            }),
            200,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        );
        await action;
        expect(uploads, 0);
        expect(store.name, 'Data perangkat A');
        expect(store.ownerId, uidA);
        expect(store.cloudRevision, 0);
        cloud.dispose();
        store.dispose();
        await client.dispose();
      },
    );
  }
  test(
    'sinkronisasi mengirim revisi dan konflik tidak menghapus catatan lokal',
    () async {
      SharedPreferences.setMockInitialValues({});
      const uid = '11111111-1111-4111-8111-111111111111';
      var rejectRevision = false;
      final requests = <Map<String, dynamic>>[];
      final transport = MockClient((request) async {
        if (request.url.path.endsWith('/rpc/sync_user_state')) {
          requests.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode(
              rejectRevision
                  ? {'code': '40001', 'message': 'Revision conflict'}
                  : {'revision': 1},
            ),
            rejectRevision ? 409 : 200,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        }
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      String encode(Map value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final exp =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final jwt =
          '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': uid, 'exp': exp, 'role': 'authenticated'})}.test';
      await client.auth.setInitialSession(
        jsonEncode({
          'access_token': jwt,
          'refresh_token': 'test-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': uid,
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'user@example.com',
            'created_at': '2026-01-01T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          },
        }),
      );
      final store = JobStore(await SharedPreferences.getInstance())
        ..ownerId = uid;
      await store.track(
        demoJobs.first,
        ApplicationStatus.applied,
        note: 'Jangan hilang',
      );
      final cloud = CloudController(store, client);
      await cloud.sync();
      while (cloud.busy) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      expect(store.cloudRevision, 1);
      expect(store.cloudDirty, isFalse);
      expect(requests.first['expected_revision'], 0);
      expect(requests.first, isNot(contains('user_id')));
      rejectRevision = true;
      await store.track(demoJobs.first, ApplicationStatus.interview);
      await cloud.sync();
      expect(cloud.conflict, isTrue);
      expect(store.cloudDirty, isTrue);
      expect(store.notes[demoJobs.first.id], 'Jangan hilang');
      expect(
        store.applications[demoJobs.first.id],
        ApplicationStatus.interview,
      );
      cloud.dispose();
      store.dispose();
      await client.dispose();
    },
  );
}

class TestAccountController extends CloudController {
  TestAccountController(JobStore store) : super(store, null);
  User? current;
  @override
  User? get user => current;
  @override
  Future<void> start() async {}
}

User testUser(String uid) => User.fromJson({
  'id': uid,
  'aud': 'authenticated',
  'role': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
})!;

Future<void> setTestSession(SupabaseClient client, String uid) async {
  String encode(Map value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final exp =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  final jwt =
      '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'sub': uid, 'exp': exp, 'role': 'authenticated'})}.test';
  await client.auth.setInitialSession(
    jsonEncode({
      'access_token': jwt,
      'refresh_token': 'test-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': uid,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'user@example.com',
        'created_at': '2026-01-01T00:00:00Z',
        'app_metadata': {},
        'user_metadata': {},
      },
    }),
  );
}
