import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:kd/BoundingBox.dart';
import 'Constants.dart';

class Detector {
  Interpreter? _interpreter;
  List<String> _labels = [];

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(Constants.modelPath);
    _labels = await rootBundle.loadString(Constants.labelsPath).then((data) => data.split('\n'));
  }

  Future<List<BoundingBox>> detectImage(Uint8List imageBytes) async {
    // Process image and run inference
    // This part involves converting and running the TensorFlow Lite model on the image

    return []; // return list of BoundingBox
  }

  void dispose() {
    _interpreter?.close();
  }
}
