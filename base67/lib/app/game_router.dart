import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/repositories/game_data_repository.dart';
import '../data/validation/data_check_screen.dart';
import '../data/models/data_class.dart';
import '../game/campaign_map_screen.dart';
import '../game/home_base_screen.dart';
import '../prologue/prologue.dart';
import '../ui/crew_bean.dart';
import '../ui/game_widgets.dart';
import '../ui/theme.dart';
import 'campaign_save.dart';
import 'campaign_save_store.dart';
import 'campaign_migration.dart';
import 'campaign_controller.dart';

class GameBootstrap extends StatefulWidget {
  const GameBootstrap({super.key});

  @override
  State<GameBootstrap> createState() => _GameBootstrapState();
}

class _GameBootstrapState extends State<GameBootstrap> {
  late final Future<_LoadedGame> _loading = _load();

  Future<_LoadedGame> _load() async {
    final repository = await GameDataRepository.load();
    final migration = CampaignMigration(repository);
    final store = CampaignSaveStore.local(migrate: migration.migrate, validate: migration.validate);
    final save = await store.load();
    return _LoadedGame(
      repository,
      store,
      save,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_LoadedGame>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return MaterialApp(
          theme: Base67Theme.light(),
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'BASE 67 could not open its saved campaign or bundled data.\n${snapshot.error}',
                ),
              ),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return MaterialApp(
          theme: Base67Theme.light(),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      final game = snapshot.data!;
      return GameRouter(
        repository: game.repository,
        store: game.store,
        save: game.save,
      );
    },
  );
}

class _LoadedGame {
  const _LoadedGame(this.repository, this.store, this.save);
  final GameDataRepository repository;
  final CampaignSaveStore store;
  final CampaignSave save;
}

class GameRouter extends StatefulWidget {
  const GameRouter({
    super.key,
    required this.repository,
    required this.store,
    required this.save,
  });

  final GameDataRepository repository;
  final CampaignSaveStore store;
  final CampaignSave save;

  @override
  State<GameRouter> createState() => _GameRouterState();
}

class _GameRouterState extends State<GameRouter> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final CampaignController _controller;
  Object? _reportedError;
  CampaignSave get _save => _controller.save;

  @override
  void initState() {
    super.initState();
    _controller = CampaignController(repository: widget.repository, store: widget.store, initial: widget.save);
    _controller.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_guard(_controller.initialize()));
    if (widget.store.recoveredFromBackup) {
      _notice('Recovered the previous valid campaign save.');
    }
  }

  void _changed() {
    if (!mounted) { return; }
    setState(() {});
    if (_controller.lastError != null && _controller.lastError != _reportedError) {
      _reportedError = _controller.lastError;
      _notice('Campaign changes were not saved. Reopen BASE 67 to try recovery.');
    }
  }

  void _notice(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) { return; }
      final context = _navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  Future<void> _guard(Future<void> action) async {
    try {
      await action;
    } catch (error) {
      if (!mounted) { return; }
      if (_reportedError != error) {
        _reportedError = error;
        _notice('Campaign changes were not saved. Reopen BASE 67 to try recovery.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_guard(_controller.resume()));
    } else {
      _controller.pause();
    }
  }

  Future<void> _updateSettings(String key, Object? value) =>
      _guard(_controller.updateSetting(key, value));

  Future<void> _completePrologue(CampaignSave updated, int generation) async {
    final accepted = await _controller.completePrologue(updated, expectedGeneration: generation);
    if (!mounted || !accepted) { return; }
    final nav = _navigatorKey.currentState!;
    nav.popUntil((route) => route.isFirst);
    nav.pushReplacementNamed('/home');
  }

  Future<void> _resetCampaign() => _guard(_controller.resetCampaign());

  Widget _prologuePage() {
    final generation = _controller.setupGeneration;
    return Prologue(
      repository: widget.repository,
      initialSave: _save.legacySnapshot(),
      onComplete: (updated) => unawaited(_guard(_completePrologue(updated, generation))),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_changed);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigatorKey,
    debugShowCheckedModeBanner: false,
    title: widget.repository.appTitle,
    theme: Base67Theme.light(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      final scale =
          media.textScaler.scale(1) *
          textScaleFromSetting(_save.settings['textScale']);
      return MediaQuery(
        data: media.copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      );
    },
    initialRoute: '/splash',
    onGenerateRoute: _route,
  );

  Route<void> _route(RouteSettings settings) {
    final path = settings.name ?? '/splash';
    final fixedPrologue = path == '/prologue' ? _prologuePage() : null;
    Widget page() => switch (path) {
      '/splash' => _SplashScreen(
        openHome: () {
          _navigatorKey.currentState!.pushReplacementNamed(
            _save.prologueComplete ? '/home' : '/prologue',
          );
        },
        openPrologue: () {
          _navigatorKey.currentState!.pushNamed('/prologue');
        },
      ),
      '/home' => HomeBaseScreen(
        save: _save,
        repository: widget.repository,
        navigate: (route) {
          _navigatorKey.currentState!.pushNamed(route);
        },
      ),
      '/campaign' => CampaignMapScreen(
        save: _save,
        repository: widget.repository,
        openLevel: (id) {
          _navigatorKey.currentState!.pushNamed('/briefing', arguments: id);
        },
      ),
      '/prologue' => fixedPrologue!,
      '/briefing' => _BriefingScreen(
        repository: widget.repository,
        levelId: settings.arguments is String
            ? settings.arguments! as String
            : null,
        navigate: (route) {
          _navigatorKey.currentState!.pushNamed(route);
        },
      ),
      '/settings' => _SettingsScreen(
        save: _save,
        update: _updateSettings,
        replayPrologue: () =>
            _navigatorKey.currentState!.pushNamed('/prologue'),
        resetCampaign: _resetCampaign,
      ),
      '/data-check' when kDebugMode => DataCheckScreen(
        repository: widget.repository,
      ),
      '/design-gallery' when kDebugMode => _DesignGalleryScreen(
        reducedMotion: _save.settings['reduceMotion'] == true,
      ),
      '/build' => _CatalogScreen(
        title: 'Build',
        intro: 'Choose a facility when the mission unlocks it. Every addition belongs to this base.',
        items: _records(widget.repository, 'buildings.json', 'buildings'),
        saved: _save.buildingLevels,
        unlockedLevelIds: _save.unlockedLevelIds,
      ),
      '/research' => _ResearchScreen(
        repository: widget.repository,
        save: _save,
      ),
      '/crew' => _CrewScreen(save: _save),
      '/notebook' => _NotebookScreen(
        repository: widget.repository,
        save: _save,
      ),
      '/badges' => _SimpleScreen(
        title: 'Badges',
        subtitle: 'Mission badges celebrate the work your crew has completed.',
        icon: Icons.military_tech_rounded,
        body: Text('${_save.badgeIds.length} badge(s) earned'),
      ),
      '/patch' => _SimpleScreen(
        title: 'Mission Patch',
        subtitle: 'Your patch travels with your persistent Mars base.',
        icon: Icons.shield_rounded,
        body: Text(
          _save.missionPatchId ?? 'Choose a patch after it is unlocked.',
        ),
      ),
      '/planning' => const _SimpleScreen(
        title: 'Mission Planning',
        subtitle: 'Review your goal, supplies, and forecast before choosing your next step.',
        icon: Icons.checklist_rounded,
      ),
      '/play' => const _SimpleScreen(
        title: 'Mission',
        subtitle: 'Mission play will be built in a later step. Your campaign state is safe.',
        icon: Icons.rocket_launch_rounded,
      ),
      '/debrief' => const _SimpleScreen(
        title: 'Mission Debrief',
        subtitle: 'Review the choices that helped your crew and base.',
        icon: Icons.fact_check_rounded,
      ),
      '/about' => const _SimpleScreen(
        title: 'About BASE 67',
        subtitle:
            'An offline-first Mars mission trainer for junior astronauts.',
        icon: Icons.info_outline_rounded,
        body: Text('Not yet tested with students.'),
      ),
      '/credits' => _SimpleScreen(
        title: 'Credits',
        subtitle: 'Project credits from the supplied data pack.',
        icon: Icons.favorite_outline_rounded,
        body: Text(
          widget.repository.displayText(
            widget.repository.document('credits.md')?['text'] as String? ??
                'Credits file unavailable.',
          ),
        ),
      ),
      _ => const _SimpleScreen(
        title: 'BASE 67',
        subtitle: 'This screen is not available.',
      ),
    };
    final reduceMotion = _save.settings['reduceMotion'] == true;
    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: reduceMotion ? Duration.zero : GameMotion.short,
      reverseTransitionDuration: reduceMotion
          ? Duration.zero
          : GameMotion.short,
      pageBuilder: (_, _, _) => ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => page(),
      ),
      transitionsBuilder: (_, animation, _, child) => reduceMotion
          ? child
          : FadeTransition(opacity: animation, child: child),
    );
  }

  List<Map<String, dynamic>> _records(
    GameDataRepository repository,
    String file,
    String field,
  ) =>
      (repository.document(file)?[field] as List?)
          ?.whereType<Map<String, dynamic>>()
          .toList() ??
      const [];
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.openHome, required this.openPrologue});
  final VoidCallback openHome;
  final VoidCallback openPrologue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.public_rounded,
                  size: 70,
                  color: GameColors.rust,
                ),
                const SizedBox(height: 12),
                Text(
                  'BASE 67',
                  style: Theme.of(context).textTheme.displaySmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'A new home begins with one good plan.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                GameButton(
                  label: 'Open Home Base',
                  icon: Icons.home_rounded,
                  expand: true,
                  onPressed: openHome,
                ),
                const SizedBox(height: 10),
                GameButton(
                  label: 'Watch the prologue',
                  icon: Icons.play_circle_outline_rounded,
                  expand: true,
                  secondary: true,
                  onPressed: openPrologue,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _BriefingScreen extends StatelessWidget {
  const _BriefingScreen({
    required this.repository,
    required this.levelId,
    required this.navigate,
  });
  final GameDataRepository repository;
  final String? levelId;
  final ValueChanged<String> navigate;

  @override
  Widget build(BuildContext context) {
    final levels =
        (repository.campaign['levels'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const [];
    final level =
        levels.where((item) => item['id'] == levelId).firstOrNull ??
        levels.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Briefing')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          Text(
            level?['name'] as String? ?? 'Choose a mission',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          FactCard(
            title: 'What you will learn',
            body:
                level?['learning_objective'] as String? ??
                'Choose an available campaign goal.',
            dataClass: DataClass.game,
          ),
          FactCard(
            title: 'Mission goal',
            body: level?['mission_objective'] as String? ?? '',
            dataClass: DataClass.game,
          ),
          const SizedBox(height: 12),
          GameButton(
            label: 'Review mission plan',
            icon: Icons.checklist_rounded,
            expand: true,
            onPressed: () => navigate('/planning'),
          ),
        ],
      ),
    );
  }
}

class _SimpleScreen extends StatelessWidget {
  const _SimpleScreen({
    required this.title,
    required this.subtitle,
    this.icon,
    this.body,
  });
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget? body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(GameSpacing.page),
          children: [
            if (icon != null) Icon(icon, size: 56, color: GameColors.teal),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: 16),
              InfoCard(child: body!),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CatalogScreen extends StatelessWidget {
  const _CatalogScreen({
    required this.title,
    required this.intro,
    required this.items,
    required this.saved,
    required this.unlockedLevelIds,
  });
  final String title;
  final String intro;
  final List<Map<String, dynamic>> items;
  final Map<String, int> saved;
  final Set<String> unlockedLevelIds;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(GameSpacing.page),
      children: [
        Text(intro),
        const SizedBox(height: 10),
        for (final item in items)
          BuildingCard(
            name: item['name'] as String? ?? 'Facility',
            level: saved[item['id']] ?? 0,
            state: saved[item['id']] != null
                ? 'Built on this base'
                : unlockedLevelIds.contains(item['introduced_level_id'])
                ? 'Ready for construction'
                : 'Locked until its mission',
            upgrade: (item['upgrade_options'] as List?)?.firstOrNull as String?,
          ),
      ],
    ),
  );
}

class _ResearchScreen extends StatelessWidget {
  const _ResearchScreen({required this.repository, required this.save});
  final GameDataRepository repository;
  final CampaignSave save;

  @override
  Widget build(BuildContext context) {
    final entries =
        (repository.document('research.json')?['projects'] as List?)
            ?.whereType<Map<String, dynamic>>() ??
        const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Research')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          const Text('Learn how each technology can support your base.'),
          for (final entry in entries)
            ResearchCard(
              name:
                  entry['name'] as String? ??
                  entry['id'] as String? ??
                  'Research topic',
              prerequisites:
                  (entry['prerequisites'] as List?)?.join(', ') ??
                  'Mission unlock',
              state: save.completedResearchIds.contains(entry['id'])
                  ? 'Completed'
                  : 'Not started',
            ),
        ],
      ),
    );
  }
}

class _CrewScreen extends StatelessWidget {
  const _CrewScreen({required this.save});
  final CampaignSave save;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crew')),
    body: ListView(
      padding: const EdgeInsets.all(GameSpacing.page),
      children: [
        const Text('Four roles help your settlement work together.'),
        for (final role in CrewRole.values)
          CrewAssignmentCard(
            name: save.crewNames[_roleLabel(role)] ?? _roleLabel(role),
            role: _roleLabel(role),
            task: 'Ready for a mission task',
            status: 'At the base',
          ),
      ],
    ),
  );
}

String _roleLabel(CrewRole role) => switch (role) {
  CrewRole.commander => 'Commander',
  CrewRole.engineer => 'Engineer',
  CrewRole.scientist => 'Scientist',
  CrewRole.medic => 'Medic',
};

class _NotebookScreen extends StatelessWidget {
  const _NotebookScreen({required this.repository, required this.save});
  final GameDataRepository repository;
  final CampaignSave save;

  @override
  Widget build(BuildContext context) {
    final cards =
        (repository.document('fact_cards.json')?['cards'] as List?)
            ?.whereType<Map<String, dynamic>>() ??
        const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Mars Notebook')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          for (final card in cards)
            if (save.notebookFactIds.contains(card['id']) ||
                save.notebookFactIds.isEmpty)
              FactCard(
                title: card['title'] as String? ?? 'Mars fact',
                body:
                    card['body'] as String? ??
                    card['template'] as String? ??
                    'A new fact will appear as your crew learns.',
                dataClass: DataClass.nasa,
              ),
          if (cards.isEmpty)
            const Text(
              'New notebook facts appear as you explore the campaign.',
            ),
        ],
      ),
    );
  }
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.save,
    required this.update,
    required this.replayPrologue,
    required this.resetCampaign,
  });
  final CampaignSave save;
  final Future<void> Function(String key, Object? value) update;
  final VoidCallback replayPrologue;
  final Future<void> Function() resetCampaign;

  @override
  Widget build(BuildContext context) {
    final scale = textScaleFromSetting(save.settings['textScale']);
    final reduced = save.settings['reduceMotion'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(GameSpacing.page),
        children: [
          Text('Text size', style: Theme.of(context).textTheme.titleLarge),
          const Text('Choose a size that feels comfortable.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final option in textScaleOptions)
                ChoiceChip(
                  label: Text('$option×'),
                  selected: scale == option,
                  onSelected: (_) => update('textScale', option),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce motion'),
            subtitle: const Text('Turn off looping astronaut movement.'),
            value: reduced,
            onChanged: (value) => update('reduceMotion', value),
          ),
          const SizedBox(height: 12),
          const DaveBubble(
            message: 'Your preferences are saved on this device.',
          ),
          const SizedBox(height: 18),
          GameButton(
            label: 'Replay prologue',
            icon: Icons.replay_rounded,
            secondary: true,
            onPressed: replayPrologue,
          ),
          const SizedBox(height: GameSpacing.sm),
          GameButton(
            label: 'Reset campaign',
            icon: Icons.restart_alt_rounded,
            onPressed: () => _confirmReset(context),
          ),
          if (kDebugMode) ...[
            GameButton(
              label: 'Debug Design Gallery',
              icon: Icons.palette_outlined,
              onPressed: () =>
                  Navigator.of(context).pushNamed('/design-gallery'),
            ),
            const SizedBox(height: 8),
            GameButton(
              label: 'Debug Data Check',
              icon: Icons.fact_check_outlined,
              onPressed: () => Navigator.of(context).pushNamed('/data-check'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset this campaign?'),
        content: const Text(
          'This removes the saved crew, base, and mission progress from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep campaign'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset campaign'),
          ),
        ],
      ),
    );
    if (reset == true) await resetCampaign();
  }
}

class _DesignGalleryScreen extends StatelessWidget {
  const _DesignGalleryScreen({required this.reducedMotion});
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Debug Design Gallery')),
    body: ListView(
      padding: const EdgeInsets.all(GameSpacing.page),
      children: [
        for (final role in CrewRole.values) ...[
          Text(_roleLabel(role), style: Theme.of(context).textTheme.titleLarge),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final mood in CrewMood.values)
                CrewBean(
                  role: role,
                  mood: mood,
                  size: 68,
                  reducedMotion: reducedMotion,
                  label: mood.name,
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        const FactCard(
          title: 'Data chip example',
          body: 'A source-backed value is labelled clearly.',
          dataClass: DataClass.nasa,
        ),
        TimerCard(
          activity: 'Example research',
          deadlineUtc: DateTime(2027),
          outcome: 'A new idea is ready.',
        ),
        const BuildingCard(name: 'Solar Array', level: 1, state: 'Built'),
        const ResearchCard(
          name: 'Solar Basics',
          prerequisites: 'First Light',
          state: 'Ready',
        ),
      ],
    ),
  );
}
