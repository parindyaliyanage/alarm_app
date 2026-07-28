import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/models/alarm_model.dart';

// ─────────────────────────────────────────────────────
// IMPORTANT: This MUST be a top-level function (not inside a class)
// Android calls this directly when the alarm fires
// ─────────────────────────────────────────────────────
@pragma('vm:entry-point')
void alarmCallback(int id) async {
  // This runs in a background isolate
  // We use local notifications to wake the screen
  final notifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );

  const androidDetails = AndroidNotificationDetails(
    'alarm_channel',         // channel id
    'Alarms',                // channel name
    channelDescription: 'Alarm notifications',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,  // this shows over lock screen
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
  );

  await notifications.show(
    id: id,
    title: '⏰ Wake Up!',
    body: 'Solve the challenge to stop the alarm',
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: id.toString(), // we'll use this to open correct screen
  );
}

// ─────────────────────────────────────────────────────
// AlarmSchedulerService — call this from your Bloc
// ─────────────────────────────────────────────────────
class AlarmSchedulerService {

  // Schedule an alarm
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    final scheduledTime = _nextAlarmTime(alarm.hour, alarm.minute);

    if (Platform.isAndroid) {
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        _alarmId(alarm.id),     // unique int ID
        alarmCallback,          // top-level function
        exact: true,
        wakeup: true,           // wake device from sleep
        rescheduleOnReboot: true,
      );
    } else if (Platform.isIOS) {
      final notifications = FlutterLocalNotificationsPlugin();

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(iOS: iosDetails);

      // Convert local DateTime to UTC TZDateTime
      final tzDateTime = tz.TZDateTime.from(scheduledTime.toUtc(), tz.UTC);

      await notifications.zonedSchedule(
        id: _alarmId(alarm.id),
        title: '⏰ Wake Up!',
        body: alarm.label.isNotEmpty ? alarm.label : 'Solve the challenge to stop the alarm',
        scheduledDate: tzDateTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    debugPrint('Alarm scheduled for $scheduledTime');
  }

  // Cancel an alarm
  static Future<void> cancelAlarm(String alarmId) async {
    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(_alarmId(alarmId));
    } else if (Platform.isIOS) {
      final notifications = FlutterLocalNotificationsPlugin();
      await notifications.cancel(id: _alarmId(alarmId));
    }
    debugPrint('Alarm cancelled: $alarmId');
  }

  // Get next occurrence of hour:minute
  // e.g. if it's 14:00 and alarm is 07:00 → schedules for tomorrow 07:00
  static DateTime _nextAlarmTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  // Convert string UUID to stable int for AlarmManager
  // AlarmManager needs an int ID, but our model uses UUID strings
  static int _alarmId(String uuid) => uuid.hashCode.abs();
}