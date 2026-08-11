import 'tts_platform_stub.dart'
    if (dart.library.io) 'tts_platform_io.dart'
    as platform;

/// Contrato de lectura en voz alta para las explicaciones.
///
/// La implementación real existe solo en plataformas con motor de voz
/// disponible (Android). En el resto, el servicio declara no estar
/// disponible y la interfaz degrada sin romper el flujo.
abstract interface class TtsService {
  bool get isSupported;

  Future<void> speak(String text);

  Future<void> stop();
}

TtsService createTtsService() => platform.createPlatformTtsService();
