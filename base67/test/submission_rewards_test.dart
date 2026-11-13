import 'dart:convert';

import 'package:base67/app/campaign_controller.dart';
import 'package:base67/app/campaign_migration.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/game/rewards_screen.dart';
import 'package:base67/game/mission_screen.dart';
import 'package:base67/progression/progression_clock.dart';
import 'package:base67/progression/progression_service.dart';
import 'package:base67/ui/theme.dart';
import 'package:base67/ui/game_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;
  late CampaignMigration migration;
  final now = DateTime.utc(2026, 11, 13);
  setUpAll(() async {
    repository = await GameDataRepository.load();
    migration = CampaignMigration(repository);
  });
  CampaignSave initial() => migration.migrate(
    const CampaignSave(
      prologueComplete: true,
      selectedSiteId: 'gale',
      buildingLevels: {'crew_habitat': 1},
    ),
  );

  test('existing completions reconcile cosmetics once without changing supplies or receipts', () async {
    final start = initial();
    final p = migration.codec.decode(jsonDecode(start.progressionJson!));
    final done = p.copyWith(
      completedLevels: migration.config.levels.take(2).toSet(),
      levelId: migration.config.levels[2],
    );
    final storage = _Memory();
    final c = CampaignController(
      repository: repository,
      store: CampaignSaveStore(storage),
      initial: start.copyWith(
        progressionJson: jsonEncode(migration.codec.encode(done)),
        unlockedLevelIds: migration.config.levels.take(3).toSet(),
      ),
      utcNow: () => now,
    );
    addTearDown(c.dispose);
    await c.initialize();
    expect(c.save.notebookFactIds, {'sunlight', 'martian_day'});
    expect(c.save.badgeIds, {'night_owl'});
    expect(c.progression.resources, done.resources);
    expect(
      migration.codec.encode(c.progression)['receipts'],
      migration.codec.encode(done)['receipts'],
    );
    expect(
      await c.selectMissionPatch(
        color: 'invalid',
        emblem: 'star',
        displayName: '',
      ),
      contains('Choose'),
    );
    expect(c.save.missionPatchId, isNull);
    expect(
      await c.selectMissionPatch(
        color: 'teal',
        emblem: 'sun',
        displayName: '  Nova  ',
      ),
      contains('saved'),
    );
    await c.reconcile();
    final restored = await CampaignSaveStore(
      storage,
      migrate: migration.migrate,
      validate: migration.validate,
    ).load();
    expect(restored.notebookFactIds, c.save.notebookFactIds);
    expect(restored.badgeIds, {'night_owl'});
    expect(restored.missionPatchId, 'teal:sun');
    expect(restored.playerDisplayName, 'Nova');
    expect(c.progression.resources, done.resources);
  });

  test('new pacing preserves exact legacy job snapshots and rejects unknown durations', () {
    final config = migration.config;
    final oldTimers = jsonDecode(
      jsonEncode(repository.document('timer_rules.json')),
    ) as Map<String, dynamic>;
    for (final row in oldTimers['timers'] as List) {
      if (row['id'] == 'solar_panel_installation') {
        row['duration_seconds'] = 300;
        row['duration_seconds_min'] = 300;
        row['duration_seconds_max'] = 900;
      }
    }
    final old = ProgressionConfig.fromDocuments(
      buildings: repository.document('buildings.json')!,
      research: repository.document('research.json')!,
      timers: oldTimers,
      crew: repository.document('crew_assignments.json')!,
      rules: repository.document('progression_rules.json')!,
      equipment: repository.document('equipment.json')!,
      events: repository.document('events.json')!,
    );
    final service = RealTimeProgressionService(old);
    final p = migration.codec.decode(jsonDecode(initial().progressionJson!));
    final active = service
        .start(
          p,
          jobId: 'legacy',
          kind: 'construction',
          targetId: 'solar_array',
          crewId: 'Engineer',
          observation: ClockObservation(token: 0, utc: now),
        )
        .state;
    final encoded = migration.codec.encode(active);
    final restored = migration.codec.decode(encoded);
    expect(
      restored.jobs['legacy']!.clock!.remaining,
      const Duration(minutes: 5),
    );
    expect(
      restored.jobs['legacy']!.recipe.duration,
      const Duration(minutes: 5),
    );
    expect(restored.resources, active.resources);
    expect(restored.crewAssignments, active.crewAssignments);
    expect(
      config.recipes['construction:solar_array']!.duration.inSeconds,
      inInclusiveRange(5, 10),
    );
    expect(
      config.recipes.values
          .where((r) => r.kind == 'upgrade' || r.kind == 'research')
          .every(
            (r) => r.duration.inSeconds >= 20 && r.duration.inSeconds <= 60,
          ),
      isTrue,
    );
    (encoded['jobs'] as Map)['legacy']['recipe']['durationMicros'] = 123456;
    expect(() => migration.codec.decode(encoded), throwsFormatException);
  });

  testWidgets(
    'empty notebook hides facts; every configured discovery resolves a bundled source',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.light(),
          home: NotebookScreen(repository: repository, save: initial()),
        ),
      );
      expect(find.text('Sunlight powers the base'), findsNothing);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is GameCopy &&
              widget.text.contains('Complete First Light'),
        ),
        findsOneWidget,
      );
      for (final card
          in repository.document('fact_cards.json')!['cards'] as List) {
        final fact = repository.fact(card['fact_id'] as String)!;
        expect(fact.sourceIds, isNotEmpty);
        expect(
          fact.sourceIds.every((id) => repository.source(id) != null),
          isTrue,
        );
        expect(migration.config.levels, contains(card['level_id']));
      }
    },
  );

  testWidgets(
    'starting and completing a mission brings its feedback back into view',
    (tester) async {
      final save = migration.migrate(
        const CampaignSave(
          prologueComplete: true,
          selectedSiteId: 'gale',
          buildingLevels: {'crew_habitat': 1, 'solar_array': 1},
        ),
      );
      final c = CampaignController(
        repository: repository,
        store: CampaignSaveStore(_Memory()),
        initial: save,
        utcNow: () => now,
      );
      addTearDown(c.dispose);
      final id = c.missions.levels.first;
      await c.initialize();
      await c.missionAction(id, 'open');
      await c.missionAction(id, 'review');
      await c.missionAction(id, 'plan');
      await c.missionAction(
        id,
        'learn',
        value: c.missions.definition(id)['answer'] as String,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.missionControl(),
          home: ListenableBuilder(
            listenable: c,
            builder: (context, _) => MissionScreen(
              controller: c,
              repository: repository,
              levelId: id,
              navigate: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      ScrollPosition page() =>
          tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      page().jumpTo(500);
      await tester.pump();
      await tester.tap(find.widgetWithText(GameButton, 'Start mission'));
      await tester.pumpAndSettle();
      expect(c.mission!['phase'], 'play');
      expect(page().pixels, 0);
      page().jumpTo(500);
      await tester.pump();
      await tester.tap(find.widgetWithText(GameButton, 'Advance one step'));
      await tester.pumpAndSettle();
      expect(c.mission!['result'], 'success');
      expect(page().pixels, 0);
      expect(find.byWidgetPredicate((widget) => widget is ColonySectionHeading &&
        widget.title == 'Expedition progress saved').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'patch unlock is enforced and enlarged controls fit a narrow phone',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final c = CampaignController(
        repository: repository,
        store: CampaignSaveStore(_Memory()),
        initial: initial(),
        utcNow: () => now,
      );
      addTearDown(c.dispose);
      expect(
        await c.selectMissionPatch(
          color: 'teal',
          emblem: 'sun',
          displayName: '',
        ),
        contains('Complete First Light'),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: Base67Theme.missionControl(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: PatchScreen(controller: c),
        ),
      );
      expect(find.text('Patch locked'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _Memory implements LocalStringStore {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
