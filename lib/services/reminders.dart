import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder_target.dart';

class ReminderService {
  static final instance = ReminderService();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  final pendingOpen = ValueNotifier<ReminderTarget?>(null);

  void _notificationTapped(NotificationResponse response) {
    pendingOpen.value = ReminderTarget.parse(response.payload);
  }

  bool get supported =>
      !kIsWeb &&
      [
        TargetPlatform.android,
        TargetPlatform.iOS,
      ].contains(defaultTargetPlatform);
  int _id(String jobId) =>
      jobId.codeUnits.fold<int>(0, (a, b) => ((a * 31) + b) & 0x7fffffff);

  Future<void> initialize() async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      onDidReceiveNotificationResponse: _notificationTapped,
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse != null) {
      _notificationTapped(launch!.notificationResponse!);
    }
  }

  Future<bool> schedule(String id, String title, DateTime at) async {
    if (!supported || !at.isAfter(DateTime.now())) return false;
    await initialize();
    bool allowed = false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      allowed = await android?.requestNotificationsPermission() ?? false;
    } else {
      allowed =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    if (!allowed) return false;
    final pending = await _plugin.pendingNotificationRequests();
    if (pending.length >= 50 && !pending.any((p) => p.id == _id(id))) {
      throw StateError('Maksimal 50 pengingat aktif.');
    }
    await _plugin.zonedSchedule(
      id: _id(id),
      title: 'Waktunya melangkah lagi',
      body: 'Buka LangkahKerja untuk melihat agenda lamaranmu.',
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'follow_up',
          'Pengingat lamaran',
          channelDescription:
              'Pengingat follow-up dan interview yang kamu atur sendiri',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.private,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$id|${at.millisecondsSinceEpoch}',
    );
    return true;
  }

  Future<void> cancel(String id) async {
    if (supported) {
      await initialize();
      await _plugin.cancel(id: _id(id));
    }
  }

  Future<void> cancelAll() async {
    pendingOpen.value = null;
    if (supported) {
      await initialize();
      await _plugin.cancelAll();
    }
  }

  Future<void> reconcile(Map<String, DateTime> agenda) async {
    if (!supported) return;
    await initialize();
    for (final request in await _plugin.pendingNotificationRequests()) {
      final payload = request.payload ?? '';
      final split = payload.lastIndexOf('|');
      if (split < 0) {
        await _plugin.cancel(id: request.id);
        continue;
      }
      final id = payload.substring(0, split);
      final expected = int.tryParse(payload.substring(split + 1));
      if (agenda[id]?.millisecondsSinceEpoch != expected) {
        await _plugin.cancel(id: request.id);
      }
    }
  }
}
