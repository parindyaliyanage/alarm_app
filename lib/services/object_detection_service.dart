import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';

class DetectionResult {
  final String label;
  final double confidence;

  DetectionResult({required this.label, required this.confidence});
}

class ObjectDetectionService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  static const int inputSize = 320;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  // Load model and labels from assets
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/efficientdet_lite0.tflite',
      );

      final labelData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      rethrow;
    }
  }

  // Run detection on a single image
  Future<List<DetectionResult>> detect(img.Image image) async {
    if (!_isLoaded || _interpreter == null) return [];

    // Resize to model input size
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Normalize pixels to [0, 255] as uint8
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resized.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        }),
      ),
    );

    // Output tensors
    final boxes = List.filled(1 * 25 * 4, 0.0).reshape([1, 25, 4]);
    final classes = List.filled(1 * 25, 0.0).reshape([1, 25]);
    final scores = List.filled(1 * 25, 0.0).reshape([1, 25]);
    final count = List.filled(1, 0.0);

    final outputs = {0: boxes, 1: classes, 2: scores, 3: count};

    _interpreter!.runForMultipleInputs([input], outputs);

    // Parse results
    final results = <DetectionResult>[];
    final numDetections = count[0].toInt();

    for (int i = 0; i < numDetections; i++) {
      final score = (scores as List)[0][i] as double;
      if (score > 0.5) {
        final classId = ((classes as List)[0][i] as double).toInt();
        if (classId < _labels.length) {
          results.add(DetectionResult(
            label: _labels[classId].toLowerCase(),
            confidence: score,
          ));
        }
      }
    }

    return results;
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}