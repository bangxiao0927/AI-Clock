import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';
import 'time_zones.dart';

/// [NotificationService] backed by the `flutter_local_notifications` plugin.
///
/// Every call is guarded: a platform failure (permission revoked, plugin
/// missing on this platform) is logged and ignored, because the in-app alerts
/// still work without notifications.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'alerts',
      'Alarms, timers and reminders',
      channelDescription: 'Alerts for your alarms, timers and reminders.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(),
  );

  @override
  Future<void> init() async {
    if (_ready) return;
    await _guard(() async {
      await initLocalTimeZone();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Permission is requested later, when the user first needs it.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    });
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    return await _guard(() async {
          final ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          if (ios != null) {
            return await ios.requestPermissions(
                  alert: true,
                  badge: false,
                  sound: true,
                ) ??
                false;
          }
          final android = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          return await android?.requestNotificationsPermission() ?? false;
        }) ??
        false;
  }

  @override
  Future<bool> isPermitted() async {
    if (!_ready) return false;
    return await _guard(() async {
          final ios = _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
          if (ios != null) return (await ios.checkPermissions())?.isEnabled;
          final android = _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
          return await android?.areNotificationsEnabled();
        }) ??
        false;
  }

  @override
  Future<void> schedule({
    required int id,
    required DateTime at,
    required String title,
    String? body,
    bool repeatsWeekly = false,
  }) async {
    if (!_ready) return;
    // A one-off notification in the past would throw; there is nothing to show.
    if (!repeatsWeekly && !at.isAfter(DateTime.now())) return;
    await _guard(
      () => _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: repeatsWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _guard(() => _plugin.cancel(id: id));
  }

  Future<T?> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      debugPrint('Notification call failed: $error');
      return null;
    }
  }
}
