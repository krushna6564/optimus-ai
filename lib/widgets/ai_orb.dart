import 'package:flutter/material.dart';

class AiOrb extends StatelessWidget {
  const AiOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFF3B82F6),
              Color(0xFF1E3A8A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.45),
              blurRadius: 80,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}