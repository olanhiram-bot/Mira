import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'mira_text_scale';

/// Estado global del escalado de texto, accesible desde cualquier widget
/// vía `TextScaleScope.of(context)`.
///
/// El notifier se crea en MyApp y se comparte por InheritedWidget.
/// Cualquier widget puede leer el valor y el toggle en la home lo cambia
/// y persiste el cambio automáticamente.
class TextScaleScope extends InheritedWidget {
  const TextScaleScope({
    required this.notifier,
    required super.child,
    super.key,
  });

  final ValueNotifier<double> notifier;

  static ValueNotifier<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TextScaleScope>()!.notifier;

  static double scaleOf(BuildContext context) => of(context).value;

  /// Alterna entre texto normal (1.0) y texto grande (1.3), persistiendo
  /// la preferencia en SharedPreferences.
  static Future<void> toggle(BuildContext context) async {
    final notifier = of(context);
    final next = notifier.value >= 1.2 ? 1.0 : 1.3;
    notifier.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_key, next);
    } catch (_) {
      // La persistencia es un extra: el cambio visual es inmediato.
    }
  }

  /// Carga la preferencia persistida. Se llama una sola vez al inicio.
  static Future<void> loadInto(ValueNotifier<double> notifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getDouble(_key);
      if (value != null) notifier.value = value;
    } catch (_) {
      // Valor por defecto: 1.0 (texto normal).
    }
  }

  @override
  bool updateShouldNotify(TextScaleScope old) => notifier != old.notifier;
}
