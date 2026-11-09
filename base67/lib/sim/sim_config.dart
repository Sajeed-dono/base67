import 'dart:math' as math;

import '../data/models/data_class.dart';

export '../data/models/data_class.dart' show DataClass;

/// A value retains provenance when copied into a simulation snapshot.
class SimValue {
  SimValue(
    this.value,
    this.unit,
    this.dataClass, {
    Iterable<String> factIds = const [],
    this.provisional = false,
  }) : factIds = List.unmodifiable(factIds);
  final double value;
  final String unit;
  final DataClass dataClass;
  final List<String> factIds;
  final bool provisional;
}

class SimSite {
  const SimSite(this.id, this.solarFactor, this.iceTier);
  final String id;
  final double solarFactor;
  final String iceTier;
}

class FacilitySpec {
  FacilitySpec(
    this.id, {
    this.equipmentId,
    this.loadId,
    Map<String, double> expansion = const {},
  }) : expansion = Map.unmodifiable(expansion);
  final String id;
  final String? equipmentId;
  final String? loadId;
  final Map<String, double> expansion;
}

class EventSpec {
  EventSpec(
    this.id,
    this.chancePerSol, {
    this.scripted = false,
    Map<String, double> effects = const {},
    Iterable<String> iceTiers = const [],
  }) : effects = Map.unmodifiable(effects),
       iceTiers = Set.unmodifiable(iceTiers);
  final String id;
  final double chancePerSol;
  final bool scripted;
  final Map<String, double> effects;
  final Set<String> iceTiers;
}

/// No asset access: a loader supplies fully resolved, validated data.
class SimConfig {
  SimConfig({
    required Map<String, SimValue> values,
    required Map<String, SimSite> sites,
    required Map<String, FacilitySpec> facilities,
    required Map<String, double> loads,
    required Map<String, double> initial,
    required Map<String, double> capacities,
    required Map<String, double> miningPerSol,
    required Map<String, EventSpec> events,
    required List<(double, double)> stormFrames,
    required Map<String, Map<String, double>> researchBonuses,
    required Map<String, List<String>> upgradeStats,
    required this.defaultSeed,
  }) : values = Map.unmodifiable(values),
       sites = Map.unmodifiable(sites),
       facilities = Map.unmodifiable(facilities),
       loads = Map.unmodifiable(loads),
       initial = Map.unmodifiable(initial),
       capacities = Map.unmodifiable(capacities),
       miningPerSol = Map.unmodifiable(miningPerSol),
       events = Map.unmodifiable(events),
       stormFrames = List.unmodifiable(stormFrames),
       researchBonuses = Map.unmodifiable({
         for (final e in researchBonuses.entries)
           e.key: Map<String, double>.unmodifiable(e.value),
       }),
       upgradeStats = Map.unmodifiable({
         for (final e in upgradeStats.entries)
           e.key: List<String>.unmodifiable(e.value),
       }) {
    for (final key in requiredValues) {
      final value = values[key]?.value;
      if (value == null || !value.isFinite) {
        throw FormatException('Missing or non-finite simulation value: $key');
      }
      if (!['target_temp', 'min_safe_temp', 'outside_temp'].contains(key) &&
          value < 0) {
        throw FormatException('$key must not be negative');
      }
    }
    for (final key in [
      'sol_hours',
      'tick_hours',
      'daylight_hours',
      'cold_hours',
      'cleaning_hours',
      'water_kg_per_litre',
    ]) {
      if (number(key) <= 0) throw FormatException('$key must be positive');
    }
    if (number('tick_hours') > number('sol_hours')) {
      throw const FormatException('A tick must not exceed a sol');
    }
    if (number('heater_min') > number('heater_max')) {
      throw const FormatException('Invalid heater range');
    }
    if (facilities.values.any(
      (f) => f.expansion.values.any((v) => !v.isFinite || v < 0),
    )) {
      throw const FormatException('Invalid storage expansion');
    }
    for (final collection in [loads, initial, capacities, miningPerSol]) {
      if (collection.values.any((v) => !v.isFinite || v < 0)) {
        throw const FormatException('Invalid non-negative simulation table');
      }
    }
    for (final id in ['oxygen_kg', 'water_kg', 'food_kg']) {
      if (!initial.containsKey(id) ||
          !capacities.containsKey(id) ||
          initial[id]! > capacities[id]!) {
        throw FormatException('Invalid reserve: $id');
      }
    }
    if (sites.isEmpty ||
        sites.values.any((s) => !s.solarFactor.isFinite || s.solarFactor < 0)) {
      throw const FormatException('Invalid sites');
    }
    if (events.values.any(
      (e) =>
          !e.chancePerSol.isFinite ||
          e.chancePerSol < 0 ||
          e.chancePerSol > 1 ||
          e.effects.values.any((v) => !v.isFinite),
    )) {
      throw const FormatException('Invalid event configuration');
    }
    for (var i = 0; i < stormFrames.length; i++) {
      final (hour, tau) = stormFrames[i];
      if (!hour.isFinite ||
          !tau.isFinite ||
          hour < 0 ||
          tau < 0 ||
          (i > 0 && hour <= stormFrames[i - 1].$1)) {
        throw const FormatException('Invalid storm keyframes');
      }
    }
    if (researchBonuses.values.any((m) => m.values.any((v) => !v.isFinite))) {
      throw const FormatException('Invalid research modifier');
    }
  }

  static const requiredValues = [
    'sol_hours',
    'tick_hours',
    'daylight_hours',
    'crew_size',
    'oxygen_per_person_hour',
    'water_per_person_hour',
    'food_per_person_hour',
    'irradiance',
    'panel_area',
    'panel_efficiency',
    'battery_unit_kwh',
    'battery_start_fraction',
    'battery_safe_fraction',
    'clear_tau',
    'dust_gain_per_hour',
    'cleaning_restores',
    'cleaning_hours',
    'cleaning_kw',
    'repair_kw',
    'target_temp',
    'heater_min',
    'heater_max',
    'min_safe_temp',
    'outside_temp',
    'cold_hours',
    'radiation_per_hour',
    'radiation_limit',
    'shielding_reduction',
    'shelter_reduction',
    'greenhouse_food_per_sol',
    'greenhouse_oxygen_per_sol',
    'water_kg_per_litre',
    'upgrade_bonus',
  ];
  final Map<String, SimValue> values;
  final Map<String, SimSite> sites;
  final Map<String, FacilitySpec> facilities;
  final Map<String, double> loads, initial, capacities, miningPerSol;
  final Map<String, EventSpec> events;
  final List<(double, double)> stormFrames;
  final Map<String, Map<String, double>> researchBonuses;
  final Map<String, List<String>> upgradeStats;
  final int defaultSeed;
  double number(String key) => values[key]!.value;

  double multiplier(
    String stat,
    Iterable<String> researchIds, {
    bool upgraded = false,
  }) {
    final ids = researchIds.toSet().toList()..sort();
    final research = ids.fold<double>(
      0,
      (sum, id) => sum + (researchBonuses[id]?[stat] ?? 0),
    );
    return math.max(0, 1 + (upgraded ? number('upgrade_bonus') : 0) + research);
  }

  SimConfig withValues(Map<String, double> replacements) => SimConfig(
    values: {
      ...values,
      for (final e in replacements.entries)
        e.key: SimValue(
          e.value,
          values[e.key]?.unit ?? '',
          values[e.key]?.dataClass ?? DataClass.game,
          factIds: values[e.key]?.factIds ?? const [],
          provisional: true,
        ),
    },
    sites: sites,
    facilities: facilities,
    loads: loads,
    initial: initial,
    capacities: capacities,
    miningPerSol: miningPerSol,
    events: events,
    stormFrames: stormFrames,
    researchBonuses: researchBonuses,
    upgradeStats: upgradeStats,
    defaultSeed: defaultSeed,
  );
}
