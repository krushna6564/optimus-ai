import 'package:flutter/material.dart';

class AIOrb extends StatelessWidget {
  const AIOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF00BFFF),
            Color(0xFF0066FF),
            Color(0xFF001A33),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.7),
            blurRadius: 40,
            spreadRadius: 12,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.memory,
          size: 90,
          color: Colors.white,
        ),
      ),
    );
  }
}