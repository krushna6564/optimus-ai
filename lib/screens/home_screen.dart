import 'package:flutter/material.dart';
import '../widgets/animated_background.dart';
import '../widgets/header_widget.dart';
import '../widgets/ai_orb.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),

          const HeaderWidget(),

          const AiOrb(),
        ],
      ),
    );
  }
}