import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:base67/app/campaign_save.dart';
import 'package:base67/app/campaign_save_store.dart';
import 'package:base67/app/game_router.dart';
import 'package:base67/data/repositories/game_data_repository.dart';
import 'package:base67/prologue/prologue.dart';
import 'package:base67/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameDataRepository repository;

  setUpAll(() async {
    repository = await GameDataRepository.load();
  });

  test('screen and game files use shared color and typography tokens', () {
    // Exemptions: lib/ui/** contains the theme token definitions, shared
    // widgets, CustomPainter scenery, and CrewBean character art. This rule
    // covers screens and game logic in lib/prologue/** and lib/game/**.
    final violations = <String>[];
    for (final directory in ['lib/prologue', 'lib/game']) {
      for (final entity in Directory(directory).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        if (RegExp(r'\bColor\s*\(\s*0x[0-9a-fA-F]+').hasMatch(source)) {
          violations.add('${entity.path}: hard-coded Color(0x...)');
        }
        if (RegExp(r'\bfontSize\s*:\s*[0-9]+(?:\.[0-9]+)?').hasMatch(source)) {
          violations.add('${entity.path}: fontSize literal');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('prologue setup round-trips saved crew, site, cargo, and campaign', () {
    final save = CampaignSave(
      completedLevelIds: {'L01_first_light'},
      unlockedLevelIds: {'L01_first_light', 'L02_power_storage'},
      crewNames: const {'Commander': 'Ari'},
      crewAges: const {'Commander': 12},
      crewAppearance: const {
        'Commander': {'suit': 2, 'visor': 1, 'face': 1},
      },
      selectedSiteId: 'gale',
      startingCargo: const {'solar_panel': 4, 'battery': 3},
      inventory: const {'solar_panel': 4, 'battery': 3},
      buildingLevels: const {'crew_habitat': 1, 'landing_craft': 1},
      resources: const {'water_kg': 10},
      resourceCapacities: const {'water_kg': 20},
      completedResearchIds: {'solar_energy_fundamentals'},
      prologueComplete: true,
    );
    final loaded = CampaignSave.decode(save.encode());
    expect(loaded.version, 2);
    expect(loaded.crewNames, save.crewNames);
    expect(loaded.crewAges, save.crewAges);
    expect(loaded.crewAppearance, save.crewAppearance);
    expect(loaded.selectedSiteId, 'gale');
    expect(loaded.startingCargo, save.startingCargo);
    expect(loaded.inventory, save.inventory);
    expect(loaded.completedLevelIds, save.completedLevelIds);
    expect(loaded.completedResearchIds, save.completedResearchIds);
    expect(loaded.resources, save.resources);
    expect(loaded.resourceCapacities, save.resourceCapacities);
    expect(loaded.prologueComplete, isTrue);
    final legacy = CampaignSave.decode(
      '{"version":1,"unlockedLevelIds":["L01_first_light"]}',
    );
    expect(legacy.version, 2);
    expect(legacy.unlockedLevelIds, {'L01_first_light'});
  });

  testWidgets('cargo points reject a loadout above the Level 1 budget', (
    tester,
  ) async {
    final mission = Mission();
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.light(),
        home: Scaffold(
          body: CargoScreen(
            mission: mission,
            repository: repository,
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Add Solar panel'));
    await tester.pump();
    expect(find.text('Cargo points: 37 / 34'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm loadout'),
    );
    expect(confirm.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [Size(360, 800), Size(1024, 1366)]) {
    testWidgets(
      'crew, site and cargo setup fit ${viewport.width.toInt()}dp at 1.4x text',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        final mission = Mission();
        Widget shell(Widget child) => MaterialApp(
          theme: Base67Theme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: const TextScaler.linear(1.4),
            ),
            child: Scaffold(body: child),
          ),
        );

        await tester.pumpWidget(
          shell(CrewScreen(mission: mission, onDone: () {})),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'crew setup');

        await tester.pumpWidget(
          shell(
            SiteScreen(
              mission: mission,
              repository: repository,
              seed: 44,
              onDone: () {},
            ),
          ),
        );
        await tester.pump();
        final siteException = tester.takeException();
        expect(siteException, isNull, reason: 'site setup: $siteException');

        await tester.pumpWidget(
          shell(
            CargoScreen(
              mission: mission,
              repository: repository,
              onDone: () {},
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'cargo setup');
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  }

  testWidgets('expired site countdown picks randomly and stays editable', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1100);
    final mission = Mission();
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: Base67Theme.light(),
        home: Scaffold(
          body: SiteScreen(
            mission: mission,
            repository: repository,
            seed: 44,
            onDone: () => continued = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 60));
    expect(find.textContaining('selected at random'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('site-gale')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('site-confirm')));
    await tester.tap(find.byKey(const ValueKey('site-confirm')));
    await tester.pump();
    expect(mission.siteId, 'gale');
    expect(
      find.text('Landing zone confirmed. Mission parameters updated.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('site-confirm')));
    expect(continued, isTrue);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('fake taps finish prologue and arrive at the persistent base', (
    tester,
  ) async {
    final initial = CampaignSave(
      inventory: const {'spare_part': 1},
      completedResearchIds: {'solar_energy_fundamentals'},
      deterministicSeed: 20261105,
      settings: const {'reduceMotion': true},
    );
    final storage = _MemoryStringStore();
    await tester.pumpWidget(
      GameRouter(
        repository: repository,
        store: CampaignSaveStore(storage),
        save: initial,
      ),
    );
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.pushNamed('/prologue');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Skip scene'));
    await tester.pump();
    await tester.tap(find.text('Skip scene'));
    await tester.pump();

    for (final role in ['Commander', 'Engineer', 'Scientist', 'Medic']) {
      final name = find.byKey(ValueKey('crew-name-$role'));
      await tester.ensureVisible(name);
      await tester.enterText(name, '$role Pilot');
      final age = find.byKey(ValueKey('crew-age-$role'));
      await tester.ensureVisible(age);
      await tester.enterText(age, '12');
    }
    final crewSetup = tester.widget<CrewScreen>(find.byType(CrewScreen));
    expect(crewSetup.mission.crew.map((member) => member.name), [
      'Commander Pilot',
      'Engineer Pilot',
      'Scientist Pilot',
      'Medic Pilot',
    ]);
    expect(crewSetup.mission.crew.map((member) => member.age), [
      12,
      12,
      12,
      12,
    ]);
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('crew-confirm')));
    await tester.pump();
    expect(find.textContaining('Four personnel confirmed'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('crew-confirm')));
    await tester.pump();

    expect(find.textContaining('Four Possible Worlds'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('site-gale')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('site-confirm')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('site-confirm')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('cargo-confirm')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('cargo-confirm')));
    await tester.pump();

    for (var scene = 0; scene < 3; scene++) {
      await tester.tap(find.text('Skip scene'));
      await tester.pump();
    }
    expect(find.text('THE MISSION BEGINS'), findsOneWidget);
    await tester.tap(find.text('Go to Home Base'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final saved = CampaignSave.decode(
      storage.values[CampaignSaveStore.storageKey]!,
    );
    expect(saved.prologueComplete, isTrue);
    expect(saved.selectedSiteId, 'gale');
    expect(saved.crewNames['Commander'], 'Commander Pilot');
    expect(saved.crewAges['Medic'], 12);
    expect(saved.startingCargo['solar_panel'], 4);
    expect(saved.inventory['spare_part'], 1);
    expect(saved.inventory['battery'], 3);
    expect(saved.buildingLevels['crew_habitat'], 1);
    expect(saved.unlockedLevelIds, {'L01_first_light'});
    expect(saved.completedLevelIds, initial.completedLevelIds);
    expect(saved.completedResearchIds, initial.completedResearchIds);

    expect(find.text('Your Mars settlement'), findsOneWidget);
    expect(find.textContaining('First Light'), findsWidgets);
    expect(find.text('Landing equipment'), findsOneWidget);
    expect(find.textContaining('Next: First Light'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryStringStore implements LocalStringStore {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
