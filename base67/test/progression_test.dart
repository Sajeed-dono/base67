import 'package:flutter_test/flutter_test.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/progression/timer_completion.dart';
import 'package:base67/sim/seeded_rng.dart';

void main() {
  test('same seed produces the same deterministic sequence', () {
    final first = SeededRng(20261105);
    final retry = SeededRng(20261105);
    expect(
      List.generate(20, (_) => first.nextDouble()),
      List.generate(20, (_) => retry.nextDouble()),
    );
  });

  test('campaign save round-trips its persistent state', () {
    final save = CampaignSave(
      completedLevelIds: {'L01_first_light'},
      unlockedLevelIds: {'L01_first_light', 'L02_power_storage'},
      completedActivityIds: {'build-01'},
      crewNames: {'Commander': 'Ari'},
      selectedSiteId: 'gale',
      inventory: {'solar_panel': 2},
      buildingLevels: {'solar_array': 1},
      resources: {'battery_kwh': 14.5},
      completedResearchIds: {'solar_energy_fundamentals'},
      timerJobs: [
        TimerJobSave(
          id: 'job-01',
          category: 'construction',
          startedAtUtc: DateTime.utc(2026, 11, 7),
          expectedCompletionAtUtc: DateTime.utc(2026, 11, 7, 1),
        ),
      ],
      badgeIds: {'power_systems'},
      notebookFactIds: {'sol_hours'},
      missionPatchId: 'patch-01',
      playerDisplayName: 'Commander Ari',
      eventHistory: ['clear_day'],
      settings: {'reduceMotion': true},
    );
    final restored = CampaignSave.decode(save.encode());
    expect(restored.completedLevelIds, save.completedLevelIds);
    expect(restored.unlockedLevelIds, save.unlockedLevelIds);
    expect(restored.completedActivityIds, save.completedActivityIds);
    expect(restored.crewNames, save.crewNames);
    expect(restored.selectedSiteId, save.selectedSiteId);
    expect(restored.inventory, save.inventory);
    expect(restored.buildingLevels, save.buildingLevels);
    expect(restored.resources, save.resources);
    expect(restored.completedResearchIds, save.completedResearchIds);
    expect(
      restored.timerJobs.single.expectedCompletionAtUtc,
      save.timerJobs.single.expectedCompletionAtUtc,
    );
    expect(restored.badgeIds, save.badgeIds);
    expect(restored.notebookFactIds, save.notebookFactIds);
    expect(restored.missionPatchId, save.missionPatchId);
    expect(restored.playerDisplayName, save.playerDisplayName);
    expect(restored.eventHistory, save.eventHistory);
    expect(restored.settings, save.settings);
  });

  test(
    'campaign save store restores through local key-value storage',
    () async {
      final storage = _MemoryStringStore();
      final store = CampaignSaveStore(storage);
      const save = CampaignSave(
        completedLevelIds: {'L01_first_light'},
        inventory: {'battery': 3},
      );
      await store.save(save);
      final restored = await CampaignSaveStore(storage).load();
      expect(restored.completedLevelIds, save.completedLevelIds);
      expect(restored.inventory, save.inventory);
    },
  );

  test(
    'offline timer completion is due and reward completion is idempotent',
    () {
      final deadline = DateTime.utc(2026, 1, 1, 1);
      expect(
        TimerCompletion.isDue(
          deadlineUtc: deadline,
          nowUtc: DateTime.utc(2026, 1, 1),
        ),
        isFalse,
      );
      expect(
        TimerCompletion.isDue(
          deadlineUtc: deadline,
          nowUtc: DateTime.utc(2026, 1, 1, 2),
        ),
        isTrue,
      );
      final initial = CampaignSave(
        timerJobs: [
          TimerJobSave(
            id: 'build-01',
            category: 'construction',
            startedAtUtc: DateTime.utc(2026, 1, 1),
            expectedCompletionAtUtc: deadline,
          ),
        ],
      );
      final once = TimerCompletion.completeJobOnce(
        save: initial,
        jobId: 'build-01',
        nowUtc: DateTime.utc(2026, 1, 1, 2),
      );
      final restoredAfterRestart = CampaignSave.decode(once.encode());
      final twice = TimerCompletion.completeJobOnce(
        save: restoredAfterRestart,
        jobId: 'build-01',
        nowUtc: DateTime.utc(2026, 1, 1, 3),
      );
      expect(twice.completedActivityIds, {'build-01'});
      expect(twice.timerJobs.single.status, 'completed');
      expect(twice.timerJobs.single.rewardApplied, isTrue);
    },
  );
}

class _MemoryStringStore implements LocalStringStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
