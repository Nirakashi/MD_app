import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LineNotifyFirebaseService {
  final String lineNotifyToken;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late StreamSubscription _firestoreListener;

  LineNotifyFirebaseService({required this.lineNotifyToken});

  // เริ่มการตรวจสอบการอัปเดต
  void startListening({
    required String collectionPath,
    Function(Map<String, dynamic>)? onUpdateCallback,
  }) {
    _firestoreListener = _firestore
        .collection(collectionPath)
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added ||
            docChange.type == DocumentChangeType.modified) {
          _handleDocumentUpdate(
            docChange.doc,
            onUpdateCallback: onUpdateCallback,
          );
        }
      }
    }, onError: (error) {
      debugPrint('Firestore Listener Error: $error');
    });
  }

  // หยุดการตรวจสอบ
  void stopListening() {
    _firestoreListener.cancel();
  }

  // จัดการเมื่อมีการอัปเดตเอกสาร
  Future<void> _handleDocumentUpdate(
      DocumentSnapshot document,
      {Function(Map<String, dynamic>)? onUpdateCallback}
      ) async {
    try {
      Map<String, dynamic>? data = document.data() as Map<String, dynamic>?;

      if (data != null) {
        // เตรียมข้อความแจ้งเตือน
        String message = _prepareNotificationMessage(document, data);

        // ส่งการแจ้งเตือน Line
        await sendLineNotify(message);

        // เรียกใช้ callback หากมีการส่งมา
        if (onUpdateCallback != null) {
          onUpdateCallback(data);
        }
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการประมวลผลเอกสาร: $e');
    }
  }

  // จัดเตรียมข้อความแจ้งเตือน
  String _prepareNotificationMessage(
      DocumentSnapshot document,
      Map<String, dynamic> data
      ) {
    String detectionText = data['detection_Text'] ?? 'ไม่มีข้อความ';
    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

    return '''
มีการอัปเดตเอกสาร
ข้อความตรวจจับ: $detectionText
เวลา: ${timestamp.toDate()}
รหัสเอกสาร: ${document.id}
''';
  }

  // ส่งการแจ้งเตือนผ่าน Line Notify
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
        debugPrint('ส่งการแจ้งเตือนไม่สำเร็จ: ${response.body}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการส่งการแจ้งเตือน: $e');
    }
  }
}

// ตัวอย่างการใช้งานใน Widget อื่นๆ
class ExampleUsageWidget extends StatefulWidget {
  @override
  _ExampleUsageWidgetState createState() => _ExampleUsageWidgetState();
}

class _ExampleUsageWidgetState extends State<ExampleUsageWidget> {
  late LineNotifyFirebaseService _lineNotifyService;

  @override
  void initState() {
    super.initState();

    // สร้าง Service โดยใส่ Line Notify Token
    _lineNotifyService = LineNotifyFirebaseService(
        lineNotifyToken: 'iYUtTdNSa1aON7tEuhSFFcA7R8lM1mYGyQgw3tvplwM'
    );

    // เริ่มการฟังการอัปเดตใน Collection 'Test'
    _lineNotifyService.startListening(
        collectionPath: 'Test',
        onUpdateCallback: (data) {
          // ทำอะไรบางอย่างเมื่อมีการอัปเดต เช่น อัปเดต UI
          print('มีการอัปเดตข้อมูล: $data');
        }
    );
  }

  @override
  void dispose() {
    // อย่าลืมหยุดการฟังเมื่อ Widget ถูกทำลาย
    _lineNotifyService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Example Usage")),
      body: Center(
        child: Text("Listening for updates..."),
      ),
    );
  }
}
