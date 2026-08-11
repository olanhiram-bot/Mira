import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mira/main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('el home ofrece un botón para activar texto grande', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mira_onboarding_completed': true,
      'mira_text_scale': 1.0,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('text-scale-toggle')), findsOneWidget);
  });

  testWidgets('al tocar el botón de texto grande, el escalado cambia', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mira_onboarding_completed': true,
      'mira_text_scale': 1.0,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('text-scale-toggle')));
    await tester.pumpAndSettle();

    // El MediaQuery más interno es el que MaterialApp aplica a las rutas
    // y el que transporta el escalado elegido por la persona usuaria.
    final mediaQuery = tester.widget<MediaQuery>(find.byType(MediaQuery).last);
    expect(mediaQuery.data.textScaler.scale(1.0), greaterThan(1.0));
  });

  testWidgets('el modo texto grande persiste al recargar', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'mira_onboarding_completed': true,
      'mira_text_scale': 1.0,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('text-scale-toggle')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('mira_text_scale'), 1.3);
  });
}
