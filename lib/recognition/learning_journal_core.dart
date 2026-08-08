/// Modelo y contrato del diario de aprendizaje local.
///
/// Este archivo no depende de `dart:io` para poder compilar en Web,
/// donde el diario es un no-op.
abstract interface class LearningJournal {
  Future<void> record(LearningExample example);

  Future<List<LearningExample>> readAll();
}

/// Un ejemplo etiquetado por el uso real: la foto, la identificación que la
/// persona confirmó y si esa identificación fue una corrección.
class LearningExample {
  const LearningExample({
    required this.imagePath,
    required this.label,
    this.confidence = 0,
    this.corrected = false,
    this.timestamp = '',
  });

  final String imagePath;
  final String label;
  final double confidence;
  final bool corrected;

  /// Marca de tiempo ISO-8601; vacía si no se registró.
  final String timestamp;

  Map<String, Object?> toJson() => {
    'v': 1,
    'imagePath': imagePath,
    'label': label,
    'confidence': confidence,
    'corrected': corrected,
    'timestamp': timestamp,
  };

  factory LearningExample.fromJson(Map<String, dynamic> json) {
    return LearningExample(
      imagePath: json['imagePath'] as String? ?? '',
      label: json['label'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      corrected: json['corrected'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}
