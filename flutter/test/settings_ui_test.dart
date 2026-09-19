import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:biblia_app/main.dart';
import 'package:biblia_app/store.dart';
import 'package:biblia_app/theme.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.i.load();
  });

  /// Navega para a aba Config internamente.
  Future<void> openConfig(WidgetTester tester) async {
    await tester.pumpWidget(const BibliaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Config'));
    await tester.pumpAndSettle();
  }

  Finder checkInThemeRow(String name) {
    return find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(Row)),
      matching: find.byIcon(Icons.check),
    );
  }

  /// O rótulo que indica o nível atual (texto em cor de destaque acima do slider).
  Finder currentLevelLabel(String name) => find.byWidgetPredicate((w) {
        return w is Text &&
            w.data == name &&
            w.style?.color ==
                kThemes[AppState.i.themeIndex].accent &&
            w.style?.fontSize == 14;
      });

  testWidgets('seleção de tema mostra o check e aplica a cor',
      (tester) async {
    await openConfig(tester);

    expect(AppState.i.themeIndex, 0);
    expect(checkInThemeRow('Claro'), findsOneWidget);
    expect(checkInThemeRow('Marrom'), findsNothing);

    await tester.tap(find.text('Marrom'));
    await tester.pumpAndSettle();

    expect(AppState.i.themeIndex, 2);
    expect(checkInThemeRow('Marrom'), findsOneWidget);
    expect(checkInThemeRow('Claro'), findsNothing);
    expect(
      find.byWidgetPredicate((w) =>
          w is Container && w.color == kMarrom.bg),
      findsWidgets,
    );
  });

  testWidgets('tema Verde aplica a paleta verde e branco',
      (tester) async {
    await openConfig(tester);

    expect(find.text('Verde'), findsOneWidget);

    await tester.tap(find.text('Verde'));
    await tester.pumpAndSettle();

    expect(AppState.i.themeIndex, 3);
    expect(checkInThemeRow('Verde'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
          (w) => w is Container && w.color == kVerde.bg),
      findsWidgets,
    );
  });

  testWidgets('slider de tamanho da letra muda a escala e o rótulo',
      (tester) async {
    await openConfig(tester);

    expect(AppState.i.fontScale, 1.0);
    expect(currentLevelLabel('Normal'), findsOneWidget);

    await tester.drag(find.byType(Slider).first, const Offset(180, 0));
    await tester.pumpAndSettle();

    final scale = AppState.i.fontScale;
    expect(scale, isNot(1.0));
    final label = kFontLevelNames[fontLevelIndex(scale)];
    expect(currentLevelLabel(label), findsOneWidget);
  });
}