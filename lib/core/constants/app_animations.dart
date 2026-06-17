import 'package:flutter/material.dart';

class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizeCurve = Curves.easeOutQuart;
  static const Curve decelerateCurve = Curves.easeOutCubic;

  // Transitions
  static Widget fadeThroughTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  static Widget slideUpTransition(Widget child, Animation<double> animation) {
    final offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: decelerateCurve,
    ));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: offsetAnimation,
        child: child,
      ),
    );
  }
}
