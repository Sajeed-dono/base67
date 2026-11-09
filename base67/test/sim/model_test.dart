import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/data/sim_config_loader.dart';
import 'package:base67/sim/engine.dart';
import 'package:base67/sim/event_model.dart';
import 'package:base67/sim/player_inputs.dart';
import 'package:base67/sim/power_model.dart';
import 'package:base67/sim/radiation_model.dart';
import 'package:base67/sim/resource_model.dart';
import 'package:base67/sim/sim_config.dart';
import 'package:base67/sim/sim_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SimConfig config;
  setUpAll(
    () async => config = SimConfigLoader.load(await GameDataRepository.load()),
  );
  SimState base({String site = 'gale'}) => SimState.initial(
    config,
    siteId: site,
    equipment: {'solar_panel': 4, 'battery': 3, 'spare_part': 2},
  );

  test('four crew reserves last about 8.20, 9.73 and 10.18 sols without production', () {
    for (final entry in {
      'oxygen_kg': 8.20,
      'water_kg': 9.73,
      'food_kg': 10.18,
    }.entries) {
      final rate = ResourceModel.consumptionPerHour(config, entry.key, 4);
      final sols =
          config.initial[entry.key]! / rate / config.number('sol_hours');
      expect(sols, closeTo(entry.value, 0.01), reason: entry.key);
      expect(sols, greaterThan(5));
    }
  });

  test('consumption is crew-scaled and uses source Earth-day hours', () {
    for (final id in config.initial.keys) {
      final hourly = ResourceModel.consumptionPerHour(config, id, 4);
      expect(ResourceModel.consumptionPerHour(config, id, 2), hourly / 2);
      expect(ResourceModel.consumptionPerHour(config, id, 0), 0);
    }
  });

  test(
    'one engine tick deducts source-backed crew needs without production',
    () {
      final before = base();
      final after = Engine(config).step(before, PlayerInputs()).state;
      for (final id in config.initial.keys) {
        expect(
          after.resources[id]!.quantity,
          closeTo(
            before.resources[id]!.quantity -
                ResourceModel.consumptionPerHour(config, id, before.crewCount),
            1e-10,
          ),
        );
        expect(
          after.resources[id]!.changes.map((c) => c.source),
          contains('crew_consumption'),
        );
      }
    },
  );

  test(
    'partial power serves essential loads first and safely reports the deficit',
    () {
      final state = base().copyWith(
        elapsedHours: config.number('daylight_hours') + 1,
        resources: {
          ...base().resources,
          'battery_kwh': ResourceState(quantity: 0.5, capacity: 60),
        },
      );
      final notices = <SimNotice>[];
      final result = PowerModel.step(
        config,
        state,
        PlayerInputs(),
        1,
        0.5,
        notices,
      );
      expect(result.battery.quantity, 0);
      expect(
        result.fractions['habitat_base'],
        0.5 / config.loads['habitat_base']!,
      );
      expect(result.fractions['heater'], 0);
      expect(result.lifeSupportShortage, isTrue);
      expect(notices.map((n) => n.code), contains('power_shortage'));
    },
  );

  test('heater uses source control range and cooling traces a safe pause', () {
    final warm = Engine(config)
        .step(base(), PlayerInputs(heaterSetPoint: config.number('heater_max')))
        .state;
    expect(warm.temperature, greaterThan(base().temperature));
    final cold = Engine(config).step(
      base().copyWith(temperature: config.number('min_safe_temp')),
      PlayerInputs(disabledLoads: ['heater']),
    );
    expect(cold.state.paused, isTrue);
    expect(cold.state.crewCount, 4);
    expect(
      cold.entries
          .expand((e) => e.notices)
          .any((n) => n.detail == 'habitat_temperature'),
      isTrue,
    );
  });

  test('radiation threshold pauses without removing crew', () {
    final trace = Engine(config).step(
      base().copyWith(radiation: config.number('radiation_limit')),
      PlayerInputs(),
    );
    expect(trace.state.paused, isTrue);
    expect(trace.state.crewCount, 4);
    expectFinite(trace.state);
  });

  test(
    'resource trace accounts for event water and bounded storage overflow',
    () {
      final state = base(site: 'arcadia').copyWith(
        resources: {
          ...base(site: 'arcadia').resources,
          'water_kg': ResourceState(quantity: 199, capacity: 200),
        },
      );
      final trace = Engine(config).step(
        state,
        PlayerInputs(
          scriptedEvents: [const ScheduledEvent('ice', 'ice_found', 0)],
        ),
      );
      final water = trace.state.resources['water_kg']!;
      expect(water.quantity, lessThanOrEqualTo(water.capacity));
      expect(water.changes.map((c) => c.source), contains('ice_found'));
      expect(
        water.changes.fold<double>(0, (sum, c) => sum + c.amount),
        closeTo(water.quantity - 199, 1e-10),
      );
    },
  );

  test('invalid tick durations return a finite unchanged-time trace', () {
    for (final duration in [0.0, -1.0, double.nan, double.infinity]) {
      final trace = Engine(config)
          .step(base(), PlayerInputs(), hours: duration);
      expectFinite(trace.state);
      expect(trace.state.elapsedHours, 0);
      expect(
        trace.entries.single.notices.map((n) => n.code),
        contains('invalid_duration'),
      );
    }
  });

  test(
    'disabled batteries retain charge but cannot discharge into a shortage',
    () {
      final initial = base();
      final state = initial.copyWith(
        elapsedHours: config.number('daylight_hours') + 1,
        facilities: {
          ...initial.facilities,
          'battery_bank': initial.facilities['battery_bank']!.copyWith(
            enabled: false,
          ),
        },
      );
      final trace = Engine(config).step(state, PlayerInputs());
      expect(
        trace.state.resources['battery_kwh']!.quantity,
        initial.resources['battery_kwh']!.quantity,
      );
      expect(trace.state.paused, isTrue);
      expect(
        trace.entries.expand((e) => e.notices).map((n) => n.code),
        contains('battery_disconnected'),
      );
      expectFinite(trace.state);
    },
  );

  test('an unbuilt upgraded storage facility grants no capacity bonus', () {
    final state = base().copyWith(
      facilities: {
        ...base().facilities,
        'food_storage': const FacilityState(units: 0, tier: 2),
      },
    );
    expect(
      ResourceModel.capacity(config, state, 'food_kg'),
      config.capacities['food_kg'],
    );
  });

  test(
    'solar equation uses irradiance, area, efficiency, site, tau and dust',
    () {
      final state = base().copyWith(
        elapsedHours: config.number('daylight_hours') / 2 - 0.5,
        dust: 0.2,
      );
      final result = PowerModel.step(config, state, PlayerInputs(), 1, 0.5, []);
      final expected =
          config.number('irradiance') /
          1000 *
          config.number('panel_area') *
          config.number('panel_efficiency') *
          4 *
          config.sites['gale']!.solarFactor *
          math.exp(-0.5) *
          0.8;
      expect(result.generationKw, closeTo(expected, 1e-10));
      expect(
        PowerModel.daylight(config, config.number('daylight_hours') + 1),
        0,
      );
      final northern = PowerModel.step(
        config,
        state.copyWith(siteId: 'arcadia'),
        PlayerInputs(),
        1,
        0.5,
        [],
      );
      expect(northern.generationKw, lessThan(result.generationKw));
    },
  );

  test('battery drains at night and never overcharges at noon', () {
    final night = base().copyWith(
      elapsedHours: config.number('daylight_hours') + 1,
    );
    final drained = PowerModel.step(config, night, PlayerInputs(), 1, 0.5, []);
    expect(
      drained.battery.quantity,
      closeTo(
        night.resources['battery_kwh']!.quantity -
            config.loads['habitat_base']! -
            config.loads['heater']!,
        1e-10,
      ),
    );
    final noon = base().copyWith(
      elapsedHours: config.number('daylight_hours') / 2,
    );
    final charged = PowerModel.step(config, noon, PlayerInputs(), 1, 0, []);
    expect(charged.battery.quantity, charged.battery.capacity);
    expect(
      charged.battery.changes.any((c) => c.source == 'storage_overflow'),
      isTrue,
    );
  });

  test('upgrade and research bonuses add and their order does not matter', () {
    final battery = base().facilities['battery_bank']!;
    final state = base().copyWith(
      facilities: {
        ...base().facilities,
        'battery_bank': battery.copyWith(tier: 2),
      },
      researchIds: ['advanced_battery_systems', 'solar_energy_fundamentals'],
    );
    final reversed = state.copyWith(
      researchIds: state.researchIds.toList().reversed,
    );
    final one = PowerModel.step(config, state, PlayerInputs(), 1, 0, []);
    final two = PowerModel.step(config, reversed, PlayerInputs(), 1, 0, []);
    expect(one.battery.capacity, closeTo(60 * (1 + 0.25 + 0.25), 1e-10));
    expect(one.battery.capacity, two.battery.capacity);
    expect(one.generationKw, two.generationKw);
    expect(
      config.multiplier('dust_gain', ['dust_protection_technology']),
      0.75,
    );
  });

  test(
    'existing storage facilities expand capacity without granting resources',
    () {
      final state = base().copyWith(
        facilities: {
          ...base().facilities,
          for (final id in [
            'food_storage',
            'life_support_module',
            'ice_miner_water_storage',
          ])
            id: const FacilityState(units: 1, status: FacilityStatus.operating),
        },
      );
      expect(ResourceModel.capacity(config, state, 'food_kg'), 300);
      expect(ResourceModel.capacity(config, state, 'water_kg'), 300);
      expect(ResourceModel.capacity(config, state, 'oxygen_kg'), 90);
      expect(state.resources['food_kg']!.quantity, 100);
    },
  );

  test('powered greenhouse and miner produce at repository rates', () {
    final state = base(site: 'arcadia').copyWith(
      crewCount: 0,
      facilities: {
        ...base(site: 'arcadia').facilities,
        'greenhouse': const FacilityState(
          units: 1,
          status: FacilityStatus.operating,
        ),
        'ice_miner_water_storage': const FacilityState(
          units: 1,
          status: FacilityStatus.operating,
        ),
      },
    );
    final result = Engine(config).step(state, PlayerInputs()).state;
    expect(
      result.resources['food_kg']!.quantity,
      closeTo(
        100 +
            config.number('greenhouse_food_per_sol') /
                config.number('sol_hours'),
        1e-10,
      ),
    );
    expect(
      result.resources['water_kg']!.quantity,
      closeTo(
        100 + config.miningPerSol['high']! / config.number('sol_hours'),
        1e-10,
      ),
    );
  });

  for (final status in FacilityStatus.values) {
    test(
      'facility state ${status.name} remains finite and respects availability',
      () {
        final initial = base();
        final state = initial.copyWith(
          facilities: {
            for (final e in initial.facilities.entries)
              e.key: e.value.copyWith(
                status: status,
                damagedUnits: status == FacilityStatus.damaged
                    ? e.value.units
                    : 0,
              ),
          },
        );
        final trace = Engine(config).step(
          state,
          PlayerInputs(cleanPanels: true, repairFacilityId: 'solar_array'),
        );
        expect(() => jsonEncode(trace.toJson()), returnsNormally);
        expectFinite(trace.state);
        if (status != FacilityStatus.operating) {
          expect(
            trace.entries
                .expand((e) => e.notices)
                .any(
                  (n) =>
                      n.code == 'facility_inactive' ||
                      n.code == 'power_shortage',
                ),
            isTrue,
          );
        }
      },
    );
  }

  test('empty storage and shortages clamp, trace, pause and retain every crew member', () {
    final empty = base().copyWith(
      resources: {
        for (final id in [...config.initial.keys, 'battery_kwh'])
          id: ResourceState(quantity: 0, capacity: 0),
      },
      facilities: {},
    );
    final result = Engine(config).step(empty, PlayerInputs());
    expectFinite(result.state);
    expect(result.state.paused, isTrue);
    expect(result.state.crewCount, 4);
    expect(
      result.entries.expand((e) => e.notices).map((n) => n.code),
      containsAll(['empty_storage', 'resource_shortage', 'needs_help']),
    );
    final stopped = Engine(config).step(result.state, PlayerInputs());
    expect(stopped.state.elapsedHours, result.state.elapsedHours);
  });

  test(
    'corrupt numeric state is clamped and never escapes as NaN or infinity',
    () {
      final corrupt = base().copyWith(
        dust: double.nan,
        temperature: double.infinity,
        radiation: double.nan,
        elapsedHours: double.negativeInfinity,
        resources: {
          for (final id in [...config.initial.keys, 'battery_kwh'])
            id: ResourceState(quantity: double.nan, capacity: double.infinity),
        },
      );
      final result = Engine(config)
          .step(corrupt, PlayerInputs(heaterSetPoint: double.nan));
      expectFinite(result.state);
      expect(() => jsonEncode(result.toJson()), returnsNormally);
      expect(
        result.entries
            .expand((e) => e.notices)
            .any((n) => n.code == 'non_finite_clamped'),
        isTrue,
      );
    },
  );

  test('load shedding disables optional production and spares essential life support', () {
    final state = base().copyWith(
      facilities: {
        ...base().facilities,
        'greenhouse': const FacilityState(
          units: 1,
          status: FacilityStatus.operating,
        ),
      },
    );
    final power = PowerModel.step(
      config,
      state,
      PlayerInputs(disabledLoads: ['greenhouse_lights', 'habitat_base']),
      1,
      0.5,
      [],
    );
    expect(power.fractions['greenhouse_lights'], 0);
    expect(power.fractions['habitat_base'], 1);
  });

  test('storm interpolation, dust buildup and completed cleaning use configured values', () {
    final a = config.stormFrames[0], b = config.stormFrames[1];
    expect(
      EventModel.stormTau(config, (a.$1 + b.$1) / 2),
      closeTo((a.$2 + b.$2) / 2, 1e-10),
    );
    final dirty = base().copyWith(dust: 0.5);
    final clean = Engine(config).step(dirty, PlayerInputs(cleanPanels: true));
    expect(
      clean.state.dust,
      closeTo(0.5 * (1 - config.number('cleaning_restores')), 1e-10),
    );
    expect(
      clean.entries.expand((e) => e.notices).map((n) => n.code),
      contains('panels_cleaned'),
    );
    final storm = Engine(config).step(
      base(),
      PlayerInputs(
        scriptedEvents: [const ScheduledEvent('storm', 'dust_storm', 0)],
      ),
    );
    expect(
      storm.state.dust,
      closeTo(config.number('dust_gain_per_hour'), 1e-10),
    );
  });

  test('shelter reduces SEP dose, shielding reduces exposure and disabled shielding does not', () {
    final unprotected = RadiationModel.dose(
      config,
      base(),
      1,
      4,
      sheltered: false,
    );
    final shelter = RadiationModel.dose(config, base(), 1, 4, sheltered: true);
    final shielded = base().copyWith(
      facilities: {
        ...base().facilities,
        'radiation_shelter': const FacilityState(
          units: 1,
          status: FacilityStatus.operating,
        ),
      },
    );
    expect(shelter, lessThan(unprotected));
    expect(
      RadiationModel.dose(config, shielded, 1, 4, sheltered: true),
      lessThan(shelter),
    );
    final off = shielded.copyWith(
      facilities: {
        ...shielded.facilities,
        'radiation_shelter': const FacilityState(
          units: 1,
          enabled: false,
          status: FacilityStatus.off,
        ),
      },
    );
    expect(RadiationModel.dose(config, off, 1, 4, sheltered: true), shelter);
  });

  test('repair consumes one spare once and sheltered crew cannot repair', () {
    final damaged = base().copyWith(
      facilities: {
        ...base().facilities,
        'solar_array': const FacilityState(
          units: 4,
          damagedUnits: 1,
          status: FacilityStatus.damaged,
        ),
      },
    );
    final result = Engine(config)
        .step(damaged, PlayerInputs(repairFacilityId: 'solar_array'));
    expect(result.state.spareParts, 1);
    expect(result.state.facilities['solar_array']!.damagedUnits, 0);
    final sheltered = Engine(config).step(
      damaged,
      PlayerInputs(shelter: true, repairFacilityId: 'solar_array'),
    );
    expect(sheltered.state.spareParts, 2);
    expect(sheltered.state.facilities['solar_array']!.damagedUnits, 1);
  });
}

void expectFinite(SimState state) {
  for (final n in [
    state.elapsedHours,
    state.dust,
    state.temperature,
    state.radiation,
    state.cleaningHours,
  ]) {
    expect(n.isFinite, isTrue);
  }
  for (final resource in state.resources.values) {
    for (final n in [
      resource.quantity,
      resource.capacity,
      resource.productionPerHour,
      resource.consumptionPerHour,
      ...resource.changes.map((c) => c.amount),
    ]) {
      expect(n.isFinite, isTrue);
    }
    expect(resource.quantity, inInclusiveRange(0, resource.capacity));
  }
}
