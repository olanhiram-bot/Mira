// Exporta el diario de aprendizaje local de Mira a un dataset de
// entrenamiento con estructura train/<etiqueta>/ y val/<etiqueta>/.
//
// Uso:
//   dart run tool/export_dataset.dart \
//     --journal <mira_learning.jsonl> --images <carpeta de fotos> \
//     --out <carpeta destino> [--val-ratio 0.2] [--dry-run]
//
// Las correcciones (corrected=true) son la etiqueta de verdad; cada ejemplo
// confirmado o corregido por el usuario alimenta una clase del dataset.
import 'dart:convert';
import 'dart:io';

import 'package:mira/recognition/learning_journal_core.dart';

Future<void> main(List<String> args) async {
  final flags = _parseArgs(args);
  final journalPath = flags['--journal'];
  final imagesDir = flags['--images'];
  final outDir = flags['--out'];
  if (journalPath == null || imagesDir == null || outDir == null) {
    stderr.writeln(
      'Uso: dart run tool/export_dataset.dart '
      '--journal <jsonl> --images <dir> --out <dir> '
      '[--val-ratio 0.2] [--dry-run]',
    );
    exitCode = 2;
    return;
  }
  final valRatio = double.tryParse(flags['--val-ratio'] ?? '0.2') ?? 0.2;
  final dryRun = flags.containsKey('--dry-run');

  final journal = File(journalPath);
  if (!await journal.exists()) {
    stderr.writeln('No existe el diario: $journalPath');
    exitCode = 1;
    return;
  }

  final examples = <LearningExample>[];
  for (final line in await journal.readAsLines()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    try {
      examples.add(
        LearningExample.fromJson(jsonDecode(trimmed) as Map<String, dynamic>),
      );
    } catch (_) {
      stderr.writeln('Línea ignorada (no es JSON válido): $trimmed');
    }
  }

  final images = Directory(imagesDir);
  final resolved = <LearningExample>[];
  for (final example in examples) {
    if (await File(example.imagePath).exists()) {
      resolved.add(example);
      continue;
    }
    final name = _basename(example.imagePath);
    final candidate = File('${images.path}/$name');
    if (name.isNotEmpty && await candidate.exists()) {
      resolved.add(
        LearningExample(
          imagePath: candidate.path,
          label: example.label,
          confidence: example.confidence,
          corrected: example.corrected,
          timestamp: example.timestamp,
        ),
      );
    } else {
      stderr.writeln(
        'Ejemplo sin foto disponible (omitido): ${example.imagePath}',
      );
    }
  }

  final partitions = _partitionByLabel(resolved, valRatio: valRatio);

  if (dryRun) {
    _printSummary(partitions);
    return;
  }

  var copied = 0;
  for (final entry in partitions.entries) {
    final label = entry.key;
    final (train, val) = entry.value;
    copied += await _copyGroup(label, 'train', train, outDir);
    copied += await _copyGroup(label, 'val', val, outDir);
  }
  _printSummary(partitions);
  stdout.writeln('Dataset exportado en $outDir ($copied fotos copiadas).');
}

/// Divide por etiqueta en train/val en orden temporal: el último
/// `valRatio` de cada clase es validación. Determinista.
Map<String, (List<LearningExample>, List<LearningExample>)> _partitionByLabel(
  List<LearningExample> examples, {
  required double valRatio,
}) {
  final byLabel = <String, List<LearningExample>>{};
  for (final example in examples) {
    byLabel.putIfAbsent(example.label, () => []).add(example);
  }
  final result = <String, (List<LearningExample>, List<LearningExample>)>{};
  for (final entry in byLabel.entries) {
    final sorted = [...entry.value]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final valCount = (sorted.length * valRatio).ceil();
    final val = sorted.skip(sorted.length - valCount).toList();
    final train = sorted.take(sorted.length - valCount).toList();
    result[entry.key] = (train, val);
  }
  return result;
}

Future<int> _copyGroup(
  String label,
  String split,
  List<LearningExample> examples,
  String outDir,
) async {
  if (examples.isEmpty) return 0;
  final dir = Directory('$outDir/$split/$label');
  await dir.create(recursive: true);
  var count = 0;
  for (var i = 0; i < examples.length; i++) {
    final source = File(examples[i].imagePath);
    final index = i.toString().padLeft(4, '0');
    final name = _basename(examples[i].imagePath);
    final dest = File('${dir.path}/${index}_$name');
    try {
      await source.copy(dest.path);
      count++;
    } catch (e) {
      stderr.writeln('No se pudo copiar ${source.path}: $e');
    }
  }
  return count;
}

void _printSummary(
  Map<String, (List<LearningExample>, List<LearningExample>)> partitions,
) {
  for (final entry in partitions.entries) {
    final (train, val) = entry.value;
    stdout.writeln('${entry.key}: ${train.length} train / ${val.length} val');
  }
  final total = partitions.values.fold<int>(
    0,
    (sum, group) => sum + group.$1.length + group.$2.length,
  );
  stdout.writeln('Total: $total ejemplos etiquetados.');
}

String _basename(String path) {
  final segments = path.replaceAll('\\', '/').split('/');
  return segments.isEmpty ? '' : segments.last;
}

Map<String, String> _parseArgs(List<String> args) {
  final flags = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (args[i].startsWith('--')) {
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        flags[args[i]] = args[i + 1];
        i++;
      } else {
        flags[args[i]] = '';
      }
    }
  }
  return flags;
}
