import 'package:shared_preferences/shared_preferences.dart';

import 'campaign_save.dart';

abstract interface class LocalStringStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPreferencesStringStore implements LocalStringStore {
  SharedPreferencesStringStore(this.preferences);

  final SharedPreferencesAsync preferences;

  @override
  Future<String?> getString(String key) => preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      preferences.setString(key, value);
}

class CampaignSaveStore {
  CampaignSaveStore(this.storage, {this.migrate, this.validate});

  factory CampaignSaveStore.local({
    CampaignSave Function(CampaignSave)? migrate,
    void Function(CampaignSave)? validate,
  }) => CampaignSaveStore(
    SharedPreferencesStringStore(SharedPreferencesAsync()),
    migrate: migrate, validate: validate,
  );

  static const storageKey = 'base67.campaign.save.v1';
  static const backupKey = '$storageKey.backup';
  final LocalStringStore storage;
  CampaignSave Function(CampaignSave)? migrate;
  void Function(CampaignSave)? validate;
  Future<void> _tail = Future.value();
  String? _expectedRaw, _lastGoodRaw;
  bool _loaded = false, _uncertain = false;
  bool recoveredFromBackup = false;

  /// Bind the application's repository validator before the first schema-3 IO.
  void configure({
    required CampaignSave Function(CampaignSave) migration,
    required void Function(CampaignSave) validation,
  }) {
    migrate ??= migration;
    validate ??= validation;
  }

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
    return result;
  }

  Future<CampaignSave> load() => _serial(() => _load());

  CampaignSave _prepare(CampaignSave save) {
    final result = migrate?.call(save) ?? save;
    if (result.version == 3 && validate == null) {
      throw const FormatException('Schema 3 needs its progression validator');
    }
    validate?.call(result);
    return result;
  }

  Future<CampaignSave> _load({bool persistMigration = true}) async {
    final primary = await storage.getString(storageKey);
    final backup = await storage.getString(backupKey);
    _loaded = false;
    _uncertain = false;
    recoveredFromBackup = false;
    CampaignSave candidate;
    String? chosen;
    if (primary == null && backup == null) {
      candidate = _prepare(const CampaignSave());
    } else {
      var legacyMigration = false;
      try {
        if (primary == null) {
          throw const FormatException('Primary save missing');
        }
        final decoded = CampaignSave.decode(primary);
        legacyMigration = decoded.version < 3;
        candidate = _prepare(decoded);
        chosen = primary;
      } on UnsupportedSaveVersion {
        // Never downgrade a future-format save to an older backup.
        rethrow;
      } catch (error) {
        // An understood legacy save that cannot migrate needs owner attention;
        // an older backup must not conceal the failure or replace its bytes.
        if (legacyMigration || backup == null) {
          rethrow;
        }
        try {
          candidate = _prepare(CampaignSave.decode(backup));
          chosen = backup;
          recoveredFromBackup = true;
        } catch (backupError) {
          throw FormatException('Primary and backup unavailable; both preserved. $error / $backupError');
        }
      }
    }
    _expectedRaw = primary;
    _lastGoodRaw = chosen;
    _loaded = true;
    // Back up the exact legacy bytes before the first schema-3 write.
    if (persistMigration && !recoveredFromBackup && candidate.version == 3 && candidate.encode() != primary) {
      await _write(candidate);
    }
    return candidate;
  }

  Future<void> save(CampaignSave save) => _serial(() async {
    if (!_loaded) { await _load(persistMigration: false); }
    await _write(_prepare(save));
  });

  Future<void> _write(CampaignSave save) async {
    if (_uncertain) { throw StateError('Save outcome uncertain; reload before changing the campaign'); }
    if (await storage.getString(storageKey) != _expectedRaw) {
      throw StateError('Save changed outside this coordinator; reload required');
    }
    final encoded = save.encode();
    if (encoded == _expectedRaw) { return; }
    final previous = _lastGoodRaw;
    if (previous != null) {
      if (await storage.getString(backupKey) != previous) {
        await storage.setString(backupKey, previous);
      }
      if (await storage.getString(backupKey) != previous) {
        throw StateError('Backup verification failed; primary not written');
      }
    }
    try {
      // One complete primary blob write per accepted state transition.
      await storage.setString(storageKey, encoded);
      final readBack = await storage.getString(storageKey);
      if (readBack != encoded) { throw StateError('Primary read-back mismatch'); }
      _prepare(CampaignSave.decode(readBack!));
      _expectedRaw = encoded;
      _lastGoodRaw = encoded;
    } catch (error) {
      _uncertain = true;
      if (previous != null) {
        try {
          await storage.setString(storageKey, previous);
        } catch (_) {
          // The verified backup remains available even if restoration fails.
        }
      }
      throw StateError('Save not accepted; prior backup retained. Reload required. $error');
    }
  }
}
