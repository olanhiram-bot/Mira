import 'tts_service.dart';

/// Lectura por voz no disponible (Web y plataformas sin motor de voz).
class UnsupportedTtsService implements TtsService {
  const UnsupportedTtsService();

  @override
  bool get isSupported => false;

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

TtsService createPlatformTtsService() => const UnsupportedTtsService();
