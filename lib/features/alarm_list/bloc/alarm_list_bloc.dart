import 'package:alarm_app/services/alarm_scheduler_service.dart';
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
    await AlarmSchedulerService.cancelAlarm(event.alarmId); // ← new
    await _repository.deleteAlarm(event.alarmId);
    final alarms = _repository.getAlarms();
    emit(AlarmListLoaded(alarms));
  } catch (e) {
    emit(AlarmListError('Failed to delete alarm: $e'));
  }
});

on<ToggleAlarm>((event, emit) async {
  try {
    await _repository.toggleAlarm(event.alarmId, event.isEnabled);

    // Schedule or cancel based on toggle ← new
    final alarms = _repository.getAlarms();
    final alarm = alarms.firstWhere((a) => a.id == event.alarmId);
    if (event.isEnabled) {
      await AlarmSchedulerService.scheduleAlarm(alarm);
    } else {
      await AlarmSchedulerService.cancelAlarm(event.alarmId);
    }

    emit(AlarmListLoaded(alarms));
  } catch (e) {
    emit(AlarmListError('Failed to toggle alarm: $e'));
  }
});
  }
}