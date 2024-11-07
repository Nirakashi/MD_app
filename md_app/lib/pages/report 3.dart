import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class report3Screen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'อัตราการกระทำผิดในพื้นที่',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UserCurrentLocation(),
    );
  }
}

class UserCurrentLocation extends StatefulWidget {
  @override
  _UserCurrentLocationState createState() => _UserCurrentLocationState();
}

class _UserCurrentLocationState extends State<UserCurrentLocation> {
  GoogleMapController? mapController;
  LatLng? _center;
  Position? _currentPosition;

  final Set<Marker> _markers = {
    Marker(
      markerId: MarkerId('huai_khwang'),
      position: LatLng(13.7749, 100.5782),
      infoWindow: InfoWindow(
        title: 'เขตห้วยขวาง',
        snippet: 'ผู้กระทำผิด 120 ราย',
      ),
    ),
    Marker(
      markerId: MarkerId('din_daeng'),
      position: LatLng(13.7780971, 100.5385511),
      infoWindow: InfoWindow(
        title: 'เขตดินแดง',
        snippet: 'ผู้กระทำผิด 110 ราย',
      ),
    ),
    Marker(
      markerId: MarkerId('wang_thonglang'),
      position: LatLng(13.7802, 100.6089),
      infoWindow: InfoWindow(
        title: 'เขตวังทองหลาง',
        snippet: 'ผู้กระทำผิด 90 ราย',
      ),
    ),
  };

  Marker? _userMarker;
  CameraPosition? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_userPosition != null) {
      controller.animateCamera(CameraUpdate.newCameraPosition(_userPosition!));
    }
  }

  _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Request permission to get the user's location
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    // Get the current location of the user
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _center = LatLng(position.latitude, position.longitude);
      _userMarker = Marker(
        markerId: MarkerId('user_location'),
        position: _center!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // จุดฟ้า
        infoWindow: InfoWindow(title: 'Your Location'),
      );

      _userPosition = CameraPosition(
        target: _center!,
        zoom: 15.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Location Map'),
      ),
      body: Column(
        children: [
          // แสดงแผนที่ในครึ่งหน้าจอ
          _center == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
            height: MediaQuery.of(context).size.height * 0.5, // กำหนดความสูงเป็นครึ่งหน้าจอ
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center!,
                zoom: 15.0,
              ),
              markers: _markers..addAll(_userMarker != null ? {_userMarker!} : {}),
            ),
          ),
          // ส่วนอื่นๆ ที่คุณต้องการในด้านล่าง
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เขตที่มีผู้กระทำผิดมากที่สุด',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 8),
                  _buildDistrictRow('เขตห้วยขวาง', '120 ราย', () => _goToLocation(13.7749, 100.5782)),
                  SizedBox(height: 8),
                  _buildDistrictRow('เขตดินแดง', '110 ราย', () => _goToLocation(13.7780971, 100.5385511)),
                  SizedBox(height: 8),
                  _buildDistrictRow('เขตวังทองหลาง', '90 ราย', () => _goToLocation(13.7802, 100.6089)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _userPosition != null
          ? FloatingActionButton(
        onPressed: () {
          _goToUserLocation();
        },
        child: Icon(Icons.my_location),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }

  // ฟังก์ชันเลื่อนไปยังตำแหน่งของผู้ใช้งาน
  Future<void> _goToUserLocation() async {
    if (_userPosition != null) {
      final GoogleMapController controller = await mapController!;
      controller.animateCamera(CameraUpdate.newCameraPosition(_userPosition!));
    }
  }

  // Widget สำหรับสร้างแถวข้อมูลเขตที่สามารถกดได้
  Widget _buildDistrictRow(String district, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            district,
            style: TextStyle(fontSize: 16),
          ),
          Text(
            count,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสำหรับเลื่อนไปยังตำแหน่งที่เลือก
  Future<void> _goToLocation(double lat, double lng) async {
    final GoogleMapController controller = await mapController!;
    final CameraPosition newPosition = CameraPosition(
      target: LatLng(lat, lng),
      zoom: 15,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }
}
