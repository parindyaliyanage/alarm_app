import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../../core/constants/app_constants.dart';
import '../../../services/object_detection_service.dart';
import 'object_challenge_event.dart';
import 'object_challenge_state.dart';

class ObjectChallengeBloc
    extends Bloc<ObjectChallengeEvent, ObjectChallengeState> {
  final ObjectDetectionService _detectionService = ObjectDetectionService();
  CameraController? _cameraController;
  Timer? _countdownTimer;
  bool _isProcessingFrame = false;
  int _frameCount = 0;

  ObjectChallengeBloc() : super(const ObjectChallengeState()) {

    on<ObjectChallengeStarted>((event, emit) async {
      // Pick random object from our 20
      final random = Random();
      final target = AppConstants.detectableObjects[
          random.nextInt(AppConstants.detectableObjects.length)];

      emit(state.copyWith(
        status: ObjectChallengeStatus.loading,
        targetObject: target,
      ));

      // Load TFLite model
      await _detectionService.loadModel();

      // Initialize camera
      final cameras = await availableCameras();
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();

      // Start scanning
      emit(state.copyWith(status: ObjectChallengeStatus.scanning));

      // Start countdown timer
      _startCountdown();

      // Start camera stream
      await _cameraController!.startImageStream((image) {
        add(FrameCaptured(image));
      });
    });

    on<FrameCaptured>((event, emit) async {
      // Only process every 3rd frame to save battery
      _frameCount++;
      if (_frameCount % 3 != 0) return;
      if (_isProcessingFrame) return;
      if (state.status != ObjectChallengeStatus.scanning) return;

      _isProcessingFrame = true;

      try {
        // Convert CameraImage to img.Image
        final image = _convertCameraImage(event.image);
        if (image == null) return;

        // Run detection
        final results = await _detectionService.detect(image);

        // Check if target object detected
        for (final result in results) {
          if (result.label == state.targetObject &&
              result.confidence > 0.8) {
            add(const ObjectDetected());
            return;
          }
        }
      } finally {
        _isProcessingFrame = false;
      }
    });

    on<ObjectDetected>((event, emit) async {
      _countdownTimer?.cancel();
      await _cameraController?.stopImageStream();
      emit(state.copyWith(status: ObjectChallengeStatus.detected));
    });

    on<ObjectChallengeTimedOut>((event, emit) async {
      _countdownTimer?.cancel();
      await _cameraController?.stopImageStream();
      emit(state.copyWith(status: ObjectChallengeStatus.timedOut));
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.secondsRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        add(const ObjectChallengeTimedOut());
      } else {
        emit(state.copyWith(secondsRemaining: remaining));
      }
    });
  }

  // Convert CameraImage (YUV420) to img.Image (RGB)
  img.Image? _convertCameraImage(CameraImage cameraImage) {
    try {
      final int width = cameraImage.width;
      final int height = cameraImage.height;
      final img.Image image = img.Image(width: width, height: height);

      final Plane yPlane = cameraImage.planes[0];
      final Plane uPlane = cameraImage.planes[1];
      final Plane vPlane = cameraImage.planes[2];

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int uvIndex =
              uPlane.bytesPerRow * (y ~/ 2) + (x ~/ 2) * uPlane.bytesPerPixel!;
          final int yIndex = y * yPlane.bytesPerRow + x;

          final int yValue = yPlane.bytes[yIndex];
          final int uValue = uPlane.bytes[uvIndex];
          final int vValue = vPlane.bytes[uvIndex];

          // YUV to RGB conversion
          int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
          int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
          int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

          image.setPixelRgb(x, y, r, g, b);
        }
      }
      return image;
    } catch (e) {
      return null;
    }
  }

  CameraController? get cameraController => _cameraController;

  @override
  Future<void> close() async {
    _countdownTimer?.cancel();
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _detectionService.dispose();
    return super.close();
  }
}