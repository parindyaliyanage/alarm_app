import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:audioplayers/audioplayers.dart';

@pragma('vm:entry-point')
class AlarmForegroundHandler extends TaskHandler {

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Sound is handled directly in alarmCallback
    // Foreground service just keeps the process alive
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // Nothing to clean up here
  }
}


class ForegroundAlarmService {

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alarm_foreground',
        channelName: 'Alarm Service',
        channelDescription: 'Keeps alarm running in background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(  // ← removed const
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> startAlarm() async {
    await FlutterForegroundTask.startService(
      serviceId: 1000,
      notificationTitle: '⏰ Alarm is ringing!',
      notificationText: 'Tap to solve the challenge',
      callback: startForegroundCallback,
    );
  }

  static Future<void> stopAlarm() async {
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(AlarmForegroundHandler());
}