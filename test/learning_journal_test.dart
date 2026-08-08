import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mira/recognition/learning_journal.dart';
import 'package:mira/recognition/learning_journal_io.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mira-journal-test-');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('guarda un ejemplo etiquetado y lo lee de vuelta', () async {
    final journal = FileLearningJournal(
      File('${tempDir.path}/mira_learning.jsonl'),
    );

    await journal.record(
      const LearningExample(
        imagePath: '/tmp/photo.jpg',
        label: 'Lavadora',
        confidence: 0.91,
        timestamp: '2026-08-08T12:00:00.000',
      ),
    );

    final examples = await journal.readAll();

    expect(examples, hasLength(1));
    expect(examples.single.imagePath, '/tmp/photo.jpg');
    expect(examples.single.label, 'Lavadora');
    expect(examples.single.confidence, 0.91);
    expect(examples.single.corrected, isFalse);
    expect(examples.single.timestamp, '2026-08-08T12:00:00.000');
  });

  test('acumula varias confirmaciones en orden y marca correcciones', () async {
    final journal = FileLearningJournal(
      File('${tempDir.path}/mira_learning.jsonl'),
    );

    await journal.record(
      const LearningExample(
        imagePath: '/tmp/a.jpg',
        label: 'Lavadora',
        confidence: 0.91,
      ),
    );
    await journal.record(
      const LearningExample(
        imagePath: '/tmp/b.jpg',
        label: 'Horno de microondas',
        confidence: 0.62,
        corrected: true,
      ),
    );

    final examples = await journal.readAll();

    expect(examples, hasLength(2));
    expect(examples[0].label, 'Lavadora');
    expect(examples[0].corrected, isFalse);
    expect(examples[1].label, 'Horno de microondas');
    expect(examples[1].corrected, isTrue);
    expect(examples[1].imagePath, '/tmp/b.jpg');
  });

  test('un diario sin registros devuelve una lista vacía', () async {
    final journal = FileLearningJournal(
      File('${tempDir.path}/no_existe.jsonl'),
    );

    expect(await journal.readAll(), isEmpty);
  });

  test('una línea corrupta no rompe el resto del diario', () async {
    final file = File('${tempDir.path}/mira_learning.jsonl');
    await file.writeAsString(
      '{"v":1,"label":"Lavadora"}\n'
      'esto-no-es-json\n'
      '{"v":1,"label":"Refrigerador","corrected":true}\n',
    );
    final journal = FileLearningJournal(file);

    final examples = await journal.readAll();

    expect(examples, hasLength(2));
    expect(examples[0].label, 'Lavadora');
    expect(examples[1].label, 'Refrigerador');
    expect(examples[1].corrected, isTrue);
  });

  test(
    'una foto temporal se copia al almacenamiento durable del diario',
    () async {
      final original = File('${tempDir.path}/foto_temporal.jpg');
      await original.writeAsBytes([1, 2, 3, 4]);
      final journal = FileLearningJournal(
        File('${tempDir.path}/mira_learning.jsonl'),
      );

      await journal.record(
        LearningExample(
          imagePath: original.path,
          label: 'Lavadora',
          confidence: 0.91,
          timestamp: '2026-08-08T12:00:00.000',
        ),
      );

      final examples = await journal.readAll();

      expect(examples.single.imagePath, isNot(original.path));
      expect(File(examples.single.imagePath).existsSync(), isTrue);
      expect(examples.single.imagePath, contains('images'));

      // La foto original puede desaparecer sin perder el ejemplo etiquetado.
      await original.delete();
      expect(File(examples.single.imagePath).existsSync(), isTrue);
    },
  );

  test(
    'el diario se escribe en formato JSONL con una línea por ejemplo',
    () async {
      final file = File('${tempDir.path}/mira_learning.jsonl');
      final journal = FileLearningJournal(file);

      await journal.record(
        const LearningExample(imagePath: '/tmp/a.jpg', label: 'Lavadora'),
      );
      await journal.record(
        const LearningExample(imagePath: '/tmp/b.jpg', label: 'Tostadora'),
      );

      final lines = await file.readAsLines();

      expect(lines, hasLength(2));
      for (final line in lines) {
        expect(line.trim().startsWith('{'), isTrue);
        expect(line.trim().endsWith('}'), isTrue);
      }
    },
  );
}
