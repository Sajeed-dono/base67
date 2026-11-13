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

// Role offsets give legacy/default crews distinct uniforms without changing saves.
Color crewSuitColor(CrewRole role, int choice) =>
    crewSuitColors[(choice + role.index) % crewSuitColors.length];

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
    final color = crewSuitColor(widget.role, widget.suitColorIndex);
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
  static final Paint _groundShadow = Paint()
    ..color = GameColors.ink.withValues(alpha: .3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);

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
    canvas.save();
    canvas.scale(size.width / 100, size.height / 116);
    if (facing.dx < 0) {
      canvas.translate(100, 0);
      canvas.scale(-1, 1);
    }
    final ink = GameColors.ink;
    final roleColor = crewSuitColors[role.index];
    final light = Color.lerp(suitColor, Colors.white, .46)!;
    final shade = Color.lerp(suitColor, ink, .42)!;
    final outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final seam = Paint()
      ..color = shade
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final shell = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [light, suitColor, shade],
        stops: const [.04, .52, 1],
      ).createShader(const Rect.fromLTWH(20, 14, 68, 89));
    final whiteShell = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, GameColors.paper, GameColors.machineryHighlight],
      ).createShader(const Rect.fromLTWH(20, 14, 60, 47));

    // Top-left key light falls across the suit and casts its shadow down-right.
    canvas.drawOval(const Rect.fromLTWH(22, 104, 68, 11), _groundShadow);
    final stride = walking ? math.sin(walkPhase * math.pi * 2) * 4 : 0.0;
    final bob = mood == CrewMood.celebrating ? -4.0 : breath * 1.5;
    canvas.save();
    canvas.translate(0, bob - (walking ? stride.abs() * .28 : 0));

    void boot(Rect rect) {
      final shape = RRect.fromRectAndRadius(rect, const Radius.circular(5));
      canvas.drawRRect(shape, Paint()..color = GameColors.paper);
      canvas.drawRRect(shape, outline);
      canvas.drawLine(
        rect.bottomLeft.translate(2, -3),
        rect.bottomRight.translate(-2, -3),
        Paint()
          ..color = GameColors.machinery
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        rect.bottomLeft.translate(3, -1),
        rect.bottomRight.translate(-3, -1),
        Paint()
          ..color = GameColors.machineryHighlight
          ..strokeWidth = 1,
      );
    }

    // Backpack and articulated legs sit behind the torso.
    final pack = RRect.fromRectAndRadius(
      const Rect.fromLTWH(65, 43, 24, 39),
      const Radius.circular(9),
    );
    canvas.drawRRect(pack, shell);
    canvas.drawRRect(pack, outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(69, 48, 16, 20),
        const Radius.circular(4),
      ),
      Paint()..color = GameColors.machinery,
    );
    for (var y = 51.0; y <= 64; y += 4) {
      canvas.drawLine(
        Offset(71, y),
        Offset(83, y),
        Paint()
          ..color = GameColors.machineryHighlight
          ..strokeWidth = 1.2,
      );
    }
    for (final leg in [(32.0, stride), (55.0, -stride)]) {
      final rect = Rect.fromLTWH(leg.$1, 79 + leg.$2, 16, 25);
      final armor = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(armor, shell);
      canvas.drawRRect(armor, outline);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leg.$1 + 1, 83 + leg.$2, 14, 8),
          const Radius.circular(3),
        ),
        Paint()..color = shade,
      );
      canvas.drawLine(
        Offset(leg.$1 + 3, 94 + leg.$2),
        Offset(leg.$1 + 13, 94 + leg.$2),
        seam,
      );
      boot(Rect.fromLTWH(leg.$1 - 5, 100 + leg.$2, 26, 11));
    }

    // Armored torso and padded shoulders.
    for (final side in [-1.0, 1.0]) {
      final arm = RRect.fromRectAndRadius(
        Rect.fromLTWH(side < 0 ? 16 : 72, 54, 13, 31),
        const Radius.circular(6),
      );
      canvas.drawRRect(arm, shell);
      canvas.drawRRect(arm, outline);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(side < 0 ? 14 : 70, 50, 17, 13),
          const Radius.circular(6),
        ),
        Paint()..color = GameColors.machineryHighlight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(side < 0 ? 14 : 70, 50, 17, 13),
          const Radius.circular(6),
        ),
        outline,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(side < 0 ? 17 : 73, 68, 11, 7),
          const Radius.circular(2),
        ),
        Paint()..color = roleColor,
      );
      canvas.drawLine(
        Offset(side < 0 ? 20 : 76, 70),
        Offset(side < 0 ? 26 : 82, 70),
        Paint()
          ..color = Colors.white.withValues(alpha: .72)
          ..strokeWidth = 1.5,
      );
    }
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 51, 50, 39),
      const Radius.circular(13),
    );
    canvas.drawRRect(body, shell);
    canvas.drawRRect(body, outline);
    canvas.drawLine(
      const Offset(31, 59),
      const Offset(31, 81),
      Paint()
        ..color = light.withValues(alpha: .8)
        ..strokeWidth = 2,
    );
    canvas.drawLine(const Offset(69, 59), const Offset(69, 81), seam);
    canvas.drawLine(const Offset(33, 86), const Offset(67, 86), seam);

    // Utility belt, chest life-support readout and role-lit shoulder stripe.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 80, 42, 8),
        const Radius.circular(3),
      ),
      Paint()..color = GameColors.machinery,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(45, 79, 11, 9),
        const Radius.circular(2),
      ),
      Paint()..color = GameColors.prologueAmber,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 61, 24, 15),
        const Radius.circular(5),
      ),
      Paint()..color = GameColors.machinery,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(40, 63, 20, 11),
        const Radius.circular(3),
      ),
      Paint()..color = GameColors.solarGlass,
    );
    canvas.drawCircle(const Offset(55, 68), 2.2, Paint()..color = roleColor);
    canvas.drawCircle(
      const Offset(55, 68),
      4.2,
      Paint()
        ..color = roleColor.withValues(alpha: .22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      const Offset(28, 55),
      const Offset(36, 58),
      Paint()
        ..color = roleColor
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      const Offset(64, 58),
      const Offset(72, 55),
      Paint()
        ..color = roleColor
        ..strokeWidth = 4,
    );

    // Rounded pressure helmet with glossy HUD visor.
    final helmet = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 14, 56, 46),
      const Radius.circular(21),
    );
    canvas.drawRRect(helmet, whiteShell);
    canvas.drawRRect(helmet, outline);
    canvas.drawArc(
      const Rect.fromLTWH(27, 17, 43, 29),
      math.pi * 1.08,
      math.pi * .60,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final x in [18.0, 76.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 31, 8, 17),
          const Radius.circular(3),
        ),
        Paint()..color = GameColors.machineryHighlight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 31, 8, 17),
          const Radius.circular(3),
        ),
        outline,
      );
    }
    if (facing.dy < -.5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 31, 40, 23),
          const Radius.circular(9),
        ),
        Paint()..color = GameColors.machineryHighlight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(30, 31, 40, 23),
          const Radius.circular(9),
        ),
        outline,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(39, 60, 22, 15),
          const Radius.circular(4),
        ),
        Paint()..color = GameColors.paper,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(39, 60, 22, 15),
          const Radius.circular(4),
        ),
        outline,
      );
    } else {
      final visor = RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 29, 40, 25),
        const Radius.circular(12),
      );
      canvas.drawRRect(
        visor,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ink,
              GameColors.solarGlass,
              Color.lerp(visorTint, ink, .3)!,
            ],
          ).createShader(const Rect.fromLTWH(30, 29, 40, 25)),
      );
      canvas.drawRRect(
        visor,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawArc(
        const Rect.fromLTWH(34, 30, 24, 14),
        math.pi * 1.12,
        math.pi * .43,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        const Offset(63, 34),
        const Offset(67, 39),
        Paint()
          ..color = GameColors.prologueTeal.withValues(alpha: .9)
          ..strokeWidth = 1.5,
      );
      _drawFaceStyle(canvas);
    }

    canvas.save();
    canvas.translate(34, 69);
    canvas.scale(.55);
    canvas.translate(-34, -69);
    _drawBadge(canvas);
    canvas.restore();
    _drawMoodDetails(canvas);
    _drawActivity(canvas);
    if (carryingReservedEquipment) {
      final box = RRect.fromRectAndRadius(
        const Rect.fromLTWH(75, 74, 18, 17),
        const Radius.circular(3),
      );
      canvas.drawRRect(box, Paint()..color = GameColors.sand);
      canvas.drawRRect(
        box,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawLine(
        const Offset(84, 75),
        const Offset(84, 89),
        Paint()
          ..color = shade
          ..strokeWidth = 1.3,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  void _drawFaceStyle(Canvas canvas) {
    final shine = Paint()
      ..color = Colors.white
      ..isAntiAlias = false;
    final x = 38.0 + faceStyleIndex % 3 * 3;
    canvas.drawRect(Rect.fromLTWH(x, 33, 10, 3), shine);
    canvas.drawRect(Rect.fromLTWH(x, 36, 5, 5), shine);
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
