import '../progression/progression_service.dart';
import '../sim/sim_config.dart';
import '../sim/sim_state.dart';

/// Simulation-time activities share the existing canonical assignment map with
/// real-time jobs. There is no clock reader, independent save or medical model.
class CrewOperations {
  CrewOperations(this.rules) {
    for (final entry in rules.entries.where((e) => e.key != 'actions')) {
      final value = entry.value;
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Invalid GAME VALUE crew rule: ${entry.key}');
      }
    }
    final ids = <String>{};
    for (final action in actions) {
      if (!ids.add(action['id'] as String) ||
          !const {'priorities','clean','forecast','drill','survey','rest','care','rally'}.contains(action['id']) ||
          !const {null,'Commander','Engineer','Scientist','Medic'}.contains(action['specialist']) ||
          action['from_level'] is! int || (action['from_level'] as int) < 1 || (action['from_level'] as int) > 15 ||
          action['hours'] is! num || !(action['hours'] as num).isFinite || (action['hours'] as num) <= 0 ||
          action['backup_hours'] is! num || !(action['backup_hours'] as num).isFinite ||
          (action['backup_hours'] as num) < (action['hours'] as num)) {
        throw const FormatException('Invalid GAME VALUE crew activity');
      }
    }
    if (number('maximum') <= 0 || ['initial_health','initial_morale','initial_fatigue',
      'safe_health','safe_morale','safe_fatigue'].any((id) => number(id) > number('maximum'))) {
      throw const FormatException('Crew rule exceeds configured scale');
    }
  }
  final Map<String, dynamic> rules;
  double number(String key) => (rules[key] as num).toDouble();
  List<Map<String, dynamic>> get actions => (rules['actions'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic> snapshot(ProgressionState p, Map? previous) => {
    ...?previous,
    'crew': {for (final role in p.crewRoles.keys) role: {
      'health': number('initial_health'), 'morale': number('initial_morale'),
      'fatigue': number('initial_fatigue'),
      ...?((previous?['crew'] as Map?)?[role] as Map?),
    }},
    'tasks': Map<String, dynamic>.from((previous?['tasks'] as Map?) ?? const {}),
    'actions': List<String>.from((previous?['actions'] as List?) ?? const []),
    'support_count': previous?['support_count'] ?? 0,
    'survey_sites': List<String>.from((previous?['survey_sites'] as List?) ?? const []),
  };

  Map<String, dynamic>? definition(String id) => actions.where((a) => a['id'] == id).firstOrNull;
  bool safe(Map<String, dynamic> settlement) => (settlement['crew'] as Map).values.every((raw) {
    final member = raw as Map;
    return (member['health'] as num) >= number('safe_health') &&
      (member['morale'] as num) >= number('safe_morale') &&
      (member['fatigue'] as num) <= number('safe_fatigue');
  });

  CrewResult assign(ProgressionState p, Map<String, dynamic> settlement,
      {required String role, required String action, required int level}) {
    final spec = definition(action);
    if (!p.crewRoles.containsKey(role) || spec == null || level < (spec['from_level'] as int)) {
      return CrewResult(p, settlement, 'This activity is not introduced yet.');
    }
    if (p.crewAssignments.containsKey(role)) {
      return CrewResult(p, settlement, 'That astronaut already has an assignment. Choose another or cancel the current plan.');
    }
    if (action == 'clean' && (p.externalFacilityReservations.contains('solar_array') ||
        p.jobs.values.any((j) => j.status == 'active' && j.recipe.targetId == 'solar_array'))) {
      return CrewResult(p, settlement, 'Panels already have an active technical job. Wait or choose a different activity.');
    }
    final preferred = spec['specialist'] == null || p.crewRoles[role] == spec['specialist'];
    final task = {'kind': action, 'remaining': spec[preferred ? 'hours' : 'backup_hours'], 'specialist': preferred};
    return CrewResult(p.copyWith(externalCrewAssignments: {
      ...p.externalCrewAssignments, role: 'mission:$action',
    }, externalFacilityReservations: {...p.externalFacilityReservations,
      if (action == 'clean') 'solar_array'}),
      {...settlement, 'tasks': {...settlement['tasks'] as Map, role: task}},
      'Assignment saved. Advance a simulation step to work or rest; real-time jobs use their own clock.');
  }

  CrewResult cancel(ProgressionState p, Map<String, dynamic> settlement, String role) {
    final task = (settlement['tasks'] as Map)[role] as Map?;
    if (task == null || p.externalCrewAssignments[role] != 'mission:${task['kind']}') {
      return CrewResult(p, settlement, 'This is not a simulation assignment. Manage real-time jobs in Build or Research.');
    }
    final assignments = {...p.externalCrewAssignments}..remove(role);
    final tasks = {...settlement['tasks'] as Map}..remove(role);
    return CrewResult(p.copyWith(externalCrewAssignments: assignments,
      externalFacilityReservations: {...p.externalFacilityReservations}
        ..removeAll(task['kind'] == 'clean' ? ['solar_array'] : const [])),
      {...settlement, 'tasks': tasks}, 'Crew freed. No resources were charged or refunded.');
  }

  CrewResult advance(ProgressionState p, Map<String, dynamic> settlement, SimState state,
      {required double hours, required bool shortage, required SimConfig config, bool cleaned = false}) {
    final tasks = <String, dynamic>{};
    final assignments = {...p.externalCrewAssignments};
    final crew = <String, dynamic>{};
    final completed = (settlement['actions'] as List).cast<String>().toSet();
    final sites = (settlement['survey_sites'] as List).cast<String>().toSet();
    final effects = <(String, bool)>[];
    for (final role in p.crewRoles.keys) {
      final member = Map<String, dynamic>.from((settlement['crew'] as Map)[role] as Map);
      final task = (settlement['tasks'] as Map)[role] as Map?;
      final resting = task?['kind'] == 'rest' || !p.crewAssignments.containsKey(role);
      var health = (member['health'] as num).toDouble();
      var fatigue = (member['fatigue'] as num).toDouble();
      health += (resting ? number('rest_health_per_hour') : 0) * hours;
      fatigue += (resting ? -number('rest_fatigue_per_hour') : number('work_fatigue_per_hour')) * hours;
      if (state.temperature < config.number('min_safe_temp')) { health -= number('cold_health_per_hour') * hours; }
      if (shortage) { health -= number('shortage_health_per_hour') * hours; }
      member['health'] = health.clamp(0, number('maximum')).toDouble();
      member['fatigue'] = fatigue.clamp(0, number('maximum')).toDouble();
      crew[role] = member;
      if (task != null) {
        final remaining = (task['remaining'] as num).toDouble() - hours;
        if (task['kind'] == 'clean' && remaining <= 0.000000001 && !cleaned) {
          tasks[role] = {...task}; // Retain assignment until actual engine success.
        } else if (remaining > 0.000000001) {
          tasks[role] = {...task, 'remaining': remaining};
        } else {
          final kind = task['kind'] as String;
          completed.add(kind);
          effects.add((kind, task['specialist'] as bool));
          assignments.remove(role);
          if (kind == 'survey') { sites.add(state.siteId); }
        }
      }
    }
    for (final (kind, preferred) in effects) {
      final fraction = preferred ? 1.0 : number('backup_effect_fraction');
      for (final raw in crew.values) {
        final member = raw as Map<String, dynamic>;
        if (kind == 'care') {
          member['health'] = ((member['health'] as num) + number('care_health') * fraction).clamp(0, number('maximum')).toDouble();
          member['morale'] = ((member['morale'] as num) + number('care_morale') * fraction).clamp(0, number('maximum')).toDouble();
          member['fatigue'] = ((member['fatigue'] as num) - number('care_fatigue') * fraction).clamp(0, number('maximum')).toDouble();
        }
        if (kind == 'rally') {
          member['morale'] = ((member['morale'] as num) + number('rally_morale') * fraction).clamp(0, number('maximum')).toDouble();
        }
      }
    }
    final reservations = {...p.externalFacilityReservations};
    if (effects.any((e) => e.$1 == 'clean')) { reservations.remove('solar_array'); }
    return CrewResult(p.copyWith(externalCrewAssignments: assignments,
      externalFacilityReservations: reservations), {
      ...settlement, 'crew': crew, 'tasks': tasks, 'actions': completed.toList()..sort(),
      'survey_sites': sites.toList()..sort(),
    }, effects.isEmpty ? '' : 'Crew activities completed: ${effects.map((e) => e.$1).join(', ')}.');
  }

  void validate(ProgressionState p, Map<String, dynamic> settlement) {
    final crew = settlement['crew'] as Map;
    if (crew.length != p.crewRoles.length || !p.crewRoles.keys.every(crew.containsKey)) {
      throw const FormatException('Crew wellbeing identities');
    }
    for (final member in crew.values) {
      for (final stat in ['health','morale','fatigue']) {
        final value = (member as Map)[stat];
        if (value is! num || !value.isFinite || value < 0 || value > number('maximum')) {
          throw const FormatException('Crew wellbeing bounds');
        }
      }
    }
    final tasks = settlement['tasks'] as Map;
    if (tasks.values.where((raw) => (raw as Map)['kind'] == 'clean').length > 1) {
      throw const FormatException('Duplicate panel maintenance');
    }
    for (final entry in tasks.entries) {
      final row = entry.value as Map;
      final spec = definition(row['kind'] as String);
      final remaining = row['remaining'];
      if (!p.crewRoles.containsKey(entry.key) || spec == null || row['specialist'] is! bool ||
          row['specialist'] != (spec['specialist'] == null || p.crewRoles[entry.key] == spec['specialist']) ||
          remaining is! num || !remaining.isFinite || remaining <= 0 ||
          remaining > (spec[row['specialist'] == true ? 'hours' : 'backup_hours'] as num) ||
          row['kind'] == 'clean' && !p.externalFacilityReservations.contains('solar_array') ||
          p.externalCrewAssignments[entry.key] != 'mission:${row['kind']}') {
        throw const FormatException('Crew assignment checkpoint');
      }
    }
    for (final entry in p.externalCrewAssignments.entries) {
      if (entry.value.startsWith('mission:') && !tasks.containsKey(entry.key)) {
        throw const FormatException('Missing mission assignment');
      }
    }
    if (!(settlement['actions'] as List).every((id) => definition(id as String) != null) ||
        settlement['support_count'] is! int || (settlement['support_count'] as int) < 0 ||
        settlement['survey_sites'] is! List) { throw const FormatException('Crew activity history'); }
  }
}

class CrewResult {
  const CrewResult(this.progression, this.settlement, this.message);
  final ProgressionState progression;
  final Map<String, dynamic> settlement;
  final String message;
}
