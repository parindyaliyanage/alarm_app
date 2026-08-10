import 'package:alarm_app/data/models/alarm_model.dart';
import 'package:equatable/equatable.dart';

abstract class AlarmSetupEvent extends Equatable {
  const AlarmSetupEvent();

  @override
  List<Object?> get props => [];
}

class LoadAlarmForEdit extends AlarmSetupEvent {
  final AlarmModel alarm;
  const LoadAlarmForEdit(this.alarm);

  @override
  List<Object?> get props => [alarm];
}

// User changed the time
class TimeChanged extends AlarmSetupEvent {
  final int hour;
  final int minute;
  const TimeChanged(this.hour, this.minute);

  @override
  List<Object?> get props => [hour, minute];
}

// User typed a label
class LabelChanged extends AlarmSetupEvent {
  final String label;
  const LabelChanged(this.label);

  @override
  List<Object?> get props => [label];
}

// User toggled a repeat day (Mon, Tue...)
class RepeatDayToggled extends AlarmSetupEvent {
  final int dayIndex; // 0=Mon, 1=Tue ... 6=Sun
  const RepeatDayToggled(this.dayIndex);

  @override
  List<Object?> get props => [dayIndex];
}

// User selected challenge type
class ChallengeTypeChanged extends AlarmSetupEvent {
  final String challengeType;
  const ChallengeTypeChanged(this.challengeType);

  @override
  List<Object?> get props => [challengeType];
}

// User tapped Save
class SaveAlarm extends AlarmSetupEvent {
  const SaveAlarm();
}