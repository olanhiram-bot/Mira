import 'package:flutter/material.dart';

import 'image_recognition.dart';

class RecognitionResultPanel extends StatefulWidget {
  const RecognitionResultPanel({
    required this.future,
    required this.onConfirmed,
    super.key,
  });

  final Future<ImageRecognitionResult> future;
  final ValueChanged<RecognizedThing> onConfirmed;

  @override
  State<RecognitionResultPanel> createState() => _RecognitionResultPanelState();
}

class _RecognitionResultPanelState extends State<RecognitionResultPanel> {
  RecognizedThing? _selected;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageRecognitionResult>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _RecognitionMessage(
            icon: Icons.auto_awesome_rounded,
            message: 'La IA está analizando la foto...',
            showProgress: true,
          );
        }

        final result = snapshot.data;
        if (result?.status == RecognitionStatus.unavailable) {
          return const _RecognitionMessage(
            icon: Icons.phone_android_rounded,
            message: 'El reconocimiento de objetos está disponible en Android.',
          );
        }
        if (result?.status == RecognitionStatus.failed) {
          return const _RecognitionMessage(
            icon: Icons.error_outline_rounded,
            message:
                'La IA no pudo analizar la foto. Toma otra foto e intenta nuevamente.',
          );
        }
        if (result == null || result.status != RecognitionStatus.recognized) {
          return const _RecognitionMessage(
            icon: Icons.help_outline_rounded,
            message:
                'Objeto no identificado con suficiente seguridad. Prueba otra foto con el objeto completo y buena luz.',
          );
        }

        final selected = _selected ?? result.things.first;
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parece ser: ${selected.label}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(selected.confidence * 100).round()}% de confianza',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (result.things.length > 1) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.things
                      .map(
                        (thing) => ChoiceChip(
                          label: Text(thing.label),
                          selected: thing == selected,
                          onSelected: (_) => setState(() {
                            _selected = thing;
                            _confirmed = false;
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'La IA puede equivocarse. Confirma antes de usar esta identificación.',
              ),
              const SizedBox(height: 10),
              if (_confirmed)
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Identificación confirmada'),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _confirmed = true);
                    widget.onConfirmed(selected);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Sí, es correcto'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RecognitionMessage extends StatelessWidget {
  const _RecognitionMessage({
    required this.icon,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
