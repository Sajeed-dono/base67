import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'facility_architecture.dart';
import 'theme.dart';

/// Original menu scenery only: not a projection of the player's actual base.
/// Static, bundled code art; no network assets or background ticker.
class ColonyBackdrop extends StatelessWidget {
  const ColonyBackdrop({super.key});
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _ColonyBackdropPainter()),
    ),
  );
}

class _ColonyBackdropPainter extends CustomPainter {
  const _ColonyBackdropPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.ink,
            GameColors.controlRaised,
            GameColors.marsRockShade,
          ],
        ).createShader(rect),
    );
    for (var i = 0; i < 45; i++) {
      canvas.drawCircle(
        Offset(
          ((i * 83 + 17) % 997) / 997 * size.width,
          ((i * 53) % 619) / 619 * size.height * .72,
        ),
        i.isEven ? 1 : .6,
        Paint()..color = GameColors.paper.withValues(alpha: .4),
      );
    }
    final center = Offset(size.width * .89, size.height * .17);
    final radius = size.shortestSide * .32;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment.topLeft,
          colors: [
            GameColors.marsLit,
            GameColors.rust,
            GameColors.marsRockShade,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    for (var i = 0; i < 9; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: center.translate(radius * .2, i * radius * .13 - radius * .5),
          width: radius * 2,
          height: radius * .35,
        ),
        math.pi * .1,
        math.pi,
        false,
        Paint()
          ..color = GameColors.marsRock.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .05,
      );
    }
    canvas.restore();
    final horizon = Path()..moveTo(0, size.height);
    for (var i = 0; i <= 16; i++) {
      horizon.lineTo(
        i / 16 * size.width,
        size.height * .88 + math.sin(i * 1.8) * size.height * .02,
      );
    }
    horizon
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(horizon, Paint()..color = GameColors.marsRock);
    for (final (x, id) in const [
      (.24, 'habitat'),
      (.58, 'battery_bank'),
      (.76, 'communications'),
    ]) {
      canvas.save();
      canvas.translate(size.width * x, size.height * .92);
      final scale = (size.width / 600).clamp(.6, 1.4).toDouble();
      canvas.scale(scale);
      FacilityArchitecture.paint(
        canvas,
        id,
        shell: GameColors.moduleShade,
        trim: GameColors.architecturalAccent,
      );
      canvas.restore();
    }
    // Keep the reading region quiet; art must never reduce label contrast.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.ink.withValues(alpha: .12),
            GameColors.ink.withValues(alpha: .88),
            GameColors.ink.withValues(alpha: .35),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ColonyBackdropPainter oldDelegate) => false;
}
