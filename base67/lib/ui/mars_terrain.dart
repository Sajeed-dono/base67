import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'mars_base_painter.dart';
import 'theme.dart';

/// Original, deterministic decorative terrain in the existing presentation
/// world. Rocks, tracks and ridges do not create collision or resource nodes.
abstract final class MarsTerrain {
  static void paint(Canvas canvas, Size size, {required bool night}) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night
              ? const [
                  GameColors.marsNight,
                  GameColors.marsRock,
                  GameColors.marsGround,
                ]
              : const [
                  GameColors.marsSkyHigh,
                  GameColors.marsSky,
                  GameColors.marsHaze,
                ],
        ).createShader(rect),
    );
    if (!night) {
      canvas.drawCircle(
        Offset(size.width * .18, size.height * .16),
        size.shortestSide * .055,
        Paint()..color = GameColors.paper.withValues(alpha: .55),
      );
    }
    for (var layer = 0; layer < 3; layer++) {
      final ridge = Path()..moveTo(0, size.height);
      for (var i = 0; i <= 24; i++) {
        final x = i / 24;
        final y =
            .30 +
            layer * .045 +
            math.sin(i * 1.3 + layer) * .027 +
            math.cos(i * .7) * .025;
        ridge.lineTo(x * size.width, y * size.height);
      }
      ridge
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
        ridge,
        Paint()
          ..color = Color.lerp(
            GameColors.marsDistant,
            GameColors.marsRock,
            layer / 3,
          )!.withValues(alpha: .8),
      );
    }
    canvas.save();
    canvas.clipPath(SettlementLayout.ground(size));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: night
              ? const [GameColors.marsRock, GameColors.marsRockShade]
              : const [
                  GameColors.marsLit,
                  GameColors.marsGround,
                  GameColors.marsRock,
                ],
        ).createShader(rect),
    );
    final hulls = SettlementLayout.facilities(const {})
        .map((site) => SettlementLayout.hull(site, size).inflate(20))
        .toList();
    // Bounded detail count, independent of frame rate and viewport dimensions.
    for (var i = 0; i < 170; i++) {
      final x = ((i * 137 + 29) % 997) / 997 * size.width;
      final y = (.37 + ((i * 73) % 593) / 593 * .63) * size.height;
      final at = Offset(x, y);
      if (hulls.any((hull) => hull.contains(at))) continue;
      final radius = 1.0 + i % 5;
      canvas.drawOval(
        Rect.fromCenter(
          center: at.translate(radius, radius),
          width: radius * 3,
          height: radius,
        ),
        Paint()..color = GameColors.marsRockShade.withValues(alpha: .25),
      );
      final rock = Path()
        ..moveTo(x - radius, y)
        ..lineTo(x - radius * .6, y - radius * .8)
        ..lineTo(x + radius * .7, y - radius * .6)
        ..lineTo(x + radius, y)
        ..close();
      canvas.drawPath(
        rock,
        Paint()..color = i.isEven ? GameColors.marsRock : GameColors.marsLit,
      );
    }
    for (var i = 0; i < 13; i++) {
      final y = size.height * (.43 + i * .046);
      final dune = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .25,
          y - 15,
          size.width * .6,
          y + 28,
          size.width,
          y - 10,
        );
      canvas.drawPath(
        dune,
        Paint()
          ..color = GameColors.marsHaze.withValues(alpha: .14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
    canvas.restore();
  }

  /// Very subtle near-ground wisps. Uses the existing presentation clock only;
  /// reduced motion is a fixed frame and never schedules a new ticker.
  static void atmosphere(
    Canvas canvas,
    Size size, {
    required double seconds,
    required bool reducedMotion,
    required bool storm,
  }) {
    final phase = reducedMotion ? 0.0 : seconds * 5;
    for (var i = 0; i < (storm ? 8 : 3); i++) {
      final x = ((i * 263 + phase) % (size.width + 240)) - 120;
      final y = size.height * (.42 + i * .065);
      canvas.drawOval(
        Rect.fromLTWH(x, y, 160, storm ? 13 : 5),
        Paint()
          ..color = GameColors.marsHaze.withValues(alpha: storm ? .1 : .035),
      );
    }
    if (storm) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = GameColors.sand.withValues(alpha: .16),
      );
    }
  }
}
