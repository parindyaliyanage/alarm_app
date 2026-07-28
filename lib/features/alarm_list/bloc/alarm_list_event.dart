import 'package:equatable/equatable.dart';

abstract class AlarmListEvent extends Equatable {
  const AlarmListEvent();

  @override
  List<Object?> get props => [];
}

// Load all alarms from database
class LoadAlarms extends AlarmListEvent {
  const LoadAlarms();
}

// Delete an alarm
class DeleteAlarm extends AlarmListEvent {
  final String alarmId;
  const DeleteAlarm(this.alarmId);

  @override
  List<Object?> get props => [alarmId];
}

// Toggle alarm on or off
class ToggleAlarm extends AlarmListEvent {
  final String alarmId;
  final bool isEnabled;
  const ToggleAlarm(this.alarmId, this.isEnabled);

  @override
  List<Object?> get props => [alarmId, isEnabled];
}