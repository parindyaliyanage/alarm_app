import 'dart:io';
import 'package:alarm_app/data/models/alarm_model.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';


@pragma('vm:entry-point')
void alarmCallback(int id) async {
  if (!Platform.isAndroid) return; // safety guard

  final notifications = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    settings: const InitializationSettings(android: androidSettings),
  );

  const androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarms',
    channelDescription: 'Alarm notifications',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
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
    payload: id.toString(),
  );
}

class AlarmSchedulerService {

  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!Platform.isAndroid) return; // iOS guard

    final scheduledTime = _nextAlarmTime(alarm.hour, alarm.minute);
    await AndroidAlarmManager.oneShotAt(
      scheduledTime,
      _alarmId(alarm.id),
      alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    debugPrint('Alarm scheduled for $scheduledTime');
  }

  static Future<void> cancelAlarm(String alarmId) async {
    if (!Platform.isAndroid) return; // iOS guard

    await AndroidAlarmManager.cancel(_alarmId(alarmId));
    debugPrint('Alarm cancelled: $alarmId');
  }

  static DateTime _nextAlarmTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static int _alarmId(String uuid) => uuid.hashCode.abs();
}