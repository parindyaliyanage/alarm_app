import 'package:equatable/equatable.dart';
import '../../../data/models/alarm_model.dart';

abstract class AlarmListState extends Equatable {
  const AlarmListState();

  @override
  List<Object?> get props => [];
}

// Initial state — nothing loaded yet
class AlarmListInitial extends AlarmListState {}

// Loading from database
class AlarmListLoading extends AlarmListState {}

// Loaded successfully — holds the list
class AlarmListLoaded extends AlarmListState {
  final List<AlarmModel> alarms;
  const AlarmListLoaded(this.alarms);

  @override
  List<Object?> get props => [alarms];
}

// Something went wrong
class AlarmListError extends AlarmListState {
  final String message;
  const AlarmListError(this.message);

  @override
  List<Object?> get props => [message];
}