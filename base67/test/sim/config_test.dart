import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/data/sim_config_loader.dart';
import 'package:base67/sim/sim_config.dart';
import 'package:base67/sim/sim_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SimConfig config;
  setUpAll(() async {
    config = SimConfigLoader.load(await GameDataRepository.load());
  });

  test(
    'simulation source excludes platform, audio, wall time and unseeded RNG',
    () {
      final forbidden = <String, RegExp>{
        'Flutter': RegExp(r'package:flutter'),
        'filesystem': RegExp(r'dart:io'),
        'UI': RegExp(r'dart:ui'),
        'audio packages': RegExp(
          r'package:[^/]*(?:audio|sound|soloud)[^/]*/',
          caseSensitive: false,
        ),
        'wall clock': RegExp(r'\bDateTime\s*\.\s*now\s*\('),
        'unseeded Random': RegExp(
          r'\bRandom\s*\(\s*\)|\bRandom\s*\.\s*secure\s*\(',
        ),
      };
      final violations = <String>[];
      for (final file in Directory(
        'lib/sim',
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        final source = file.readAsStringSync();
        for (final rule in forbidden.entries) {
          if (rule.value.hasMatch(source)) {
            violations.add('${file.path}: ${rule.key}');
          }
        }
        // Also restrict dependencies to this pure layer and its pure enum.
        for (final match in RegExp("import\\s+'([^']+)'").allMatches(source)) {
          final uri = match[1]!;
          expect(
            uri == 'dart:math' ||
                !uri.contains('/') ||
                uri == '../data/models/data_class.dart',
            isTrue,
            reason: '${file.path}: unexpected dependency $uri',
          );
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
      expect(forbidden['unseeded Random']!.hasMatch('Random()'), isTrue);
      expect(forbidden['unseeded Random']!.hasMatch('Random.secure()'), isTrue);
      expect(forbidden['unseeded Random']!.hasMatch('Random(123)'), isFalse);
    },
  );

  test('loader resolves source facts, units and provisional inputs', () {
    expect(config.values['irradiance']!.factIds, ['solar_irradiance']);
    expect(config.values['irradiance']!.dataClass, DataClass.nasa);
    expect(config.values['water_per_person_hour']!.factIds, ['crew_water']);
    expect(config.values['water_per_person_hour']!.provisional, isTrue);
    expect(config.number('water_kg_per_litre'), 1);
    expect(config.initial, {'oxygen_kg': 30, 'water_kg': 100, 'food_kg': 100});
    expect(config.loads, isNot(contains('earth_communications')));
    expect(config.loads, isNot(contains('rover_charging')));
    expect(config.facilities.keys, isNot(contains('rover')));
  });

  test(
    'invalid config fails at load rather than corrupting a running engine',
    () {
      expect(() => config.withValues({'sol_hours': 0}), throwsFormatException);
      expect(
        () => config.withValues({'tick_hours': double.nan}),
        throwsFormatException,
      );
      expect(() => config.withValues({'crew_size': -1}), throwsFormatException);
      expect(
        () => config.withValues({'battery_unit_kwh': double.infinity}),
        throwsFormatException,
      );
    },
  );

  test(
    'missing facts and incompatible units are rejected by the adapter',
    () async {
      final missing = await GameDataRepository.load(
        bundle: _FactBundle('missing'),
      );
      expect(() => SimConfigLoader.load(missing), throwsFormatException);
      final units = await GameDataRepository.load(bundle: _FactBundle('unit'));
      expect(() => SimConfigLoader.load(units), throwsFormatException);
    },
  );

  test('snapshots, config and modifier collections cannot be mutated', () {
    final state = SimState.initial(config, siteId: 'gale');
    expect(() => config.initial['oxygen_kg'] = 0, throwsUnsupportedError);
    expect(
      () =>
          config.researchBonuses['solar_energy_fundamentals']!['solar_output'] =
              3,
      throwsUnsupportedError,
    );
    expect(() => state.resources.clear(), throwsUnsupportedError);
    expect(() => state.facilities.clear(), throwsUnsupportedError);
    expect(() => state.researchIds.add('anything'), throwsUnsupportedError);
  });

  test('spare inventory does not construct a maintenance facility', () {
    final state = SimState.initial(
      config,
      siteId: 'gale',
      equipment: {'spare_part': 2, 'ice_miner': 1},
    );
    expect(state.spareParts, 2);
    expect(state.facilities['maintenance_bay']!.units, 0);
    expect(state.resources['water_kg']!.capacity, 300);
  });
}

class _FactBundle extends CachingAssetBundle {
  _FactBundle(this.mode);
  final String mode;
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final source = await rootBundle.loadString(key);
    if (!key.endsWith('/nasa_data.json')) return source;
    return mode == 'missing'
        ? source.replaceFirst('"sol_hours":', '"unavailable":')
        : source.replaceFirst('"unit": "W/m2"', '"unit": "unsupported"');
  }
}
