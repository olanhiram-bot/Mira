import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mira/recognition/image_recognition.dart';
import 'package:mira/recognition/recognition_panel.dart';
import 'package:mira/speech/tts_service.dart';

/// Fake que registra el texto hablado para poder verificar la interacción.
class FakeTtsService implements TtsService {
  final List<String> spoken = <String>[];
  bool stopped = false;
  bool supported = true;

  @override
  bool get isSupported => supported;

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

void main() {
  Future<ImageRecognitionResult> recognizedResult() async {
    return ImageRecognitionResult.fromCandidates(const [
      RecognitionCandidate(label: 'washing machine', confidence: 0.91),
    ]);
  }

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('el panel ofrece escuchar la identificación en voz alta', (
    WidgetTester tester,
  ) async {
    final tts = FakeTtsService();
    await tester.pumpWidget(
      wrap(
        RecognitionResultPanel(
          future: recognizedResult(),
          onConfirmed: (_) {},
          tts: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listenButton = find.byKey(const ValueKey('listen-explanation'));
    expect(listenButton, findsOneWidget);

    await tester.tap(listenButton);
    await tester.pumpAndSettle();

    expect(tts.spoken, isNotEmpty);
    expect(tts.spoken.first, contains('Lavadora'));
  });

  testWidgets(
    'el panel omite el botón de voz cuando el TTS no está disponible',
    (WidgetTester tester) async {
      final tts = FakeTtsService()..supported = false;
      await tester.pumpWidget(
        wrap(
          RecognitionResultPanel(
            future: recognizedResult(),
            onConfirmed: (_) {},
            tts: tts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('listen-explanation')), findsNothing);
    },
  );

  testWidgets('el panel detiene la voz si se vuelve a tocar el botón', (
    WidgetTester tester,
  ) async {
    final tts = FakeTtsService();
    await tester.pumpWidget(
      wrap(
        RecognitionResultPanel(
          future: recognizedResult(),
          onConfirmed: (_) {},
          tts: tts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final listenButton = find.byKey(const ValueKey('listen-explanation'));
    await tester.tap(listenButton);
    await tester.pumpAndSettle();
    await tester.tap(listenButton);
    await tester.pumpAndSettle();

    expect(tts.stopped, isTrue);
  });
}
