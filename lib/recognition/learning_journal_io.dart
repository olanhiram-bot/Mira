import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'learning_journal_core.dart';

/// Diario de aprendizaje persistente en formato JSONL (una línea por ejemplo)
/// dentro del almacenamiento privado de la app. Nunca sale del dispositivo.
class FileLearningJournal implements LearningJournal {
  FileLearningJournal(this.file)
    : imagesDir = Directory('${file.parent.path}/images');

  final File file;

  /// Carpeta privada donde se copian las fotos de los ejemplos etiquetados.
  ///
  /// La foto original vive en la carpeta temporal de la cámara y puede
  /// desaparecer; sin una copia durable no hay dataset para entrenar.
  final Directory imagesDir;

  @override
  Future<void> record(LearningExample example) async {
    await file.parent.create(recursive: true);
    final storedPath = await _copyImageDurably(example.imagePath);
    final stored = LearningExample(
      imagePath: storedPath,
      label: example.label,
      confidence: example.confidence,
      corrected: example.corrected,
      timestamp: example.timestamp,
    );
    final sink = file.openWrite(mode: FileMode.append);
    sink.write(jsonEncode(stored.toJson()));
    sink.write('\n');
    await sink.flush();
    await sink.close();
  }

  Future<String> _copyImageDurably(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) return sourcePath;
    await imagesDir.create(recursive: true);
    final name = source.uri.pathSegments.isEmpty
        ? 'photo.jpg'
        : source.uri.pathSegments.last;
    final dest = File(
      '${imagesDir.path}/'
      '${DateTime.now().microsecondsSinceEpoch}_$name',
    );
    await source.copy(dest.path);
    return dest.path;
  }

  @override
  Future<List<LearningExample>> readAll() async {
    if (!await file.exists()) return const [];
    final lines = await file.readAsLines();
    final examples = <LearningExample>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        examples.add(
          LearningExample.fromJson(jsonDecode(trimmed) as Map<String, dynamic>),
        );
      } catch (_) {
        // Una línea dañada no debe romper el diario ni la revisión de la foto.
      }
    }
    return examples;
  }
}

Future<LearningJournal> openLearningJournal() async {
  final directory = await getApplicationDocumentsDirectory();
  return FileLearningJournal(File('${directory.path}/mira_learning.jsonl'));
}
