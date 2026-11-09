import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/data/sim_config_loader.dart';
import 'package:base67/sim/engine.dart';
import 'package:base67/sim/player_inputs.dart';
import 'package:base67/sim/seeded_rng.dart';
import 'package:base67/sim/sim_config.dart';
import 'package:base67/sim/sim_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SimConfig config;
  setUpAll(
    () async => config = SimConfigLoader.load(await GameDataRepository.load()),
  );
  SimState initial(int seed) => SimState.initial(
    config,
    siteId: 'gale',
    seed: seed,
    equipment: {'solar_panel': 4, 'battery': 3, 'spare_part': 2},
  );
  final controls = PlayerInputs(
    enabledRandomEvents: ['meteor_shower', 'clear_day', 'sep_event'],
    scriptedEvents: [const ScheduledEvent('script-storm', 'dust_storm', 1.5)],
  );

  test(
    'same seed, configuration and inputs give exactly the same complete trace',
    () {
      List<Object> play() {
        var state = initial(41);
        return List.generate(80, (_) {
          final result = Engine(config).step(state, controls);
          state = result.state;
          return result.toJson();
        });
      }

      expect(jsonEncode(play()), jsonEncode(play()));
    },
  );

  test('RNG state restores exactly after a split sequence', () {
    final first = SeededRng(41);
    for (var i = 0; i < 7; i++) {
      first.nextDouble();
    }
    final restored = SeededRng(first.state);
    expect(
      List.generate(100, (_) => first.nextDouble()),
      List.generate(100, (_) => restored.nextDouble()),
    );
    final different = SeededRng(42);
    expect(first.nextDouble(), isNot(different.nextDouble()));
  });

  test('sol boundaries advance without drift and random checks consume a stable sequence', () {
    final engine = Engine(config);
    var state = initial(41).copyWith(crewCount: 0);
    final inputs = PlayerInputs(
      enabledRandomEvents: ['meteor_shower', 'clear_day'],
    );
    var other = state;
    final reverse = PlayerInputs(
      enabledRandomEvents: ['clear_day', 'meteor_shower'],
    );
    for (var i = 0; i < 200; i++) {
      state = engine.step(state, inputs).state;
      other = engine.step(other, reverse).state;
    }
    expect(state.elapsedHours, closeTo(200, 1e-9));
    expect(state.lastRandomSol, (200 / config.number('sol_hours')).floor());
    expect(jsonEncode(state.toJson()), jsonEncode(other.toJson()));
  });

  test('immutable snapshot continuation matches uninterrupted stepping', () {
    final engine = Engine(config);
    var uninterrupted = initial(41);
    var resumed = initial(41);
    final whole = <Object>[], split = <Object>[];
    for (var i = 0; i < 20; i++) {
      final result = engine.step(uninterrupted, controls);
      uninterrupted = result.state;
      whole.add(result.toJson());
    }
    for (var i = 0; i < 20; i++) {
      if (i == 8) {
        resumed = SimState.fromJson(
          jsonDecode(jsonEncode(resumed.toJson())) as Map<String, dynamic>,
        );
      }
      final result = Engine(config).step(resumed, controls);
      resumed = result.state;
      split.add(result.toJson());
    }
    expect(jsonEncode(split), jsonEncode(whole));
  });

  test('scripted event fires at its sub-tick boundary only once', () {
    final engine = Engine(config);
    final inputs = PlayerInputs(
      scriptedEvents: [const ScheduledEvent('one', 'sep_event', 0.5)],
    );
    final first = engine.step(initial(42), inputs);
    expect(first.entries.length, 2);
    expect(first.entries.first.state.elapsedHours, 0.5);
    expect(
      first.entries.last.notices.where((n) => n.code == 'event').length,
      1,
    );
    final next = engine.step(first.state, inputs);
    expect(
      next.entries.expand((e) => e.notices).where((n) => n.code == 'event'),
      isEmpty,
    );
  });

  test('run uses the baseline policy and stops safely instead of simulating absence', () {
    final trace = Engine(config).run(initial(41), steps: 1000);
    expect(trace.state.paused, isTrue);
    expect(trace.state.crewCount, config.number('crew_size'));
    final snapshot = jsonEncode(trace.state.toJson());
    Engine(config).step(trace.state, PlayerInputs());
    expect(jsonEncode(trace.state.toJson()), snapshot);
  });
}
