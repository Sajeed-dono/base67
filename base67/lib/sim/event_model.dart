import 'dart:math' as math;

import 'player_inputs.dart';
import 'seeded_rng.dart';
import 'sim_config.dart';
import 'sim_state.dart';
import 'simulation_clock.dart';

class EventResult {
  const EventResult(this.state, this.tau, this.spike);
  final SimState state;
  final double tau, spike;
}

abstract final class EventModel {
  static double stormTau(SimConfig config, double age) {
    final frames = config.stormFrames;
    if (frames.isEmpty) return config.number('clear_tau');
    if (age <= frames.first.$1) return frames.first.$2;
    for (var i = 1; i < frames.length; i++) {
      final a = frames[i - 1], b = frames[i];
      if (age <= b.$1) {
        return a.$2 + (b.$2 - a.$2) * (age - a.$1) / (b.$1 - a.$1);
      }
    }
    return config.number('clear_tau');
  }

  static EventResult atStart(
    SimConfig config,
    SimState initial,
    PlayerInputs inputs,
    List<SimNotice> notices,
  ) {
    var state = initial;
    var spike = 0.0;
    final active = {
      for (final e in state.activeEvents.entries)
        if (e.value.endHour > state.elapsedHours) e.key: e.value,
    };
    state = state.copyWith(activeEvents: active);
    void fire(EventSpec event) {
      notices.add(SimNotice('event', event.id));
      switch (event.id) {
        case 'dust_storm':
          if (config.stormFrames.isNotEmpty) {
            active[event.id] = ActiveEvent(
              event.id,
              state.elapsedHours,
              state.elapsedHours + config.stormFrames.last.$1,
            );
          }
        case 'clear_day':
          active[event.id] = ActiveEvent(
            event.id,
            state.elapsedHours,
            state.elapsedHours +
                (event.effects['duration_sols'] ?? 0) *
                    config.number('sol_hours'),
          );
        case 'sep_event':
          spike += event.effects['dose_spike_msv'] ?? 0;
        case 'meteor_shower':
          final panel = state.facilities['solar_array'];
          if (panel != null && panel.units > panel.damagedUnits) {
            final damage = math.min(
              panel.units,
              panel.damagedUnits + (event.effects['units'] ?? 0).toInt(),
            );
            state = state.copyWith(
              facilities: {
                ...state.facilities,
                'solar_array': panel.copyWith(
                  damagedUnits: damage,
                  status: FacilityStatus.damaged,
                ),
              },
            );
          } else {
            notices.add(
              const SimNotice('event_no_effect', 'no_panel_to_damage'),
            );
          }
        case 'ice_found':
          if (event.iceTiers.contains(config.sites[state.siteId]!.iceTier)) {
            final water = state.resources['water_kg']!;
            final amount = event.effects['water_kg'] ?? 0;
            state = state.copyWith(
              resources: {
                ...state.resources,
                'water_kg': ResourceState(
                  quantity: finiteNumber(
                    water.quantity + amount,
                    water.quantity,
                    notices,
                    'ice_event_water',
                  ),
                  capacity: water.capacity,
                  changes: [
                    ResourceChange('ice_found', amount, DataClass.game),
                  ],
                ),
              },
            );
          } else {
            notices.add(
              const SimNotice('event_no_effect', 'ice_tier_requirement'),
            );
          }
        default:
          notices.add(SimNotice('event_no_effect', 'unsupported:${event.id}'));
      }
    }

    final fired = {...state.firedScriptIds};
    final scheduled = [...inputs.scriptedEvents]
      ..sort((a, b) {
        final byHour = a.atHour.compareTo(b.atHour);
        return byHour == 0 ? a.id.compareTo(b.id) : byHour;
      });
    for (final script in scheduled) {
      if (!script.atHour.isFinite || script.atHour < 0) {
        notices.add(SimNotice('invalid_script', script.id));
        continue;
      }
      if (script.atHour > state.elapsedHours || !fired.add(script.id)) continue;
      final event = config.events[script.eventId];
      if (event == null) {
        notices.add(SimNotice('unknown_event', script.eventId));
      } else {
        fire(event);
      }
    }
    final sol = SimulationClock.solIndex(
      state.elapsedHours,
      config.number('sol_hours'),
    );
    final rng = SeededRng(state.rngState);
    if (sol > state.lastRandomSol) {
      final ids = inputs.enabledRandomEvents.toList()..sort();
      for (final id in ids) {
        final event = config.events[id];
        if (event == null || event.scripted) {
          notices.add(SimNotice('random_event_not_available', id));
          continue;
        }
        if (rng.nextDouble() < event.chancePerSol) fire(event);
      }
      state = state.copyWith(lastRandomSol: sol);
    }
    state = state.copyWith(
      activeEvents: active,
      firedScriptIds: fired,
      rngState: rng.state,
    );
    final storm = active['dust_storm'];
    final clear = active['clear_day'];
    final tau = storm != null
        ? stormTau(config, state.elapsedHours - storm.startHour)
        : clear != null
        ? config.events['clear_day']!.effects['tau_override'] ??
              config.number('clear_tau')
        : config.number('clear_tau');
    return EventResult(state, tau, spike);
  }
}
