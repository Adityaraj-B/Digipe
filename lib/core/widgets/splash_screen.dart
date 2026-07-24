import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Center Logo
            Image.asset(
              'assets/images/Logo White.png',
              width: 160,
              height: 60,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image fails to load
                return Image.asset(
                  'assets/images/Icon.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFAF9F8),
                      size: 80,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            // Subtle Loading Indicator
            const SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                color: Color(0xFFFAF9F8),
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
