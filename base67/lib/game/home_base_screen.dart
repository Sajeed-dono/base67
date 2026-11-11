import 'package:flutter/material.dart';

import '../app/campaign_save.dart';
import '../data/models/data_class.dart';
import '../data/repositories/game_data_repository.dart';
import '../ui/crew_bean.dart';
import '../ui/crew_movement.dart';
import '../ui/settlement_map.dart';
import '../ui/settlement_snapshot.dart';
import '../ui/game_widgets.dart';
import '../ui/mars_base_painter.dart';
import '../ui/theme.dart';
import '../ui/settlement_status_panel.dart';
import '../sim/sim_state.dart';
import '../progression/progression_service.dart';
import '../sim/simulation_clock.dart';

class HomeBaseScreen extends StatelessWidget {
  const HomeBaseScreen({
    super.key,
    required this.save,
    required this.repository,
    required this.navigate,
    this.movement,
    this.world,
    this.progression,
    this.generationKw,
    this.solHours,
    this.daylightHours,
  });

  final CampaignSave save;
  final CrewMovement? movement;
  final GameDataRepository repository;
  final ValueChanged<String> navigate;
  final SimState? world;
  final ProgressionState? progression;
  final double? generationKw;
  final double? solHours, daylightHours;

  @override
  Widget build(BuildContext context) {
    final chapters = (repository.campaign['chapters'] as List?) ?? const [];
    final levels = (repository.campaign['levels'] as List?) ?? const [];
    final unlocked = save.unlockedLevelIds;
    final nextLevel = levels.cast<Map<String, dynamic>>().firstWhere(
      (level) =>
          unlocked.contains(level['id']) &&
          !save.completedLevelIds.contains(level['id']),
      orElse: () => levels.isNotEmpty
          ? levels.first as Map<String, dynamic>
          : <String, dynamic>{},
    );
    final nextTitle = nextLevel['name'] as String? ?? 'Campaign briefing';
    final chapterId = nextLevel['chapter_id'];
    final chapter = chapters
        .cast<Map<String, dynamic>>()
        .where((item) => item['id'] == chapterId)
        .firstOrNull;
    final chapterName = chapter?['name'] as String? ?? 'Chapter 1';
    final facilities = settlementFacilities(save);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: GameColors.night,
      appBar: AppBar(
        title: Text(repository.appTitle),
        backgroundColor: GameColors.night,
        foregroundColor: GameColors.sand,
        actions: [
          IconButton(
            tooltip: 'Campaign Map',
            icon: const Icon(Icons.route_rounded),
            onPressed: () => navigate('/campaign'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => navigate('/settings'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              width >= 720 ? 20 : 0,
              0,
              width >= 720 ? 20 : 0,
              28,
            ),
            children: [
              _Header(nextTitle: nextTitle, chapterName: chapterName),
              if (world != null) ...[
                const SizedBox(height: GameSpacing.md),
                SettlementStatusPanel(
                  world: world!,
                  generationKw: generationKw,
                ),
              ],
              const SizedBox(height: 14),
              if (width >= 720)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _baseMap(context, facilities)),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _sidePanel(context, nextTitle)),
                  ],
                )
              else ...[
                _baseMap(context, facilities),
                const SizedBox(height: 14),
                _resourceSummary(context),
                const SizedBox(height: 14),
                _crewPanel(context),
                const SizedBox(height: 14),
                _equipmentSummary(context),
                const SizedBox(height: 14),
                _nextMission(context, nextTitle, chapterName),
              ],
              const SizedBox(height: 16),
              _navigationGrid(context),
              if (progression != null &&
                  progression!.jobs.values.any(
                    (job) =>
                        !const {'completed', 'cancelled'}.contains(job.status),
                  )) ...[
                const SizedBox(height: GameSpacing.md),
                SavedJobsPanel(
                  jobs: progression!.jobs.values.where(
                    (job) =>
                        !const {'completed', 'cancelled'}.contains(job.status),
                  ),
                  onManage: () => navigate('/build'),
                ),
              ] else if (progression == null &&
                  save.timerJobs
                      .where((job) => job.status == 'active')
                      .isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Work in progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final job in save.timerJobs.where(
                  (job) => job.status == 'active',
                ))
                  TimerCard(
                    activity: job.targetId ?? job.category,
                    deadlineUtc: job.expectedCompletionAtUtc,
                    outcome: 'Your base gains the planned upgrade.',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _baseMap(BuildContext context, List<MarsFacility> facilities) =>
      MarsPanel(
        padding: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(GameRadii.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettlementMap(
                facilities: facilities,
                crew: MapCrew.fromSave(save),
                movement: movement,
                reducedMotion: save.settings['reduceMotion'] == true,
                night:
                    world != null &&
                    solHours != null &&
                    daylightHours != null &&
                    SimulationClock.hourOfSol(world!.elapsedHours, solHours!) >=
                        daylightHours!,
                storm:
                    world?.activeEvents['dust_storm'] != null &&
                    world!.activeEvents['dust_storm']!.endHour >
                        world!.elapsedHours,
                dust: world?.dust ?? 0,
                onManage: navigate,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, color: GameColors.rust),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(switch (save.selectedSiteId) {
                        null => 'Landing site not selected yet',
                        'gale' => 'Gale Crater',
                        'arcadia' => 'Arcadia Planitia',
                        'deuteronilus' => 'Deuteronilus Mensae',
                        'equatorial_plain' => 'Equatorial Plain',
                        final site => site,
                      }, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Icon(Icons.public_rounded, color: GameColors.teal),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sidePanel(BuildContext context, String nextTitle) => Column(
    children: [
      _resourceSummary(context),
      const SizedBox(height: 14),
      _crewPanel(context),
      const SizedBox(height: 14),
      _equipmentSummary(context),
      const SizedBox(height: 14),
      _nextMission(context, nextTitle, 'Current Chapter'),
    ],
  );

  Widget _resourceSummary(BuildContext context) {
    final entries = <(String, String)>[
      ('Power', 'battery_kwh'),
      ('Water', 'water_kg'),
      ('Food', 'food_kg'),
      ('Oxygen', 'oxygen_kg'),
    ];
    return MarsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Base reserves', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Your stored amounts stay with this base.'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final entry in entries)
                SizedBox(
                  width: 125,
                  child: _ResourceAmount(
                    name: entry.$1,
                    amount: save.resources[entry.$2],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _crewPanel(BuildContext context) {
    const roles = CrewRole.values;
    const sourceRoles = ['Commander', 'Engineer', 'Scientist', 'Medic'];
    return MarsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your crew', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < roles.length; i++)
                CrewBean(
                  role: roles[i],
                  label: save.crewNames[sourceRoles[i]] ?? sourceRoles[i],
                  suitColorIndex:
                      save.crewAppearance[sourceRoles[i]]?['suit'] ?? 0,
                  visorTintIndex:
                      save.crewAppearance[sourceRoles[i]]?['visor'] ?? 0,
                  faceStyleIndex:
                      save.crewAppearance[sourceRoles[i]]?['face'] ?? 0,
                  size: 60,
                  reducedMotion: save.settings['reduceMotion'] == true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _equipmentSummary(BuildContext context) {
    final equipment =
        (repository.document('equipment.json')?['equipment'] as List? ??
                const [])
            .whereType<Map<String, dynamic>>();
    final names = {for (final item in equipment) item['id']: item['name']};
    final inventory = save.inventory.entries
        .where((entry) => entry.value > 0)
        .toList();
    return MarsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Landing equipment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: GameSpacing.xs),
          if (inventory.isEmpty)
            const Text('Equipment appears here after cargo is confirmed.')
          else
            for (final item in inventory)
              Text('${names[item.key] ?? item.key}: ${item.value}'),
          const SizedBox(height: GameSpacing.xs),
          const DataChip(DataClass.game),
        ],
      ),
    );
  }

  Widget _nextMission(BuildContext context, String nextTitle, String chapter) =>
      MarsPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: GameColors.teal),
            ),
            const SizedBox(height: 4),
            Text(
              'Next goal: $nextTitle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a mission when you are ready. Your base stays with you.',
            ),
            const SizedBox(height: 12),
            GameButton(
              label: 'Continue mission',
              icon: Icons.rocket_launch_rounded,
              expand: true,
              onPressed: () => navigate(
                save.missionJson == null ? '/campaign' : '/resume-mission',
              ),
            ),
          ],
        ),
      );

  Widget _navigationGrid(BuildContext context) {
    final actions = <(String, IconData, String)>[
      ('Campaign Map', Icons.route_rounded, '/campaign'),
      ('Build', Icons.home_work_rounded, '/build'),
      ('Research', Icons.science_rounded, '/research'),
      ('Crew', Icons.groups_rounded, '/crew'),
      ('Mars Notebook', Icons.menu_book_rounded, '/notebook'),
      ('Badges', Icons.military_tech_rounded, '/badges'),
      ('Mission Patch', Icons.shield_rounded, '/patch'),
      ('Settings', Icons.tune_rounded, '/settings'),
      ('About', Icons.info_outline_rounded, '/about'),
      ('Credits', Icons.favorite_outline_rounded, '/credits'),
      if (save.completedLevelIds.containsAll(
        (repository.campaign['levels'] as List).map(
          (row) => (row as Map)['id'] as String,
        ),
      ))
        ('Certificate', Icons.school_rounded, '/certificate'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth < 520 ? 2 : 4,
          mainAxisExtent: 66,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) => _NavTile(
          label: actions[index].$1,
          icon: actions[index].$2,
          onTap: () => navigate(actions[index].$3),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.nextTitle, required this.chapterName});
  final String nextTitle;
  final String chapterName;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOME BASE',
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: GameColors.tealLight, letterSpacing: 1.3),
        ),
        Text(
          'Your Mars settlement',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: GameColors.sand),
        ),
        Text(
          '$chapterName · Next: $nextTitle',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}

class _ResourceAmount extends StatelessWidget {
  const _ResourceAmount({required this.name, required this.amount});
  final String name;
  final double? amount;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 80),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: GameColors.paper,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: GameColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleSmall),
        Text(amount == null ? '—' : amount!.toStringAsFixed(1)),
        const DataChip(DataClass.game),
      ],
    ),
  );
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.paper,
          foregroundColor: GameColors.ink,
          elevation: 3,
          side: const BorderSide(color: GameColors.ink, width: 2),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: GameColors.rust),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, softWrap: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
