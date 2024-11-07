import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutoria'),
      ),
      body: Center(
        child: Text('Welcome to Camera Screen!'),
      ),
    );
  }
}