import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart';

/// Lectura por voz con el motor del sistema en Android.
///
/// La inicialización del motor es perezosa: la primera llamada configura
/// idioma y velocidad. Los fallos del motor nunca deben propagarse al
/// flujo de reconocimiento.
class AndroidTtsService implements TtsService {
  AndroidTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _configure() async {
    if (_configured) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    if (!isSupported) return;
    try {
      await _configure();
      await _tts.speak(text);
    } catch (_) {
      // La voz es un extra accesible: su fallo no debe romper la app.
    }
  }

  @override
  Future<void> stop() async {
    if (!isSupported) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

TtsService createPlatformTtsService() => AndroidTtsService();
