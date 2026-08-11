import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'image_recognition.dart';

ImageRecognitionService createMlKitImageRecognitionService() {
  return LocalImageRecognitionService(
    supported: defaultTargetPlatform == TargetPlatform.android,
    confidenceThreshold: 0.55,
    processor: _processImage,
  );
}

Future<List<RecognitionCandidate>> _processImage(String imagePath) async {
  final modelPath = await _ensureModelPath();
  final labeler = ImageLabeler(
    options: LocalLabelerOptions(
      modelPath: modelPath,
      confidenceThreshold: 0.15,
      maxCount: 5,
    ),
  );
  try {
    final image = InputImage.fromFilePath(imagePath);
    final labels = await labeler.processImage(image);
    return labels
        .map(
          (label) => RecognitionCandidate(
            label: label.label,
            confidence: label.confidence,
          ),
        )
        .toList();
  } finally {
    await labeler.close();
  }
}

const _domainModelAsset = 'assets/models/mira_appliances.tflite';
const _domainModelLength = 2533448;

Future<String> _ensureModelPath() async {
  final modelFile = File('${Directory.systemTemp.path}/mira_appliances.tflite');
  if (await modelFile.exists() &&
      await modelFile.length() == _domainModelLength) {
    return modelFile.path;
  }

  final data = await rootBundle.load(_domainModelAsset);
  await modelFile.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return modelFile.path;
}
