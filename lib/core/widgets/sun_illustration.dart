import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

/// Custom painted sun illustration matching the DIGIPe design.
/// Solid orange circle with slow-rotating triangular rays and a glow.
class SunIllustration extends StatefulWidget {
  final double size;
  const SunIllustration({super.key, this.size = 120});

  @override
  State<SunIllustration> createState() => _SunIllustrationState();
}

class _SunIllustrationState extends State<SunIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _rotation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) => CustomPaint(
          painter: _SunPainter(rotation: _rotation.value),
        ),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  final double rotation;

  const _SunPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppColors.sunOrange.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius * 1.55, glowPaint);

    // Medium glow ring
    final glowPaint2 = Paint()
      ..color = AppColors.sunOrange.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 1.3, glowPaint2);

    // Rays — 12 rays rotating slowly
    final rayPaint = Paint()
      ..color = AppColors.sunOrange.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    const halfWidth = 0.04;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi;
      final innerR = radius * 1.18;
      final outerR = radius * 1.55;

      final path = Path()
        ..moveTo(
          innerR * math.cos(angle - halfWidth),
          innerR * math.sin(angle - halfWidth),
        )
        ..lineTo(
          outerR * math.cos(angle),
          outerR * math.sin(angle),
        )
        ..lineTo(
          innerR * math.cos(angle + halfWidth),
          innerR * math.sin(angle + halfWidth),
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
    canvas.restore();

    // Main sun circle — radial gradient fill
    final sunGradient = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.sunOrange, AppColors.sunOrangeDeep],
        center: const Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sunGradient);

    // Inner highlight crescent (top-left)
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final highlightPath = Path()
      ..addOval(Rect.fromCircle(
        center: center + const Offset(-6, -6),
        radius: radius * 0.7,
      ));
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.rotation != rotation;
}