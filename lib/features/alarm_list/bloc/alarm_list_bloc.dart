import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/alarm_repository.dart';
import 'alarm_list_event.dart';
import 'alarm_list_state.dart';

class AlarmListBloc extends Bloc<AlarmListEvent, AlarmListState> {
  final AlarmRepository _repository;

  AlarmListBloc(this._repository) : super(AlarmListInitial()) {

    // Handle LoadAlarms event
    on<LoadAlarms>((event, emit) {
      try {
        emit(AlarmListLoading());
        final alarms = _repository.getAlarms();
        emit(AlarmListLoaded(alarms));
      } catch (e) {
        emit(AlarmListError('Failed to load alarms: $e'));
      }
    });

    // Handle DeleteAlarm event
    on<DeleteAlarm>((event, emit) async {
      try {
        await _repository.deleteAlarm(event.alarmId);
        final alarms = _repository.getAlarms();
        emit(AlarmListLoaded(alarms));
      } catch (e) {
        emit(AlarmListError('Failed to delete alarm: $e'));
      }
    });

    // Handle ToggleAlarm event
    on<ToggleAlarm>((event, emit) async {
      try {
        await _repository.toggleAlarm(event.alarmId, event.isEnabled);
        final alarms = _repository.getAlarms();
        emit(AlarmListLoaded(alarms));
      } catch (e) {
        emit(AlarmListError('Failed to toggle alarm: $e'));
      }
    });
  }
}