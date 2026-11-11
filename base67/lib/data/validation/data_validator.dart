import 'dart:convert';

class DataValidator {
  DataValidator(this.documents);

  final Map<String, Map<String, dynamic>> documents;

  List<String> validate() {
    final errors = <String>[];
    final sources = _rows(documents['sources.json']?['sources']);
    final sourceById = _uniqueById('source', sources, errors);
    final facts = _map(documents['nasa_data.json']?['facts']);
    _validateNasaMetadata(errors);

    for (final entry in sourceById.entries) {
      final uri = Uri.tryParse('${entry.value['url'] ?? ''}');
      if (uri == null ||
          !uri.hasAuthority ||
          !(uri.host == 'nasa.gov' || uri.host.endsWith('.nasa.gov'))) {
        errors.add('${entry.key} is not a nasa.gov source.');
      }
    }
    for (final entry in facts.entries) {
      final fact = _map(entry.value);
      final refs = fact['source_ids'];
      if (refs is! List || refs.isEmpty) {
        errors.add('Fact ${entry.key} has no source.');
      }
      if (fact['value'] == null || fact['value'] == '') {
        errors.add('Fact ${entry.key} has no value.');
      }
      for (final id
          in refs is List ? refs.whereType<String>() : const <String>[]) {
        if (!sourceById.containsKey(id)) {
          errors.add('Fact ${entry.key} cites unknown source $id.');
        }
      }
    }

    const legacyGameFiles = [
      'sites',
      'equipment',
      'loads',
      'levels',
      'events',
      'lessons',
      'crew',
      'radio',
      'badges',
      'game_constants',
    ];
    for (final name in legacyGameFiles) {
      final doc = documents['$name.json'];
      if (_map(doc?['_meta'])['data_class'] != 'GAME_VALUE') {
        errors.add('$name.json is not marked GAME_VALUE.');
      }
      _checkFactReferences(doc, facts.keys.toSet(), errors, name);
      final encoded = jsonEncode(doc);
      if (encoded.contains('"provenance":"measured"') ||
          encoded.contains('"provenance":"published"')) {
        errors.add('$name.json claims measured/published data.');
      }
    }

    const extraNames = [
      'campaign.json',
      'buildings.json',
      'research.json',
      'progression_rules.json',
      'timer_rules.json',
      'resource_economy.json',
      'crew_assignments.json',
      'sim_params.json',
      'site_risk.json',
      'tutorial.json',
      'campaign_operations.json',
      'scoring.json',
      'fact_cards.json',
      'display_text.json',
    ];
    for (final name in extraNames) {
      final doc = documents[name];
      if (doc == null) {
        errors.add('Missing extra data file $name.');
        continue;
      }
      final meta = _map(doc['_meta']);
      if (meta['data_class'] != 'GAME_VALUE') {
        errors.add('$name is not marked GAME_VALUE.');
      }
      if (meta['version'] is! String || (meta['version'] as String).isEmpty) {
        errors.add('$name has no version.');
      }
      _checkFactReferences(doc, facts.keys.toSet(), errors, name);
    }

    _validateCampaign(errors);
    _validateProgression(errors);
    _validateBuildings(errors);
    _validateResearch(errors);
    _validateTimers(errors);
    _validateCrewAssignments(errors);
    _validateSiteRisk(errors);
    return errors;
  }

  void _validateNasaMetadata(List<String> errors) {
    final factMeta = _map(documents['nasa_data.json']?['_meta']);
    if (factMeta['data_class'] != 'NASA_DATA') {
      errors.add('nasa_data.json is not marked NASA_DATA.');
    }
    final sourceMeta = _map(documents['sources.json']?['_meta']);
    if (sourceMeta.containsKey('data_class') &&
        sourceMeta['data_class'] != 'NASA_DATA') {
      errors.add('sources.json has an invalid data_class.');
    }
  }

  void _validateCampaign(List<String> errors) {
    final campaign = documents['campaign.json'];
    if (campaign == null) return;
    final chapters = _rows(campaign['chapters']);
    final levels = _rows(campaign['levels']);
    if (chapters.length != 5) {
      errors.add('Campaign must contain 5 chapters; found ${chapters.length}.');
    }
    if (levels.length != 15) {
      errors.add('Campaign must contain 15 levels; found ${levels.length}.');
    }
    final levelById = _uniqueById('campaign level', levels, errors);
    for (var i = 0; i < levels.length; i++) {
      if (levels[i]['order'] != i + 1) {
        errors.add('Campaign level at index $i is out of order.');
      }
      for (final field in [
        'chapter_id',
        'name',
        'learning_objective',
        'mission_objective',
        'new_mechanics',
        'debrief',
      ]) {
        if (levels[i][field] == null) {
          errors.add('Campaign level ${levels[i]['id']} is missing $field.');
        }
      }
    }
    final chapterById = _uniqueById('campaign chapter', chapters, errors);
    final members = <String, int>{};
    for (final chapter in chapters) {
      for (final id
          in (chapter['level_ids'] as List? ?? const []).whereType<String>()) {
        members.update(id, (n) => n + 1, ifAbsent: () => 1);
        if (!levelById.containsKey(id)) {
          errors.add('Chapter ${chapter['id']} references unknown level $id.');
        } else if (levelById[id]!['chapter_id'] != chapter['id']) {
          errors.add(
            'Level $id and chapter ${chapter['id']} disagree on membership.',
          );
        }
      }
    }
    for (final level in levels) {
      if (!chapterById.containsKey(level['chapter_id'])) {
        errors.add(
          'Level ${level['id']} references unknown chapter ${level['chapter_id']}.',
        );
      }
      if (members[level['id']] != 1) {
        errors.add('Level ${level['id']} must belong to exactly one chapter.');
      }
      for (final id
          in (level['prerequisite_level_ids'] as List? ?? const [])
              .whereType<String>()) {
        if (!levelById.containsKey(id)) {
          errors.add(
            'Level ${level['id']} has unknown level prerequisite $id.',
          );
        }
      }
    }
  }

  void _validateProgression(List<String> errors) {
    final levels = _rows(documents['campaign.json']?['levels']);
    final levelIds = levels.map((row) => row['id']).whereType<String>().toSet();
    final unlocks = _rows(
      documents['progression_rules.json']?['level_unlocks'],
    );
    final unlockIds = <String>{};
    final unlockById = <String, Map<String, dynamic>>{};
    for (final unlock in unlocks) {
      final id = unlock['level_id'];
      if (id is! String || !levelIds.contains(id)) {
        errors.add('Progression rule references unknown level $id.');
      } else if (!unlockIds.add(id)) {
        errors.add('Duplicate progression rule for level $id.');
      } else {
        unlockById[id] = unlock;
      }
      for (final prerequisite
          in (unlock['required_completed_level_ids'] as List? ?? const [])
              .whereType<String>()) {
        if (!levelIds.contains(prerequisite)) {
          errors.add('Unlock for $id references unknown level $prerequisite.');
        }
      }
    }
    if (unlockIds.length != levelIds.length) {
      errors.add(
        'Progression rules must define an unlock for every campaign level.',
      );
    }
    for (final level in levels) {
      final id = level['id'];
      final campaignPrerequisites =
          (level['prerequisite_level_ids'] as List? ?? const [])
              .whereType<String>()
              .toSet();
      final progressionPrerequisites =
          ((unlockById[id]?['required_completed_level_ids'] as List?) ??
                  const [])
              .whereType<String>()
              .toSet();
      if (campaignPrerequisites.length != progressionPrerequisites.length ||
          !campaignPrerequisites.containsAll(progressionPrerequisites)) {
        errors.add(
          'Campaign and progression prerequisites disagree for level $id.',
        );
      }
    }
  }

  void _validateBuildings(List<String> errors) {
    final buildings = _rows(documents['buildings.json']?['buildings']);
    final byId = _uniqueById('building', buildings, errors);
    final levels = _rows(documents['campaign.json']?['levels']);
    final levelIds = levels.map((row) => row['id']).whereType<String>().toSet();
    final equipment = _rows(documents['equipment.json']?['equipment']);
    final equipmentIds = equipment
        .map((row) => row['id'])
        .whereType<String>()
        .toSet();
    final timerIds = _timerIds();
    for (final building in buildings) {
      final id = building['id'];
      if (!levelIds.contains(building['introduced_level_id'])) {
        errors.add(
          'Building $id references unknown campaign level ${building['introduced_level_id']}.',
        );
      }
      for (final required
          in (building['required_equipment_ids'] as List? ?? const [])
              .whereType<String>()) {
        if (!equipmentIds.contains(required)) {
          errors.add('Building $id requires unknown equipment $required.');
        }
      }
      for (final prerequisite
          in (building['prerequisite_building_ids'] as List? ?? const [])
              .whereType<String>()) {
        if (!byId.containsKey(prerequisite)) {
          errors.add('Building $id has unknown prerequisite $prerequisite.');
        }
      }
      final timerId = building['construction_timer_id'];
      if (timerId != null && !timerIds.contains(timerId)) {
        errors.add('Building $id references unknown timer $timerId.');
      }
    }
  }

  void _validateResearch(List<String> errors) {
    final projects = _rows(documents['research.json']?['projects']);
    final byId = _uniqueById('research project', projects, errors);
    final levelIds = _rows(documents['campaign.json']?['levels'])
        .map((row) => row['id'])
        .whereType<String>()
        .toSet();
    final timerIds = _timerIds();
    for (final project in projects) {
      final id = project['id'];
      if (!levelIds.contains(project['introduced_level_id'])) {
        errors.add(
          'Research $id references unknown campaign level ${project['introduced_level_id']}.',
        );
      }
      for (final prerequisite
          in (project['prerequisites'] as List? ?? const [])
              .whereType<String>()) {
        if (!byId.containsKey(prerequisite)) {
          errors.add('Research $id has unknown prerequisite $prerequisite.');
        }
      }
      final timerId = project['timer_id'];
      if (timerId != null && !timerIds.contains(timerId)) {
        errors.add('Research $id references unknown timer $timerId.');
      }
    }
  }

  void _validateTimers(List<String> errors) {
    final clock = _map(documents['timer_rules.json']?['clock']);
    final categories = (clock['categories'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final timers = _rows(documents['timer_rules.json']?['timers']);
    final byId = _uniqueById('timer', timers, errors);
    for (final timer in timers) {
      final id = timer['id'];
      final min = timer['duration_seconds_min'];
      final max = timer['duration_seconds_max'];
      if (min is! num || max is! num || min <= 0 || max < min) {
        errors.add('Timer $id must have a positive, ordered duration range.');
      }
      if (!categories.contains(timer['category'])) {
        errors.add('Timer $id has unknown category ${timer['category']}.');
      }
      if (timer['status'] != 'provisional') {
        errors.add('Timer $id must remain marked provisional.');
      }
      for (final prerequisite
          in (timer['prerequisites'] as List? ?? const [])
              .whereType<String>()) {
        if (!byId.containsKey(prerequisite)) {
          errors.add('Timer $id has unknown timer prerequisite $prerequisite.');
        }
      }
    }
  }

  void _validateCrewAssignments(List<String> errors) {
    const roles = {'Commander', 'Engineer', 'Scientist', 'Medic'};
    final tasks = _rows(documents['crew_assignments.json']?['tasks']);
    final byId = _uniqueById('crew task', tasks, errors);
    final timers = _timerIds();
    final research = _rows(documents['research.json']?['projects'])
        .map((row) => row['id'])
        .whereType<String>()
        .toSet();
    for (final task in tasks) {
      final id = task['id'];
      if (!roles.contains(task['role_id'])) {
        errors.add('Crew task $id has unknown role ${task['role_id']}.');
      }
      if (!{
        'instant',
        'simulation',
        'real',
        'unassigned',
      }.contains(task['time_basis'])) {
        errors.add(
          'Crew task $id has invalid time basis ${task['time_basis']}.',
        );
      }
      final timerId = task['timer_id'];
      if (timerId != null && !timers.contains(timerId)) {
        errors.add('Crew task $id references unknown timer $timerId.');
      }
      final researchId = task['research_id'];
      if (researchId != null && !research.contains(researchId)) {
        errors.add('Crew task $id references unknown research $researchId.');
      }
      for (final prerequisite
          in (task['prerequisites'] as List? ?? const []).whereType<String>()) {
        if (!byId.containsKey(prerequisite)) {
          errors.add('Crew task $id has unknown prerequisite $prerequisite.');
        }
      }
    }
  }

  void _validateSiteRisk(List<String> errors) {
    final siteRows = _rows(documents['sites.json']?['sites']);
    final sites = _uniqueById('site', siteRows, errors);
    final riskRows = _rows(documents['site_risk.json']?['sites']);
    final risks = _uniqueById('site risk', riskRows, errors);
    const difficulty = {
      'gale': 'EASY',
      'arcadia': 'MEDIUM',
      'deuteronilus': 'HARD',
      'equatorial_plain': 'EXTREME',
    };
    for (final entry in difficulty.entries) {
      if (!sites.containsKey(entry.key)) {
        errors.add('Missing original landing site ${entry.key}.');
      }
      if (risks[entry.key]?['difficulty'] != entry.value) {
        errors.add('Site risk ${entry.key} must be labelled ${entry.value}.');
      }
    }
  }

  Set<String> _timerIds() =>
      _rows(documents['timer_rules.json']?['timers'])
          .map((row) => row['id'])
          .whereType<String>()
          .toSet();

  Map<String, Map<String, dynamic>> _uniqueById(
    String type,
    List<Map<String, dynamic>> rows,
    List<String> errors,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row['id'];
      if (id is! String || id.isEmpty) {
        errors.add('$type entry has no id.');
      } else if (result.containsKey(id)) {
        errors.add('Duplicate $type id $id.');
      } else {
        result[id] = row;
      }
    }
    return result;
  }

  void _checkFactReferences(
    Object? value,
    Set<String> factIds,
    List<String> errors,
    String name,
  ) {
    if (value is Map) {
      for (final entry in value.entries) {
        if (entry.key == 'fact_id' &&
            entry.value is String &&
            !factIds.contains(entry.value)) {
          errors.add('$name uses unknown NASA fact id ${entry.value}.');
        } else if (entry.key == 'fact_ids' && entry.value is List) {
          for (final id in (entry.value as List).whereType<String>()) {
            if (!factIds.contains(id)) {
              errors.add('$name uses unknown NASA fact id $id.');
            }
          }
        }
        if (entry.key == 'nasa_fact_ids') {
          final refs = entry.value;
          final ids = refs is Map
              ? refs.values
              : refs is List
              ? refs
              : const [];
          for (final id in ids.whereType<String>()) {
            if (!factIds.contains(id) && !_factAliasNames.contains(id)) {
              errors.add('$name uses unknown NASA fact id $id.');
            }
          }
        }
        _checkFactReferences(entry.value, factIds, errors, name);
      }
    } else if (value is List) {
      for (final item in value) {
        _checkFactReferences(item, factIds, errors, name);
      }
    }
  }

  static const _factAliasNames = {
    'lat',
    'lon',
    'elevation',
    'air_temp_high',
    'air_temp_low',
    'radiation',
    'ice_depth',
    'ice_rank',
    'temp_mean',
  };

  static List<Map<String, dynamic>> _rows(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];
  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : <String, dynamic>{};
}
