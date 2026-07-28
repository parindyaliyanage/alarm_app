import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../services/alarm_scheduler_service.dart';
import 'alarm_trigger_event.dart';
import 'alarm_trigger_state.dart';

class AlarmTriggerBloc extends Bloc<AlarmTriggerEvent, AlarmTriggerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  bool _isDisposed = false;

  AlarmTriggerBloc() : super(const AlarmTriggerState()) {

    on<AlarmStarted>((event, emit) async {
      await WakelockPlus.enable();

      // Stop background player and take over with in-app player
      await stopBackgroundAlarm();

      // Start fresh in-app looping sound
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));

      emit(_generateQuestion(state));
    });

    on<NewQuestionGenerated>((event, emit) {
      emit(_generateQuestion(state));
    });

    on<AnswerSubmitted>((event, emit) async {
      final userAnswer = int.tryParse(event.answer);
      if (userAnswer == null) return;

      if (userAnswer == state.correctAnswer) {
        final remaining = state.questionsLeft - 1;
        if (remaining <= 0) {
          add(const AlarmDismissed());
        } else {
          emit(_generateQuestion(state.copyWith(
            questionsLeft: remaining,
            isWrong: false,
          )));
        }
      } else {
        emit(state.copyWith(isWrong: true, questionsLeft: 3));
        await Future.delayed(const Duration(milliseconds: 600));
        emit(state.copyWith(isWrong: false));
        emit(_generateQuestion(state.copyWith(questionsLeft: 3)));
      }
    });

    on<AlarmDismissed>((event, emit) async {
      if (!_isDisposed) {
        _isDisposed = true;
        await _audioPlayer.stop();
        await WakelockPlus.disable();

        // Also cancel the ongoing notification
        await FlutterLocalNotificationsPlugin().cancelAll();
      }
      emit(state.copyWith(status: AlarmStatus.solved));
    });
  }

  AlarmTriggerState _generateQuestion(AlarmTriggerState current) {
    final useAddition = _random.nextBool();
    int first, second, answer;

    if (useAddition) {
      first = 100 + _random.nextInt(900);
      second = 100 + _random.nextInt(900);
      answer = first + second;
    } else {
      first = 100 + _random.nextInt(900);
      second = 100 + _random.nextInt(first - 100);
      answer = first - second;
    }

    return current.copyWith(
      firstNumber: first,
      secondNumber: second,
      operator: useAddition ? '+' : '-',
      correctAnswer: answer,
      isWrong: false,
    );
  }

  @override
  Future<void> close() async {
    if (!_isDisposed) {
      _isDisposed = true;
      await _audioPlayer.stop();
      await _audioPlayer.dispose();
      await WakelockPlus.disable();
    }
    return super.close();
  }
}