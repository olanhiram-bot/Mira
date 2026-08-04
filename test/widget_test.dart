import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mira/main.dart';

void main() {
  testWidgets('Mira completa el onboarding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Mira'), findsOneWidget);
    expect(find.text('Mira lo que importa.'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('Empezar con Mira'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-start')));
    await tester.pumpAndSettle();

    expect(find.text('Entiende lo que ves.'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: MiraEntryPage()));
    await tester.pumpAndSettle();
    expect(find.text('Mira lo que importa.'), findsNothing);
    expect(find.text('Entiende lo que ves.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
