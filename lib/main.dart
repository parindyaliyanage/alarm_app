import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'data/models/alarm_model.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz.initializeTimeZones();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  await Hive.openBox<AlarmModel>(AppConstants.alarmBox);

  // Initialize Notifications for both Android and iOS
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notificationsPlugin.initialize(settings: initSettings);

  // Platform-specific setup
  if (Platform.isAndroid) {
    // Initialize Alarm Manager
    await AndroidAlarmManager.initialize();

    // Request notification permission (Android 13+)
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  } else if (Platform.isIOS) {
    // Request notification permission (iOS)
    final iosPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  runApp(const AlarmApp());
}