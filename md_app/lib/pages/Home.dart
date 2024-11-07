import 'package:flutter/material.dart';
import 'package:md_app/pages/report 1.dart';
import 'package:md_app/pages/report 2.dart';
import 'package:md_app/pages/report 3.dart';
import 'package:md_app/pages/tutorial.dart';
import 'Camera.dart';
import 'package:md_app/pages/profile.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: currentIndex == 0
          ? AppBar(
        title: Text('Home'),
      )
          : null,
      body: IndexedStack(
        index: currentIndex,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // เปลี่ยนให้ขยายเต็มที่
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => report1Screen()),
                    );
                  },
                  child: Text(
                    'สถิติการตรวจจับการกระทำผิด',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => report2Screen()),
                    );
                  },
                  child: Text(
                    'ข้อมูลช่วงเวลาที่มีการกระทำผิด',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => report3Screen()),
                    );
                  },
                  child: Text(
                    'อัตราการกระทำผิดในพื้นที่ต่างๆ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TutorialScreen()),
                    );
                  },
                  child: Text(
                    'Tutorial',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CameraScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: 'Camera'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
    );
  }
}
