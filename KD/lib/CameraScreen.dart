import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'Detector.dart';
import 'OverlayView.dart';
import 'BoundingBox.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  final Detector _detector = Detector();
  List<BoundingBox> _boundingBoxes = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _detector.loadModel();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {});
    _cameraController.startImageStream((image) async {
      // Call detector.detectImage(image) and update _boundingBoxes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_cameraController.value.isInitialized)
            CameraPreview(_cameraController),
          OverlayView(boundingBoxes: _boundingBoxes),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _detector.dispose();
    super.dispose();
  }
}
