import 'package:flutter/material.dart';
import 'dart:math';

// Simple Confetti Painter
class ConfettiPainter extends CustomPainter {
  final List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random();

    for (int i = 0; i < 50; i++) {
      paint.color = colors[random.nextInt(colors.length)].withValues(alpha: 0.8);
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double r = random.nextDouble() * 5 + 2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
