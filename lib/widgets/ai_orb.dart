import 'dart:async';

import 'package:flutter/material.dart';

enum AiState {
  idle,
  listening,
  thinking,
}

class AiOrb extends StatefulWidget {
  const AiOrb({super.key});

  @override
  State<AiOrb> createState() => _AiOrbState();
}

class _AiOrbState extends State<AiOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  AiState _state = AiState.idle;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _handleOrbTap() {
    if (_state == AiState.idle) {
      setState(() {
        _state = AiState.listening;
      });

      _controller.duration = const Duration(milliseconds: 800);
    } else if (_state == AiState.listening) {
      setState(() {
        _state = AiState.thinking;
      });

      _controller.duration = const Duration(milliseconds: 600);

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;

        setState(() {
          _state = AiState.idle;
        });

        _controller.duration = const Duration(seconds: 2);
      });
    }
  }

  String get _statusText {
    switch (_state) {
      case AiState.idle:
        return 'OPTIMUS is ready';

      case AiState.listening:
        return 'Listening...';

      case AiState.thinking:
        return 'Thinking...';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _handleOrbTap,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final animationValue =
                      Curves.easeInOut.transform(_controller.value);

                  double scale;
                  double glow;
                  double opacity;

                  switch (_state) {
                    case AiState.idle:
                      scale = 0.94 + (animationValue * 0.12);
                      glow = 20 + (animationValue * 25);
                      opacity = 0.65;

                    case AiState.listening:
                      scale = 0.90 + (animationValue * 0.20);
                      glow = 30 + (animationValue * 35);
                      opacity = 0.85;

                    case AiState.thinking:
                      scale = 0.88 + (animationValue * 0.24);
                      glow = 35 + (animationValue * 45);
                      opacity = 0.95;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFF4285F4),
                            Color(0xFF2455B8),
                            Color(0xFF132B63),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2878FF).withValues(
                              alpha: opacity,
                            ),
                            blurRadius: glow,
                            spreadRadius:
                                _state == AiState.thinking ? 10 : 5,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 25),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _statusText,
              key: ValueKey(_state),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}