import 'package:equatable/equatable.dart';

abstract class AlarmTriggerEvent extends Equatable {
  const AlarmTriggerEvent();

  @override
  List<Object?> get props => [];
}

// Alarm screen opened — start sound + wakelock
class AlarmStarted extends AlarmTriggerEvent {
  const AlarmStarted();
}

// User submitted math answer
class AnswerSubmitted extends AlarmTriggerEvent {
  final String answer;
  const AnswerSubmitted(this.answer);

  @override
  List<Object?> get props => [answer];
}

// Generate a new math question
class NewQuestionGenerated extends AlarmTriggerEvent {
  const NewQuestionGenerated();
}

// Alarm dismissed successfully
class AlarmDismissed extends AlarmTriggerEvent {
  const AlarmDismissed();
}