import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';
import '../../core/constants/app_constants.dart';

class AlarmRepository {
  // Get the open Hive box
  Box<AlarmModel> get _box => Hive.box<AlarmModel>(AppConstants.alarmBox);

  // Get all alarms
  List<AlarmModel> getAlarms() {
    return _box.values.toList();
  }

  // Save a new alarm
  Future<void> saveAlarm(AlarmModel alarm) async {
    await _box.put(alarm.id, alarm);
  }

  // Update existing alarm
  Future<void> updateAlarm(AlarmModel alarm) async {
    await _box.put(alarm.id, alarm);
  }

  // Delete an alarm
  Future<void> deleteAlarm(String id) async {
    await _box.delete(id);
  }

  // Toggle alarm on/off
  Future<void> toggleAlarm(String id, bool isEnabled) async {
    final alarm = _box.get(id);
    if (alarm != null) {
      await _box.put(id, alarm.copyWith(isEnabled: isEnabled));
    }
  }
}