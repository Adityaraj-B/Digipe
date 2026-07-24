import 'package:flutter/material.dart';
import 'dart:math' as math;

class SunIllustration extends StatelessWidget {
  final double size;
  const SunIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SunPainter(),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.72;
    const petalCount = 12;

    // Scalloped petal ring (orange)
    final petalPaint = Paint()
      ..color = const Color(0xFFF5811F)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < petalCount; i++) {
      final angle = (2 * math.pi / petalCount) * i;
      final nextAngle = (2 * math.pi / petalCount) * (i + 1);
      final midAngle = (angle + nextAngle) / 2;

      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final pMid = Offset(
        center.dx + outerRadius * math.cos(midAngle),
        center.dy + outerRadius * math.sin(midAngle),
      );
      final p2 = Offset(
        center.dx + innerRadius * math.cos(nextAngle),
        center.dy + innerRadius * math.sin(nextAngle),
      );

      if (i == 0) path.moveTo(p1.dx, p1.dy);
      path.quadraticBezierTo(pMid.dx, pMid.dy, p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, petalPaint);

    // Inner solid circle (yellow-orange gradient)
    final innerPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFFC93C),
          Color(0xFFF9A825),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius * 0.92));

    canvas.drawCircle(center, innerRadius * 0.92, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}