
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
  String _transcript = '';

  @override
  void initState() {
    super.initState();

    _voiceSubscription = _voiceEngine.events.listen((event) {
      if (!mounted) return;

      setState(() {
        if (event == 'wake_word_detected') {
          _wakeWordCount++;
          _transcript = 'Wake word detected. Listening...';
        } else if (event.startsWith('transcript:')) {
          _transcript = event.substring('transcript:'.length).trim();
        } else if (event == 'voice_ready') {
          _transcript = 'Listening for Hey Optimus...';
        } else if (event == 'voice_stopped') {
          _isVoiceEngineRunning = false;
          _transcript = 'Voice engine stopped.';
        } else if (event.startsWith('voice_error:')) {
          _transcript = 'Voice error: ${event.substring('voice_error:'.length)}';
        }
      });
    });
  }

  Future<void> _toggleVoiceEngine() async {
    if (_isVoiceEngineRunning) {
      await _voiceEngine.stop();
      if (!mounted) return;
      setState(() {
        _isVoiceEngineRunning = false;
        _transcript = 'Voice engine stopped.';
      });
    } else {
      try {
        await _voiceEngine.start();
        if (!mounted) return;
        setState(() {
          _isVoiceEngineRunning = true;
          _transcript = 'Starting voice engine...';
        });
      } catch (error) {
        debugPrint('Could not start voice engine: $error');
        if (!mounted) return;
        setState(() {
          _isVoiceEngineRunning = false;
          _transcript = 'Could not start voice engine.';
        });
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
            bottom: 100,
            left: 24,
            right: 24,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF101A35).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _transcript.isEmpty
                      ? 'Your recognized speech will appear here'
                      : _transcript,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),

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