import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  Offset? _focusPoint;
  final ImagePicker _picker = ImagePicker();
  final String lineNotifyToken = 'iYUtTdNSa1aON7tEuhSFFcA7R8lM1mYGyQgw3tvplwM';
  late LineNotifyFirebaseService _lineNotifyService;

  @override
  void initState() {
    super.initState();
    _initializeLineNotify();
    _startPollingForNewDocuments();
    _initializeCamera();
  }

  void _initializeLineNotify() {
    _lineNotifyService = LineNotifyFirebaseService(lineNotifyToken: lineNotifyToken);
  }

  Future<void> _startPollingForNewDocuments() async {
    Timer.periodic(Duration(minutes: 1), (timer) async {
      await _lineNotifyService.checkForNewDocuments();
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = controller.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  void _setFocusPoint(TapDownDetails details) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _focusPoint = localPosition;
    });
  }

  Future<void> _uploadVideo(BuildContext context) async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    File videoFile = File(video.path);
    String fileName = video.name;

    try {
      await FirebaseStorage.instance
          .ref('Vdo_user_upload/$fileName')
          .putFile(videoFile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video uploaded successfully!')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading video: $e')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera'),
        actions: [
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.download),
            onPressed: () => _uploadVideo(context),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              onTapDown: _setFocusPoint,
              child: Stack(
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: CameraPreview(controller),
                  ),
                  if (_focusPoint != null)
                    Positioned.fill(
                      top: 50,
                      child: Align(
                        alignment: Alignment(
                          (_focusPoint!.dx / MediaQuery.of(context).size.width) * 2 - 1,
                          (_focusPoint!.dy / MediaQuery.of(context).size.height) * 2 - 1,
                        ),
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class LineNotifyFirebaseService {
  final String lineNotifyToken;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? lastProcessedId;

  LineNotifyFirebaseService({required this.lineNotifyToken});

  Future<void> checkForNewDocuments() async {
    try {
      // ใช้ orderBy และ startAfter สำหรับการ query
      Query query = _firestore.collection('test')
          .orderBy('timestamp', descending: true)
          .limit(10);

      if (lastProcessedId != null) {
        DocumentSnapshot lastDoc = await _firestore
            .collection('test')
            .doc(lastProcessedId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfter([lastDoc.get('timestamp')]);
        }
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ไม่พบข้อมูลใหม่');
        return;
      }

      for (var doc in snapshot.docs) {
        await _processDocument(doc);
      }

      // บันทึก ID ของเอกสารล่าสุดที่ประมวลผล
      if (snapshot.docs.isNotEmpty) {
        lastProcessedId = snapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการตรวจสอบเอกสารใหม่: $e');
    }
  }

  Future<void> _processDocument(DocumentSnapshot doc) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // ตรวจสอบว่ามีข้อมูลที่จำเป็นครบถ้วนหรือไม่
      if (!_validateDocumentData(data)) {
        debugPrint('ข้อมูลไม่ครบถ้วนหรือไม่ถูกต้อง: ${doc.id}');
        await sendLineNotify('ข้อมูลในเอกสาร ID ${doc.id} ไม่ครบถ้วน');
        return;
      }

      String message = _prepareNotificationMessage(doc, data);
      await sendLineNotify(message);

    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการประมวลผลเอกสาร ${doc.id}: $e');
    }
  }


  bool _validateDocumentData(Map<String, dynamic> data) {
    // ตรวจสอบว่ามีฟิลด์ที่จำเป็นครบถ้วนหรือไม่
    return data.containsKey('detected_text') &&
        data.containsKey('timestamp') &&
        data['detected_text'] != null;
  }

  String _prepareNotificationMessage(DocumentSnapshot document, Map<String, dynamic> data) {
    // ดึงข้อมูลและจัดการกรณีที่ข้อมูลเป็น null
    String detectionText = data['detected_text']?.toString() ?? 'ไม่พบข้อมูล';
    String timestamp = '';

    // จัดการกับ timestamp ที่อาจเป็น string หรือ Timestamp
    var timestampData = data['timestamp'];
    if (timestampData is Timestamp) {
      timestamp = timestampData.toDate().toString();
    } else if (timestampData is String) {
      timestamp = timestampData;
    } else {
      timestamp = 'ไม่พบเวลา';
    }

    return '''
\n
📝 License Plate: $detectionText
⏰ date&Time: $timestamp
''';
  }

  Future<void> sendLineNotify(String message) async {
    final Uri url = Uri.parse('https://notify-api.line.me/api/notify');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $lineNotifyToken'
        },
        body: {'message': message},
      );

      if (response.statusCode == 200) {
        debugPrint('ส่งการแจ้งเตือนสำเร็จ');
      } else {
        debugPrint('ส่งการแจ้งเตือนไม่สำเร็จ: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการส่งการแจ้งเตือน: $e');
    }
  }
}
