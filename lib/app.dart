import 'dart:isolate';
import 'dart:ui';
import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:alarm_app/services/alarm_scheduler_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/theme_picker/view/theme_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/repositories/alarm_repository.dart';
import 'features/alarm_list/bloc/alarm_list_bloc.dart';
import 'features/alarm_list/bloc/alarm_list_event.dart';
import 'features/alarm_list/view/alarm_list_screen.dart';
import 'features/alarm_trigger/bloc/alarm_trigger_bloc.dart';
import 'features/alarm_trigger/view/alarm_trigger_screen.dart';

// Global navigator key — lets us navigate from outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool _triggerScreenOpen = false;

/// Opens the alarm challenge screen, unless it is already showing.
void openAlarmTriggerScreen(String challengeType) {
  if (_triggerScreenOpen) return;
  final navigator = navigatorKey.currentState;
  if (navigator == null) return;
  _triggerScreenOpen = true;
  navigator
      .push(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => AlarmTriggerBloc(),
            child: AlarmTriggerScreen(challengeType: challengeType),
          ),
        ),
      )
      .whenComplete(() => _triggerScreenOpen = false);
}

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
  final ReceivePort _alarmPort = ReceivePort();

  @override
  void initState() {
    super.initState();
    _setupNotificationTapHandler();
    _listenForAlarms();
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping(kUiAlarmPortName);
    _alarmPort.close();
    super.dispose();
  }

  /// The alarm callback runs in a separate background isolate. While the app
  /// is alive, it sends the challenge type here so we can ring immediately.
  void _listenForAlarms() {
    IsolateNameServer.removePortNameMapping(kUiAlarmPortName);
    IsolateNameServer.registerPortWithName(
      _alarmPort.sendPort,
      kUiAlarmPortName,
    );
    _alarmPort.listen((message) {
      final challengeType = message is String
          ? message
          : AppConstants.mathChallenge;
      final activeBox = Hive.box(AppConstants.activeAlarmBox);
      activeBox.put(AppConstants.activeAlarmKey, true);
      activeBox.put(AppConstants.activeChallengeTypeKey, challengeType);
      openAlarmTriggerScreen(challengeType);
    });
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

        openAlarmTriggerScreen(challengeType);
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the app whenever the user picks a different theme.
    return ValueListenableBuilder<AppThemeChoice?>(
      valueListenable: ThemeController.instance,
      builder: (context, choice, _) {
        final themeData = (choice ?? AppThemeChoice.teal).themeData;

        return MaterialApp(
          title: 'Bedzilla',
          navigatorKey: navigatorKey, // attach global key
          debugShowCheckedModeBanner: false,
          // Both themes are dark, so the same ThemeData is used for both
          // slots and ThemeMode is fixed to dark.
          theme: themeData,
          darkTheme: themeData,
          themeMode: ThemeMode.dark,
          // First launch: no theme chosen yet → show the picker.
          home: choice == null
              ? const ThemePickerScreen()
              : BlocProvider(
                  create: (_) =>
                      AlarmListBloc(AlarmRepository())..add(const LoadAlarms()),
                  child: const AlarmListScreen(),
                ),
        );
      },
    );
  }
}
