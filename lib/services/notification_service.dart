import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Inisialisasi timezone
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings);
    if (Platform.isAndroid) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      print("🔔 Notification permission granted: $granted");
    }
  }

  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledTime) async {
    final tz.TZDateTime scheduledTZ =
        tz.TZDateTime.from(scheduledTime, tz.local);

    print("📅 Scheduling notification at: $scheduledTZ");

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTZ,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tododo_channel',
          'Task & Event Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );

    // 🔍 Cek apakah notifikasi benar-benar masuk ke daftar yang dijadwalkan
    final pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();
    print("📌 Pending Notifications: ${pendingNotifications.length}");
    for (var notif in pendingNotifications) {
      print("🔔 ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}");
    }
  }
}
