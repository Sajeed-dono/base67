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
    _drawPath(canvas, size);
    if (!terrainOnly) {
      for (final facility in facilities) {
        paintFacility(canvas, size, facility, panelDust: panelDust);
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

  void _drawPath(Canvas canvas, Size size) {
    // Surface access routes are decorative, traversable ground. They do not
    // imply power connectivity, installed corridors or new facility ownership.
    for (final end in const [
      Offset(.23, .75),
      Offset(.74, .69),
      Offset(.77, .49),
      Offset(.50, .77),
      Offset(.34, .86),
    ]) {
      final route = Path()
        ..moveTo(size.width * .48, size.height * .62)
        ..lineTo(size.width * end.dx, size.height * (end.dy + .045));
      canvas.drawPath(
        route,
        Paint()
          ..color = GameColors.ink.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12,
      );
      canvas.drawPath(
        route,
        Paint()
          ..color = GameColors.sand.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
    }
    final path = Path()
      ..moveTo(size.width * .12, size.height * .90)
      ..cubicTo(
        size.width * .35,
        size.height * .82,
        size.width * .55,
        size.height * .92,
        size.width * .80,
        size.height * .76,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE9BB8A).withValues(alpha: .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF8C5044).withValues(alpha: .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
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
    // Cast shadow and pad are decorative, within the original solid footprint.
    final cast = Path()
      ..moveTo(-22, 4)
      ..lineTo(22, 4)
      ..lineTo(38, 24)
      ..lineTo(-3, 28)
      ..close();
    canvas.drawPath(
      cast,
      Paint()..color = GameColors.marsRockShade.withValues(alpha: .3),
    );
    canvas.drawOval(
      const Rect.fromLTWH(-31, 14, 65, 14),
      Paint()..color = GameColors.ink.withValues(alpha: .22),
    );
    final built = facility.count > 0;
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
    if (!built) {
      canvas.saveLayer(
        const Rect.fromLTWH(-50, -40, 100, 75),
        Paint()..color = Colors.white.withValues(alpha: .55),
      );
    }
    FacilityArchitecture.paint(
      canvas,
      facility.id,
      shell: shell,
      trim: trim,
      operational: built && !inactive,
    );
    if (!built) {
      canvas.restore();
    }
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
      final warning = Path()
        ..moveTo(21, -27)
        ..lineTo(30, -11)
        ..lineTo(12, -11)
        ..close();
      canvas.drawPath(warning, Paint()..color = GameColors.danger);
      final mark = TextPainter(
        text: const TextSpan(
          text: '!',
          style: TextStyle(
            color: GameColors.paper,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mark.paint(canvas, const Offset(19, -25));
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
      canvas.drawRect(
        const Rect.fromLTWH(-26, 22, 52, 4),
        Paint()..color = GameColors.ink,
      );
      canvas.drawRect(
        Rect.fromLTWH(-26, 22, 52 * facility.jobProgress!, 4),
        Paint()..color = GameColors.gold,
      );
    }
    final suffix = !built
        ? facility.referenceOnly
              ? ' / station site'
              : facility.available
              ? ' / unbuilt'
              : ' / locked'
        : facility.condition == 'off'
        ? ' / off'
        : facility.count > 1
        ? ' / ${facility.count} units'
        : '';
    final tp = TextPainter(
      text: TextSpan(
        text: '${facility.label}$suffix',
        style: const TextStyle(
          color: GameColors.paper,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: GameColors.ink, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 110);
    tp.paint(canvas, Offset(-tp.width / 2, 29));
    canvas.restore();
  }

  void _drawLights(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD58A).withValues(alpha: .85);
    for (final fraction in const [
      Offset(.20, .64),
      Offset(.48, .56),
      Offset(.80, .62),
    ]) {
      canvas.drawCircle(
        Offset(size.width * fraction.dx, size.height * fraction.dy),
        2.8,
        paint,
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
