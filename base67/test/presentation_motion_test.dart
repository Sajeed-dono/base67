import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/prologue_scenery.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final accessible in [false, true]) {
    testWidgets(
      'system ${accessible ? 'accessible navigation' : 'reduced motion'} stops decorative loops',
      (tester) async {
        Widget page(bool reduced) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: reduced && !accessible,
              accessibleNavigation: reduced && accessible,
            ),
            child: const Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: PrologueScenery(
                      scene: PrologueScene.touchdown,
                      reducedMotion: false,
                    ),
                  ),
                  CrewBean(role: CrewRole.engineer, reducedMotion: false),
                ],
              ),
            ),
          ),
        );
        await tester.pumpWidget(page(true));
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        final crew = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is CrewBeanPainter,
        );
        final before = tester.widget<CustomPaint>(crew).painter;
        await tester.pump(GameMotion.idle);
        expect(tester.widget<CustomPaint>(crew).painter, same(before));
        await tester.pumpWidget(page(false));
        await tester.pump(GameMotion.short);
        expect(tester.binding.transientCallbackCount, greaterThan(0));
        expect(tester.widget<CustomPaint>(crew).painter, isNot(same(before)));
        await tester.pumpWidget(page(true));
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
