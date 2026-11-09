import 'dart:math' as math;

import 'player_inputs.dart';
import 'power_model.dart';
import 'sim_config.dart';
import 'sim_state.dart';

abstract final class ResourceModel {
  static double consumptionPerHour(
    SimConfig config,
    String resource,
    int crew,
  ) {
    final key = switch (resource) {
      'oxygen_kg' => 'oxygen_per_person_hour',
      'water_kg' => 'water_per_person_hour',
      'food_kg' => 'food_per_person_hour',
      _ => null,
    };
    return key == null ? 0 : math.max(0, crew) * config.number(key);
  }

  static double capacity(SimConfig config, SimState state, String resource) {
    var result = config.capacities[resource] ?? 0;
    for (final spec in config.facilities.values) {
      final facility = state.facilities[spec.id];
      if (facility == null ||
          facility.status == FacilityStatus.notBuilt ||
          facility.status == FacilityStatus.underConstruction) {
        continue;
      }
      final units = (facility.units - facility.damagedUnits).clamp(
        0,
        facility.units,
      );
      result += (spec.expansion[resource] ?? 0) * units;
    }
    final facilityId = switch (resource) {
      'oxygen_kg' => 'life_support_module',
      'water_kg' => 'ice_miner_water_storage',
      _ => 'food_storage',
    };
    final stat = resource.replaceFirst('_kg', '_capacity');
    return result *
        config.multiplier(
          stat,
          state.researchIds,
          upgraded: upgradedFor(config, state, facilityId, stat),
        );
  }

  static SimState step(
    SimConfig config,
    SimState state,
    PlayerInputs inputs,
    PowerResult power,
    double hours,
    List<SimNotice> notices,
  ) {
    final greenhouse = state.facilities['greenhouse']?.workingUnits ?? 0;
    final miner =
        state.facilities['ice_miner_water_storage']?.workingUnits ?? 0;
    final solHours = config.number('sol_hours');
    final production = {
      'oxygen_kg':
          greenhouse *
          config.number('greenhouse_oxygen_per_sol') /
          solHours *
          (power.fractions['greenhouse_lights'] ?? 0) *
          config.multiplier(
            'oxygen_output',
            state.researchIds,
            upgraded: upgradedFor(config, state, 'greenhouse', 'oxygen_output'),
          ),
      'food_kg':
          greenhouse *
          config.number('greenhouse_food_per_sol') /
          solHours *
          (power.fractions['greenhouse_lights'] ?? 0) *
          config.multiplier(
            'food_output',
            state.researchIds,
            upgraded: upgradedFor(config, state, 'greenhouse', 'food_output'),
          ),
      'water_kg':
          miner *
          (config.miningPerSol[config.sites[state.siteId]!.iceTier] ?? 0) /
          solHours *
          (power.fractions['ice_miner'] ?? 0) *
          config.multiplier(
            'water_output',
            state.researchIds,
            upgraded: upgradedFor(
              config,
              state,
              'ice_miner_water_storage',
              'water_output',
            ),
          ),
    };
    final resources = {...state.resources, 'battery_kwh': power.battery};
    var needsHelp = power.lifeSupportShortage;
    for (final id in config.initial.keys) {
      final cap = finiteNumber(
        capacity(config, state, id),
        0,
        notices,
        '$id capacity',
      );
      final previous = bounded(
        state.resources[id]?.quantity ?? 0,
        0,
        cap,
        notices,
        id,
      );
      final produced = finiteNumber(
        production[id] ?? 0,
        0,
        notices,
        '$id production',
      );
      final consumed = finiteNumber(
        consumptionPerHour(config, id, state.crewCount),
        0,
        notices,
        '$id consumption',
      );
      final requested = finiteNumber(
        previous + (produced - consumed) * hours,
        previous,
        notices,
        '$id balance',
      );
      final quantity = bounded(requested, 0, cap, notices, '$id balance');
      final changes = [
        ...?state.resources[id]?.changes,
        if (previous != state.resources[id]?.quantity)
          ResourceChange(
            'capacity_clamp',
            previous - (state.resources[id]?.quantity ?? 0),
            DataClass.derived,
          ),
        ResourceChange(
          id == 'water_kg' ? 'ice_mining' : 'greenhouse',
          produced * hours,
          DataClass.game,
        ),
        ResourceChange(
          'crew_consumption',
          -consumed * hours,
          DataClass.derived,
        ),
        if (requested != quantity)
          ResourceChange(
            'storage_clamp',
            quantity - requested,
            DataClass.derived,
          ),
      ];
      resources[id] = ResourceState(
        quantity: quantity,
        capacity: cap,
        productionPerHour: produced,
        consumptionPerHour: consumed,
        changes: changes,
      );
      if (quantity == 0 && state.crewCount > 0) {
        needsHelp = true;
        notices.add(SimNotice('resource_shortage', id));
      }
    }
    final heater = power.fractions['heater'] ?? 0;
    final requestedSetPoint = finiteNumber(
      inputs.heaterSetPoint ?? config.number('target_temp'),
      config.number('target_temp'),
      notices,
      'heater_set_point',
    );
    final setPoint = bounded(
      requestedSetPoint,
      config.number('heater_min'),
      config.number('heater_max'),
      notices,
      'heater_set_point',
    );
    final target =
        config.number('outside_temp') +
        (setPoint - config.number('outside_temp')) * heater;
    final temperature = finiteNumber(
      target +
          (state.temperature - target) *
              math.exp(-hours / config.number('cold_hours')),
      target,
      notices,
      'temperature',
    );
    if (state.crewCount > 0 && temperature < config.number('min_safe_temp')) {
      notices.add(const SimNotice('needs_help', 'habitat_temperature'));
      needsHelp = true;
    }
    return state.copyWith(
      resources: resources,
      temperature: temperature,
      paused: needsHelp || state.paused,
    );
  }
}
