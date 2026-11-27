import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../data/models/alarm_model.dart';
import 'foreground_alarm_service.dart';

// Port names used to talk between the alarm isolate and the app (UI) isolate.
const String kUiAlarmPortName = 'alarm_ui_port';
const String _kBgAlarmPortName = 'alarm_bg_port';

// Global player lives at top level — survives in background isolate
AudioPlayer? _backgroundPlayer;
ReceivePort? _bgStopPort;

@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> params) async {
  if (!Platform.isAndroid) return;

  final challengeType =
      (params['challengeType'] as String?) ?? AppConstants.mathChallenge;

  // ── 1. Show fullscreen notification FIRST so it is never late ──
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
    playSound: false, // we handle sound ourselves
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

  // ── 2. If the app is running, let it handle the alarm itself ──
  // (Hive boxes are not shared between isolates, so the app would never
  // notice a flag written from here.)
  final uiPort = IsolateNameServer.lookupPortByName(kUiAlarmPortName);
  if (uiPort != null) {
    uiPort.send(challengeType);
    return;
  }

  // ── 3. App is not running: play sound here ──
  _backgroundPlayer = AudioPlayer();
  await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
  await _backgroundPlayer!.play(AssetSource('sounds/alarm.mp3'));

  // Listen for a "stop" from the app isolate once the user opens the challenge
  _bgStopPort?.close();
  IsolateNameServer.removePortNameMapping(_kBgAlarmPortName);
  _bgStopPort = ReceivePort();
  IsolateNameServer.registerPortWithName(
    _bgStopPort!.sendPort,
    _kBgAlarmPortName,
  );
  _bgStopPort!.listen((_) => _stopLocalPlayer());

  await Hive.initFlutter();
  final activeBox = await Hive.openBox(AppConstants.activeAlarmBox);
  await activeBox.put(AppConstants.activeAlarmKey, true);
  await activeBox.put(AppConstants.activeChallengeTypeKey, challengeType);

  // ── 4. Start foreground service to survive app clear ──
  ForegroundAlarmService.init();
  await ForegroundAlarmService.startAlarm();
}

Future<void> _stopLocalPlayer() async {
  await _backgroundPlayer?.stop();
  await _backgroundPlayer?.dispose();
  _backgroundPlayer = null;
  _bgStopPort?.close();
  _bgStopPort = null;
  IsolateNameServer.removePortNameMapping(_kBgAlarmPortName);
}

// Called from AlarmTriggerBloc when challenge screen opens.
// Works from any isolate: stops a local player and tells the alarm isolate
// to stop its player too.
Future<void> stopBackgroundAlarm() async {
  IsolateNameServer.lookupPortByName(_kBgAlarmPortName)?.send('stop');
  await _stopLocalPlayer();
}

class AlarmSchedulerService {

  static Future<void> scheduleAlarm(AlarmModel alarm) async {
  if (!Platform.isAndroid) return;

  final scheduledTime = _nextAlarmTime(alarm.hour, alarm.minute);
  await AndroidAlarmManager.oneShotAt(
    scheduledTime,
    _alarmId(alarm.id),
    alarmCallback,
    // alarmClock uses AlarmManager.setAlarmClock: exact, and never
    // deferred by Doze / battery optimisation (plain setExact can be late).
    alarmClock: true,
    exact: true,
    wakeup: true,
    allowWhileIdle: true,
    rescheduleOnReboot: true,
    params: {'challengeType': alarm.challengeType},
  );
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