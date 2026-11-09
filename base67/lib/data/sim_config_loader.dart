import 'dart:math' as math;

import '../sim/sim_config.dart';
import 'repositories/game_data_repository.dart';

/// Flutter/asset access stops here. The engine receives only pure data.
abstract final class SimConfigLoader {
  static SimConfig load(GameDataRepository repository) {
    Map<String, dynamic> doc(String id) {
      final result = repository.document(id);
      if (result == null) throw FormatException('Missing document: $id');
      return result;
    }

    double numeric(Object? raw, String path) {
      if (raw is! num || !raw.isFinite) {
        throw FormatException('Missing or non-finite number: $path');
      }
      return raw.toDouble();
    }

    final values = <String, SimValue>{};
    double fact(String id, String unit) {
      final value = repository.fact(id);
      final actualUnit = value?.raw['unit'] as String?;
      if (value == null ||
          (actualUnit != unit &&
              !(unit == 'degrees' &&
                  actualUnit?.startsWith('degrees N') == true))) {
        throw FormatException('Missing fact or unexpected unit: $id');
      }
      return numeric(value.value, id);
    }

    void nasa(String key, String id, String unit) {
      values[key] = SimValue(
        fact(id, unit),
        unit,
        DataClass.nasa,
        factIds: [id],
      );
    }

    void game(String key, Object? raw, [String unit = '']) {
      values[key] = SimValue(
        numeric(raw, key),
        unit,
        DataClass.game,
        provisional: true,
      );
    }

    void derived(String key, double value, String unit, List<String> ids) {
      values[key] = SimValue(
        value,
        unit,
        DataClass.derived,
        factIds: ids,
        provisional: true,
      );
    }

    final constants = doc('game_constants.json');
    final time = constants['time'] as Map;
    final solar = constants['solar'] as Map;
    final battery = constants['battery'] as Map;
    final dust = constants['dust'] as Map;
    final habitat = constants['habitat'] as Map;
    final radiation = constants['radiation'] as Map;
    final parameters = doc('sim_params.json');
    final economy = doc('resource_economy.json');
    final equipment = {
      for (final row in (doc('equipment.json')['equipment'] as List))
        (row as Map)['id'] as String: row,
    };
    final actions = {
      for (final row in (doc('loads.json')['actions'] as List))
        (row as Map)['id'] as String: row,
    };
    nasa('sol_hours', 'sol_hours', 'hours');
    nasa('irradiance', 'solar_irradiance', 'W/m2');
    nasa('outside_temp', 'temp_mean', 'C');
    // The source rates are per Earth day, not per Martian sol.
    derived(
      'oxygen_per_person_hour',
      fact('crew_oxygen', 'kg/person/day') / Duration.hoursPerDay,
      'kg/person/hour',
      ['crew_oxygen'],
    );
    final waterAssumption = (economy['assumptions'] as List)
        .cast<Map>()
        .firstWhere((r) => r['id'] == 'water_kg_per_litre');
    game('water_kg_per_litre', waterAssumption['value'], 'kg/L');
    derived(
      'water_per_person_hour',
      fact('crew_water', 'L/person/day') *
          values['water_kg_per_litre']!.value /
          Duration.hoursPerDay,
      'kg/person/hour',
      ['crew_water'],
    );
    derived(
      'food_per_person_hour',
      fact('crew_food_packaged', 'kg/person/day') / Duration.hoursPerDay,
      'kg/person/hour',
      ['crew_food_packaged'],
    );
    derived(
      'radiation_per_hour',
      fact('rad_gale_surface', 'mSv/day') / Duration.hoursPerDay,
      'mSv/hour',
      ['rad_gale_surface'],
    );
    game('tick_hours', time['tick_hours'], 'hours');
    game('daylight_hours', time['daylight_hours'], 'hours');
    game('crew_size', (constants['crew'] as Map)['size'], 'people');
    game('panel_area', equipment['solar_panel']!['area_m2'], 'm2');
    game('panel_efficiency', equipment['solar_panel']!['efficiency']);
    game('battery_unit_kwh', equipment['battery']!['capacity_kwh'], 'kWh');
    game(
      'battery_start_fraction',
      numeric(battery['start_pct'], 'start') / 100,
    );
    game(
      'battery_safe_fraction',
      numeric(battery['safe_min_pct'], 'reserve') / 100,
    );
    game('clear_tau', solar['baseline_clear_tau']);
    game(
      'dust_gain_per_hour',
      numeric(dust['panel_dust_gain_pct_per_storm_hour'], 'dust gain') / 100,
    );
    game(
      'cleaning_restores',
      numeric(dust['panel_cleaning_restores_pct'], 'cleaning') / 100,
    );
    game(
      'cleaning_hours',
      actions['panel_cleaning']!['duration_hours'],
      'hours',
    );
    game('cleaning_kw', actions['panel_cleaning']!['kw'], 'kW');
    game('repair_kw', actions['repair']!['kw'], 'kW');
    game('target_temp', habitat['target_temp_c'], 'C');
    final heater = (doc('loads.json')['loads'] as List).cast<Map>().firstWhere(
      (row) => row['id'] == 'heater',
    );
    final heaterRange = heater['set_point_range_c'] as List;
    game('heater_min', heaterRange.first, 'C');
    game('heater_max', heaterRange.last, 'C');
    game('min_safe_temp', habitat['min_safe_temp_c'], 'C');
    game('cold_hours', habitat['cold_time_constant_hours'], 'hours');
    game('radiation_limit', radiation['game_mission_limit_msv'], 'mSv');
    game(
      'shielding_reduction',
      numeric(equipment['shielding']!['dose_reduction_pct'], 'shielding') / 100,
    );
    game(
      'shelter_reduction',
      numeric(actions['shelter']!['dose_reduction_pct_during_sep'], 'shelter') /
          100,
    );
    game(
      'greenhouse_food_per_sol',
      equipment['greenhouse']!['food_kg_per_sol'],
      'kg/sol',
    );
    game(
      'greenhouse_oxygen_per_sol',
      equipment['greenhouse']!['oxygen_kg_per_sol'],
      'kg/sol',
    );
    game('upgrade_bonus', (parameters['parameters'] as Map)['upgrade_bonus']);
    final sites = <String, SimSite>{};
    for (final raw in doc('sites.json')['sites'] as List) {
      final row = raw as Map;
      final latitudeId = (row['nasa_fact_ids'] as Map)['lat'] as String;
      // Recompute from the source latitude instead of rounded legacy factors.
      final latitude = fact(latitudeId, 'degrees');
      final id = row['id'] as String;
      sites[id] = SimSite(
        id,
        math.cos(latitude * math.pi / 180).abs(),
        row['ice_tier'] as String,
      );
      derived('site_solar_$id', sites[id]!.solarFactor, '', [latitudeId]);
    }
    final expansions = <String, Map<String, double>>{};
    for (final raw in economy['storage_expansions'] as List) {
      final row = raw as Map;
      expansions.putIfAbsent(
        row['facility_id'] as String,
        () => {},
      )[row['resource_id'] as String] = numeric(
        row['capacity'],
        'expansion',
      );
    }
    final facilities = <String, FacilitySpec>{};
    for (final raw in doc('buildings.json')['buildings'] as List) {
      final row = raw as Map;
      final id = row['id'] as String;
      final requiredEquipment =
          (row['required_equipment_ids'] as List).firstOrNull as String?;
      // Spare parts are inventory, not installed maintenance bays.
      final equipmentId = requiredEquipment == 'spare_part'
          ? null
          : requiredEquipment;
      facilities[id] = FacilitySpec(
        id,
        equipmentId: equipmentId,
        loadId: id == 'crew_habitat'
            ? 'habitat_base'
            : equipment[equipmentId]?['load_id'] as String?,
        expansion: expansions[id] ?? {},
      );
    }
    final initial = <String, double>{}, capacities = <String, double>{};
    for (final raw in economy['resources'] as List) {
      final row = raw as Map;
      initial[row['id'] as String] = numeric(row['initial'], 'initial');
      capacities[row['id'] as String] = numeric(row['capacity'], 'capacity');
    }
    final events = <String, EventSpec>{};
    for (final raw in doc('events.json')['events'] as List) {
      final row = raw as Map;
      final effect = row['effect'] as Map? ?? {};
      events[row['id'] as String] = EventSpec(
        row['id'] as String,
        numeric(row['chance_per_sol'], 'chance'),
        scripted: row['scripted'] == true,
        effects: {
          for (final e in effect.entries)
            if (e.value is num) e.key as String: numeric(e.value, 'effect'),
        },
        iceTiers: ((row['requires_ice_tier'] as List?) ?? []).cast<String>(),
      );
    }
    final frames =
        (doc('events.json')['tau_profiles'] as List).cast<Map>().firstWhere(
              (r) => r['id'] == 'storm_2018_stylized',
            )['keyframes']
            as List;
    return SimConfig(
      values: values,
      sites: sites,
      facilities: facilities,
      loads: {
        for (final raw in doc('loads.json')['loads'] as List)
          if ((raw as Map)['concept_only'] != true)
            raw['id'] as String: numeric(raw['kw'], 'load'),
      },
      initial: initial,
      capacities: capacities,
      miningPerSol: {
        for (final e
            in (equipment['ice_miner']!['water_kg_per_sol_by_ice_tier'] as Map)
                .entries)
          e.key as String: numeric(e.value, 'mining'),
      },
      events: events,
      stormFrames: [
        for (final raw in frames)
          (
            numeric((raw as Map)['hour'], 'storm hour'),
            numeric(raw['tau'], 'tau'),
          ),
      ],
      researchBonuses: {
        for (final e in (parameters['research_bonuses'] as Map).entries)
          e.key as String: {
            for (final b in (e.value as Map).entries)
              b.key as String: numeric(b.value, 'bonus'),
          },
      },
      upgradeStats: {
        for (final e in (parameters['upgrade_stats'] as Map).entries)
          e.key as String: (e.value as List).cast<String>(),
      },
      defaultSeed: numeric(
        (constants['rng'] as Map)['default_seed'],
        'seed',
      ).toInt(),
    );
  }
}
