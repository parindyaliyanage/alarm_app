import 'package:equatable/equatable.dart';

enum ObjectChallengeStatus {
  loading,      // model loading
  scanning,     // camera active, scanning
  detected,     // object found
  timedOut,     // 2 min passed, switch to math
}

class ObjectChallengeState extends Equatable {
  final ObjectChallengeStatus status;
  final String targetObject;    // what to find
  final int secondsRemaining;   // countdown
  final double confidence;      // last detection confidence
  final String? detectedLabel;  // what was actually detected

  const ObjectChallengeState({
    this.status = ObjectChallengeStatus.loading,
    this.targetObject = '',
    this.secondsRemaining = 120,
    this.confidence = 0.0,
    this.detectedLabel,
  });

  ObjectChallengeState copyWith({
    ObjectChallengeStatus? status,
    String? targetObject,
    int? secondsRemaining,
    double? confidence,
    String? detectedLabel,
  }) {
    return ObjectChallengeState(
      status: status ?? this.status,
      targetObject: targetObject ?? this.targetObject,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      confidence: confidence ?? this.confidence,
      detectedLabel: detectedLabel ?? this.detectedLabel,
    );
  }

  // Format seconds as MM:SS
  String get formattedTime {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        status, targetObject,
        secondsRemaining, confidence, detectedLabel,
      ];
}