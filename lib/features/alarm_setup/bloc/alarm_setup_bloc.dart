import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/alarm_model.dart';
import '../../../data/repositories/alarm_repository.dart';
import 'alarm_setup_event.dart';
import 'alarm_setup_state.dart';

class AlarmSetupBloc extends Bloc<AlarmSetupEvent, AlarmSetupState> {
  final AlarmRepository _repository;

  AlarmSetupBloc(this._repository) : super(const AlarmSetupState()) {

    on<TimeChanged>((event, emit) {
      emit(state.copyWith(hour: event.hour, minute: event.minute));
    });

    on<LabelChanged>((event, emit) {
      emit(state.copyWith(label: event.label));
    });

    on<RepeatDayToggled>((event, emit) {
      // Copy the list and flip the tapped day
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
          id: const Uuid().v4(), // unique ID
          hour: state.hour,
          minute: state.minute,
          label: state.label,
          repeatDays: state.repeatDays,
          isEnabled: true,
          challengeType: state.challengeType,
        );
        await _repository.saveAlarm(alarm);
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