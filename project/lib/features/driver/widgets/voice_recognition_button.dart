import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

/// Botón de reconocimiento de voz con efecto de brillo
class VoiceRecognitionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isListening;

  const VoiceRecognitionButton({
    super.key,
    required this.onPressed,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AvatarGlow(
        animate: isListening,
        glowColor: Colors.blue,
        endRadius: 40.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? Colors.blue : Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            color: isListening ? Colors.white : Colors.blue,
            size: 30,
          ),
        ),
      ),
    );
  }
}
