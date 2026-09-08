import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: Image.asset(
          'assets/IMG_4803.png',
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
