import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

abstract class ObjectChallengeEvent extends Equatable {
  const ObjectChallengeEvent();

  @override
  List<Object?> get props => [];
}

// Start camera and load model
class ObjectChallengeStarted extends ObjectChallengeEvent {
  const ObjectChallengeStarted();
}

// New camera frame to process
class FrameCaptured extends ObjectChallengeEvent {
  final CameraImage image;
  const FrameCaptured(this.image);

  @override
  List<Object?> get props => [image];
}

// 2 minutes passed — switch to math
class ObjectChallengeTimedOut extends ObjectChallengeEvent {
  const ObjectChallengeTimedOut();
}

// Object successfully detected
class ObjectDetected extends ObjectChallengeEvent {
  const ObjectDetected();
}