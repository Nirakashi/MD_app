import 'package:flutter/material.dart';
import 'BoundingBox.dart';

class OverlayView extends StatelessWidget {
  final List<BoundingBox> boundingBoxes;

  const OverlayView({Key? key, required this.boundingBoxes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BoxPainter(boundingBoxes),
    );
  }
}

class BoxPainter extends CustomPainter {
  final List<BoundingBox> boundingBoxes;
  BoxPainter(this.boundingBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    boundingBoxes.forEach((box) {
      canvas.drawRect(
        Rect.fromLTRB(
          box.x1 * size.width,
          box.y1 * size.height,
          box.x2 * size.width,
          box.y2 * size.height,
        ),
        paint,
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
