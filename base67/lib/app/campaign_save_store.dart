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
  CampaignSaveStore(this.storage);

  factory CampaignSaveStore.local() =>
      CampaignSaveStore(SharedPreferencesStringStore(SharedPreferencesAsync()));

  static const storageKey = 'base67.campaign.save.v1';
  final LocalStringStore storage;

  Future<CampaignSave> load() async {
    final value = await storage.getString(storageKey);
    return value == null ? const CampaignSave() : CampaignSave.decode(value);
  }

  Future<void> save(CampaignSave save) =>
      storage.setString(storageKey, save.encode());
}
