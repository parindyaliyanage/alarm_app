import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'data/models/alarm_model.dart';
import 'core/constants/app_constants.dart';
import 'app.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(AlarmModelAdapter());
  await Hive.openBox<AlarmModel>(AppConstants.alarmBox);

  // Initialize Alarm Manager
  await AndroidAlarmManager.initialize();

  // Initialize Notifications
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);
    await notificationsPlugin.initialize(settings: initSettings);

  // Request notification permission (Android 13+)
  final androidPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.requestNotificationsPermission();

  runApp(const AlarmApp());
}