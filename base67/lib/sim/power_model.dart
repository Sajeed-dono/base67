import 'dart:math' as math;

import 'player_inputs.dart';
import 'sim_config.dart';
import 'sim_state.dart';
import 'simulation_clock.dart';

bool upgradedFor(
  SimConfig config,
  SimState state,
  String facility,
  String stat,
) =>
    (state.facilities[facility]?.storageUnits ?? 0) > 0 &&
    (state.facilities[facility]?.tier ?? 1) > 1 &&
    (config.upgradeStats[facility]?.contains(stat) ?? false);

class PowerResult {
  PowerResult(
    this.battery,
    Map<String, double> fractions,
    this.generationKw,
    this.lifeSupportShortage,
  ) : fractions = Map.unmodifiable(fractions);
  final ResourceState battery;
  final Map<String, double> fractions;
  final double generationKw;
  final bool lifeSupportShortage;
}

abstract final class PowerModel {
  static double daylight(SimConfig config, double hours) {
    final hour = SimulationClock.hourOfSol(hours, config.number('sol_hours'));
    return hour >= config.number('daylight_hours')
        ? 0
        : math.max(
            0,
            math.sin(math.pi * hour / config.number('daylight_hours')),
          );
  }

  static PowerResult step(
    SimConfig config,
    SimState state,
    PlayerInputs inputs,
    double hours,
    double tau,
    List<SimNotice> notices,
  ) {
    final panels = state.facilities['solar_array']?.workingUnits ?? 0;
    final bank = state.facilities['battery_bank'];
    final batteries = bank?.storageUnits ?? 0;
    final connected = (bank?.workingUnits ?? 0) > 0;
    final capacity = finiteNumber(
      batteries *
          config.number('battery_unit_kwh') *
          config.multiplier(
            'battery_capacity',
            state.researchIds,
            upgraded: upgradedFor(
              config,
              state,
              'battery_bank',
              'battery_capacity',
            ),
          ),
      0,
      notices,
      'battery_capacity',
    );
    final previous = bounded(
      state.resources['battery_kwh']?.quantity ?? 0,
      0,
      capacity,
      notices,
      'battery_quantity',
    );
    final site = config.sites[state.siteId]!;
    final generation = finiteNumber(
      config.number('irradiance') /
          1000 *
          config.number('panel_area') *
          config.number('panel_efficiency') *
          panels *
          daylight(config, state.elapsedHours + hours / 2) *
          site.solarFactor *
          math.exp(-tau) *
          (1 - state.dust) *
          config.multiplier(
            'solar_output',
            state.researchIds,
            upgraded: upgradedFor(config, state, 'solar_array', 'solar_output'),
          ),
      0,
      notices,
      'generation',
    );
    var available = finiteNumber(
      (connected ? previous : 0) + generation * hours,
      connected ? previous : 0,
      notices,
      'available_energy',
    );
    var used = 0.0;
    final fractions = <String, double>{};
    for (final id in [
      'habitat_base',
      'heater',
      'greenhouse_lights',
      'ice_miner',
      'panel_cleaning',
      'repair',
    ]) {
      final units = switch (id) {
        'greenhouse_lights' =>
          state.facilities['greenhouse']?.workingUnits ?? 0,
        'ice_miner' =>
          state.facilities['ice_miner_water_storage']?.workingUnits ?? 0,
        'habitat_base' ||
        'heater' => state.facilities['crew_habitat']?.workingUnits ?? 0,
        'panel_cleaning' =>
          inputs.cleanPanels &&
                  !inputs.shelter &&
                  inputs.crewAvailableForActions &&
                  panels > 0
              ? 1
              : 0,
        'repair' =>
          inputs.repairFacilityId != null &&
                  !inputs.shelter &&
                  inputs.crewAvailableForActions
              ? 1
              : 0,
        _ => 0,
      };
      final enabled =
          units > 0 &&
          (id == 'habitat_base' || !inputs.disabledLoads.contains(id));
      final kw = switch (id) {
        'panel_cleaning' => config.number('cleaning_kw'),
        'repair' => config.number('repair_kw'),
        _ => config.loads[id] ?? 0,
      };
      final requested = enabled
          ? finiteNumber(kw * units * hours, 0, notices, '$id demand')
          : 0.0;
      final delivered = math.min(available, requested);
      fractions[id] = !enabled
          ? 0
          : requested == 0
          ? 1
          : delivered / requested;
      available -= delivered;
      used += delivered;
      if (delivered < requested) {
        notices.add(SimNotice('power_shortage', id));
      } else if (!enabled &&
          units == 0 &&
          ['greenhouse_lights', 'ice_miner'].contains(id)) {
        notices.add(SimNotice('facility_inactive', id));
      }
    }
    final stored = connected
        ? bounded(available, 0, capacity, notices, 'battery_storage')
        : previous;
    final spill = connected ? math.max(0.0, available - capacity) : available;
    if (batteries > 0 && !connected) {
      notices.add(const SimNotice('battery_disconnected', 'charge_retained'));
    }
    if (spill > 0 && !connected) {
      notices.add(const SimNotice('energy_spilled', 'battery_disconnected'));
    }
    if (capacity == 0) {
      notices.add(const SimNotice('empty_storage', 'battery_kwh'));
    }
    if (capacity > 0 &&
        stored / capacity < config.number('battery_safe_fraction')) {
      notices.add(const SimNotice('reserve_warning', 'battery_kwh'));
    }
    final habitatPresent = (state.facilities['crew_habitat']?.units ?? 0) > 0;
    final lifeShort =
        state.crewCount > 0 &&
        (!habitatPresent || (fractions['habitat_base'] ?? 0) < 1);
    if (lifeShort) {
      notices.add(const SimNotice('needs_help', 'life_support_power'));
    }
    final result = ResourceState(
      quantity: stored,
      capacity: capacity,
      productionPerHour: generation,
      consumptionPerHour: used / hours,
      changes: [
        if (previous != state.resources['battery_kwh']?.quantity)
          ResourceChange(
            'capacity_clamp',
            previous - (state.resources['battery_kwh']?.quantity ?? 0),
            DataClass.derived,
          ),
        ResourceChange(
          'solar_generation',
          generation * hours,
          DataClass.derived,
        ),
        ResourceChange('power_loads', -used, DataClass.game),
        if (spill > 0)
          ResourceChange('storage_overflow', -spill, DataClass.derived),
      ],
    );
    return PowerResult(result, fractions, generation, lifeShort);
  }
}
