import 'package:alarm_app/features/alarm_trigger/bloc/alarm_trigger_bloc.dart';
import 'package:alarm_app/features/alarm_trigger/view/alarm_trigger_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  // Add after opening alarms box
  await Hive.openBox(AppConstants.activeAlarmBox);

  // Force default value on first launch
  final activeBox = Hive.box(AppConstants.activeAlarmBox);
  await activeBox.put(AppConstants.activeAlarmKey, false);

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
  await notificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (response) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => AlarmTriggerBloc(),
            child: const AlarmTriggerScreen(),
          ),
        ),
      );
    },
  );

  // Platform-specific setup
  if (!kIsWeb && Platform.isAndroid) {
    // Initialize Alarm Manager
    await AndroidAlarmManager.initialize();

    // Request notification permission (Android 13+)
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  } else if (!kIsWeb && Platform.isIOS) {
    // Request notification permission (iOS)
    final iosPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  runApp(const AlarmApp());
}
