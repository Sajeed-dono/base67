import 'dart:convert';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const crew = [
  MapCrew(CrewRole.commander, 'Alex'), MapCrew(CrewRole.engineer, 'Sam'),
  MapCrew(CrewRole.scientist, 'Jo'), MapCrew(CrewRole.medic, 'Lee'),
];

CrewMovement scene({List<MarsFacility> facilities = const [], List<MapCrew> members = crew,
    bool reduced = true}) {
  final model = CrewMovement()..configure(const Size(360, 280), facilities, members, reduceMotion: reduced);
  addTearDown(model.dispose);
  return model;
}

void frames(CrewMovement model, int count) {
  for (var i = 0; i < count; i++) { model.tick(1 / 30); }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('directional input moves only the selected astronaut', () {
    final model = scene();
    model.actors['engineer']!.position = const Offset(160, 220);
    model.select('engineer');
    // Pause autonomous paths only to isolate ownership of direct velocity.
    for (final actor in model.actors.values) { actor.path = []; }
    final others = {for (final e in model.actors.entries) if (e.key != 'engineer') e.key: e.value.position};
    final start = model.actors['engineer']!.position;
    model.input(const Offset(0, -1)); frames(model, 15);
    expect(model.actors['engineer']!.position.dy, lessThan(start.dy));
    expect(model.actors['engineer']!.facing, const Offset(0, -1));
    for (final e in others.entries) { expect(model.actors[e.key]!.position, e.value); }
    model.input(Offset.zero);
    final stopped = model.actors['engineer']!.position;
    frames(model, 5); expect(model.actors['engineer']!.position, stopped);
  });

  test('selection and release retain assignments and resume navigation', () {
    const assigned = MapCrew(CrewRole.engineer, 'Sam', task: 'clean', mood: CrewMood.working);
    final model = scene(members: [crew[0], assigned, crew[2], crew[3]],
      facilities: SettlementLayout.facilities({'crew_habitat': 1, 'solar_array': 1}));
    model.select('engineer'); model.input(const Offset(1, 0)); frames(model, 5);
    expect(model.actors['engineer']!.member.task, 'clean');
    model.select('medic');
    expect(model.actors['engineer']!.path, isNotEmpty);
    model.release();
    expect(model.manual, isFalse); expect(model.direction, Offset.zero);
    expect(model.actors['engineer']!.member.task, 'clean');
    expect(model.destinationId(assigned), 'solar_array');
  });

  test('actual mission and real job identities choose existing destinations', () {
    final model = scene();
    const cases = <(String, String?, String)>[
      ('clean', null, 'solar_array'), ('major_repair', 'greenhouse', 'greenhouse'),
      ('construction', 'crew_habitat', 'habitat'), ('upgrade', 'battery_bank', 'battery_bank'),
      ('research', 'Solar Research', 'research_lab'), ('forecast', null, 'research_lab'),
      ('survey', null, 'rover'), ('care', null, 'medical_area'), ('rest', null, 'habitat'),
      ('drill', null, 'radiation_shelter'), ('shelter', null, 'radiation_shelter'),
      ('priorities', null, 'communications'), ('rally', null, 'communications'),
    ];
    for (final row in cases) {
      expect(model.destinationId(MapCrew(CrewRole.engineer, 'Sam', task: row.$1, target: row.$2)), row.$3);
    }
  });

  test('assignment and facility availability changes recalculate destinations', () {
    const resting = MapCrew(CrewRole.scientist, 'Jo', task: 'rest');
    final model = scene(members: [resting], facilities: SettlementLayout.facilities({'crew_habitat': 1}));
    final habitat = model.actors['scientist']!.destination;
    const researching = MapCrew(CrewRole.scientist, 'Jo', task: 'research', target: 'solar_research');
    model.configure(model.size, SettlementLayout.facilities({'crew_habitat': 1}), [researching], reduceMotion: true);
    expect(model.actors['scientist']!.destination, habitat, reason: 'An absent lab uses the existing habitat.');
    model.configure(model.size, SettlementLayout.facilities({'crew_habitat': 1, 'research_lab': 1}), [researching], reduceMotion: true);
    expect(model.actors['scientist']!.destination, isNot(habitat));
    expect(model.walkable(model.actors['scientist']!.destination!), isTrue);
  });

  test('a first construction approaches its unbuilt site; missing research uses a station', () {
    const construction = MapCrew(CrewRole.engineer, 'Sam', task: 'construction', target: 'greenhouse');
    const research = MapCrew(CrewRole.engineer, 'Sam', task: 'research', target: 'greenhouse_research');
    final facilities = SettlementLayout.facilities({'crew_habitat': 1});
    final model = scene(facilities: facilities, members: const [construction]);
    final site = model.actors['engineer']!.destination;
    expect(site, isNotNull); expect(model.walkable(site!), isTrue);
    model.configure(model.size, facilities, const [research], reduceMotion: true);
    expect(model.actors['engineer']!.destination, isNot(site));
  });

  test('equal geometry, assignments and animation inputs give equal movement', () {
    final facilities = SettlementLayout.facilities({'crew_habitat': 1, 'research_lab': 1, 'solar_array': 1});
    final first = scene(facilities: facilities);
    final second = scene(facilities: facilities);
    first.select('engineer'); second.select('engineer');
    first.input(const Offset(0, -1)); second.input(const Offset(0, -1));
    frames(first, 20); frames(second, 20);
    first.release(); second.release(); frames(first, 180); frames(second, 180);
    for (final id in first.actors.keys) {
      expect(first.actors[id]!.position, second.actors[id]!.position);
      expect(first.actors[id]!.path, second.actors[id]!.path);
    }
  });

  test('direct and autonomous paths cannot cross hulls, sky or map boundaries', () {
    const solar = MarsFacility('solar_array', 'Solar', Offset(.5, .7), level: 1);
    final model = scene(facilities: const [solar], members: const [MapCrew(CrewRole.engineer, 'Sam', task: 'clean')]);
    model.select('engineer');
    final actor = model.actors['engineer']!;
    actor.position = const Offset(112, 196);
    expect(model.walkable(actor.position), isTrue);
    model.input(const Offset(1, 0));
    for (var i = 0; i < 120; i++) {
      final before = actor.position; model.tick(1 / 30);
      expect(model.segmentWalkable(before, actor.position), isTrue);
      expect(SettlementLayout.hull(solar, model.size).inflate(CrewMotion.radius).contains(actor.position), isFalse);
    }
    expect(actor.position.dx, lessThan(180));
    for (final direction in const [Offset(-1, 0), Offset(0, -1), Offset(1, 0), Offset(0, 1)]) {
      model.input(direction); frames(model, 300);
      expect(model.walkable(actor.position), isTrue);
    }
    model.release();
    for (var i = 0; i < 200; i++) {
      final before = actor.position; model.tick(1 / 30);
      expect(model.segmentWalkable(before, actor.position), isTrue);
    }
  });

  test('four autonomous astronauts keep distinct collision-safe positions', () {
    final model = scene(facilities: SettlementLayout.facilities({'crew_habitat': 1}));
    for (var frame = 0; frame < 350; frame++) {
      model.tick(1 / 30);
      final actors = model.actors.values.toList();
      for (var i = 0; i < actors.length; i++) {
        expect(model.walkable(actors[i].position), isTrue);
        for (var j = i + 1; j < actors.length; j++) {
          expect((actors[i].position - actors[j].position).distance,
            greaterThanOrEqualTo(CrewMotion.separation - .001));
        }
      }
    }
  });

  test('reduced motion removes decorative time while retaining functional movement', () {
    final model = scene(members: const [MapCrew(CrewRole.commander, 'Alex')]);
    model.select('commander');
    model.actors['commander']!.position = const Offset(180, 220);
    final start = model.actors['commander']!.position;
    model.input(const Offset(0, -1)); frames(model, 12);
    expect(model.actors['commander']!.position, isNot(start));
    expect(model.animationSeconds, 0);
    model.input(Offset.zero);
    expect(model.needsFrames, isFalse);
  });

  test('resize reuses session positions and keeps crew on reachable ground', () {
    final model = scene(facilities: SettlementLayout.facilities({'crew_habitat': 1}));
    model.select('engineer');
    model.configure(const Size(720, 280), SettlementLayout.facilities({'crew_habitat': 1}), crew, reduceMotion: true);
    expect(model.selected, 'engineer'); expect(model.manual, isTrue);
    final positions = model.actors.values.map((a) => a.position).toSet();
    expect(positions.length, 4);
    for (final point in positions) { expect(model.walkable(point), isTrue); }
  });

  test('walking cannot mutate resources, timers, task reservations or mission completion', () {
    // Detached projection fixture, not a persistence/codec validity test.
    final save = CampaignSave(version: 3,
      crewAppearance: const {'Engineer': {'suit': 4, 'visor': 2, 'face': 1}},
      progressionJson: jsonEncode({
        'resources': {'oxygen_kg': 13, 'water_kg': 17}, 'packedStock': {'spare_part': 1},
        'externalCrewAssignments': {'Engineer': 'mission:clean'},
        'externalFacilityReservations': ['solar_array'], 'completedLevels': [],
        'jobs': {'r': {'status': 'active', 'crewId': 'Scientist',
          'recipe': {'kind': 'research', 'targetId': 'solar_research'},
          'clock': {'remainingMicros': 123456}}},
      }), missionJson: jsonEncode({'phase': 'play', 'environment': {'hours': 9},
        'settlement': {'tasks': {'Engineer': {'kind': 'clean', 'remaining': 1}},
          'crew': {'Engineer': {'health': 72, 'morale': 81, 'fatigue': 16}}}}));
    final before = jsonEncode(save.toJson());
    final members = MapCrew.fromSave(save);
    expect(members[1].task, 'clean'); expect(members[1].suit, 4);
    expect(members[2].task, 'research');
    final model = scene(members: members, facilities: SettlementLayout.facilities({'crew_habitat': 1, 'solar_array': 1, 'research_lab': 1}));
    model.select('engineer'); model.input(const Offset(1, 0)); frames(model, 30);
    model.release(); frames(model, 350);
    final engineer = model.actors['engineer']!;
    expect(engineer.path, isEmpty);
    expect(engineer.destination, isNotNull);
    expect((engineer.position - engineer.destination!).distance, lessThan(.01),
      reason: 'Actually reaching the station must not complete or charge the task.');
    model.nudge(const Offset(0, -1));
    expect(jsonEncode(save.toJson()), before);
    expect(model.actors['engineer']!.member.task, 'clean');
    expect(MapCrew.fromSave(save)[2].task, 'research');
  });
}
