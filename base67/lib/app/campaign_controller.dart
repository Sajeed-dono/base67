import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/repositories/game_data_repository.dart';
import '../progression/progression_clock.dart';
import '../progression/progression_service.dart';
import '../missions/mission_runtime.dart';
import '../sim/sim_state.dart';
import 'campaign_migration.dart';
import 'campaign_save.dart';
import 'campaign_save_store.dart';

/// The sole app mutation coordinator. Save first, publish after verified IO.
/// Queued operations read current state; callbacks cannot submit old snapshots.
class CampaignController extends ChangeNotifier {
  CampaignController({
    required GameDataRepository repository,
    required this.store,
    required CampaignSave initial,
    DateTime Function()? utcNow,
  }) : migration = CampaignMigration(repository),
       _utcNow = utcNow ?? DateTime.now,
       _save = initial {
    store.configure(
      migration: migration.migrate,
      validation: migration.validate,
    );
    _save = CampaignSave.decode(migration.migrate(initial).encode());
    _issuedToken = progression.lastObservationToken;
  }

  final CampaignSaveStore store;
  final CampaignMigration migration;
  final DateTime Function() _utcNow;
  CampaignSave _save;
  Future<void> _tail = Future.value();
  Future<void>? _initialization;
  Timer? _wakeUp;
  bool _disposed = false, _paused = false, _blocked = false;
  int _issuedToken = -1, _setupGeneration = 0;
  Object? lastError;
  CampaignSave get save => CampaignSave.decode(_save.encode());
  int get setupGeneration => _setupGeneration;
  ProgressionState get progression =>
      migration.codec.decode(jsonDecode(_save.progressionJson!));
  RealTimeProgressionService get service =>
      RealTimeProgressionService(migration.config);
  MissionRuntime get missions => migration.missions;
  Map<String, dynamic>? get mission => _save.missionJson == null
      ? null
      : jsonDecode(_save.missionJson!) as Map<String, dynamic>;
  SimState get missionWorld => missions.world(
    progression,
    mission,
    site: _save.selectedSiteId ?? missions.config.sites.keys.first,
    seed: _save.deterministicSeed ?? missions.config.defaultSeed,
  );

  /// All mission writes use the same serialized, verified one-blob save path.
  /// Mission UI commands include the expected identity to reject old screens.
  Future<String> missionAction(String levelId, String action, {String? value}) {
    final generation = _setupGeneration;
    final observation = _capture();
    return _serial(() async {
      if (generation != _setupGeneration) {
        return 'campaign_changed';
      }
      if (!_save.prologueComplete ||
          !missions.supports(levelId) ||
          !_save.unlockedLevelIds.contains(levelId)) {
        return 'level_locked';
      }
      if (_save.selectedSiteId == null) {
        return 'Saved landing site not found; owner review is needed.';
      }
      if (observation.token <= progression.lastObservationToken) {
        return 'stale_observation';
      }
      var current = mission;
      var badges = _save.badgeIds;
      var state = service.reconcile(progression, observation: observation);
      SimState world(Map<String, dynamic>? snapshot) => missions.world(
        state,
        snapshot,
        site: _save.selectedSiteId!,
        seed: _save.deterministicSeed ?? missions.config.defaultSeed,
      );
      if (action == 'open') {
        if (current?['level'] == levelId) {
          return 'resumed';
        }
        if (current != null && current['phase'] != 'debrief') {
          return 'mission_in_progress';
        }
        current = missions.open(levelId, world(current), current);
      } else {
        if (current == null || current['level'] != levelId) {
          return 'mission_changed';
        }
        final phase = current['phase'];
        switch (action) {
          case 'review':
            if (phase != 'briefing') {
              return 'wrong_phase';
            }
            current = {...current, 'phase': 'review'};
          case 'plan':
            if (phase != 'review') {
              return 'wrong_phase';
            }
            current = {...current, 'phase': 'planning'};
          case 'learn':
            if (value != missions.definition(levelId)['answer']) {
              return 'Try comparing the meters with the lesson.';
            }
            current = {
              ...current,
              'learned': {
                ...(current['learned'] as List).cast<String>(),
                missions.definition(levelId)['interaction'] as String,
              }.toList(),
              'message': 'Good observation. Try it with your own base.',
            };
          case 'hint':
            current = {
              ...current,
              'hint': ((current['hint'] as int) + 1).clamp(0, 3),
            };
          case 'crew':
            final parts = value?.split(':') ?? const <String>[];
            if (parts.length != 2) {
              return 'Choose an astronaut and activity.';
            }
            final result = missions.crew.assign(
              state,
              missions.settlement(state, current),
              role: parts[0],
              action: parts[1],
              level: missions.order(levelId),
            );
            if (identical(result.progression, state)) {
              return result.message;
            }
            state = result.progression;
            current = {
              ...current,
              'settlement': result.settlement,
              'message': result.message,
            };
          case 'cancel_crew':
            final result = missions.crew.cancel(
              state,
              missions.settlement(state, current),
              value ?? '',
            );
            state = result.progression;
            current = {
              ...current,
              'settlement': result.settlement,
              'message': result.message,
            };
          case 'support':
            final result = missions.support(
              state,
              current,
              site: _save.selectedSiteId!,
              seed: _save.deterministicSeed ?? missions.config.defaultSeed,
            );
            state = result.progression;
            current = result.session;
          case 'shelter':
            if (!missions.introduced(levelId, 'shelter') ||
                (world(current).facilities['radiation_shelter']?.workingUnits ??
                        0) ==
                    0) {
              return 'Build a working shelter before using this procedure.';
            }
            current = {
              ...current,
              'shelter': current['shelter'] != true,
              'message': 'Shelter procedure changed. Outdoor cleaning pauses while sheltered; essential systems still need power.',
            };
          case 'toggle':
            if (!const {'planning', 'play'}.contains(phase) ||
                !missions.canControlLoad(state, levelId, value ?? '')) {
              return 'system_locked';
            }
            final loads = (current['disabled'] as List).cast<String>().toSet();
            if (!loads.remove(value)) {
              loads.add(value!);
            }
            current = {
              ...current,
              'disabled': loads.toList(),
              'message': value == 'heater'
                  ? 'Heater changed: less power also means a colder habitat.'
                  : 'Load changed: production needs its power restored.',
            };
          case 'begin':
            if (phase != 'planning') {
              return 'wrong_phase';
            }
            for (final required in migration.config.requiredUnits.entries) {
              final recipe =
                  migration.config.recipes['construction:${required.key}']!;
              if (missions.order(recipe.levelId) <= missions.order(levelId) &&
                  (state.facilities[required.key] ?? 0) < required.value) {
                return 'Build ${required.key.replaceAll('_', ' ')} before starting. Planning and other activities stay available.';
              }
            }
            if ((state.facilities['solar_array'] ?? 0) == 0) {
              return 'Install a solar array first. Other planning stays available.';
            }
            if (missions.order(levelId) >= 2 &&
                (state.facilities['battery_bank'] ?? 0) == 0) {
              return 'Install battery storage first.';
            }
            if (missions.order(levelId) == 6 &&
                (state.facilities['greenhouse'] ?? 0) == 0) {
              return 'Greenhouse construction is still needed. Preparation stays available.';
            }
            if (!(current['learned'] as List).contains(
              missions.definition(levelId)['interaction'],
            )) {
              return 'Discuss the mission question before starting.';
            }
            current = missions.begin(current, world(current));
          case 'step' || 'prepare' || 'clean':
            if (_paused) {
              return 'app_paused';
            }
            if (action == 'clean' &&
                !missions.introduced(levelId, 'cleaning')) {
              return 'system_locked';
            }
            if (action == 'clean') {
              final free = state.crewRoles.keys.where(
                (r) => !state.crewAssignments.containsKey(r),
              );
              if (free.isEmpty) {
                return 'Crew are busy. Wait, cancel an assignment, or choose another plan.';
              }
              final role = free.contains('Engineer') ? 'Engineer' : free.first;
              final assignment = missions.crew.assign(
                state,
                missions.settlement(state, current),
                role: role,
                action: 'clean',
                level: missions.order(levelId),
              );
              if (identical(assignment.progression, state)) {
                return assignment.message;
              }
              state = assignment.progression;
              current = {...current, 'settlement': assignment.settlement};
            }
            final result = missions.step(
              state,
              current,
              site: _save.selectedSiteId ?? missions.config.sites.keys.first,
              seed: _save.deterministicSeed ?? missions.config.defaultSeed,
              preparation: action == 'prepare',
            );
            state = result.progression;
            current = result.session;
          case 'retry':
            if (phase != 'debrief') {
              return 'wrong_phase';
            }
            if (current['result'] == 'retry') {
              badges = {...badges, 'good_failure'};
            }
            current = {
              ...missions.open(levelId, world(current), current),
              'phase': 'planning',
            };
          default:
            return 'unknown_action';
        }
      }
      var unlocked = _save.unlockedLevelIds;
      var results = _save.levelResults;
      if (current['result'] == 'success' &&
          !state.completedLevels.contains(levelId)) {
        final nextIndex = missions.levels.indexOf(levelId) + 1;
        state = service.resupply(
          state.copyWith(
            completedLevels: {...state.completedLevels, levelId},
            levelId: nextIndex < missions.levels.length
                ? missions.levels[nextIndex]
                : levelId,
          ),
        );
        unlocked = {
          ...unlocked,
          if (nextIndex < missions.levels.length) missions.levels[nextIndex],
        };
        results = {
          ...results,
          levelId: {
            'outcome': 'success',
            'seed': current['seed'],
            'history': current['history'],
            'baseline': current['baseline'],
            'elapsed_hours': (current['environment'] as Map)['hours'],
            'assisted':
                ((current['settlement'] as Map?)?['support_count'] as int? ??
                    0) >
                (current['baseline_support'] as int? ?? 0),
            'crew': (current['settlement'] as Map?)?['crew'],
            'completed_at_utc': observation.utc.toIso8601String(),
          },
        };
      }
      await _commit(
        _withProgression(_save, state).copyWith(
          missionJson: jsonEncode(current),
          unlockedLevelIds: unlocked,
          levelResults: results,
          badgeIds: badges,
        ),
      );
      return 'saved';
    });
  }

  /// Progressive presentation access; the underlying service still validates
  /// recipes, costs, crew, prerequisites and concurrency at activation.
  Future<String> startMissionJob({
    required String jobId,
    required String kind,
    required String targetId,
    String? crewId,
  }) {
    final currentOrder = missions.order(progression.levelId);
    if (kind == 'research' &&
        currentOrder < (missions.rules['research_from_level'] as int)) {
      return Future.value('Research is introduced with greenhouse planning.');
    }
    return start(jobId: jobId, kind: kind, targetId: targetId, crewId: crewId);
  }

  ClockObservation _capture() =>
      ClockObservation(token: ++_issuedToken, utc: _utcNow().toUtc());

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      if (_disposed) {
        throw StateError('Campaign controller disposed');
      }
      if (_blocked) {
        throw StateError('Campaign needs reload after a failed save');
      }
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        _blocked = true;
        _wakeUp?.cancel();
        if (!_disposed) {
          notifyListeners();
        }
        rethrow;
      }
    });
    _tail = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return result;
  }

  Future<void> initialize() {
    if (_initialization != null) {
      return _initialization!;
    }
    final observation = _capture();
    return _initialization = _serial(() async {
      final state = service.reconcile(progression, observation: observation);
      await _commit(_withProgression(_save, state));
    });
  }

  CampaignSave _withProgression(CampaignSave save, ProgressionState state) =>
      save.copyWith(
        version: 3,
        progressionJson: jsonEncode(migration.codec.encode(state)),
      );

  Future<void> _commit(CampaignSave next) async {
    // Reconcile cosmetic rewards for old saves too, without issuing resupply.
    next = next.copyWith(
      badgeIds: {
        ...next.badgeIds,
        for (final badge in badgeDefinitions)
          if (next.completedLevelIds.contains(badge['level_id']))
            badge['id'] as String,
      },
      notebookFactIds: {
        ...next.notebookFactIds,
        for (final card in notebookCards)
          if (next.completedLevelIds.contains(card['level_id']))
            card['id'] as String,
      },
    );
    migration.validate(next);
    await store.save(next);
    _save = CampaignSave.decode(next.encode());
    lastError = null;
    if (!_disposed) {
      notifyListeners();
      _schedule();
    }
  }

  void _schedule() {
    _wakeUp?.cancel();
    if (_disposed || _paused || _blocked) {
      return;
    }
    final active = progression.jobs.values.where((j) => j.status == 'active');
    Duration? soonest;
    for (final job in active) {
      final wait = job.clock!.remaining;
      if (soonest == null || wait < soonest) {
        soonest = wait;
      }
    }
    if (soonest != null) {
      _wakeUp = Timer(soonest, () {
        unawaited(
          reconcile().catchError((Object error) {
            // _serial records the error and pauses further mutation.
          }),
        );
      });
    }
  }

  Future<String> _transition(
    ProgressionResult Function(
      RealTimeProgressionService service,
      ProgressionState current,
      ClockObservation observation,
    )
    operation,
  ) {
    // Capture before asynchronous queue delivery, never attach a new token later.
    final observation = _capture();
    final generation = _setupGeneration;
    return _serial(() async {
      if (generation != _setupGeneration) {
        return 'campaign_changed';
      }
      if (!_save.prologueComplete) {
        throw StateError('Complete setup before progression');
      }
      final current = progression;
      if (observation.token <= current.lastObservationToken) {
        return 'stale_observation';
      }
      final result = operation(service, current, observation);
      if (!identical(result.state, current)) {
        await _commit(_withProgression(_save, result.state));
      }
      return result.code;
    });
  }

  Future<void> reconcile() {
    final observation = _capture();
    final generation = _setupGeneration;
    return _serial(() async {
      if (generation != _setupGeneration) {
        return;
      }
      final state = service.reconcile(progression, observation: observation);
      await _commit(_withProgression(_save, state));
    });
  }

  Future<String> start({
    required String jobId,
    required String kind,
    required String targetId,
    String? crewId,
  }) => _transition(
    (s, current, observation) => s.start(
      current,
      jobId: jobId,
      kind: kind,
      targetId: targetId,
      crewId: crewId,
      observation: observation,
    ),
  );
  Future<String> activate(String jobId) => _transition(
    (s, current, observation) =>
        s.activate(current, jobId: jobId, observation: observation),
  );
  Future<String> cancel(String jobId) => _transition(
    (s, current, observation) =>
        s.cancel(current, jobId: jobId, observation: observation),
  );
  Future<String> enqueue({
    required String jobId,
    required String kind,
    required String targetId,
    String? crewId,
  }) => _transition(
    (s, current, observation) => s.enqueue(
      s.reconcile(current, observation: observation),
      jobId: jobId,
      kind: kind,
      targetId: targetId,
      crewId: crewId,
    ),
  );
  Future<String> recover({String? identity}) => _transition(
    (s, current, observation) => s.recover(
      s.reconcile(current, observation: observation),
      identity: identity,
    ),
  );
  Future<String> unpackSpareParts() => _transition(
    (s, current, observation) =>
        s.unpackSpareParts(s.reconcile(current, observation: observation)),
  );

  /// Trusted mission coordination only; the service still validates catalogue
  /// identity and the actual damage transition. No UI creates event authority.
  Future<String> observeDamage({
    required String occurrenceId,
    required int damagedCount,
  }) => _transition(
    (s, current, observation) => s.observeDamage(
      s.reconcile(current, observation: observation),
      occurrenceId: occurrenceId,
      damagedCount: damagedCount,
    ),
  );
  Future<String> confirmDamage(String occurrenceId) => _transition(
    (s, current, observation) => s.confirmDamage(
      s.reconcile(current, observation: observation),
      occurrenceId,
    ),
  );

  /// Reports the existing already-paid field outcome, never executes an action.
  Future<String> recordFieldRepair({
    required String damageId,
    required int damagedCount,
  }) => _transition(
    (s, current, observation) => s.recordFieldRepair(
      s.reconcile(current, observation: observation),
      damageId: damageId,
      damagedCount: damagedCount,
    ),
  );

  Future<void> updateSetting(String key, Object? value) => _serial(() async {
    await _commit(_save.copyWith(settings: {..._save.settings, key: value}));
  });

  List<Map<String, dynamic>> get badgeDefinitions =>
      (migration.repository.campaign['badges'] as List)
          .cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get notebookCards =>
      (migration.repository.document('fact_cards.json')!['cards'] as List)
          .cast<Map<String, dynamic>>();

  Future<String> selectMissionPatch({
    required String color,
    required String emblem,
    required String displayName,
  }) => _serial(() async {
    final options =
        migration.repository.document('badges.json')!['mission_patch'] as Map;
    if (!_save.completedLevelIds.contains(missions.levels.first)) {
      return 'Complete First Light to unlock your patch.';
    }
    if (!(options['colors'] as List).contains(color) ||
        !(options['emblems'] as List).contains(emblem) ||
        displayName.trim().length > 40) {
      return 'Choose a listed color and emblem, and a name up to 40 characters.';
    }
    await _commit(
      _save.copyWith(
        missionPatchId: '$color:$emblem',
        playerDisplayName: displayName.trim(),
      ),
    );
    return 'Patch saved on this device.';
  });

  Future<bool> completePrologue(
    CampaignSave proposed, {
    required int expectedGeneration,
  }) => _serial(() async {
    if (_save.prologueComplete) {
      return true;
    } // Replay is presentation only.
    if (expectedGeneration != _setupGeneration || !proposed.prologueComplete) {
      return false;
    }
    // Setup is the only place legacy presentation input becomes a new base.
    await _commit(
      migration.migrate(proposed.copyWith(settings: _save.settings)),
    );
    _setupGeneration++;
    return true;
  });

  /// Called only by the router's existing explicit reset confirmation.
  Future<void> resetCampaign() => _serial(() async {
    await _commit(migration.migrate(CampaignSave(settings: _save.settings)));
    _setupGeneration++;
  });

  void pause() {
    _paused = true;
    _wakeUp?.cancel();
  }

  Future<void> resume() async {
    _paused = false;
    await initialize();
    await reconcile();
  }

  @override
  void dispose() {
    _disposed = true;
    _wakeUp?.cancel();
    super.dispose();
  }
}
