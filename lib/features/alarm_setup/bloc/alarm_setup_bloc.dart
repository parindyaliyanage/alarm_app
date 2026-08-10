import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/alarm_model.dart';
import '../../../data/repositories/alarm_repository.dart';
import '../../../services/alarm_scheduler_service.dart';
import 'alarm_setup_event.dart';
import 'alarm_setup_state.dart';

class AlarmSetupBloc extends Bloc<AlarmSetupEvent, AlarmSetupState> {
  final AlarmRepository _repository;

  AlarmSetupBloc(this._repository) : super(const AlarmSetupState()) {

    // ← NEW: pre-fill form with existing alarm data
    on<LoadAlarmForEdit>((event, emit) {
      final alarm = event.alarm;
      emit(AlarmSetupState(
        editingAlarmId: alarm.id,
        hour: alarm.hour,
        minute: alarm.minute,
        label: alarm.label,
        repeatDays: List<bool>.from(alarm.repeatDays),
        challengeType: alarm.challengeType,
      ));
    });

    on<TimeChanged>((event, emit) {
      emit(state.copyWith(hour: event.hour, minute: event.minute));
    });

    on<LabelChanged>((event, emit) {
      emit(state.copyWith(label: event.label));
    });

    on<RepeatDayToggled>((event, emit) {
      final updated = List<bool>.from(state.repeatDays);
      updated[event.dayIndex] = !updated[event.dayIndex];
      emit(state.copyWith(repeatDays: updated));
    });

    on<ChallengeTypeChanged>((event, emit) {
      emit(state.copyWith(challengeType: event.challengeType));
    });

    on<SaveAlarm>((event, emit) async {
      emit(state.copyWith(isSaving: true));
      try {
        final alarm = AlarmModel(
          id: state.editingAlarmId ?? const Uuid().v4(), // ← reuse ID if editing
          hour: state.hour,
          minute: state.minute,
          label: state.label,
          repeatDays: state.repeatDays,
          isEnabled: true,
          challengeType: state.challengeType,
        );

        await _repository.saveAlarm(alarm); // put() overwrites if same ID

        // Cancel old schedule and reschedule with new time
        await AlarmSchedulerService.cancelAlarm(alarm.id);
        await AlarmSchedulerService.scheduleAlarm(alarm);

        emit(state.copyWith(isSaving: false, isSaved: true));
      } catch (e) {
        emit(state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save alarm: $e',
        ));
      }
    });
  }
}