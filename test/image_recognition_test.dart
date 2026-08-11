import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mira/main.dart';
import 'package:mira/recognition/image_recognition.dart';
import 'package:mira/recognition/recognition_panel.dart';

void main() {
  test('normaliza etiquetas útiles en español y por confianza', () {
    final result = ImageRecognitionResult.fromCandidates([
      const RecognitionCandidate(label: 'Washing machine', confidence: 0.91),
      const RecognitionCandidate(label: 'Home appliance', confidence: 0.84),
      const RecognitionCandidate(label: 'Furniture', confidence: 0.32),
      const RecognitionCandidate(label: 'Washing machine', confidence: 0.72),
    ]);

    expect(result.status, RecognitionStatus.recognized);
    expect(result.things, hasLength(2));
    expect(result.things.first.label, 'Lavadora');
    expect(result.things.first.confidence, 0.91);
    expect(result.things.last.label, 'Electrodoméstico');
  });

  test('mapea las etiquetas del modelo de dominio a nombres visibles', () {
    const pairs = <String, String>{
      'lavadora': 'Lavadora',
      'microondas': 'Microondas',
      'refrigerador': 'Refrigerador',
      'tostadora': 'Tostadora',
    };
    for (final entry in pairs.entries) {
      final result = ImageRecognitionResult.fromCandidates([
        RecognitionCandidate(label: entry.key, confidence: 0.9),
      ]);
      expect(result.things.single.label, entry.value, reason: entry.key);
    }
  });

  test('una predicción de dominio con confianza baja queda incierta', () async {
    final service = LocalImageRecognitionService(
      processor: (_) async => const [
        RecognitionCandidate(label: 'tostadora', confidence: 0.48),
      ],
    );

    final result = await service.recognize(imagePath: '/tmp/photo.jpg');

    expect(result.status, RecognitionStatus.uncertain);
    expect(result.things, isEmpty);
  });

  test('limita y traduce las mejores predicciones de objetos comunes', () {
    final result = ImageRecognitionResult.fromCandidates([
      const RecognitionCandidate(label: 'Refrigerator', confidence: 0.96),
      const RecognitionCandidate(label: 'Microwave oven', confidence: 0.90),
      const RecognitionCandidate(label: 'Remote control', confidence: 0.86),
      const RecognitionCandidate(label: 'Mobile phone', confidence: 0.80),
    ]);

    expect(result.things.map((thing) => thing.label), [
      'Refrigerador',
      'Horno de microondas',
      'Control remoto',
    ]);
  });

  test('no presenta etiquetas genéricas como una identificación', () {
    final result = ImageRecognitionResult.fromCandidates([
      const RecognitionCandidate(label: 'Machine', confidence: 0.94),
      const RecognitionCandidate(label: 'Product', confidence: 0.90),
      const RecognitionCandidate(label: 'Technology', confidence: 0.81),
    ]);

    expect(result.status, RecognitionStatus.uncertain);
    expect(result.things, isEmpty);
  });

  testWidgets('muestra una predicción con confianza y pide confirmación', (
    tester,
  ) async {
    RecognizedThing? confirmed;
    final result = ImageRecognitionResult.fromCandidates([
      const RecognitionCandidate(label: 'Washing machine', confidence: 0.91),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecognitionResultPanel(
            future: Future.value(result),
            onConfirmed: (thing) => confirmed = thing,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Parece ser: Lavadora'), findsOneWidget);
    expect(find.text('91% de confianza'), findsOneWidget);
    expect(find.textContaining('Confirma antes'), findsOneWidget);
    await tester.tap(find.text('Sí, es correcto'));
    expect(confirmed?.label, 'Lavadora');
  });

  testWidgets(
    'confirmar la primera sugerencia no se registra como corrección',
    (tester) async {
      RecognizedThing? confirmed;
      RecognizedThing? corrected;
      final result = ImageRecognitionResult.fromCandidates([
        const RecognitionCandidate(label: 'Washing machine', confidence: 0.91),
        const RecognitionCandidate(label: 'Refrigerator', confidence: 0.72),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecognitionResultPanel(
              future: Future.value(result),
              onConfirmed: (thing) => confirmed = thing,
              onCorrected: (thing) => corrected = thing,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Sí, es correcto'));
      expect(confirmed?.label, 'Lavadora');
      expect(corrected, isNull);
    },
  );

  testWidgets(
    'elegir otra opción antes de confirmar se registra como corrección',
    (tester) async {
      RecognizedThing? confirmed;
      RecognizedThing? corrected;
      final result = ImageRecognitionResult.fromCandidates([
        const RecognitionCandidate(label: 'Washing machine', confidence: 0.91),
        const RecognitionCandidate(label: 'Refrigerator', confidence: 0.72),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecognitionResultPanel(
              future: Future.value(result),
              onConfirmed: (thing) => confirmed = thing,
              onCorrected: (thing) => corrected = thing,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Refrigerador'));
      await tester.pump();
      await tester.tap(find.text('Sí, es correcto'));

      expect(confirmed?.label, 'Refrigerador');
      expect(corrected?.label, 'Refrigerador');
    },
  );

  test(
    'el servicio convierte la salida local de IA al modelo de la app',
    () async {
      final service = LocalImageRecognitionService(
        processor: (_) async => const [
          RecognitionCandidate(label: 'Refrigerator', confidence: 0.88),
        ],
      );

      final result = await service.recognize(imagePath: '/tmp/photo.jpg');

      expect(result.status, RecognitionStatus.recognized);
      expect(result.things.single.label, 'Refrigerador');
    },
  );

  test('el modelo especializado rechaza una predicción moderada', () async {
    final service = LocalImageRecognitionService(
      processor: (_) async => const [
        RecognitionCandidate(label: 'flagpole', confidence: 0.45),
      ],
    );

    final result = await service.recognize(imagePath: '/tmp/city.jpg');

    expect(result.status, RecognitionStatus.uncertain);
  });

  test(
    'el modelo especializado identifica un mouse con confianza alta',
    () async {
      final service = LocalImageRecognitionService(
        processor: (_) async => const [
          RecognitionCandidate(label: 'mouse', confidence: 0.72),
        ],
      );

      final result = await service.recognize(imagePath: '/tmp/mouse.jpg');

      expect(result.status, RecognitionStatus.recognized);
      expect(result.things.single.label, 'Mouse de computadora');
    },
  );

  test(
    'el servicio convierte fallos de inferencia en un estado seguro',
    () async {
      final service = LocalImageRecognitionService(
        processor: (_) => Future.error(StateError('modelo no disponible')),
      );

      final result = await service.recognize(imagePath: '/tmp/photo.jpg');

      expect(result.status, RecognitionStatus.failed);
    },
  );

  test('el servicio declara no disponible una plataforma sin modelo', () async {
    var processorCalled = false;
    final service = LocalImageRecognitionService(
      supported: false,
      processor: (_) async {
        processorCalled = true;
        return const [];
      },
    );

    final result = await service.recognize(imagePath: '/tmp/photo.jpg');

    expect(result.status, RecognitionStatus.unavailable);
    expect(processorCalled, isFalse);
  });

  testWidgets('explica cuando el reconocimiento no está disponible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecognitionResultPanel(
            future: Future.value(const ImageRecognitionResult.unavailable()),
            onConfirmed: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text('El reconocimiento de objetos está disponible en Android.'),
      findsOneWidget,
    );
  });

  testWidgets('mantiene el respaldo manual cuando la inferencia falla', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecognitionResultPanel(
            future: Future.value(const ImageRecognitionResult.failed()),
            onConfirmed: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'La IA no pudo analizar la foto. Toma otra foto e intenta nuevamente.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('no afirma una identidad cuando la confianza es insuficiente', (
    tester,
  ) async {
    final uncertain = ImageRecognitionResult.fromCandidates([
      const RecognitionCandidate(label: 'Toaster', confidence: 0.40),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecognitionResultPanel(
            future: Future.value(uncertain),
            onConfirmed: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Objeto no identificado con suficiente seguridad. Prueba otra foto con el objeto completo y buena luz.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Parece ser:'), findsNothing);
  });

  testWidgets('la revisión completa se puede desplazar con texto grande', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.6),
          ),
          child: Scaffold(
            body: CapturedImageView(
              image: XFile('/missing-photo.png'),
              onRetake: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('captured-review-scroll')),
      findsOneWidget,
    );
    expect(find.textContaining('zona'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
