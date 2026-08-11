import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility/text_scale.dart';
import 'recognition/image_recognition.dart';
import 'recognition/learning_journal.dart';
import 'recognition/ml_kit_image_recognition_service.dart';
import 'recognition/recognition_panel.dart';

const _ink = Color(0xFF132D32);
const _teal = Color(0xFF176B68);
const _mint = Color(0xFFD8F0E7);
const _cream = Color(0xFFF8F8F3);
const _sand = Color(0xFFF1EDE3);
const _coral = Color(0xFFE78262);
const _onboardingCompletedKey = 'mira_onboarding_completed';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<double> _textScale = ValueNotifier<double>(1.0);

  @override
  void initState() {
    super.initState();
    TextScaleScope.loadInto(_textScale);
  }

  @override
  void dispose() {
    _textScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _teal,
          brightness: Brightness.light,
        ).copyWith(
          primary: _teal,
          onPrimary: Colors.white,
          surface: _cream,
          onSurface: _ink,
          surfaceContainerHighest: _sand,
        );

    return TextScaleScope(
      notifier: _textScale,
      child: ValueListenableBuilder<double>(
        valueListenable: _textScale,
        builder: (context, scale, child) {
          return MaterialApp(
            title: 'Mira',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: colorScheme,
              scaffoldBackgroundColor: _cream,
              textTheme: const TextTheme(
                displaySmall: TextStyle(
                  color: _ink,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  letterSpacing: -1.2,
                ),
                headlineSmall: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
                titleMedium: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                bodyLarge: TextStyle(
                  color: Color(0xFF476064),
                  fontSize: 17,
                  height: 1.45,
                ),
                bodyMedium: TextStyle(
                  color: Color(0xFF476064),
                  fontSize: 15,
                  height: 1.4,
                ),
                labelLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            // Aplica el escalado de texto elegido a toda la app. Este
            // MediaQuery es el más interno, así que es el que ven las rutas.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const MiraEntryPage(),
          );
        },
      ),
    );
  }
}

class MiraEntryPage extends StatefulWidget {
  const MiraEntryPage({super.key});

  @override
  State<MiraEntryPage> createState() => _MiraEntryPageState();
}

class _MiraEntryPageState extends State<MiraEntryPage> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
      );
      if (mounted) {
        setState(
          () => _onboardingCompleted =
              preferences.getBool(_onboardingCompletedKey) ?? false,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _onboardingCompleted = false);
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 5),
      );
      await preferences
          .setBool(_onboardingCompletedKey, true)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // The app can continue even if local persistence is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = _onboardingCompleted;
    if (completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (completed) return const MiraHomePage();

    return MiraOnboardingPage(onCompleted: _completeOnboarding);
  }
}

class MiraOnboardingPage extends StatefulWidget {
  const MiraOnboardingPage({super.key, this.onCompleted});

  final Future<void> Function()? onCompleted;

  @override
  State<MiraOnboardingPage> createState() => _MiraOnboardingPageState();
}

class _MiraOnboardingPageState extends State<MiraOnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == _onboardingSteps.length - 1) {
      _finish();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    await widget.onCompleted?.call();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MiraHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth < 760 ? screenWidth : 760.0;
    final isLastPage = _currentPage == _onboardingSteps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _teal,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 23,
                          semanticLabel: 'Mira',
                        ),
                      ),
                      const SizedBox(width: 11),
                      Text(
                        'Mira',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        key: const ValueKey('onboarding-skip'),
                        onPressed: _finish,
                        child: const Text('Saltar'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _onboardingSteps.length,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      itemBuilder: (context, index) =>
                          _OnboardingStepView(step: _onboardingSteps[index]),
                    ),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final indicators = Row(
                        children: List.generate(
                          _onboardingSteps.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: index == _currentPage ? 26 : 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: index == _currentPage ? _teal : _sand,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                      final action = FilledButton(
                        key: ValueKey(
                          isLastPage ? 'onboarding-start' : 'onboarding-next',
                        ),
                        onPressed: _nextPage,
                        child: Text(
                          isLastPage ? 'Empezar con Mira' : 'Siguiente',
                        ),
                      );
                      final previous = _currentPage > 0
                          ? IconButton(
                              tooltip: 'Página anterior',
                              onPressed: () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            )
                          : null;

                      if (constraints.maxWidth < 480) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: indicators),
                                ?previous,
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: action),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: indicators),
                          ?previous,
                          const SizedBox(width: 8),
                          action,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
}

const _onboardingSteps = [
  _OnboardingStep(
    icon: Icons.visibility_rounded,
    eyebrow: 'OBSERVA',
    title: 'Mira lo que importa.',
    description: 'Entiende aparatos que no conoces sin sentirte perdido.',
  ),
  _OnboardingStep(
    icon: Icons.camera_alt_rounded,
    eyebrow: 'ENFOCA',
    title: 'Una foto abre el camino.',
    description: 'Enfoca un botón, una perilla o una pantalla y continúa.',
  ),
  _OnboardingStep(
    icon: Icons.lightbulb_outline_rounded,
    eyebrow: 'COMPRENDE',
    title: 'Explicaciones sencillas.',
    description: 'Recibe orientación clara para decidir qué hacer después.',
  ),
];

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 28, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OnboardingIllustration(step: step),
          const SizedBox(height: 32),
          Text(
            step.eyebrow,
            style: textTheme.labelLarge?.copyWith(
              color: _teal,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(step.title, style: textTheme.displaySmall),
          const SizedBox(height: 16),
          Text(step.description, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 265,
      decoration: BoxDecoration(
        color: _sand,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -56,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: _mint.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, color: _coral, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    'Listo para ayudarte',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(42),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A132D32),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(step.icon, color: _mint, size: 58),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key});

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  XFile? _capturedImage;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCapturing = false;
  bool _isInitializing = false;
  bool _isAppInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _capturedImage = null;
    });

    await _controller?.dispose();
    _controller = null;

    CameraController? nextController;
    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 8),
      );
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'No encontramos una cámara disponible en este dispositivo.';
          });
        }
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      nextController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await nextController.initialize().timeout(const Duration(seconds: 12));

      if (!mounted || _isAppInactive) {
        await nextController.dispose();
        return;
      }

      _controller = nextController;
      setState(() => _isLoading = false);
    } on CameraException catch (error) {
      await nextController?.dispose();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _cameraErrorMessage(error);
        });
      }
    } catch (_) {
      await nextController?.dispose();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No pudimos abrir la cámara. Intenta nuevamente.';
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isAppInactive = true;
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _isAppInactive = false;
      if (_capturedImage == null && _controller == null) {
        _initializeCamera();
      }
    }
  }

  Future<void> _pauseCamera() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();

    if (mounted && _capturedImage == null) {
      setState(() => _isLoading = true);
    }
  }

  String _cameraErrorMessage(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Mira necesita permiso para usar la cámara. Actívalo en la configuración del dispositivo.';
      default:
        return 'No pudimos abrir la cámara. Intenta nuevamente.';
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final image = await controller.takePicture();
      if (mounted) {
        setState(() => _capturedImage = image);
      }
    } on CameraException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_cameraErrorMessage(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toma una foto'), centerTitle: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const _CameraStateMessage(
        icon: Icons.camera_alt_outlined,
        title: 'Preparando la cámara',
        message: 'Danos un momento.',
        showProgress: true,
      );
    }

    if (_errorMessage != null) {
      return _CameraStateMessage(
        icon: Icons.no_photography_outlined,
        title: 'No pudimos abrir la cámara',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _initializeCamera,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Intentar de nuevo'),
        ),
      );
    }

    final image = _capturedImage;
    if (image != null) {
      return CapturedImageView(
        image: image,
        onRetake: () => setState(() => _capturedImage = null),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _CameraStateMessage(
        icon: Icons.no_photography_outlined,
        title: 'Cámara no disponible',
        message: 'Intenta abrirla nuevamente.',
      );
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CameraPreview(controller),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Coloca el control dentro del encuadre.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isCapturing ? null : _takePicture,
            icon: _isCapturing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt_rounded),
            label: Text(_isCapturing ? 'Guardando foto' : 'Tomar foto'),
          ),
        ),
      ],
    );
  }
}

class _CameraStateMessage extends StatelessWidget {
  const _CameraStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _mint,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: _teal, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (showProgress) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

class CapturedImageView extends StatefulWidget {
  const CapturedImageView({
    required this.image,
    required this.onRetake,
    super.key,
  });

  final XFile image;
  final VoidCallback onRetake;

  @override
  State<CapturedImageView> createState() => _CapturedImageViewState();
}

class _CapturedImageViewState extends State<CapturedImageView> {
  late final Future<Uint8List> _imageBytes;
  late final Future<_OcrResult> _ocrResult;
  late final Future<ImageRecognitionResult> _recognitionResult;
  late final Future<LearningJournal> _journal;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.image.readAsBytes();
    _ocrResult = _recognizeText();
    _recognitionResult = createMlKitImageRecognitionService().recognize(
      imagePath: widget.image.path,
    );
    _journal = openLearningJournal();
  }

  /// Guarda la confirmación o corrección como ejemplo etiquetado local.
  ///
  /// El diario alimenta futuros ciclos de entrenamiento del modelo de dominio.
  /// Nunca debe romper la revisión de la foto: los fallos se ignoran.
  Future<void> _recordSelection(
    RecognizedThing thing, {
    required bool corrected,
  }) async {
    try {
      final journal = await _journal;
      await journal.record(
        LearningExample(
          imagePath: widget.image.path,
          label: thing.label,
          confidence: thing.confidence,
          corrected: corrected,
          timestamp: DateTime.now().toIso8601String(),
        ),
      );
    } catch (_) {
      // Aprender del uso es opcional; la revisión sigue funcionando.
    }
  }

  Future<_OcrResult> _recognizeText() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const _OcrResult.unavailable();
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(widget.image.path);
      final result = await recognizer
          .processImage(image)
          .timeout(const Duration(seconds: 10));
      final texts = <String>[];
      for (final block in result.blocks) {
        final text = block.text.trim();
        if (text.isNotEmpty && !texts.contains(text)) {
          texts.add(text);
        }
      }
      return _OcrResult(texts: texts.take(8).toList());
    } catch (_) {
      return const _OcrResult.error();
    } finally {
      await recognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = (constraints.maxHeight * 0.48)
            .clamp(220.0, 420.0)
            .toDouble();
        return SingleChildScrollView(
          key: const ValueKey('captured-review-scroll'),
          child: Column(
            children: [
              SizedBox(
                height: photoHeight,
                child: FutureBuilder<Uint8List>(
                  future: _imageBytes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return const _CameraStateMessage(
                        icon: Icons.broken_image_outlined,
                        title: 'No pudimos mostrar la foto',
                        message: 'Puedes tomar otra fotografía.',
                      );
                    }
                    return _buildPhoto(snapshot.data!);
                  },
                ),
              ),
              _OcrResultPanel(future: _ocrResult),
              RecognitionResultPanel(
                future: _recognitionResult,
                onConfirmed: (thing) =>
                    _recordSelection(thing, corrected: false),
                onCorrected: (thing) =>
                    _recordSelection(thing, corrected: true),
              ),
              const SizedBox(height: 14),
              Text(
                'La identificación se realiza en este dispositivo. '
                'Confirma el resultado porque la IA puede equivocarse. '
                'Tus confirmaciones y correcciones se guardan solo en este '
                'dispositivo para mejorar el reconocimiento.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onRetake,
                  child: const Text('Tomar otra foto'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoto(Uint8List bytes) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: _ink,
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _ink.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'ANÁLISIS CON IA LOCAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OcrResult {
  const _OcrResult({
    this.texts = const [],
    this.available = true,
    this.failed = false,
  });

  const _OcrResult.unavailable() : this(available: false);

  const _OcrResult.error() : this(failed: true);

  final List<String> texts;
  final bool available;
  final bool failed;
}

class _OcrResultPanel extends StatelessWidget {
  const _OcrResultPanel({required this.future});

  final Future<_OcrResult> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OcrResult>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Leyendo etiquetas...',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data;
        if (result == null || !result.available) {
          return const _OcrMessage(
            icon: Icons.phone_android_rounded,
            message: 'La lectura automática estará disponible en Android.',
          );
        }
        if (result.failed) {
          return const _OcrMessage(
            icon: Icons.help_outline_rounded,
            message: 'No pudimos leer las etiquetas. Puedes tomar otra foto.',
          );
        }
        if (result.texts.isEmpty) {
          return const _OcrMessage(
            icon: Icons.search_off_rounded,
            message: 'No encontramos texto claro en la fotografía.',
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _sand,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Texto encontrado',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Es una ayuda orientativa para confirmar la identificación.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.texts
                    .map((text) => Chip(label: Text(text)))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OcrMessage extends StatelessWidget {
  const _OcrMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class MiraHomePage extends StatelessWidget {
  const MiraHomePage({super.key});

  void _openCamera(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CameraCapturePage()));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth < 760 ? screenWidth : 760.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 540;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _teal,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.visibility_rounded,
                                color: Colors.white,
                                size: 25,
                                semanticLabel: 'Mira',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('Mira', style: textTheme.titleLarge),
                            const Spacer(),
                            IconButton(
                              key: const ValueKey('text-scale-toggle'),
                              tooltip: 'Texto grande',
                              onPressed: () => TextScaleScope.toggle(context),
                              icon: const Icon(Icons.text_fields_rounded),
                            ),
                            if (compact)
                              Semantics(
                                label: 'Tus fotos permanecen en tu dispositivo',
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _mint,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: _teal,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: _teal, size: 9),
                                    SizedBox(width: 7),
                                    Text('En tu dispositivo'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 56),
                        Text(
                          'Entiende lo que ves.',
                          style: textTheme.displaySmall,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Text(
                            'Mira una interfaz, descubre qué hace cada control y recibe una explicación clara.',
                            style: textTheme.bodyLarge,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -42,
                                top: -50,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: _teal.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: _mint,
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    child: const Icon(
                                      Icons.center_focus_strong_rounded,
                                      color: _teal,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(
                                    'Una foto es suficiente',
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Enfoca el aparato y deja que Mira te ayude a leerlo.',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFC4D6D3),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: () => _openCamera(context),
                                      icon: const Icon(
                                        Icons.camera_alt_rounded,
                                      ),
                                      label: const Text('Empezar con una foto'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _coral,
                                        foregroundColor: _ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Diseñada para ser clara',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        if (compact)
                          const Column(
                            children: [
                              _FeatureCard(
                                icon: Icons.touch_app_rounded,
                                title: 'Sin complicaciones',
                                description:
                                    'Un paso a la vez, con controles fáciles de encontrar.',
                              ),
                              SizedBox(height: 12),
                              _FeatureCard(
                                icon: Icons.volume_up_rounded,
                                title: 'Explicaciones claras',
                                description:
                                    'Lenguaje sencillo para tomar mejores decisiones.',
                              ),
                            ],
                          )
                        else
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.touch_app_rounded,
                                  title: 'Sin complicaciones',
                                  description:
                                      'Un paso a la vez, con controles fáciles de encontrar.',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: _FeatureCard(
                                  icon: Icons.volume_up_rounded,
                                  title: 'Explicaciones claras',
                                  description:
                                      'Lenguaje sencillo para tomar mejores decisiones.',
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              color: _teal,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Durante el MVP, tus fotos permanecen en tu dispositivo.',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3E7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _teal, size: 26),
          const SizedBox(height: 14),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 7),
          Text(description, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
