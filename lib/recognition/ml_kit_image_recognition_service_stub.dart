import 'image_recognition.dart';

ImageRecognitionService createMlKitImageRecognitionService() {
  return LocalImageRecognitionService(
    supported: false,
    processor: (_) async => const [],
  );
}
