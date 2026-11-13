import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum CrewMood {
  okay,
  cold,
  hungry,
  worried,
  working,
  resting,
  sheltering,
  researching,
  celebrating,
}

enum CrewRole { commander, engineer, scientist, medic }

const crewSuitColors = <Color>[
  Color(0xFFEF6C4D),
  Color(0xFF3B86A8),
  Color(0xFF38A58C),
  Color(0xFF9C6BC1),
  Color(0xFFE0A838),
  Color(0xFF4F91D1),
  Color(0xFFCA6686),
  Color(0xFF6B9A4C),
  Color(0xFFAE5D32),
  Color(0xFF56748A),
  Color(0xFF8B78C5),
  Color(0xFFB64C48),
];

const crewVisorColors = <Color>[
  GameColors.tealLight,
  GameColors.sand,
  GameColors.colorBlindSafeBlue,
];

class CrewBean extends StatefulWidget {
  const CrewBean({
    super.key,
    required this.role,
    this.mood = CrewMood.okay,
    this.suitColorIndex = 0,
    this.visorTintIndex = 0,
    this.faceStyleIndex = 0,
    this.reducedMotion = false,
    this.size = 88,
    this.label,
  });

  final CrewRole role;
  final CrewMood mood;
  final int suitColorIndex;
  final int visorTintIndex;
  final int faceStyleIndex;
  final bool reducedMotion;
  final double size;
  final String? label;

  @override
  State<CrewBean> createState() => _CrewBeanState();
}

class _CrewBeanState extends State<CrewBean>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: GameMotion.idle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setMotion();
  }

  bool get _reduced =>
      widget.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  void _setMotion() {
    if (_reduced) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CrewBean oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setMotion();
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = crewSuitColors[widget.suitColorIndex % crewSuitColors.length];
    final painter = AnimatedBuilder(
      animation: _breath,
      builder: (context, _) => CustomPaint(
        size: Size(widget.size, widget.size * 1.16),
        painter: CrewBeanPainter(
          role: widget.role,
          mood: widget.mood,
          suitColor: color,
          visorTint:
              crewVisorColors[widget.visorTintIndex % crewVisorColors.length],
          faceStyleIndex: widget.faceStyleIndex,
          breath: _reduced ? 0 : _breath.value,
        ),
      ),
    );
    return Semantics(
      label:
          widget.label ?? '${widget.role.name} astronaut, ${widget.mood.name}',
      image: true,
      child: SizedBox(
        width: widget.size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            painter,
            if (widget.label != null) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: widget.size,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label!,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CrewBeanPainter extends CustomPainter {
  const CrewBeanPainter({
    required this.role,
    required this.mood,
    required this.suitColor,
    required this.visorTint,
    required this.faceStyleIndex,
    required this.breath,
    this.walking = false,
    this.walkPhase = 0,
    this.facing = Offset.zero,
    this.activity,
    this.activityPhase = 0,
    this.carryingReservedEquipment = false,
  });

  final CrewRole role;
  final CrewMood mood;
  final Color suitColor;
  final Color visorTint;
  final int faceStyleIndex;
  final double breath;
  final bool walking;
  final double walkPhase;
  final Offset facing;
  final String? activity;
  final double activityPhase;
  final bool carryingReservedEquipment;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100;
    final sy = size.height / 116;
    canvas.save();
    canvas.scale(sx, sy);
    if (facing.dx < 0) {
      canvas.translate(100, 0);
      canvas.scale(-1, 1);
    }
    final stride = walking ? math.sin(walkPhase * math.pi * 2) * 5 : 0.0;
    final bob = mood == CrewMood.celebrating ? -4.0 : breath * 1.5;
    final suit = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(crewSuitColors.first, GameColors.paper, .24)!,
          crewSuitColors.first,
          GameColors.rust,
        ],
      ).createShader(const Rect.fromLTWH(20, 14, 70, 88));
    final trim = Paint()..color = Colors.white.withValues(alpha: 0.92);
    final dark = Paint()..color = GameColors.ink;
    final shadow = Paint()
      ..color = GameColors.ink.withValues(alpha: .24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final visor = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          GameColors.solarCellLine,
          Color.lerp(GameColors.solarGlass, visorTint, .15)!,
          GameColors.marsNight,
        ],
      ).createShader(const Rect.fromLTWH(34, 31, 35, 22));
    final stroke = Paint()
      ..color = Color.lerp(suitColor, GameColors.ink, .62)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawOval(const Rect.fromLTWH(23, 100, 62, 9), shadow);
    canvas.save();
    final squash = walking ? math.sin(walkPhase * math.pi * 2) * .025 : 0.0;
    canvas.translate(0, bob + (walking ? stride.abs() * -.35 : 0));
    canvas.translate(52, 70);
    canvas.rotate(
      walking
          ? facing.dx * -.045 + facing.dy * .02
          : math.sin(breath * math.pi * 2) * .012,
    );
    canvas.scale(1 + squash, 1 - squash);
    canvas.translate(-52, -70);
    if (walking) {
      final dust = Paint();
      final phase = (walkPhase % 1 + 1) % 1;
      for (var i = 0; i < 3; i++) {
        final age = (phase + i / 3) % 1;
        dust.color = GameColors.sand.withValues(alpha: (1 - age) * .34);
        canvas.drawCircle(
          Offset(34 + age * 10, 99 - age * 4 + i * 1.5),
          1.2 + age * 1.3,
          dust,
        );
      }
    }
    // Backpack sits behind the rounded suit.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(67, 40, 22, 40),
        const Radius.circular(8),
      ),
      suit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(68, 47, 18, 14),
        const Radius.circular(5),
      ),
      trim,
    );
    // Legs and boots.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(31, 78 + stride, 15, 24),
        const Radius.circular(7),
      ),
      suit,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(55, 78 - stride, 15, 24),
        const Radius.circular(7),
      ),
      suit,
    );
    canvas.drawOval(Rect.fromLTWH(25, 95 + stride, 25, 9), dark);
    canvas.drawOval(Rect.fromLTWH(52, 95 - stride, 25, 9), dark);
    // Separate pressure helmet, orange torso and shoulder patches keep the
    // small map sprite readable without changing its animation coordinates.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 54, 48, 34),
      const Radius.circular(9),
    );
    canvas.drawRRect(body, suit);
    canvas.drawRRect(body, stroke);
    for (final x in [20.0, 70.0]) {
      final arm = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 57, 12, 29),
        const Radius.circular(5),
      );
      canvas.drawRRect(arm, suit);
      canvas.drawRRect(arm, stroke);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 78, 12, 8),
          const Radius.circular(3),
        ),
        trim,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(27, 77, 46, 8),
        const Radius.circular(3),
      ),
      trim,
    );
    canvas.drawRect(
      const Rect.fromLTWH(46, 78, 9, 6),
      Paint()..color = suitColor,
    );
    final helmet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(23, 14, 56, 46),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      helmet,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            GameColors.paper,
            GameColors.machineryHighlight,
          ],
        ).createShader(const Rect.fromLTWH(23, 14, 56, 46)),
    );
    canvas.drawRRect(helmet, stroke);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 33, 7, 15),
        const Radius.circular(2),
      ),
      trim,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(76, 33, 7, 15),
        const Radius.circular(2),
      ),
      trim,
    );
    canvas.drawArc(
      const Rect.fromLTWH(28, 18, 44, 33),
      3.4,
      1.4,
      false,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Visor, shine and lower suit panel.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 30, 39, 26),
        const Radius.circular(13),
      ),
      dark,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 33, 31, 19),
        const Radius.circular(10),
      ),
      visor,
    );
    canvas.drawArc(
      const Rect.fromLTWH(39, 34, 20, 12),
      3.2,
      1.1,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawArc(
      const Rect.fromLTWH(38, 35, 24, 15),
      3.25,
      .85,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final accent = switch (role) {
      CrewRole.commander => GameColors.gold,
      CrewRole.engineer => GameColors.colorBlindSafeBlue,
      CrewRole.scientist => GameColors.teal,
      CrewRole.medic => const Color(0xFFCA6686),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(21, 59, 9, 10),
        const Radius.circular(2),
      ),
      Paint()..color = accent,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 62, 24, 12),
        const Radius.circular(5),
      ),
      trim,
    );
    if (facing.dy < -.5) {
      // Rear view retains the helmet, backpack and role badge.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(29, 27, 44, 32),
          const Radius.circular(14),
        ),
        trim,
      );
      final pack = RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 51, 29, 30),
        const Radius.circular(7),
      );
      canvas.drawRRect(pack, trim);
      canvas.drawRRect(pack, stroke);
      canvas.drawLine(const Offset(43, 62), const Offset(64, 62), stroke);
    } else {
      canvas.save();
      canvas.translate(facing.dx.abs() * 2, facing.dy * 2);
      _drawMood(canvas);
      canvas.restore();
      _drawFaceStyle(canvas);
    }
    canvas.save();
    canvas.translate(34, 69);
    canvas.scale(.65);
    canvas.translate(-34, -69);
    _drawBadge(canvas);
    canvas.restore();
    _drawMoodDetails(canvas);
    _drawActivity(canvas);
    if (carryingReservedEquipment) {
      final box = RRect.fromRectAndRadius(
        const Rect.fromLTWH(74, 72, 21, 18),
        const Radius.circular(3),
      );
      canvas.drawRRect(box, Paint()..color = GameColors.sand);
      canvas.drawRRect(box, stroke);
      canvas.drawLine(const Offset(84, 74), const Offset(84, 88), stroke);
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawFaceStyle(Canvas canvas) {
    final mark = Paint()..color = GameColors.sand.withValues(alpha: .78);
    switch (faceStyleIndex % 3) {
      case 1:
        canvas.drawCircle(const Offset(38, 53), 1.6, mark);
        canvas.drawCircle(const Offset(65, 53), 1.6, mark);
      case 2:
        canvas.drawCircle(const Offset(40, 41), 1.3, mark);
        canvas.drawCircle(const Offset(64, 41), 1.3, mark);
        canvas.drawCircle(const Offset(52, 56), 1.3, mark);
    }
  }

  /// Only the map supplies an activity after arrival at an assigned station.
  /// Optional motion describes work; it has no timing/completion side effects.
  void _drawActivity(Canvas canvas) {
    if (activity == null) {
      return;
    }
    final swing = math.sin(activityPhase * 3) * 3;
    final tool = Paint()
      ..color = GameColors.sand
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final outline = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    switch (activity) {
      case 'major_repair' || 'repair' || 'clean' || 'construction' || 'upgrade':
        canvas.drawLine(Offset(76, 66 + swing), Offset(89, 57 + swing), tool);
        canvas.drawCircle(Offset(90, 56 + swing), 4, outline);
        if (activity == 'construction') {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(71, 77, 21, 14),
              const Radius.circular(3),
            ),
            Paint()..color = GameColors.gold,
          );
          canvas.drawRect(const Rect.fromLTWH(77, 73, 8, 5), outline);
        }
      case 'research' || 'forecast' || 'survey' || 'priorities' || 'rally':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(73, 60 + swing, 18, 23),
            const Radius.circular(3),
          ),
          Paint()..color = GameColors.ink,
        );
        canvas.drawLine(Offset(77, 66 + swing), Offset(86, 66 + swing), tool);
        canvas.drawLine(Offset(77, 72 + swing), Offset(83, 72 + swing), tool);
      case 'care':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(74, 68, 20, 17),
            const Radius.circular(3),
          ),
          Paint()..color = GameColors.paper,
        );
        canvas.drawLine(
          const Offset(84, 71),
          const Offset(84, 82),
          tool..color = GameColors.teal,
        );
        canvas.drawLine(const Offset(79, 76), const Offset(89, 76), tool);
      default:
        break;
    }
  }

  void _drawMood(Canvas canvas) {
    final face = Paint()..color = GameColors.ink;
    final white = Paint()..color = Colors.white;
    final eyeY = mood == CrewMood.worried ? 43.0 : 45.0;
    final eyeRadius = mood == CrewMood.resting ? 1.8 : 2.5;
    if (mood == CrewMood.resting) {
      final line = Paint()
        ..color = GameColors.ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(42, 45), const Offset(47, 45), line);
      canvas.drawLine(const Offset(56, 45), const Offset(61, 45), line);
    } else {
      canvas.drawCircle(Offset(44, eyeY), eyeRadius + 1, white);
      canvas.drawCircle(Offset(59, eyeY), eyeRadius + 1, white);
      canvas.drawCircle(Offset(45, eyeY + 1), eyeRadius, face);
      canvas.drawCircle(Offset(60, eyeY + 1), eyeRadius, face);
    }
    final mouth = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    switch (mood) {
      case CrewMood.worried:
      case CrewMood.hungry:
        path.moveTo(48, 53);
        path.quadraticBezierTo(52, 49, 57, 53);
      case CrewMood.cold:
        path.moveTo(49, 53);
        path.lineTo(55, 53);
      case CrewMood.celebrating:
        path.moveTo(47, 51);
        path.quadraticBezierTo(52, 60, 59, 51);
      case CrewMood.resting:
        path.moveTo(49, 53);
        path.lineTo(55, 53);
      default:
        path.moveTo(47, 51);
        path.quadraticBezierTo(52, 57, 59, 51);
    }
    canvas.drawPath(path, mouth);
  }

  void _drawMoodDetails(Canvas canvas) {
    final accent = Paint()..color = GameColors.gold;
    final ink = Paint()
      ..color = GameColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case CrewMood.cold:
        final frost = Paint()..color = Colors.white.withValues(alpha: 0.9);
        canvas.drawCircle(const Offset(76, 25), 3, frost);
        canvas.drawCircle(const Offset(20, 48), 2, frost);
      case CrewMood.hungry:
        canvas.drawCircle(const Offset(73, 69), 7, accent);
        canvas.drawLine(const Offset(73, 62), const Offset(73, 76), ink);
      case CrewMood.worried:
        canvas.drawCircle(
          const Offset(74, 43),
          3,
          Paint()..color = const Color(0xFF78B9D0),
        );
      case CrewMood.working:
        canvas.drawLine(const Offset(77, 65), const Offset(85, 57), ink);
        canvas.drawLine(const Offset(81, 54), const Offset(87, 60), ink);
      case CrewMood.sheltering:
        final shield = Path()
          ..moveTo(20, 24)
          ..lineTo(27, 27)
          ..lineTo(26, 35)
          ..lineTo(20, 39)
          ..lineTo(14, 35)
          ..lineTo(13, 27)
          ..close();
        canvas.drawPath(shield, accent);
      case CrewMood.researching:
        canvas.drawLine(const Offset(76, 35), const Offset(82, 48), ink);
        canvas.drawLine(const Offset(82, 48), const Offset(76, 53), ink);
        canvas.drawLine(const Offset(76, 53), const Offset(71, 48), ink);
        canvas.drawCircle(
          const Offset(77, 44),
          2,
          Paint()..color = GameColors.teal,
        );
      case CrewMood.celebrating:
        for (final point in const [
          Offset(17, 20),
          Offset(81, 18),
          Offset(82, 72),
        ]) {
          canvas.drawCircle(point, 3, accent);
        }
      case CrewMood.okay:
      case CrewMood.resting:
        break;
    }
  }

  void _drawBadge(Canvas canvas) {
    final center = const Offset(34, 69);
    canvas.drawCircle(center, 12, Paint()..color = GameColors.sand);
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = GameColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final badge = Paint()
      ..color = GameColors.rust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (role) {
      case CrewRole.commander:
        final points = <Offset>[];
        for (var index = 0; index < 10; index++) {
          final angle = -math.pi / 2 + index * math.pi / 5;
          final radius = index.isEven ? 8.0 : 4.0;
          points.add(
            Offset(
              center.dx + radius * math.cos(angle),
              center.dy + radius * math.sin(angle),
            ),
          );
        }
        final star = Path()..addPolygon(points, true);
        canvas.drawPath(star, Paint()..color = GameColors.rust);
      case CrewRole.engineer:
        canvas.drawCircle(const Offset(36, 64), 4, badge);
        canvas.drawLine(const Offset(36, 68), const Offset(31, 76), badge);
        canvas.drawLine(const Offset(31, 76), const Offset(27, 73), badge);
        canvas.drawLine(const Offset(31, 76), const Offset(35, 78), badge);
      case CrewRole.scientist:
        final flask = Path()
          ..moveTo(31, 61)
          ..lineTo(37, 61)
          ..moveTo(33, 61)
          ..lineTo(33, 67)
          ..lineTo(28, 75)
          ..quadraticBezierTo(27, 78, 31, 78)
          ..lineTo(38, 78)
          ..quadraticBezierTo(41, 78, 39, 75)
          ..lineTo(35, 67)
          ..lineTo(35, 61);
        canvas.drawPath(flask, badge);
        canvas.drawLine(const Offset(30, 73), const Offset(38, 73), badge);
      case CrewRole.medic:
        final cross = Paint()..color = GameColors.teal;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(31, 62, 6, 14),
            const Radius.circular(2),
          ),
          cross,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 66, 14, 6),
            const Radius.circular(2),
          ),
          cross,
        );
    }
  }

  @override
  bool shouldRepaint(covariant CrewBeanPainter oldDelegate) =>
      role != oldDelegate.role ||
      mood != oldDelegate.mood ||
      suitColor != oldDelegate.suitColor ||
      visorTint != oldDelegate.visorTint ||
      faceStyleIndex != oldDelegate.faceStyleIndex ||
      breath != oldDelegate.breath ||
      walking != oldDelegate.walking ||
      walkPhase != oldDelegate.walkPhase ||
      facing != oldDelegate.facing ||
      activity != oldDelegate.activity ||
      activityPhase != oldDelegate.activityPhase ||
      carryingReservedEquipment != oldDelegate.carryingReservedEquipment;
}
