import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../app/campaign_save.dart';
import 'crew_bean.dart';
import 'mars_base_painter.dart';
import 'theme.dart';

/// Detached, read-only presentation. No service, clock or save callback is
/// available to movement, so arrival cannot execute an assignment.
class MapCrew {
  const MapCrew(
    this.role,
    this.name, {
    this.task,
    this.target,
    this.mood = CrewMood.okay,
    this.suit = 0,
    this.visor = 0,
    this.face = 0,
    this.progress,
    this.remainingLabel,
    this.hasReservedEquipment = false,
  });
  final CrewRole role;
  final String name;
  final String? task, target;
  final CrewMood mood;
  final int suit, visor, face;
  final double? progress;
  final String? remainingLabel;
  final bool hasReservedEquipment;
  String get id => role.name;

  static List<MapCrew> fromSave(CampaignSave save) {
    final p = save.progressionJson == null
        ? const <String, dynamic>{}
        : jsonDecode(save.progressionJson!) as Map<String, dynamic>;
    final mission = save.missionJson == null
        ? const <String, dynamic>{}
        : jsonDecode(save.missionJson!) as Map<String, dynamic>;
    final external = p['externalCrewAssignments'] as Map? ?? const {};
    final jobs = (p['jobs'] as Map? ?? const {}).values.whereType<Map>();
    return [
      for (final role in CrewRole.values)
        (() {
          final key = role.name[0].toUpperCase() + role.name.substring(1);
          final job = jobs
              .where((j) => j['status'] == 'active' && j['crewId'] == key)
              .firstOrNull;
          final recipe = job?['recipe'] as Map?;
          final String? task = job != null
              ? (recipe?['kind'] as String?)
              : (external[key] as String?)?.replaceFirst('mission:', '');
          final sheltered = mission['shelter'] == true;
          final effective = sheltered ? 'shelter' : task;
          final String? target = sheltered
              ? 'radiation_shelter'
              : (recipe?['targetId'] as String?);
          final appearance = save.crewAppearance[key];
          final clock = job?['clock'] as Map?;
          final remaining = clock?['remainingMicros'] as num?;
          final duration = clock?['durationMicros'] as num?;
          final simulationTask =
              ((mission['settlement'] as Map?)?['tasks'] as Map?)?[key] as Map?;
          return MapCrew(
            role,
            save.crewNames[key] ?? key,
            task: effective,
            target: target,
            suit: appearance?['suit'] ?? 0,
            visor: appearance?['visor'] ?? 0,
            face: appearance?['face'] ?? 0,
            progress: remaining != null && duration != null && duration > 0
                ? (1 - remaining / duration).clamp(0, 1).toDouble()
                : null,
            remainingLabel: remaining != null
                ? '${(remaining / Duration.microsecondsPerSecond).ceil()} real seconds at last check'
                : simulationTask == null
                ? null
                : '${simulationTask['remaining']} simulation hours',
            hasReservedEquipment:
                job != null &&
                (job['reservedStock'] as Map? ?? const {}).values.any(
                  (n) => (n as num) > 0,
                ),
            mood: switch (effective) {
              'shelter' || 'drill' => CrewMood.sheltering,
              'rest' => CrewMood.resting,
              'research' || 'forecast' || 'survey' => CrewMood.researching,
              null =>
                mission['phase'] == 'debrief'
                    ? mission['result'] == 'success'
                          ? CrewMood.celebrating
                          : CrewMood.worried
                    : CrewMood.okay,
              _ => CrewMood.working,
            },
          );
        })(),
    ];
  }
}

class MovingCrew {
  MovingCrew(this.member, this.position);
  MapCrew member;
  Offset position, facing = const Offset(0, 1);
  Offset? destination;
  List<Offset> path = [];
  bool walking = false;
  double blockedSeconds = 0;
}

/// Disposable, session-only positions shared by the existing map views.
/// Time here is animation delta seconds, never Mars time or job UTC.
class CrewMovement extends ChangeNotifier {
  final Map<String, MovingCrew> actors = {};
  final ValueNotifier<String> feedback = ValueNotifier(
    'Autonomous crew. Select an astronaut to take control.',
  );
  String selected = CrewRole.commander.name;
  bool manual = false;
  bool reducedMotion = false;
  Offset direction = Offset.zero;
  double animationSeconds = 0;
  Size size = Size.zero;
  List<MarsFacility> _facilities = [];
  List<Rect> _hulls = [];
  Path _ground = Path();
  Set<Offset> _cells = {};
  String _signature = '';
  String _geometrySignature = '';
  final Map<String, String> _visits = {};
  bool get visiting => _visits.containsKey(selected);
  String get destinationLabel {
    final member = actors[selected]?.member;
    if (member == null) {
      return 'No astronaut selected';
    }
    final id = _visits[selected] ?? destinationId(member);
    final site = _facilities
        .where(
          (f) => f.id == id && (f.count > 0 || member.task == 'construction'),
        )
        .firstOrNull;
    return site?.label ?? 'Habitat station';
  }

  bool get needsFrames =>
      actors.values.any((a) => a.path.isNotEmpty) ||
      (manual && direction != Offset.zero) ||
      actors.isNotEmpty && !reducedMotion;

  void configure(
    Size nextSize,
    List<MarsFacility> facilities,
    List<MapCrew> crew, {
    required bool reduceMotion,
  }) {
    if (nextSize.isEmpty) {
      return;
    }
    reducedMotion = reduceMotion;
    final geometrySignature =
        '$nextSize:${facilities.map((f) => '${f.id}:${f.position}').join('|')}';
    final geometryChanged = geometrySignature != _geometrySignature;
    final signature =
        '$geometrySignature:'
        '${facilities.map((f) => '${f.id}:${f.level}:${f.condition}').join('|')}:'
        '${crew.map((c) => '${c.id}:${c.task}:${c.target}').join('|')}';
    if (signature == _signature) {
      for (final member in crew) {
        actors[member.id]?.member = member;
      }
      return;
    }
    final previous = size;
    size = nextSize;
    _facilities = facilities;
    _signature = signature;
    _geometrySignature = geometrySignature;
    if (geometryChanged) {
      _ground = SettlementLayout.ground(size);
      _hulls = [
        for (final facility in facilities)
          SettlementLayout.hull(facility, size).inflate(CrewMotion.radius),
      ];
      _cells = {
        for (double y = CrewMotion.grid; y < size.height; y += CrewMotion.grid)
          for (double x = CrewMotion.grid; x < size.width; x += CrewMotion.grid)
            if (walkable(Offset(x, y))) Offset(x, y),
      };
    }
    actors.removeWhere((id, _) => !crew.any((member) => member.id == id));
    for (final member in crew) {
      final actor = actors[member.id];
      final desired = actor == null
          ? _destination(member)
          : previous.isEmpty
          ? actor.position
          : Offset(
              actor.position.dx / previous.width * size.width,
              actor.position.dy / previous.height * size.height,
            );
      if (actor == null) {
        actors[member.id] = MovingCrew(member, _nearest(desired, member.id));
      } else {
        actor.member = member;
        if (geometryChanged) {
          actor.position = _nearest(desired, member.id);
        }
      }
    }
    for (final actor in actors.values) {
      actor.path = [];
      actor.destination = null;
    }
    _planAll();
  }

  bool walkable(Offset p) {
    final r = CrewMotion.radius;
    if (p.dx < r ||
        p.dy < r ||
        p.dx > size.width - r ||
        p.dy > size.height - r) {
      return false;
    }
    if ([
      p,
      p.translate(-r, 0),
      p.translate(r, 0),
      p.translate(0, -r),
      p.translate(0, r),
    ].any((point) => !_ground.contains(point))) {
      return false;
    }
    return !_hulls.any((hull) => hull.contains(p));
  }

  bool _free(Offset p, String id, {bool goals = false}) => !actors.entries.any(
    (e) =>
        e.key != id &&
        ((e.value.position - p).distance < CrewMotion.separation ||
            goals &&
                e.value.destination != null &&
                (e.value.destination! - p).distance < CrewMotion.separation),
  );

  Offset _nearest(Offset p, String id) {
    Offset? best;
    var distance = double.infinity;
    for (final cell in _cells) {
      final d = (cell - p).distanceSquared;
      if (d < distance && _free(cell, id)) {
        best = cell;
        distance = d;
      }
    }
    // An empty geometry cannot accept input; normal maps always have ground.
    return best ?? p;
  }

  /// Four-neighbour BFS with stable tie order; no diagonal corner cutting.
  /// Select the nearest reachable exterior cell rather than a building centre.
  List<Offset> _route(MovingCrew actor, Offset desired) {
    final start = _nearest(actor.position, actor.member.id);
    if (!_cells.contains(start)) {
      return [];
    }
    final queue = Queue<Offset>()..add(start);
    final parent = <Offset, Offset?>{start: null};
    Offset best = start;
    var score = double.infinity;
    while (queue.isNotEmpty) {
      final cell = queue.removeFirst();
      final distance = (cell - desired).distanceSquared;
      if (distance < score && _free(cell, actor.member.id, goals: true)) {
        score = distance;
        best = cell;
      }
      for (final delta in const [
        Offset(0, 1),
        Offset(1, 0),
        Offset(0, -1),
        Offset(-1, 0),
      ]) {
        final next = cell + delta * CrewMotion.grid;
        if (_cells.contains(next) &&
            !parent.containsKey(next) &&
            _free(next, actor.member.id) &&
            segmentWalkable(cell, next)) {
          parent[next] = cell;
          queue.add(next);
        }
      }
    }
    final reversed = <Offset>[];
    Offset? cursor = best;
    while (cursor != null) {
      reversed.add(cursor);
      cursor = parent[cursor];
    }
    final path = reversed.reversed.toList();
    // Include the start so replanning from between grid cells cannot cut a hull.
    return segmentWalkable(actor.position, start) ? path : [];
  }

  bool segmentWalkable(Offset a, Offset b) {
    final steps = math.max(
      1,
      ((b - a).distance / (CrewMotion.radius / 2)).ceil(),
    );
    for (var i = 0; i <= steps; i++) {
      if (!walkable(Offset.lerp(a, b, i / steps)!)) {
        return false;
      }
    }
    return true;
  }

  String destinationId(MapCrew member) => switch (member.task) {
    'clean' => 'solar_array',
    'major_repair' ||
    'repair' ||
    'construction' ||
    'upgrade' => SettlementLayout.painterId(member.target ?? 'maintenance_bay'),
    'research' || 'forecast' => 'research_lab',
    'survey' => 'rover',
    'care' => 'medical_area',
    'rest' => 'habitat',
    'drill' || 'shelter' => 'radiation_shelter',
    'priorities' || 'rally' => 'communications',
    _ => switch (member.role) {
      CrewRole.commander => 'communications',
      CrewRole.engineer => 'maintenance_bay',
      CrewRole.scientist => 'research_lab',
      CrewRole.medic => 'medical_area',
    },
  };

  Offset _destination(MapCrew member) {
    final id = _visits[member.id] ?? destinationId(member);
    // Absent facilities use the existing habitat station, never a fictitious lab.
    final facility =
        _facilities
            .where(
              (f) =>
                  f.id == id && (f.level > 0 || member.task == 'construction'),
            )
            .firstOrNull ??
        _facilities.where((f) => f.id == 'habitat').firstOrNull;
    if (facility == null) {
      return Offset(size.width / 2, size.height * .94);
    }
    final hull = SettlementLayout.hull(facility, size);
    return Offset(hull.center.dx, hull.bottom + CrewMotion.separation);
  }

  void _planAll() {
    for (final actor in actors.values) {
      if (manual && actor.member.id == selected) {
        continue;
      }
      actor.path = _route(actor, _destination(actor.member));
      actor.destination = actor.path.lastOrNull;
    }
  }

  void select(String id) {
    if (!actors.containsKey(id)) {
      return;
    }
    _visits.remove(id);
    selected = id;
    manual = true;
    direction = Offset.zero;
    actors[id]!.path = [];
    actors[id]!.destination = null;
    _planAll();
    feedback.value =
        'Direct control: ${actors[id]!.member.name}. Assignment unchanged.';
    notifyListeners();
  }

  void input(Offset value) {
    if (!actors.containsKey(selected)) {
      return;
    }
    if (!manual && value != Offset.zero) {
      select(selected);
    }
    direction = value.distance > 1 ? value / value.distance : value;
    if (direction != Offset.zero) {
      actors[selected]!.path = [];
    }
  }

  void release() {
    _visits.remove(selected);
    manual = false;
    direction = Offset.zero;
    _planAll();
    feedback.value =
        'Autonomous crew. Walking does not complete assigned work.';
    notifyListeners();
  }

  /// A reversible physical visit, never a simulation assignment or repair.
  bool approach(String facilityId) {
    final actor = actors[selected];
    final site = _facilities.where((f) => f.id == facilityId).firstOrNull;
    if (actor == null ||
        site == null ||
        site.count == 0 &&
            !(actor.member.task == 'construction' &&
                SettlementLayout.painterId(actor.member.target ?? '') ==
                    facilityId)) {
      feedback.value = 'This facility is not installed. Review its existing Build plan first.';
      return false;
    }
    manual = false;
    direction = Offset.zero;
    _visits[selected] = facilityId;
    actor.path = _route(actor, _destination(actor.member));
    actor.destination = actor.path.lastOrNull;
    feedback.value =
        'Approaching ${site.label}. Assignment unchanged; arrival performs no work.';
    notifyListeners();
    return true;
  }

  bool atAssignment(MovingCrew actor) =>
      !actor.walking &&
      actor.destination != null &&
      (actor.position - actor.destination!).distance < 1 &&
      !(manual && actor.member.id == selected) &&
      !_visits.containsKey(actor.member.id);

  /// Accessible one-cell movement; no asynchronous input or simulation step.
  void nudge(Offset delta) {
    if (!actors.containsKey(selected) || delta == Offset.zero) {
      return;
    }
    if (!manual) {
      select(selected);
    }
    final actor = actors[selected]!;
    final next = actor.position + delta / delta.distance * CrewMotion.grid;
    if (segmentWalkable(actor.position, next) && _free(next, selected)) {
      actor.position = next;
      actor.facing = delta / delta.distance;
    }
    direction = Offset.zero;
    actor.path = [];
    actor.walking = false;
    notifyListeners();
  }

  void tick(double seconds) {
    if (size.isEmpty || seconds <= 0) {
      return;
    }
    final dt = seconds.clamp(0, CrewMotion.maxFrameSeconds).toDouble();
    if (!reducedMotion) {
      animationSeconds += dt;
    }
    for (final actor in actors.values) {
      final direct = manual && actor.member.id == selected;
      final vector = direct
          ? direction
          : actor.path.isEmpty
          ? Offset.zero
          : actor.path.first - actor.position;
      actor.walking = false;
      if (vector.distance < .01) {
        if (!direct && actor.path.isNotEmpty) {
          actor.path.removeAt(0);
        }
        continue;
      }
      final unit = vector / vector.distance;
      final distance =
          CrewMotion.speed * dt * (direct ? math.min(1, vector.distance) : 1);
      final next =
          actor.position +
          unit * (direct ? distance : math.min(distance, vector.distance));
      if (segmentWalkable(actor.position, next) &&
          _free(next, actor.member.id)) {
        actor.position = next;
        actor.facing = unit;
        actor.walking = true;
        actor.blockedSeconds = 0;
        if (!direct && (actor.path.first - next).distance < .01) {
          actor.path.removeAt(0);
          if (actor.path.isEmpty) {
            feedback.value =
                '${actor.member.name} reached their station. Assigned work follows its own timer.';
          }
        }
      } else if (!direct) {
        actor.blockedSeconds += dt;
        if (actor.blockedSeconds >= 1) {
          actor.blockedSeconds = 0;
          actor.path = _route(actor, _destination(actor.member));
          actor.destination = actor.path.lastOrNull;
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    feedback.dispose();
    super.dispose();
  }
}
