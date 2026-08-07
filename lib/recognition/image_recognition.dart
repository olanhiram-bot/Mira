enum RecognitionStatus { recognized, uncertain, unavailable, failed }

typedef ImageCandidateProcessor =
    Future<List<RecognitionCandidate>> Function(String imagePath);

abstract interface class ImageRecognitionService {
  Future<ImageRecognitionResult> recognize({required String imagePath});
}

class LocalImageRecognitionService implements ImageRecognitionService {
  const LocalImageRecognitionService({
    required this.processor,
    this.supported = true,
    this.confidenceThreshold = 0.55,
  });

  final ImageCandidateProcessor processor;
  final bool supported;
  final double confidenceThreshold;

  @override
  Future<ImageRecognitionResult> recognize({required String imagePath}) async {
    if (!supported) return const ImageRecognitionResult.unavailable();

    try {
      final candidates = await processor(
        imagePath,
      ).timeout(const Duration(seconds: 12));
      return ImageRecognitionResult.fromCandidates(
        candidates,
        confidenceThreshold: confidenceThreshold,
      );
    } catch (_) {
      return const ImageRecognitionResult.failed();
    }
  }
}

class RecognitionCandidate {
  const RecognitionCandidate({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class RecognizedThing {
  const RecognizedThing({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class ImageRecognitionResult {
  const ImageRecognitionResult._({
    required this.status,
    this.things = const [],
  });

  factory ImageRecognitionResult.fromCandidates(
    Iterable<RecognitionCandidate> candidates, {
    double confidenceThreshold = 0.55,
    int maxResults = 3,
  }) {
    final sorted = candidates.toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));
    final things = <RecognizedThing>[];
    final labels = <String>{};

    for (final candidate in sorted) {
      if (candidate.confidence < confidenceThreshold) continue;
      if (_nonIdentifyingLabels.contains(
        candidate.label.trim().toLowerCase(),
      )) {
        continue;
      }
      final label = _translateLabel(candidate.label);
      if (!labels.add(label.toLowerCase())) continue;
      things.add(
        RecognizedThing(label: label, confidence: candidate.confidence),
      );
      if (things.length == maxResults) break;
    }

    return ImageRecognitionResult._(
      status: things.isEmpty
          ? RecognitionStatus.uncertain
          : RecognitionStatus.recognized,
      things: things,
    );
  }

  const ImageRecognitionResult.unavailable()
    : this._(status: RecognitionStatus.unavailable);

  const ImageRecognitionResult.failed()
    : this._(status: RecognitionStatus.failed);

  final RecognitionStatus status;
  final List<RecognizedThing> things;
}

const _nonIdentifyingLabels = <String>{
  'machine',
  'object',
  'product',
  'technology',
};

const _spanishLabels = <String, String>{
  'mouse': 'Mouse de computadora',
  'computer mouse': 'Mouse de computadora',
  'washing machine': 'Lavadora',
  'home appliance': 'Electrodoméstico',
  'major appliance': 'Electrodoméstico grande',
  'refrigerator': 'Refrigerador',
  'microwave oven': 'Horno de microondas',
  'oven': 'Horno',
  'stove': 'Estufa',
  'dishwasher': 'Lavavajillas',
  'clothes dryer': 'Secadora',
  'vacuum cleaner': 'Aspiradora',
  'coffee maker': 'Cafetera',
  'toaster': 'Tostadora',
  'air conditioner': 'Aire acondicionado',
  'electric fan': 'Ventilador',
  'television': 'Televisión',
  'remote control': 'Control remoto',
  'mobile phone': 'Teléfono móvil',
  'laptop': 'Computadora portátil',
  'computer': 'Computadora',
  'keyboard': 'Teclado',
  'clock': 'Reloj',
  'lamp': 'Lámpara',
  'furniture': 'Mueble',
  'vehicle': 'Vehículo',
  'food': 'Alimento',
  'plant': 'Planta',
  'animal': 'Animal',
};

String _translateLabel(String label) {
  final normalized = label.trim();
  return _spanishLabels[normalized.toLowerCase()] ?? normalized;
}
