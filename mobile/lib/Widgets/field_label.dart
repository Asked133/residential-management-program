import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
    );
  }
}

