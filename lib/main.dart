import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local database)
  await Hive.initFlutter();

  // Initialize Android Alarm Manager
  await AndroidAlarmManager.initialize();

  runApp(const AlarmApp());
}