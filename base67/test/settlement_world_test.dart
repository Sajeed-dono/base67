import 'dart:convert';

import 'package:base67/app/campaign_save.dart';
import 'package:base67/ui/crew_bean.dart';
import 'package:base67/ui/crew_movement.dart';
import 'package:base67/ui/mars_base_painter.dart';
import 'package:base67/ui/settlement_camera.dart';
import 'package:base67/ui/settlement_snapshot.dart';
import 'package:base67/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'accessible facility framing uses existing camera bounds and transform',
    () {
      for (final width in [360.0, 800.0, 1024.0]) {
        final camera = SettlementCamera()
          ..layout(Size(width, 400), const Offset(450, 500));
        for (final site in SettlementLayout.facilities({'crew_habitat': 1})) {
          final point = Offset(
            site.position.dx * SettlementView.world.width,
            site.position.dy * SettlementView.world.height,
          );
          camera.overview();
          camera.frame(point);
          expect(camera.following, isFalse);
          final screen = camera.worldToScreen(point);
          expect((Offset.zero & camera.viewport).contains(screen), isTrue);
          expect(
            (camera.screenToWorld(screen) - point).distance,
            lessThan(.000001),
          );
        }
      }
    },
  );
  test(
    'camera forward/inverse coordinates agree after pan, zoom and resize',
    () {
      final camera = SettlementCamera()
        ..layout(const Size(360, 400), const Offset(450, 500));
      for (final point in const [
        Offset(200, 350),
        Offset(500, 400),
        Offset(720, 630),
      ]) {
        expect(
          (camera.screenToWorld(camera.worldToScreen(point)) - point).distance,
          lessThan(.000001),
        );
      }
      camera.pan(const Offset(50, -30));
      final anchor = camera.viewport.center(Offset.zero);
      final before = camera.screenToWorld(anchor);
      camera.zoomAt(1.2, anchor);
      expect(
        (camera.screenToWorld(anchor) - before).distance,
        lessThan(.000001),
      );
      camera.layout(const Size(800, 500), const Offset(450, 500));
      const point = Offset(420, 520);
      expect(
        (camera.screenToWorld(camera.worldToScreen(point)) - point).distance,
        lessThan(.000001),
      );
    },
  );

  test('camera boundaries, overview and follow are finite and view-only', () {
    final camera = SettlementCamera()
      ..layout(const Size(360, 400), const Offset(450, 500));
    camera.pan(const Offset(100000, -100000));
    final first = camera.screenToWorld(Offset.zero);
    final last = camera.screenToWorld(const Offset(360, 400));
    expect(first.dx, greaterThanOrEqualTo(0));
    expect(first.dy, greaterThanOrEqualTo(0));
    expect(last.dx, lessThanOrEqualTo(camera.world.width));
    expect(last.dy, lessThanOrEqualTo(camera.world.height));
    camera.overview();
    expect(camera.center, camera.world.center(Offset.zero));
    camera.following = true;
    camera.zoomAt(1.2, camera.viewport.center(Offset.zero));
    final before = camera.center;
    const focus = Offset(550, 500);
    camera.follow(focus, 1 / 30, reducedMotion: false);
    expect(
      (camera.center - focus).distance,
      lessThan((before - focus).distance),
    );
    expect(
      camera.center,
      isNot(focus),
      reason: 'Normal follow eases rather than jumps.',
    );
    camera.follow(focus, 1 / 30, reducedMotion: true);
    expect(camera.center, focus);
  });

  test(
    'viewport and task changes do not rescale or snap stable world positions',
    () {
      final movement = CrewMovement();
      addTearDown(movement.dispose);
      final facilities = SettlementLayout.facilities({
        'crew_habitat': 1,
        'solar_array': 1,
      });
      const engineer = MapCrew(CrewRole.engineer, 'Sam', task: 'clean');
      movement.configure(SettlementView.world, facilities, const [
        engineer,
      ], reduceMotion: true);
      movement.select('engineer');
      movement.actors['engineer']!.position = const Offset(90, 560);
      final original = movement.actors['engineer']!.position;
      final camera = SettlementCamera()..layout(const Size(360, 400), original);
      camera.zoomAt(1.5, const Offset(180, 200));
      camera.pan(const Offset(30, 40));
      camera.layout(const Size(800, 500), original);
      movement.configure(SettlementView.world, facilities, const [
        MapCrew(
          CrewRole.engineer,
          'Sam',
          task: 'major_repair',
          target: 'solar_array',
        ),
      ], reduceMotion: true);
      expect(movement.actors['engineer']!.position, original);
      expect(movement.size, SettlementView.world);
      expect(movement.manual, isTrue);
    },
  );

  test(
    'approach rejects unbuilt facilities and never changes assignment or save',
    () {
      final save = CampaignSave(
        version: 3,
        progressionJson: jsonEncode({
          'facilities': {'crew_habitat': 1, 'solar_array': 2},
          'upgradeTiers': {'solar_array': 1},
          'damagedUnits': {'solar_array': 1},
          'operatingStates': {'solar_array': 'off'},
          'resources': {'materials': 27},
          'externalCrewAssignments': {'Engineer': 'mission:clean'},
          'jobs': {},
          'packedStock': {'solar_panel': 1},
          'completedLevels': [],
        }),
      );
      final before = save.encode();
      final facilities = settlementFacilities(save);
      final solar = facilities.firstWhere((f) => f.id == 'solar_array');
      expect(solar.count, 2);
      expect(solar.damagedUnits, 1);
      expect(solar.condition, 'off');
      expect(solar.level, 2);
      expect(facilities.any((f) => f.id == 'power_control_station'), isTrue);
      expect(
        facilities.firstWhere((f) => f.id == 'research_lab').referenceOnly,
        isTrue,
      );
      final movement = CrewMovement();
      addTearDown(movement.dispose);
      movement.configure(
        SettlementView.world,
        facilities,
        MapCrew.fromSave(save),
        reduceMotion: true,
      );
      movement.select('engineer');
      expect(movement.approach('greenhouse'), isFalse);
      expect(movement.approach('habitat'), isTrue);
      expect(movement.visiting, isTrue);
      expect(movement.manual, isFalse);
      final actor = movement.actors['engineer']!;
      for (var i = 0; i < 450; i++) {
        movement.tick(1 / 30);
        expect(movement.walkable(actor.position), isTrue);
      }
      expect(actor.member.task, 'clean');
      expect(save.encode(), before);
      movement.release();
      expect(movement.visiting, isFalse);
      expect(actor.member.task, 'clean');
      expect(save.encode(), before);
    },
  );

  test(
    'presentation projects real job progress, reserved equipment and success',
    () {
      final save = CampaignSave(
        version: 3,
        progressionJson: jsonEncode({
          'facilities': {'crew_habitat': 1},
          'upgradeTiers': {},
          'operatingStates': {'solar_array': 'underConstruction'},
          'jobs': {
            'build': {
              'status': 'active',
              'crewId': 'Engineer',
              'recipe': {'kind': 'construction', 'targetId': 'solar_array'},
              'clock': {'durationMicros': 100, 'remainingMicros': 25},
              'reservedStock': {'solar_panel': 1},
            },
          },
        }),
        missionJson: jsonEncode({'phase': 'debrief', 'result': 'success'}),
      );
      final before = save.encode();
      final site = settlementFacilities(save)
          .firstWhere((f) => f.id == 'solar_array');
      expect(site.count, 0);
      expect(site.condition, 'underConstruction');
      expect(site.jobProgress, .75);
      final members = MapCrew.fromSave(save);
      expect(members[1].progress, .75);
      expect(members[1].hasReservedEquipment, isTrue);
      expect(members[0].mood, CrewMood.celebrating);
      expect(save.encode(), before);
    },
  );
}
