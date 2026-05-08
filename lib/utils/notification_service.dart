// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:permission_handler/permission_handler.dart';

// class NotificationService {
//   final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     // Android initialization
//     const AndroidInitializationSettings androidInit =
//         AndroidInitializationSettings('@drawable/ic_notification');

//     // iOS initialization
//     const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

//     // Combined initialization
//     const InitializationSettings initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iosInit,
//     );

//     // Initialize plugin
//     await _notifications.initialize(initSettings);

//     // Request notification permissions (POST_NOTIFICATIONS)
//     await _requestPermissions();

//     // Request exact alarm permission (SCHEDULE_EXACT_ALARM) for Android 12+
//     await requestExactAlarmsPermission();
//   }

//   Future<void> _requestPermissions() async {
//     try {
//       if (await Permission.notification.isDenied) {
//         final status = await Permission.notification.request();
//         print('🔔 Notification permission status: $status');
//       } else {
//         print('🔔 Notification permission already granted');
//       }
//     } catch (e) {
//       print('❌ Error while requesting notification permission: $e');
//     }
//   }

//   /// Request exact alarm permission (SCHEDULE_EXACT_ALARM) on Android 12+.
//   /// Uses permission_handler's Permission.scheduleExactAlarm.
//   /// If the permission cannot be granted via runtime prompt, opens app settings.
//   Future<void> requestExactAlarmsPermission() async {
//     try {
//       // Check support / current status
//       final status = await Permission.scheduleExactAlarm.status;
//       if (status.isGranted) {
//         print('⏰ Exact alarm permission already granted');
//         return;
//       }

//       // Try to request it
//       final result = await Permission.scheduleExactAlarm.request();

//       if (result.isGranted) {
//         print('✅ Exact alarm permission granted');
//         return;
//       }

//       // Some OEMs/Android versions do not allow runtime requests for this permission.
//       // If denied or restricted, guide user to app settings.
//       print(
//           '⚠ Exact alarm permission not granted (status: $result). Opening app settings so the user can enable it manually.');
//       await openAppSettings();
//     } catch (e) {
//       print('❌ Error while requesting exact alarm permission: $e');
//     }
//   }

//   // ----------------------------- DAILY SCHEDULE -----------------------------
//   Future<void> scheduleDailyNotification(int hour, int minute) async {
//     print("🔥 scheduleDailyNotification() CALLED");

//     try {
//       print("🔥 Preparing android details...");
//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'daily_channel_id',
//         'Daily Notifications',
//         channelDescription: 'Daily reminder notification',
//         importance: Importance.max,
//         priority: Priority.max,
//       );

//       const NotificationDetails platformDetails = NotificationDetails(
//         android: androidDetails,
//       );

//       print("🔥 Calculating next schedule time...");
//       final scheduleTime = _nextInstanceOfTime(hour, minute); // 9:00 PM daily
//       print("📅 Next notification at: $scheduleTime");

//       print("🔥 Triggering zonedSchedule()...");
//       await _notifications.zonedSchedule(
//         0,
//         'Reminder',
//         "Hey, Forgetting Today’s Entry?",
//         scheduleTime,
//         platformDetails,
//         androidScheduleMode: AndroidScheduleMode.alarmClock,
//         matchDateTimeComponents: DateTimeComponents.time,
//       );

//       print("🎉 Notification scheduled successfully!");

//       // Report pending notifications for debugging
//       final pending = await _notifications.pendingNotificationRequests();
//       print("🟩 Pending notifications: ${pending.length}");
//       for (var p in pending) {
//         print("➡️ Pending ID: ${p.id}, Title: ${p.title}, Body: ${p.body}");
//       }
//     } catch (e) {
//       print("❌ ERROR scheduling daily notification: $e");
//     }
//   }

//   // ----------------------------- NEXT DAILY TIME -----------------------------
//   tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
//     final now = tz.TZDateTime.now(tz.local);

//     tz.TZDateTime scheduled = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     );

//     // If the time already passed today → schedule next day
//     if (scheduled.isBefore(now)) {
//       scheduled = scheduled.add(const Duration(days: 1));
//     }

//     return scheduled;
//   }

//   // ----------------------------- INSTANT NOTIFICATION -----------------------------
//   Future<void> showNotificationOnPress(String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'manual_channel',
//       'Manual Notifications',
//       channelDescription: 'Notifications triggered manually',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const NotificationDetails platformDetails = NotificationDetails(
//       android: androidDetails,
//     );

//     await _notifications.show(
//       1, // ID
//       title,
//       body,
//       platformDetails,
//     );
//   }
// }

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(initSettings);

    // Request POST_NOTIFICATIONS (Android 13)
    await _requestPostNotificationPermission();

    // Request Exact Alarm permission on Android 12+ (opens settings)
    await _requestExactAlarmPermission();
  }

  // ------------------ REQUEST POST NOTIFICATION ------------------
  Future<void> _requestPostNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;

      if (!status.isGranted) {
        final result = await Permission.notification.request();
        print("🔔 Notification Permission: $result");
      }
    }
  }

  // ------------------ EXACT ALARM PERMISSION (REAL WORKING VERSION) ------------------
  Future<void> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    // Android 12+ = SCHEDULE_EXACT_ALARM restriction
    // final sdk = (await Permission.scheduleExactAlarm.status).toString();

    // Check if already allowed
    if (await Permission.scheduleExactAlarm.isGranted) {
      print("⏰ Exact Alarm already allowed");
      return;
    }

    print("⚠ Exact Alarm not granted → Opening settings.");

    // OPEN SYSTEM SETTINGS (This is the REAL correct method)
    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    await intent.launch();
  }

  // ----------------------------- DAILY SCHEDULE -----------------------------
  Future<void> scheduleDailyNotification() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'daily_channel',
            'Daily Notifications',
            channelDescription: 'Daily 9 PM reminder',
            importance: Importance.max,
            priority: Priority.max,
          );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final scheduleTime = _nextInstanceOf(21, 00);

      print("📅 Scheduling at $scheduleTime");

      await _notifications.zonedSchedule(
        100, // Unique ID
        'Reminder',
        "Hey, Forgetting Today’s Entry?",
        scheduleTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print("✅ Daily notification scheduled!");
    } catch (e) {
      print("❌ Error scheduling: $e");
    }
  }

  // ----------------------------- CALCULATE NEXT TIME -----------------------------
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime target = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If passed → schedule next day
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    return target;
  }

  // ----------------------------- INSTANT NOTIFICATION -----------------------------
  Future<void> showNotificationNow(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'instant_channel',
          'Instant Notifications',
          channelDescription: 'Triggered manually',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      200, // ID
      title,
      body,
      details,
    );
  }
}
