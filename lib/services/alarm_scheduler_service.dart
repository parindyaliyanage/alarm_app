import 'dart:io';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/alarm_model.dart';
import 'foreground_alarm_service.dart';

// Global player lives at top level — survives in background isolate
AudioPlayer? _backgroundPlayer;

@pragma('vm:entry-point')
void alarmCallback(int id) async {
  if (!Platform.isAndroid) return;

  // ── 1. Play sound IMMEDIATELY ──
  _backgroundPlayer = AudioPlayer();
  await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
  await _backgroundPlayer!.play(AssetSource('sounds/alarm.mp3'));

  // ── 2. Mark alarm as active in Hive ──
  await Hive.initFlutter();
  final activeBox = await Hive.openBox(AppConstants.activeAlarmBox);
  await activeBox.put(AppConstants.activeAlarmKey, true);

  // ── 3. Start foreground service to survive app clear ──
  ForegroundAlarmService.init();
  await ForegroundAlarmService.startAlarm();

  // ── 4. Show fullscreen notification ──
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
    playSound: false,      // we handle sound ourselves
    enableVibration: true,
    ongoing: true,
    autoCancel: false,
  );

  await notifications.show(
    id: id,
    title: '⏰ Wake Up!',
    body: 'Solve the challenge to stop the alarm',
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: id.toString(),
  );
}

// Called from AlarmTriggerBloc when challenge screen opens
Future<void> stopBackgroundAlarm() async {
  await _backgroundPlayer?.stop();
  await _backgroundPlayer?.dispose();
  _backgroundPlayer = null;
}

class AlarmSchedulerService {

  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!Platform.isAndroid) return;

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
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(_alarmId(alarmId));
    await stopBackgroundAlarm();
    await ForegroundAlarmService.stopAlarm();
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