import 'dart:async';
import 'package:flutter/material.dart';

/// Enumeración de comandos de voz reconocibles
enum VoiceCommand {
  acceptRide,
  rejectRide,
  startRide,
  completeRide,
  unknown,
}

/// Servicio simplificado de reconocimiento de voz
/// Esta implementación simula el reconocimiento de voz para evitar problemas de compilación
class VoiceRecognitionService {
  static final VoiceRecognitionService _instance =
      VoiceRecognitionService._internal();
  static VoiceRecognitionService get instance => _instance;

  VoiceRecognitionService._internal();

  bool _isListening = false;
  bool _isInitialized = true;
  Timer? _listeningTimer;
  final StreamController<VoiceCommand> _commandController =
      StreamController<VoiceCommand>.broadcast();

  Stream<VoiceCommand> get onCommand => _commandController.stream;
  bool get isListening => _isListening;

  // Mapa de comandos y sus palabras clave
  final Map<VoiceCommand, List<String>> _commandKeywords = {
    VoiceCommand.acceptRide: [
      'accept',
      'yes',
      'ok',
      'قبول',
      'نعم',
      'موافق',
      'اقبل',
      'اوافق',
      'اوك',
      'حسنا'
    ],
    VoiceCommand.rejectRide: [
      'reject',
      'no',
      'cancel',
      'رفض',
      'لا',
      'الغاء',
      'ارفض',
      'الغي'
    ],
    VoiceCommand.startRide: [
      'start',
      'begin',
      'go',
      'ابدأ',
      'انطلق',
      'بدء',
      'ابدا',
      'يلا'
    ],
    VoiceCommand.completeRide: [
      'complete',
      'finish',
      'end',
      'done',
      'انهي',
      'انتهى',
      'خلص',
      'تم',
      'وصلنا'
    ],
  };

  /// Inicializa el servicio (simulado)
  Future<bool> initialize() async {
    return _isInitialized;
  }

  /// Comienza a escuchar comandos de voz (simulado)
  /// Esta versión mejorada permite al usuario seleccionar un comando específico
  /// para pruebas, o usar el modo automático
  Future<void> startListening({VoiceCommand? forcedCommand}) async {
    if (_isListening) return;

    _isListening = true;

    // Mostrar mensaje de depuración
    debugPrint('🎤 Iniciando reconocimiento de voz...');

    // Simular el reconocimiento de voz con un temporizador
    _listeningTimer = Timer(const Duration(seconds: 3), () {
      VoiceCommand command;

      if (forcedCommand != null) {
        // Usar el comando forzado si se proporciona
        command = forcedCommand;
        debugPrint('🎤 Usando comando forzado: $command');
      } else {
        // Simular un comando aleatorio (para demostración)
        // Modificado para favorecer "aceptar" con mayor probabilidad (70%)
        final random = (DateTime.now().millisecondsSinceEpoch % 10);

        if (random < 7) {
          // 70% de probabilidad de aceptar
          command = VoiceCommand.acceptRide;
          debugPrint('🎤 Simulando comando de voz: ACEPTAR');
        } else if (random < 9) {
          // 20% de probabilidad de rechazar
          command = VoiceCommand.rejectRide;
          debugPrint('🎤 Simulando comando de voz: RECHAZAR');
        } else {
          // 10% de probabilidad de comando desconocido
          command = VoiceCommand.unknown;
          debugPrint('🎤 Simulando comando de voz: DESCONOCIDO');
        }
      }

      // Enviar el comando al controlador
      _commandController.add(command);

      // Actualizar estado
      _isListening = false;
      debugPrint('🎤 Reconocimiento de voz finalizado');
    });
  }

  /// Detiene la escucha de comandos de voz
  Future<void> stopListening() async {
    _listeningTimer?.cancel();
    _isListening = false;
  }

  /// Simula la conversión de texto a voz
  Future<void> speak(String text) async {
    debugPrint('🔊 TTS: $text');
  }

  /// Libera recursos
  void dispose() {
    _listeningTimer?.cancel();
    _commandController.close();
  }
}
