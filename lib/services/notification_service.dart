import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/doc.dart';
import '../utils/dates.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Bucharest'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();

      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<bool> requestPermissions() async {
    await init();
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      final a = await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      final i = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      final m = await mac?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return a == true || i == true || m == true || _ready;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncAll(List<Doc> docs, AppSettings settings) async {
    if (!_ready) return;
    for (final doc in docs) {
      await syncDoc(doc, settings);
    }
  }

  Future<void> syncDoc(Doc doc, AppSettings settings) async {
    if (!_ready) return;
    await cancelDoc(doc.id);
    final exp = tryParseIsoDate(doc.expira);
    if (exp == null) return;

    for (final daysBefore in settings.notifyDaysBefore) {
      final when = DateTime(
        exp.year,
        exp.month,
        exp.day,
        settings.notifyHour,
        settings.notifyMinute,
      ).subtract(Duration(days: daysBefore));
      if (when.isBefore(DateTime.now())) continue;

      final title = daysBefore == 0
          ? 'Document expiră azi'
          : daysBefore == 1
              ? 'Document expiră mâine'
              : 'Document expiră în $daysBefore zile';
      final body = '${doc.membru}: ${doc.nume} (${fmtData(doc.expira)})';

      try {
        await _plugin.zonedSchedule(
          _notifId(doc.id, daysBefore),
          title,
          body,
          tz.TZDateTime.from(when, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'docalert_expiry',
              'Expirare documente',
              channelDescription:
                  'Alerte înainte de expirarea documentelor familiei',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (_) {
        // Unele platforme (web/desktop) nu suportă programarea exactă.
      }
    }
  }

  Future<void> cancelDoc(String docId) async {
    if (!_ready) return;
    const possible = [0, 1, 3, 7, 14, 21, 30, 45, 60, 90];
    for (final d in possible) {
      try {
        await _plugin.cancel(_notifId(docId, d));
      } catch (_) {}
    }
  }

  int _notifId(String docId, int daysBefore) {
    var h = 0x811C9DC5;
    final s = '$docId#$daysBefore';
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0x7fffffff;
    }
    return h == 0 ? 1 : h;
  }
}
