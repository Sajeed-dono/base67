import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/repositories/game_data_repository.dart';
import '../progression/progression_clock.dart';
import '../progression/progression_service.dart';
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
    store.configure(migration: migration.migrate, validation: migration.validate);
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
  ProgressionState get progression => migration.codec.decode(jsonDecode(_save.progressionJson!));
  RealTimeProgressionService get service => RealTimeProgressionService(migration.config);

  ClockObservation _capture() => ClockObservation(token: ++_issuedToken, utc: _utcNow().toUtc());

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) async {
      if (_disposed) { throw StateError('Campaign controller disposed'); }
      if (_blocked) { throw StateError('Campaign needs reload after a failed save'); }
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        _blocked = true;
        _wakeUp?.cancel();
        if (!_disposed) { notifyListeners(); }
        rethrow;
      }
    });
    _tail = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  Future<void> initialize() {
    if (_initialization != null) { return _initialization!; }
    final observation = _capture();
    return _initialization = _serial(() async {
      final state = service.reconcile(progression, observation: observation);
      await _commit(_withProgression(_save, state));
    });
  }

  CampaignSave _withProgression(CampaignSave save, ProgressionState state) =>
    save.copyWith(version: 3, progressionJson: jsonEncode(migration.codec.encode(state)));

  Future<void> _commit(CampaignSave next) async {
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
    if (_disposed || _paused || _blocked) { return; }
    final active = progression.jobs.values.where((j) => j.status == 'active');
    Duration? soonest;
    for (final job in active) {
      final wait = job.clock!.remaining;
      if (soonest == null || wait < soonest) { soonest = wait; }
    }
    if (soonest != null) {
      _wakeUp = Timer(soonest, () {
        unawaited(reconcile().catchError((Object error) {
          // _serial records the error and pauses further mutation.
        }));
      });
    }
  }

  Future<String> _transition(ProgressionResult Function(
    RealTimeProgressionService service, ProgressionState current, ClockObservation observation,
  ) operation) {
    // Capture before asynchronous queue delivery, never attach a new token later.
    final observation = _capture();
    final generation = _setupGeneration;
    return _serial(() async {
      if (generation != _setupGeneration) { return 'campaign_changed'; }
      if (!_save.prologueComplete) { throw StateError('Complete setup before progression'); }
      final current = progression;
      if (observation.token <= current.lastObservationToken) { return 'stale_observation'; }
      final result = operation(service, current, observation);
      if (!identical(result.state, current)) { await _commit(_withProgression(_save, result.state)); }
      return result.code;
    });
  }

  Future<void> reconcile() {
    final observation = _capture();
    final generation = _setupGeneration;
    return _serial(() async {
      if (generation != _setupGeneration) { return; }
      final state = service.reconcile(progression, observation: observation);
      await _commit(_withProgression(_save, state));
    });
  }

  Future<String> start({required String jobId, required String kind,
    required String targetId, String? crewId}) => _transition((s, current, observation) =>
      s.start(current, jobId: jobId, kind: kind, targetId: targetId,
        crewId: crewId, observation: observation));
  Future<String> activate(String jobId) => _transition((s, current, observation) =>
    s.activate(current, jobId: jobId, observation: observation));
  Future<String> cancel(String jobId) => _transition((s, current, observation) =>
    s.cancel(current, jobId: jobId, observation: observation));
  Future<String> enqueue({required String jobId, required String kind,
    required String targetId, String? crewId}) => _transition((s, current, observation) =>
      s.enqueue(s.reconcile(current, observation: observation), jobId: jobId,
        kind: kind, targetId: targetId, crewId: crewId));
  Future<String> recover({String? identity}) => _transition((s, current, observation) =>
    s.recover(s.reconcile(current, observation: observation), identity: identity));
  Future<String> unpackSpareParts() => _transition((s, current, observation) =>
    s.unpackSpareParts(s.reconcile(current, observation: observation)));

  /// Trusted mission coordination only; the service still validates catalogue
  /// identity and the actual damage transition. No UI creates event authority.
  Future<String> observeDamage({required String occurrenceId, required int damagedCount}) =>
    _transition((s, current, observation) => s.observeDamage(
      s.reconcile(current, observation: observation), occurrenceId: occurrenceId, damagedCount: damagedCount));
  Future<String> confirmDamage(String occurrenceId) =>
    _transition((s, current, observation) => s.confirmDamage(
      s.reconcile(current, observation: observation), occurrenceId));
  /// Reports the existing already-paid field outcome, never executes an action.
  Future<String> recordFieldRepair({required String damageId, required int damagedCount}) =>
    _transition((s, current, observation) => s.recordFieldRepair(
      s.reconcile(current, observation: observation), damageId: damageId, damagedCount: damagedCount));

  Future<void> updateSetting(String key, Object? value) => _serial(() async {
    await _commit(_save.copyWith(settings: {..._save.settings, key: value}));
  });

  Future<bool> completePrologue(CampaignSave proposed, {required int expectedGeneration}) =>
    _serial(() async {
      if (_save.prologueComplete) { return true; } // Replay is presentation only.
      if (expectedGeneration != _setupGeneration || !proposed.prologueComplete) { return false; }
      // Setup is the only place legacy presentation input becomes a new base.
      await _commit(migration.migrate(proposed.copyWith(settings: _save.settings)));
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
