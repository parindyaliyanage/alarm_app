import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/repositories/alarm_repository.dart';
import 'features/alarm_list/bloc/alarm_list_bloc.dart';
import 'features/alarm_list/bloc/alarm_list_event.dart';
import 'features/alarm_list/view/alarm_list_screen.dart';
import 'features/alarm_trigger/bloc/alarm_trigger_bloc.dart';
import 'features/alarm_trigger/view/alarm_trigger_screen.dart';

// Global navigator key — lets us navigate from outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AlarmApp extends StatefulWidget {
  const AlarmApp({super.key});

  @override
  State<AlarmApp> createState() => _AlarmAppState();
}

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) async {
  await Hive.initFlutter();
  final activeBox = await Hive.openBox(AppConstants.activeAlarmBox);
  await activeBox.put(AppConstants.activeAlarmKey, true);
}

class _AlarmAppState extends State<AlarmApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationTapHandler();
  }

  void _setupNotificationTapHandler() {
    // This fires when user taps the alarm notification
    FlutterLocalNotificationsPlugin().initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final activeBox = Hive.box(AppConstants.activeAlarmBox);
        activeBox.put(AppConstants.activeAlarmKey, true);

        final challengeType =
            activeBox.get(
                  AppConstants.activeChallengeTypeKey,
                  defaultValue: AppConstants.mathChallenge,
                )
                as String;

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => AlarmTriggerBloc(),
              child: AlarmTriggerScreen(
                challengeType: challengeType,
              ), // ← correct
            ),
          ),
        );
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      navigatorKey: navigatorKey, // attach global key
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) =>
            AlarmListBloc(AlarmRepository())..add(const LoadAlarms()),
        child: const AlarmListScreen(),
      ),
    );
  }
}
