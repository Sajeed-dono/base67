import 'dart:math' as math;

import 'package:base67/data/models/data_class.dart';
import 'package:base67/ui/data_class_chip.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color first, Color second) {
  final a = first.computeLuminance(), b = second.computeLuminance();
  return (math.max(a, b) + .05) / (math.min(a, b) + .05);
}

void main() {
  test(
    'B1 text and action foregrounds contrast with their paired surfaces',
    () {
      for (final pair in <(Color, Color)>[
        (GameColors.onStructural, GameColors.structuralSurface),
        (GameColors.onStructural, GameColors.structuralRaised),
        (GameColors.onStructural, GameColors.informationSurface),
        (GameColors.onStructural, GameColors.radioSurface),
        (GameColors.machinery, GameColors.structuralRaised),
        (GameColors.onControl, GameColors.controlRaised),
        (GameColors.onControlSecondary, GameColors.controlRaised),
        (GameColors.informationOnControl, GameColors.controlRaised),
        (GameColors.paper, GameColors.architecturalAccent),
        (GameColors.information, GameColors.structuralSurface),
        (GameColors.onCritical, GameColors.critical),
      ]) {
        expect(
          _contrast(pair.$1, pair.$2),
          greaterThanOrEqualTo(4.5),
          reason: 'Foreground ${pair.$1} on ${pair.$2}',
        );
      }
    },
  );

  for (final width in [360.0, 800.0, 1024.0]) {
    testWidgets(
      'B1 shared surfaces at $width dp preserve 1.4x text and actions',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        BuildContext? controlContext;
        var pressed = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: Base67Theme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.4),
                disableAnimations: true,
              ),
              child: Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(GameSpacing.page),
                  children: [
                    const InfoCard(
                      child: GameCopy(
                        'Structural panels keep a readable cream surface.',
                      ),
                    ),
                    MissionControlPanel(
                      child: Builder(
                        builder: (context) {
                          controlContext = context;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Mission control',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const GameCopy(
                                'Review this information before choosing the next action.',
                              ),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: DataClassChip(
                                  DataClass.game,
                                  key: ValueKey('control-chip'),
                                ),
                              ),
                              GameButton(
                                key: const ValueKey('review-action'),
                                label: 'Review plan',
                                onPressed: () => pressed = true,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const DaveBubble(
                      message: 'Help stays readable on either panel surface.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(Theme.of(controlContext!).brightness, Brightness.dark);
        expect(
          DefaultTextStyle.of(controlContext!).style.color,
          GameColors.onControl,
        );
        expect(
          MediaQuery.textScalerOf(controlContext!).scale(GameTypography.body),
          closeTo(GameTypography.body * 1.4, .001),
        );
        final chip = tester.widget<Container>(
          find.descendant(
            of: find.byKey(const ValueKey('control-chip')),
            matching: find.byType(Container),
          ),
        );
        expect(
          (chip.decoration! as BoxDecoration).color,
          GameColors.controlRaised,
        );
        final action = find.byKey(const ValueKey('review-action'));
        await tester.ensureVisible(action);
        await tester.pump();
        expect(action.hitTestable(), findsOneWidget);
        expect(
          tester.getSize(action).height,
          greaterThanOrEqualTo(GameSpacing.touchTarget),
        );
        expect(
          tester.getSize(action).width,
          greaterThanOrEqualTo(GameSpacing.touchTarget),
        );
        final bounds = tester.getRect(action);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(width));
        expect(bounds.top, greaterThanOrEqualTo(0));
        expect(bounds.bottom, lessThanOrEqualTo(1000));
        for (final scrollable in tester.widgetList<Scrollable>(
          find.byType(Scrollable),
        )) {
          expect(
            scrollable.axisDirection,
            anyOf(AxisDirection.down, AxisDirection.up),
          );
        }
        await tester.tap(action);
        expect(pressed, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
