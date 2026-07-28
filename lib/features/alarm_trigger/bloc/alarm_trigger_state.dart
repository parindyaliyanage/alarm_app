import 'package:equatable/equatable.dart';

enum AlarmStatus { ringing, solved, failed }

class AlarmTriggerState extends Equatable {
  final int firstNumber;
  final int secondNumber;
  final String operator;   // '+' or '-'
  final int correctAnswer;
  final int questionsLeft; // user must solve 3 in a row
  final bool isWrong;      // flash red on wrong answer
  final AlarmStatus status;

  const AlarmTriggerState({
    this.firstNumber = 0,
    this.secondNumber = 0,
    this.operator = '+',
    this.correctAnswer = 0,
    this.questionsLeft = 3,
    this.isWrong = false,
    this.status = AlarmStatus.ringing,
  });

  AlarmTriggerState copyWith({
    int? firstNumber,
    int? secondNumber,
    String? operator,
    int? correctAnswer,
    int? questionsLeft,
    bool? isWrong,
    AlarmStatus? status,
  }) {
    return AlarmTriggerState(
      firstNumber: firstNumber ?? this.firstNumber,
      secondNumber: secondNumber ?? this.secondNumber,
      operator: operator ?? this.operator,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      questionsLeft: questionsLeft ?? this.questionsLeft,
      isWrong: isWrong ?? this.isWrong,
      status: status ?? this.status,
    );
  }

  // Display string e.g. "234 + 121 = ?"
  String get question => '$firstNumber $operator $secondNumber = ?';

  @override
  List<Object?> get props => [
        firstNumber,
        secondNumber,
        operator,
        correctAnswer,
        questionsLeft,
        isWrong,
        status,
      ];
}