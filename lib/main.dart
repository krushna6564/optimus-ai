import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const OptimusApp());
}

class OptimusApp extends StatelessWidget {
  const OptimusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OPTIMUS",
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
