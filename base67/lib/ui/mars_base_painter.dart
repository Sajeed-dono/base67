import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'facility_architecture.dart';
import 'mars_terrain.dart';

class MarsFacility {
  const MarsFacility(
    this.id,
    this.label,
    this.position, {
    this.level = 0,
    this.available = false,
    this.installedUnits,
    this.damagedUnits = 0,
    this.operatingState,
    this.jobProgress,
    this.jobLabel,
    this.referenceOnly = false,
  });
  final String id;
  final String label;
  final Offset position;
  final int level;
  final bool available;
  final int? installedUnits;
  final int damagedUnits;
  final String? operatingState, jobLabel;
  final double? jobProgress;
  final bool referenceOnly;
  int get count => installedUnits ?? (level > 0 ? 1 : 0);
  String get canonicalId => switch (id) {
    'habitat' || 'medical_area' => 'crew_habitat',
    'communications' => 'mission_control_hub',
    _ => id,
  };
  String get condition =>
      operatingState ??
      (count == 0
          ? 'notBuilt'
          : damagedUnits > 0
          ? 'damaged'
          : 'operating');
}

/// One layout for both settlement views. IDs here are painter aliases only;
/// ownership and assignments retain their canonical progression IDs.
abstract final class SettlementLayout {
  static List<MarsFacility> facilities(
    Map<String, int> units, {
    Set<String> unlocked = const {},
  }) => [
    for (final row in const <(String, String, String, double, double, String)>[
      ('habitat', 'crew_habitat', 'Habitat', .48, .57, 'L13_crew_care'),
      ('landing_craft', 'landing_craft', 'Lander', .16, .84, ''),
      ('solar_array', 'solar_array', 'Solar', .23, .75, 'L01_first_light'),
      ('battery_bank', 'battery_bank', 'Power', .74, .69, 'L02_power_storage'),
      (
        'greenhouse',
        'greenhouse',
        'Greenhouse',
        .77,
        .49,
        'L06_greenhouse_online',
      ),
      ('research_lab', 'research_lab', 'Lab', .23, .50, 'L01_first_light'),
      (
        'power_control_station',
        'power_control_station',
        'Power control',
        .47,
        .46,
        'L03_energy_manager',
      ),
      (
        'life_support_module',
        'life_support_module',
        'Life support',
        .50,
        .77,
        'L07_breathing_matters',
      ),
      (
        'radiation_shelter',
        'radiation_shelter',
        'Shelter',
        .31,
        .38,
        'L09_shelter_protocol',
      ),
      (
        'ice_miner_water_storage',
        'ice_miner_water_storage',
        'Ice and water',
        .69,
        .37,
        'L11_ice_operations',
      ),
      (
        'food_storage',
        'food_storage',
        'Food',
        .16,
        .62,
        'L12_food_and_supplies',
      ),
      (
        'maintenance_bay',
        'maintenance_bay',
        'Workshop',
        .50,
        .34,
        'L04_dust_on_mars',
      ),
      (
        'communications',
        'mission_control_hub',
        'Comms',
        .87,
        .59,
        'L14_mission_control',
      ),
      ('rover', 'rover', 'Rover', .65, .86, 'L10_finding_water'),
      ('medical_area', 'crew_habitat', 'Crew care', .34, .86, 'L13_crew_care'),
    ])
      MarsFacility(
        row.$1,
        row.$3,
        Offset(row.$4, row.$5),
        level: units[row.$2] ?? 0,
        available: unlocked.contains(row.$6),
        referenceOnly: const {'research_lab', 'rover'}.contains(row.$1),
      ),
  ];

  static String painterId(String id) => switch (id) {
    'crew_habitat' => 'habitat',
    'mission_control_hub' => 'communications',
    _ => id,
  };

  static double scale(Size size) =>
      (size.shortestSide / 360).clamp(.72, 1.35).toDouble();

  /// Conservative solid hull including appendages. Labels and shadows are not
  /// solid. Even an unbuilt site has a visible shell in the existing painter.
  static Rect hull(MarsFacility facility, Size size) {
    final s = scale(size);
    final center = Offset(
      facility.position.dx * size.width,
      facility.position.dy * size.height,
    );
    final halfWidth = switch (facility.id) {
      'solar_array' => 42.0,
      'rover' => 33.0,
      'habitat' => 28.0,
      _ => 27.0,
    };
    return Rect.fromLTRB(
      center.dx - halfWidth * s,
      center.dy - 30 * s,
      center.dx + halfWidth * s,
      center.dy + 25 * s,
    );
  }

  static Path ground(Size size) => Path()
    ..moveTo(0, size.height * .45)
    ..cubicTo(
      size.width * .18,
      size.height * .31,
      size.width * .30,
      size.height * .49,
      size.width * .48,
      size.height * .38,
    )
    ..cubicTo(
      size.width * .68,
      size.height * .27,
      size.width * .83,
      size.height * .46,
      size.width,
      size.height * .34,
    )
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
}

class MarsBasePainter extends CustomPainter {
  const MarsBasePainter({
    required this.facilities,
    this.sunset = false,
    this.panelDust = 0,
    this.storm = false,
    this.terrainOnly = false,
  });

  final List<MarsFacility> facilities;
  final bool sunset;
  final double panelDust;
  final bool storm;
  final bool terrainOnly;

  @override
  void paint(Canvas canvas, Size size) {
    MarsTerrain.paint(canvas, size, night: sunset);
    _drawPath(canvas, size, facilities);
    if (!terrainOnly) {
      for (final facility in facilities) {
        paintFacility(canvas, size, facility, panelDust: panelDust);
      }
      final labels = <Rect>[];
      for (final facility in facilities.where((site) => site.count > 0)) {
        final rect = paintFacilityLabel(
          canvas,
          size,
          facility,
          occupied: labels,
        );
        if (rect != null) labels.add(rect);
      }
    }
    if (sunset) _drawLights(canvas, size);
    if (!terrainOnly) {
      MarsTerrain.atmosphere(
        canvas,
        size,
        seconds: 0,
        reducedMotion: true,
        storm: storm,
      );
    }
  }

  void _drawPath(Canvas canvas, Size size, List<MarsFacility> facilities) {
    // Trails and conduits are decorative, never resource connectivity.
    final routes = <Path>[];
    final hub = facilities
        .where((site) => site.canonicalId == 'crew_habitat')
        .firstOrNull;
    final origin = hub?.position ?? const Offset(.48, .57);
    final nearby =
        facilities
            .where(
              (site) => site.count > 0 && site.canonicalId != 'crew_habitat',
            )
            .where((site) {
              final dx = site.position.dx - origin.dx;
              final dy = site.position.dy - origin.dy;
              return dx * dx + dy * dy <= .20;
            })
            .toList()
          ..sort((a, b) {
            final da =
                math.pow(a.position.dx - origin.dx, 2) +
                math.pow(a.position.dy - origin.dy, 2);
            final db =
                math.pow(b.position.dx - origin.dx, 2) +
                math.pow(b.position.dy - origin.dy, 2);
            return da.compareTo(db);
          });
    for (final site in nearby.take(6)) {
      final start = Offset(
        size.width * origin.dx,
        size.height * (origin.dy + .045),
      );
      final finish = Offset(
        size.width * site.position.dx,
        size.height * (site.position.dy + .045),
      );
      final control = Offset(
        (start.dx + finish.dx) / 2 + (finish.dy - start.dy) * .12,
        (start.dy + finish.dy) / 2 - 17,
      );
      routes.add(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(control.dx, control.dy, finish.dx, finish.dy),
      );
    }
    final hulls = SettlementLayout.facilities(const {})
        .map((s) => SettlementLayout.hull(s, size).inflate(8))
        .toList();
    for (var index = 0; index < routes.length; index++) {
      for (final metric in routes[index].computeMetrics()) {
        final left = <Offset>[], right = <Offset>[];
        final cable = Path();
        for (var d = 0.0; d < metric.length + 6; d += 6) {
          final tangent = metric.getTangentForOffset(
            math.min(d, metric.length),
          )!;
          final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
          final edge =
              10 + math.sin(d * .14 + index) * 1.5 + math.sin(d * .43) * .7;
          left.add(tangent.position + normal * edge);
          right.add(tangent.position - normal * edge);
          final conduit = tangent.position + normal * 15;
          if (d == 0) {
            cable.moveTo(conduit.dx, conduit.dy);
          } else {
            cable.lineTo(conduit.dx, conduit.dy);
          }
        }
        final trail = Path()..addPolygon([...left, ...right.reversed], true);
        canvas.drawPath(
          trail.shift(const Offset(2, 3)),
          Paint()
            ..color = GameColors.marsRockShade.withValues(alpha: .3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawPath(
          trail,
          Paint()
            ..color = Color.lerp(
              GameColors.sand,
              GameColors.marsGround,
              sunset ? .86 : .72,
            )!
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
        canvas.drawPath(
          routes[index],
          Paint()
            ..color = GameColors.ink.withValues(alpha: .36)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 13
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          routes[index],
          Paint()
            ..color = GameColors.machinery.withValues(alpha: .9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          routes[index],
          Paint()
            ..color = GameColors.solarCellLine.withValues(
              alpha: sunset ? .42 : .55,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          routes[index],
          Paint()
            ..color = GameColors.workLight.withValues(alpha: sunset ? .85 : .52)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawPath(
          cable,
          Paint()
            ..color = GameColors.ink.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
        canvas.drawPath(
          cable,
          Paint()
            ..color = GameColors.workLight.withValues(alpha: sunset ? .92 : .72)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        for (var d = 38.0; d < metric.length - 20; d += 96) {
          final tangent = metric.getTangentForOffset(d)!;
          final at =
              tangent.position +
              Offset(-tangent.vector.dy, tangent.vector.dx) * 18;
          if (hulls.any((hull) => hull.contains(at))) continue;
          canvas.drawOval(
            Rect.fromCenter(center: at.translate(3, 2), width: 9, height: 4),
            Paint()..color = GameColors.ink.withValues(alpha: .28),
          );
          canvas.drawLine(
            at,
            at.translate(0, -12),
            Paint()
              ..color = GameColors.machinery
              ..strokeWidth = 2,
          );
          canvas.drawLine(
            at.translate(-1, -11),
            at.translate(-1, -16),
            Paint()
              ..color = GameColors.workLight
              ..strokeWidth = 2.5
              ..strokeCap = StrokeCap.round,
          );
          if (sunset) {
            final center = at.translate(0, -14);
            canvas.drawCircle(
              center,
              15,
              Paint()
                ..shader = RadialGradient(
                  colors: [
                    GameColors.workLight.withValues(alpha: .48),
                    Colors.transparent,
                  ],
                ).createShader(Rect.fromCircle(center: center, radius: 15)),
            );
          }
        }
      }
    }
  }

  static void paintFacility(
    Canvas canvas,
    Size size,
    MarsFacility facility, {
    double panelDust = 0,
  }) {
    final center = Offset(
      facility.position.dx * size.width,
      facility.position.dy * size.height,
    );
    final scale = SettlementLayout.scale(size);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    final built = facility.count > 0;
    if (!built) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.white.withValues(alpha: GameOpacity.ghost),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(-24, 12, 57, 21),
      Paint()
        ..color = GameColors.ink.withValues(alpha: .32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-31, 14, 65, 14),
      Paint()..color = GameColors.ink.withValues(alpha: .18),
    );
    final inactive =
        facility.condition == 'off' ||
        facility.condition == 'outOfResources' ||
        built && facility.damagedUnits >= facility.count;
    final shell = inactive
        ? GameColors.outline
        : built
        ? GameColors.structuralSurface
        : GameColors.muted;
    final trim = inactive
        ? GameColors.muted
        : built
        ? GameColors.architecturalAccent
        : GameColors.outline;
    FacilityArchitecture.paint(
      canvas,
      facility.id,
      shell: shell,
      trim: trim,
      operational: built && !inactive,
    );
    if (facility.id == 'solar_array' && built && panelDust > 0) {
      canvas.drawRect(
        const Rect.fromLTWH(-41, -18, 80, 24),
        Paint()
          ..color = GameColors.sand.withValues(
            alpha: (panelDust * 4).clamp(0, .8).toDouble(),
          ),
      );
    }
    if (facility.damagedUnits > 0) {
      final fracture = Path()
        ..moveTo(-14, -14)
        ..lineTo(-8, -6)
        ..lineTo(-11, -1)
        ..lineTo(-4, 6);
      canvas.drawPath(
        fracture,
        Paint()
          ..color = GameColors.machinery
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final warning = RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, -31, 22, 17),
        const Radius.circular(6),
      );
      canvas.drawRRect(warning, Paint()..color = GameColors.danger);
      final mark = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: GameColors.paper,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mark.paint(
        canvas,
        Offset(
          warning.left + (warning.width - mark.width) / 2,
          warning.top + (warning.height - mark.height) / 2,
        ),
      );
    }
    if (facility.level > 1) {
      canvas.drawCircle(
        const Offset(-24, -23),
        9,
        Paint()..color = GameColors.gold,
      );
      final tier = TextPainter(
        text: TextSpan(
          text: '${facility.level}',
          style: const TextStyle(
            color: GameColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tier.paint(canvas, Offset(-24 - tier.width / 2, -23 - tier.height / 2));
    }
    if (facility.jobProgress != null) {
      if (!built) {
        final rail = Paint()
          ..color = GameColors.machineryHighlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (final x in [-25.0, 0.0, 25.0]) {
          canvas.drawLine(Offset(x, -27), Offset(x, 20), rail);
        }
        canvas.drawLine(const Offset(-25, -27), const Offset(25, -27), rail);
        canvas.drawLine(const Offset(-25, 0), const Offset(25, -27), rail);
      }
      final rail = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-27, 21, 54, 6),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rail,
        Paint()..color = GameColors.ink.withValues(alpha: .92),
      );
      final progress = (facility.jobProgress ?? 0).clamp(0, 1).toDouble();
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(-26, 22, 52 * progress, 4),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        fill,
        Paint()
          ..color = GameColors.gold.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(fill, Paint()..color = GameColors.gold);
    }
    if (!built) {
      canvas.restore();
      final lock = Paint()
        ..color = GameColors.paper.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameBorders.standard;
      canvas.drawArc(
        const Rect.fromLTWH(-3, 12, 6, 8),
        math.pi,
        math.pi,
        false,
        lock,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, 16, 10, 8),
          const Radius.circular(2),
        ),
        lock,
      );
    }
    canvas.restore();
  }

  /// Labels are separate from cached buildings so they always paint on top.
  static Rect? paintFacilityLabel(
    Canvas canvas,
    Size size,
    MarsFacility facility, {
    Iterable<Rect> occupied = const [],
  }) {
    if (facility.count == 0) return null;
    final tp = TextPainter(
      text: TextSpan(
        text: facility.label,
        style: const TextStyle(
          color: GameColors.paper,
          fontSize: GameTypography.labelSmall,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: GameColors.ink, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 110);
    final labelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-tp.width / 2 - 6, 27, tp.width + 12, tp.height + 5),
      const Radius.circular(GameRadii.chip),
    );
    final scale = SettlementLayout.scale(size);
    final center = Offset(
      facility.position.dx * size.width,
      facility.position.dy * size.height,
    );
    final bounds = Rect.fromLTWH(
      center.dx + labelRect.left * scale,
      center.dy + labelRect.top * scale,
      labelRect.width * scale,
      labelRect.height * scale,
    );
    if (occupied.any((rect) => rect.overlaps(bounds))) return null;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.drawRRect(labelRect, Paint()..color = GameColors.hudGlass);
    canvas.drawRRect(
      labelRect,
      Paint()
        ..color = GameColors.hudBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = GameBorders.subtle,
    );
    tp.paint(canvas, Offset(-tp.width / 2, 29.5));
    canvas.restore();
    return bounds;
  }

  void _drawLights(Canvas canvas, Size size) {
    for (final fraction in const [
      Offset(.20, .64),
      Offset(.48, .56),
      Offset(.80, .62),
    ]) {
      final center = Offset(
        size.width * fraction.dx,
        size.height * fraction.dy,
      );
      const radius = 16.0;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x88FFD58A), Color(0x22FFD58A), Colors.transparent],
            stops: [0, .35, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      canvas.drawCircle(
        center,
        2.8,
        Paint()..color = const Color(0xFFFFD58A).withValues(alpha: .92),
      );
    }
  }

  @override
  bool shouldRepaint(covariant MarsBasePainter oldDelegate) =>
      facilities != oldDelegate.facilities ||
      sunset != oldDelegate.sunset ||
      panelDust != oldDelegate.panelDust ||
      storm != oldDelegate.storm ||
      terrainOnly != oldDelegate.terrainOnly;
}
