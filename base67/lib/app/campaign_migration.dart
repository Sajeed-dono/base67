import 'dart:convert';

import '../data/repositories/game_data_repository.dart';
import '../progression/progression_service.dart';
import '../data/sim_config_loader.dart';
import '../missions/mission_runtime.dart';
import 'campaign_save.dart';

/// Repository adaptation and one-way schema migration; no IO or clock reads.
class CampaignMigration {
  CampaignMigration(this.repository)
    : config = ProgressionConfig.fromDocuments(
        buildings: repository.document('buildings.json')!,
        research: repository.document('research.json')!,
        timers: repository.document('timer_rules.json')!,
        crew: repository.document('crew_assignments.json')!,
        rules: repository.document('progression_rules.json')!,
        equipment: repository.document('equipment.json')!,
        events: repository.document('events.json')!,
      );

  final GameDataRepository repository;
  final ProgressionConfig config;
  late final missions = MissionRuntime(SimConfigLoader.load(repository),
    {...repository.document('tutorial.json')!,
      'missions': [...repository.document('tutorial.json')!['missions'] as List,
        ...repository.document('campaign_operations.json')!['missions'] as List],
      'mission_rules': {...repository.document('tutorial.json')!['mission_rules'] as Map,
        ...repository.document('campaign_operations.json')!['mission_rules'] as Map}}, config.levels,
    operations: repository.document('campaign_operations.json')!,
    crewRules: repository.document('crew_assignments.json')!['mission_operations'] as Map<String, dynamic>,
    progressionConfig: config);
  late final codec = ProgressionCodec(config, equipmentIds: [
    for (final row in repository.document('equipment.json')!['equipment'] as List)
      (row as Map)['id'] as String,
  ]);

  CampaignSave migrate(CampaignSave save) {
    validateMetadata(save);
    if (save.version == 3) {
      validate(save);
      return save;
    }
    if (save.version != 2) { throw UnsupportedSaveVersion(save.version); }
    final levels = config.levels;
    if (!levels.toSet().containsAll(save.completedLevelIds) ||
        !levels.toSet().containsAll(save.unlockedLevelIds)) {
      throw const FormatException('Unknown legacy campaign level; original save preserved');
    }
    final current = levels.firstWhere(
      (id) => save.unlockedLevelIds.contains(id) && !save.completedLevelIds.contains(id),
      orElse: () => levels.last,
    );
    final installed = <String, int>{}, tiers = <String, int>{};
    for (final e in save.buildingLevels.entries) {
      if (e.value == 0) { continue; }
      if (e.value < 0 || e.value > 2 ||
          (!config.maxUnits.containsKey(e.key) && e.key != 'landing_craft') ||
          (e.value > 1 && !config.recipes.containsKey('upgrade:${e.key}'))) {
        throw const FormatException('Ambiguous legacy facility; original save preserved');
      }
      // Schema 2 stored presentation levels, not installed-unit counts.
      installed[e.key] = 1;
      if (e.value > 1) { tiers[e.key] = e.value - 1; }
    }
    final resources = {...save.resources};
    final capacities = {...save.resourceCapacities};
    final receipts = <String, ProgressionReceipt>{};
    final log = <String>['migration:schema2_to_schema3'];
    if (save.prologueComplete) {
      for (final raw in repository.document('resource_economy.json')!['resources'] as List) {
        final row = raw as Map;
        resources.putIfAbsent(row['id'] as String, () => (row['initial'] as num).toDouble());
        capacities.putIfAbsent(row['id'] as String, () => (row['capacity'] as num).toDouble());
      }
      // Presence, including zero, means an existing balance; never refill it.
      if (save.resources.containsKey('materials')) {
        receipts['resupply:start'] = ProgressionReceipt('resupply', config.startMaterials.toDouble());
        log.add('migration:existing_material_balance_preserved');
      }
    }
    final completed = {...save.completedActivityIds};
    final legacy = <TimerJobSave>[];
    final ids = <String>{};
    for (final job in save.timerJobs) {
      if (job.id.isEmpty || !ids.add(job.id) ||
          !const {'queued','blocked','active','cancelled','completed'}.contains(job.status) ||
          job.expectedCompletionAtUtc.isBefore(job.startedAtUtc)) {
        throw const FormatException('Malformed legacy job; original save preserved');
      }
      // No trustworthy payment/effect/allocation history exists in schema 2.
      // Preserve the record, release crew, prohibit ID reuse, apply no effect.
      legacy.add(TimerJobSave(
        id: job.id, category: job.category, startedAtUtc: job.startedAtUtc,
        expectedCompletionAtUtc: job.expectedCompletionAtUtc,
        status: job.status == 'completed' ? 'completed' : 'cancelled',
        rewardApplied: true, targetId: job.targetId,
      ));
      completed.add(job.id);
      log.add('migration:legacy_job_retired:${job.id}:crew_freed:no_cost:no_effect');
    }
    var state = ProgressionState(
      levelId: current, resources: resources, packedStock: save.inventory,
      facilities: installed, upgradeTiers: tiers,
      completedLevels: save.completedLevelIds,
      completedResearch: save.completedResearchIds,
      completedActivityIds: completed,
      crewRoles: {for (final role in const ['Commander','Engineer','Scientist','Medic']) role: role},
      receipts: receipts, log: log,
    );
    final service = RealTimeProgressionService(config);
    final unpacked = service.unpackSpareParts(state);
    if (!const {'spares_unpacked','nothing_to_unpack'}.contains(unpacked.code)) {
      throw FormatException('Legacy spare ownership unresolved: ${unpacked.code}; original save preserved');
    }
    state = unpacked.state;
    if (save.prologueComplete) { state = service.resupply(state); }
    final migrated = save.copyWith(
      version: 3, progressionJson: jsonEncode(codec.encode(state)),
      legacyTimerJobs: legacy, resourceCapacities: capacities,
    );
    validate(migrated);
    return migrated;
  }

  void validate(CampaignSave save) {
    validateMetadata(save);
    if (save.version != 3 || save.progressionJson == null) {
      throw const FormatException('Application saves require schema 3');
    }
    final state = codec.decode(jsonDecode(save.progressionJson!));
    if (save.missionJson != null) {
      final mission = jsonDecode(save.missionJson!) as Map<String, dynamic>;
      missions.validate(mission);
      if (mission['settlement'] != null) {
        missions.crew.validate(state, Map<String, dynamic>.from(mission['settlement'] as Map));
      }
      if (!save.prologueComplete || save.selectedSiteId == null ||
          !save.unlockedLevelIds.contains(mission['level'])) {
        throw const FormatException('Mission requires completed setup and an unlocked level');
      }
      if (mission['result'] == 'success' && !state.completedLevels.contains(mission['level'])) {
        throw const FormatException('Mission outcome is missing its campaign completion');
      }
    }
    if (!config.levels.toSet().containsAll(save.unlockedLevelIds)) {
      throw const FormatException('Unknown unlocked level');
    }
    for (final job in save.legacyTimerJobs) {
      if (!const {'cancelled','completed'}.contains(job.status) ||
          !job.rewardApplied || job.assignedCrewRole != null ||
          state.jobs.containsKey(job.id) || !state.completedActivityIds.contains(job.id)) {
        throw const FormatException('Unsafe archived legacy job');
      }
    }
  }

  void validateMetadata(CampaignSave save) {
    for (final map in [save.resources, save.resourceCapacities]) {
      if (map.values.any((n) => !n.isFinite || n < 0)) {
        throw const FormatException('Invalid resource balance/capacity');
      }
    }
    if (save.inventory.values.any((n) => n < 0) ||
        save.startingCargo.values.any((n) => n < 0)) {
      throw const FormatException('Negative cargo');
    }
    if (save.selectedSiteId != null &&
        !(repository.document('sites.json')!['sites'] as List)
            .any((row) => (row as Map)['id'] == save.selectedSiteId)) {
      throw const FormatException('Unknown landing site');
    }
  }
}
