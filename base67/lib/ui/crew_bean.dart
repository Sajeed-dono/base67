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
    final light = Color.lerp(suitColor, Colors.white, .36)!;
    final shade = Color.lerp(suitColor, ink, .4)!;
    void pixels(Rect rect, Color color) => canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    void panel(Rect rect, Color color) {
      pixels(rect.inflate(2), ink);
      pixels(rect, color);
    }

    void shape(List<Offset> points, Color color) => canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    // The top-left light casts this cached-paint shadow down and right.
    canvas.drawOval(const Rect.fromLTWH(24, 105, 64, 10), _groundShadow);
    final stride = walking
        ? (math.sin(walkPhase * math.pi * 2) * 3).roundToDouble()
        : 0.0;
    final bob = mood == CrewMood.celebrating ? -4.0 : breath * 1.5;
    canvas.save();
    canvas.translate(0, bob - (walking ? stride.abs() * .35 : 0));
    panel(const Rect.fromLTWH(15, 36, 17, 42), shade);
    pixels(const Rect.fromLTWH(15, 38, 5, 35), visorTint);
    for (final leg in [(30.0, stride), (55.0, -stride)]) {
      panel(Rect.fromLTWH(leg.$1, 83 + leg.$2, 16, 22), suitColor);
      pixels(Rect.fromLTWH(leg.$1 + 1, 86 + leg.$2, 5, 16), light);
      panel(Rect.fromLTWH(leg.$1 - 4, 102 + leg.$2, 23, 9), GameColors.paper);
      pixels(
        Rect.fromLTWH(leg.$1 - 4, 108 + leg.$2, 23, 3),
        GameColors.machinery,
      );
      pixels(Rect.fromLTWH(leg.$1, 98 + leg.$2, 16, 4), ink);
    }
    panel(const Rect.fromLTWH(28, 55, 46, 34), suitColor);
    pixels(const Rect.fromLTWH(30, 57, 7, 27), light);
    pixels(const Rect.fromLTWH(66, 58, 7, 27), shade);
    pixels(const Rect.fromLTWH(35, 86, 32, 5), shade);
    for (final x in [17.0, 75.0]) {
      panel(Rect.fromLTWH(x, 59, 11, 25), suitColor);
      pixels(Rect.fromLTWH(x, 61, 4, 20), light);
      panel(Rect.fromLTWH(x, 86, 11, 9), GameColors.paper);
      pixels(Rect.fromLTWH(x, 82, 11, 4), ink);
    }
    final roleColor = crewSuitColors[role.index];
    pixels(const Rect.fromLTWH(19, 58, 8, 5), roleColor);
    pixels(const Rect.fromLTWH(77, 58, 7, 5), roleColor);
    pixels(const Rect.fromLTWH(42, 80, 18, 4), GameColors.paper);
    pixels(const Rect.fromLTWH(48, 81, 6, 2), suitColor);
    const helmet = [
      Offset(22, 27),
      Offset(28, 27),
      Offset(28, 19),
      Offset(36, 19),
      Offset(36, 13),
      Offset(63, 13),
      Offset(63, 19),
      Offset(72, 19),
      Offset(72, 27),
      Offset(79, 27),
      Offset(79, 48),
      Offset(73, 48),
      Offset(73, 57),
      Offset(65, 57),
      Offset(65, 62),
      Offset(33, 62),
      Offset(33, 57),
      Offset(25, 57),
      Offset(25, 48),
      Offset(22, 48),
    ];
    shape(helmet, ink);
    shape(const [
      Offset(26, 29),
      Offset(31, 29),
      Offset(31, 22),
      Offset(38, 22),
      Offset(38, 17),
      Offset(61, 17),
      Offset(61, 22),
      Offset(69, 22),
      Offset(69, 29),
      Offset(75, 29),
      Offset(75, 47),
      Offset(69, 47),
      Offset(69, 54),
      Offset(62, 54),
      Offset(62, 58),
      Offset(35, 58),
      Offset(35, 54),
      Offset(29, 54),
      Offset(29, 47),
      Offset(26, 47),
    ], GameColors.paper);
    pixels(const Rect.fromLTWH(44, 27, 24, 3), GameColors.solarCellLine);
    panel(const Rect.fromLTWH(22, 31, 8, 15), GameColors.machineryHighlight);
    pixels(const Rect.fromLTWH(23, 32, 3, 12), Colors.white);
    pixels(const Rect.fromLTWH(71, 31, 5, 18), GameColors.machinery);
    if (facing.dy < -.5) {
      panel(const Rect.fromLTWH(34, 32, 31, 15), GameColors.machineryHighlight);
      pixels(const Rect.fromLTWH(40, 38, 19, 3), suitColor);
      panel(const Rect.fromLTWH(38, 58, 27, 23), GameColors.paper);
      pixels(const Rect.fromLTWH(41, 61, 20, 5), shade);
      pixels(const Rect.fromLTWH(42, 73, 18, 3), suitColor);
    } else {
      shape(const [
        Offset(34, 31),
        Offset(70, 31),
        Offset(70, 48),
        Offset(65, 48),
        Offset(65, 54),
        Offset(38, 54),
        Offset(38, 50),
        Offset(34, 50),
      ], ink);
      pixels(const Rect.fromLTWH(67, 33, 3, 13), GameColors.solarGlass);
      pixels(const Rect.fromLTWH(40, 54, 22, 3), GameColors.machinery);
      _drawFaceStyle(canvas);
    }
    canvas.save();
    canvas.translate(34, 69);
    canvas.scale(.55);
    canvas.translate(-34, -69);
    _drawBadge(canvas);
    canvas.restore();
    panel(const Rect.fromLTWH(59, 66, 7, 5), GameColors.solarGlass);
    pixels(const Rect.fromLTWH(60, 67, 3, 1), visorTint);
    _drawMoodDetails(canvas);
    _drawActivity(canvas);
    if (carryingReservedEquipment) {
      panel(const Rect.fromLTWH(75, 74, 18, 17), GameColors.sand);
      pixels(const Rect.fromLTWH(82, 74, 3, 17), shade);
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
