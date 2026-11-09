import 'dart:math' as math;

import 'event_model.dart';
import 'player_inputs.dart';
import 'power_model.dart';
import 'radiation_model.dart';
import 'resource_model.dart';
import 'sim_config.dart';
import 'sim_state.dart';
import 'simulation_clock.dart';

abstract interface class Policy {
  PlayerInputs inputsFor(SimState state);
}

/// Trivial baseline only; campaign-specific strategies belong to later prompts.
class BaselinePolicy implements Policy {
  const BaselinePolicy();
  @override
  PlayerInputs inputsFor(SimState state) => PlayerInputs();
}

class TraceEntry {
  TraceEntry(this.state, Iterable<SimNotice> notices)
    : notices = List.unmodifiable(notices);
  final SimState state;
  final List<SimNotice> notices;
  Map<String, Object> toJson() => {
    'state': state.toJson(),
    'notices': notices.map((n) => n.toJson()).toList(),
  };
}

class Trace {
  Trace(this.state, Iterable<TraceEntry> entries)
    : entries = List.unmodifiable(entries);
  final SimState state;
  final List<TraceEntry> entries;
  List<Map<String, Object>> toJson() => entries.map((e) => e.toJson()).toList();
}

class Engine {
  const Engine(this.config);
  final SimConfig config;

  SimState _safe(SimState state, List<SimNotice> notices) {
    final facilities = <String, FacilityState>{};
    for (final e in state.facilities.entries) {
      final units = math.max(0, e.value.units);
      final damage = e.value.damagedUnits.clamp(0, units);
      final tier = math.max(1, e.value.tier);
      if (units != e.value.units ||
          damage != e.value.damagedUnits ||
          tier != e.value.tier) {
        notices.add(SimNotice('facility_clamped', e.key));
      }
      facilities[e.key] = e.value.copyWith(
        units: units,
        damagedUnits: damage,
        tier: tier,
      );
      if (e.value.workingUnits == 0) {
        notices.add(
          SimNotice('facility_inactive', '${e.key}:${e.value.status.name}'),
        );
      }
    }
    final resources = <String, ResourceState>{};
    for (final id in {
      ...state.resources.keys,
      ...config.initial.keys,
      'battery_kwh',
    }) {
      final r = state.resources[id];
      final cap = math.max(
        0.0,
        finiteNumber(r?.capacity ?? 0, 0, notices, '$id capacity'),
      );
      resources[id] = ResourceState(
        quantity: bounded(r?.quantity ?? 0, 0, cap, notices, '$id quantity'),
        capacity: cap,
      );
    }
    var site = state.siteId;
    if (!config.sites.containsKey(site)) {
      site = (config.sites.keys.toList()..sort()).first;
      notices.add(
        const SimNotice('unknown_site', 'using_first_configured_site'),
      );
    }
    final events = <String, ActiveEvent>{};
    for (final e in state.activeEvents.entries) {
      if (e.value.startHour.isFinite &&
          e.value.endHour.isFinite &&
          e.value.startHour >= 0 &&
          e.value.endHour >= e.value.startHour) {
        events[e.key] = e.value;
      } else {
        notices.add(SimNotice('invalid_active_event', e.key));
      }
    }
    return state.copyWith(
      siteId: site,
      resources: resources,
      facilities: facilities,
      activeEvents: events,
      crewCount: math.max(0, state.crewCount),
      spareParts: math.max(0, state.spareParts),
      elapsedHours: math.max(
        0,
        finiteNumber(state.elapsedHours, 0, notices, 'hours'),
      ),
      dust: bounded(state.dust, 0, 1, notices, 'panel_dust'),
      temperature: finiteNumber(
        state.temperature,
        config.number('target_temp'),
        notices,
        'temperature',
      ),
      radiation: math.max(
        0,
        finiteNumber(state.radiation, 0, notices, 'radiation'),
      ),
      cleaningHours: bounded(
        state.cleaningHours,
        0,
        config.number('cleaning_hours'),
        notices,
        'cleaning_hours',
      ),
    );
  }

  Trace step(SimState initial, PlayerInputs inputs, {double? hours}) {
    final notices = <SimNotice>[];
    var state = _safe(initial, notices);
    var remaining = hours ?? config.number('tick_hours');
    if (!remaining.isFinite || remaining <= 0) {
      notices.add(const SimNotice('invalid_duration', 'no_time_advanced'));
      return Trace(state, [TraceEntry(state, notices)]);
    }
    // step is bounded by the configured tick; run is the multi-tick API.
    if (remaining > config.number('tick_hours')) {
      remaining = config.number('tick_hours');
      notices.add(
        const SimNotice('duration_clamped', 'use_run_for_multiple_ticks'),
      );
    }
    if (state.paused && !inputs.resume) {
      notices.add(const SimNotice('simulation_paused', 'needs_help'));
      return Trace(state, [TraceEntry(state, notices)]);
    }
    state = state.copyWith(paused: false);
    final entries = <TraceEntry>[];
    var repairPending = inputs.repairFacilityId;
    while (remaining > 0 && !state.paused) {
      state = state.copyWith(
        resources: {
          for (final e in state.resources.entries)
            e.key: ResourceState(
              quantity: e.value.quantity,
              capacity: e.value.capacity,
            ),
        },
      );
      var duration = math.min(
        remaining,
        SimulationClock.untilNextSol(
          state.elapsedHours,
          config.number('sol_hours'),
        ),
      );
      for (final scheduled in inputs.scriptedEvents) {
        final delta = scheduled.atHour - state.elapsedHours;
        if (delta.isFinite &&
            delta > 0 &&
            !state.firedScriptIds.contains(scheduled.id)) {
          duration = math.min(duration, delta);
        }
      }
      for (final active in state.activeEvents.values) {
        final delta = active.endHour - state.elapsedHours;
        if (delta > 0) duration = math.min(duration, delta);
      }
      if (state.elapsedHours + duration == state.elapsedHours) {
        notices.add(const SimNotice('duration_too_small', 'no_time_advanced'));
        entries.add(TraceEntry(state, notices));
        break;
      }
      final events = EventModel.atStart(config, state, inputs, notices);
      state = events.state;
      final power = PowerModel.step(
        config,
        state,
        inputs,
        duration,
        events.tau,
        notices,
      );
      if (repairPending != null) {
        final facility = state.facilities[repairPending];
        if (inputs.shelter ||
            !inputs.crewAvailableForActions ||
            facility == null ||
            facility.damagedUnits == 0 ||
            state.spareParts == 0 ||
            (power.fractions['repair'] ?? 0) < 1) {
          notices.add(SimNotice('repair_unavailable', repairPending));
        } else {
          final damage = facility.damagedUnits - 1;
          state = state.copyWith(
            spareParts: state.spareParts - 1,
            facilities: {
              ...state.facilities,
              repairPending: facility.copyWith(
                damagedUnits: damage,
                status: damage == 0
                    ? FacilityStatus.operating
                    : FacilityStatus.damaged,
              ),
            },
          );
          notices.add(SimNotice('repaired', repairPending));
        }
        repairPending = null;
      }
      var dust = state.dust;
      if (state.activeEvents.containsKey('dust_storm')) {
        dust +=
            config.number('dust_gain_per_hour') *
            duration *
            config.multiplier('dust_gain', state.researchIds);
      }
      var cleaning = state.cleaningHours;
      if (inputs.cleanPanels &&
          !inputs.shelter &&
          inputs.crewAvailableForActions) {
        cleaning += duration * (power.fractions['panel_cleaning'] ?? 0);
        if (cleaning >= config.number('cleaning_hours')) {
          dust *= 1 - config.number('cleaning_restores');
          cleaning -= config.number('cleaning_hours');
          notices.add(const SimNotice('panels_cleaned', 'output_restored'));
        }
      } else if (inputs.cleanPanels) {
        notices.add(
          const SimNotice('cleaning_unavailable', 'crew_sheltered_or_busy'),
        );
      }
      state = state.copyWith(
        dust: bounded(dust, 0, 1, notices, 'panel_dust'),
        cleaningHours: cleaning,
      );
      state = ResourceModel.step(
        config,
        state,
        inputs,
        power,
        duration,
        notices,
      );
      final radiation = math.max(
        0.0,
        finiteNumber(
          state.radiation +
              RadiationModel.dose(
                config,
                state,
                duration,
                events.spike,
                sheltered: inputs.shelter,
              ),
          state.radiation,
          notices,
          'radiation',
        ),
      );
      var paused = state.paused;
      if (radiation >= config.number('radiation_limit') &&
          state.crewCount > 0) {
        paused = true;
        notices.add(const SimNotice('needs_help', 'radiation_game_limit'));
      }
      state = state.copyWith(
        radiation: radiation,
        paused: paused,
        elapsedHours: finiteNumber(
          state.elapsedHours + duration,
          state.elapsedHours,
          notices,
          'elapsed_hours',
        ),
      );
      entries.add(TraceEntry(state, notices));
      notices.clear();
      remaining -= duration;
    }
    return Trace(state, entries);
  }

  Trace run(
    SimState initial, {
    required int steps,
    Policy policy = const BaselinePolicy(),
  }) {
    var state = initial;
    final entries = <TraceEntry>[];
    for (var i = 0; i < steps; i++) {
      final result = step(state, policy.inputsFor(state));
      state = result.state;
      entries.addAll(result.entries);
      if (state.paused) break;
    }
    return Trace(state, entries);
  }
}
