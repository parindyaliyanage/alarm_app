import 'package:equatable/equatable.dart';
import '../../../core/constants/app_constants.dart';

class AlarmSetupState extends Equatable {
  final String? editingAlarmId;
  final int hour;
  final int minute;
  final String label;
  final List<bool> repeatDays; // 7 days, Mon-Sun
  final String challengeType;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const AlarmSetupState({
    this.editingAlarmId, 
    this.hour = 7,
    this.minute = 0,
    this.label = '',
    this.repeatDays = const [false, false, false, false, false, false, false],
    this.challengeType = AppConstants.mathChallenge,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  bool get isEditing => editingAlarmId != null;

  // Helper to create a modified copy
  AlarmSetupState copyWith({
    int? hour,
    int? minute,
    String? label,
    List<bool>? repeatDays,
    String? challengeType,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
  }) {
    return AlarmSetupState(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      repeatDays: repeatDays ?? this.repeatDays,
      challengeType: challengeType ?? this.challengeType,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      errorMessage: errorMessage,
    );
  }

  // Human readable time
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [
        hour,
        minute,
        label,
        repeatDays,
        challengeType,
        isSaving,
        isSaved,
        errorMessage,
      ];
}