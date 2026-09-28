
import 'dart:async';

import 'package:flutter/material.dart';

import '../voice/voice_engine_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/header_widget.dart';
import '../widgets/ai_orb.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceEngineService _voiceEngine = VoiceEngineService();
  StreamSubscription<String>? _voiceSubscription;

  int _wakeWordCount = 0;
  bool _isVoiceEngineRunning = false;

  @override
  void initState() {
    super.initState();

    _voiceSubscription = _voiceEngine.events.listen((event) {
      if (event == 'wake_word_detected' && mounted) {
        setState(() {
          _wakeWordCount++;
        });
      }
    });
  }

  Future<void> _toggleVoiceEngine() async {
    if (_isVoiceEngineRunning) {
      await _voiceEngine.stop();
      if (!mounted) return;
      setState(() {
        _isVoiceEngineRunning = false;
      });
    } else {
      try {
        await _voiceEngine.start();
        if (!mounted) return;
        setState(() {
          _isVoiceEngineRunning = true;
        });
      } catch (error) {
        debugPrint('Could not start voice engine: $error');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start voice engine: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          const HeaderWidget(),
          AiOrb(wakeWordCount: _wakeWordCount),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _toggleVoiceEngine,
                icon: Icon(
                  _isVoiceEngineRunning ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  _isVoiceEngineRunning
                      ? 'Stop Voice Engine'
                      : 'Start Voice Engine',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}