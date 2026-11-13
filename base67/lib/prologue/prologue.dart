// BASE 67 — Prologue (8 scenes). Drop into a fresh `flutter create base67` project.
// Story dialogue is sourced from docs/source/BASE_67_Prologue_Preview.pdf.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/repositories/game_data_repository.dart';
import '../data/validation/data_check_screen.dart';
import '../app/campaign_save.dart';
import '../data/models/data_class.dart';
import '../sim/seeded_rng.dart';
import '../ui/crew_bean.dart';
import '../ui/game_widgets.dart';
import '../ui/prologue_scenery.dart';
import '../ui/theme.dart';

ThemeData _prologueTheme() {
  final base = Base67Theme.missionControl();
  final shape = BeveledRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    side: const BorderSide(color: GameColors.prologueBorder),
  );
  return base.copyWith(
    scaffoldBackgroundColor: GameColors.prologueBackground,
    cardTheme: base.cardTheme.copyWith(
      color: GameColors.prologuePanel,
      elevation: 0,
      shape: shape,
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: GameColors.prologueBackground,
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: GameColors.prologueTeal, width: 2),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: GameColors.prologueAmber, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(
          Size(GameSpacing.touchTarget, GameSpacing.primaryButtonHeight),
        ),
        foregroundColor: const WidgetStatePropertyAll(GameColors.paper),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? GameColors.controlRaised
              : GameColors.prologueOrange,
        ),
        shape: WidgetStatePropertyAll(shape),
        elevation: const WidgetStatePropertyAll(2),
        shadowColor: const WidgetStatePropertyAll(GameColors.prologueOrange),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GameColors.prologueTeal,
        side: const BorderSide(color: GameColors.prologueBorder),
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: GameColors.prologueTeal),
    ),
  );
}

// ---------------------------------------------------------------- data

class Line {
  final String text;
  final String? who;
  const Line(this.text, [this.who]);
}

class Cine {
  final String title, place;
  final List<Line> lines;
  final String? endCard;
  const Cine(this.title, this.place, this.lines, {this.endCard});
}

const cine1 = Cine('Scene 1 -- The Last Year', 'BLACK SCREEN', [
  Line(
    'Good evening. We begin tonight with an urgent update from the International Climate Emergency Council. Scientists warn that a chain reaction of climate disasters is accelerating faster than expected. Food production is failing, freshwater supplies are shrinking, and extreme weather is disrupting life across the globe.',
    'NEWS PRESENTER',
  ),
  Line(
    'Governments worldwide have declared a state of emergency. Despite international efforts, the situation continues to deteriorate.',
    'NEWS PRESENTER',
  ),
  Line(
    'Officials now warn that Earth may become unable to sustain human civilization within the next year.',
    'NEWS PRESENTER',
  ),
  Line(
    'With humanity facing an uncertain future, the world’s attention is turning beyond Earth. Scientists and space agencies are racing to determine whether another world could offer us a chance to survive.',
    'NEWS PRESENTER',
  ),
], endCard: 'BASE 67');

const cine2 = Cine(
  'Scene 2 -- The Calling',
  'INT. SPACE OPERATIONS FACILITY -- NIGHT',
  [
    Line('The protagonist stands alone, gazing at the spacecraft.'),
    Line('Quite a sight.', 'COMMANDER'),
    Line('It’s everything I imagined.', 'PROTAGONIST'),
    Line('Almost.', 'PROTAGONIST'),
    Line('Then you understand why I’ve called you here.', 'COMMANDER'),
    Line(
      'Our first expedition lost contact seconds before touchdown. We received no landing confirmation. No distress signal. Nothing.',
      'COMMANDER',
    ),
    Line(
      'They could have landed anywhere within these zones. We don’t know whether the crew survived.',
      'COMMANDER',
    ),
    Line('Then we find them.', 'PROTAGONIST'),
    Line(
      'That’s the first objective. The second is to investigate possible signs of life and determine whether Mars can support a permanent human outpost.',
      'COMMANDER',
    ),
    Line(
      'But understand what you’re walking into. Radiation, extreme temperatures, dust storms. Limited power, water, food, and air. Every decision will have consequences.',
      'COMMANDER',
    ),
    Line('Then we’ll make every resource count.', 'PROTAGONIST'),
    Line(
      'Your transport has a strict cargo limit. You’ll have to decide what the mission needs most. You’ll also receive a personalized AI assistant, Dave. He’ll monitor your systems, track resources, analyse threats, and help you make informed decisions.',
      'COMMANDER',
    ),
    Line('And the final call?', 'PROTAGONIST'),
    Line('Always yours.', 'COMMANDER'),
    Line(
      'Earth has given us a year. We can’t afford to waste it.',
      'PROTAGONIST',
    ),
    Line('You know this mission may cost you everything.', 'COMMANDER'),
    Line('I know.', 'PROTAGONIST'),
    Line(
      'But if there’s a chance to save our people, find something that changes our future, or build a place where humanity can survive… I’m taking it.',
      'PROTAGONIST',
    ),
    Line('Are you ready to take command?', 'COMMANDER'),
    Line('I’m ready.', 'PROTAGONIST'),
    Line(
      'Then there’s one more thing. You may take three people with you. Choose carefully. Out there, they’re more than your crew. They’re the people you’ll depend on when everything goes wrong.',
      'COMMANDER',
    ),
    Line('I already have three people in mind.', 'PROTAGONIST'),
    Line('Then let’s bring your team together.', 'COMMANDER'),
  ],
);

const cine6 = Cine(
  'Scene 6 -- The Final Goodbye',
  'INT. SPACE OPERATIONS FACILITY -- LAUNCH PREPARATION AREA',
  [
    Line(
      'The four astronauts stand before the Commander, now dressed in their launch suits. For the first time, the mission feels real.',
    ),
    Line(
      'You’ve chosen your team. You’ve chosen your destination. And you’ve made your decisions about what to take.',
      'COMMANDER',
    ),
    Line(
      'From here on, you’ll face situations we can’t predict and problems we can’t solve for you.',
      'COMMANDER',
    ),
    Line(
      'Good luck, Commander. Bring your crew home. And if you find a future out there… make it count.',
      'COMMANDER',
    ),
    Line('We will.', 'PROTAGONIST'),
  ],
);

const cine7 = Cine('Scene 7 -- Departure', 'EXT. LAUNCH FACILITY -- DAWN', [
  Line(
    'Crew status: confirmed. Life-support systems: operational. Navigation: ready. Mars transfer trajectory: calculated.',
    'DAVE',
  ),
  Line(
    'Earth fills the horizon. A beautiful, fragile world. A world they may never see again.',
  ),
  Line('Commander, all systems are ready. Awaiting authorization.', 'DAVE'),
  Line('Dave, initiate launch sequence.', 'PROTAGONIST'),
  Line('Launch sequence initiated. Ten seconds to ignition.', 'DAVE'),
  Line('Five. Four. Three. Two. One. Ignition.', 'MISSION CONTROL'),
  Line(
    'Earth departure confirmed. Mars transfer trajectory established.',
    'DAVE',
  ),
  Line('Let’s get to work.', 'PROTAGONIST'),
]);

const cine8 = Cine('Scene 8 -- Touchdown', 'INT. SPACECRAFT -- MARS APPROACH', [
  Line('Atmospheric entry confirmed. Descent sequence active.', 'DAVE'),
  Line('Altitude decreasing. Landing zone approaching.', 'DAVE'),
  Line('IMPACT. Silence.'),
  Line('Touchdown confirmed. Mars surface contact established.', 'DAVE'),
  Line(
    'There is no familiar sky. No city lights. No sound of wind through trees. Only a hostile world—and the fragile shelter they have brought with them.',
  ),
  Line('All right, team. Let’s build our future.', 'PROTAGONIST'),
], endCard: 'BASE 67\nTHE MISSION BEGINS.');

class CrewMember {
  CrewMember({
    required this.role,
    required this.tagline,
    required this.profile,
    required this.trait,
    this.name = '',
    this.age,
    this.suitColorIndex = 0,
    this.visorTintIndex = 0,
    this.faceStyleIndex = 0,
  });
  final String role, tagline, profile, trait;
  String name;
  int? age;
  int suitColorIndex;
  int visorTintIndex;
  int faceStyleIndex;
}

class Mission {
  Mission({CampaignSave? initial, this.seed = 0})
    : crew = [
        CrewMember(
          role: 'Commander',
          tagline: 'The Determined Leader',
          profile: 'The protagonist is courageous, responsible, and focused under pressure. Their strength is the ability to keep moving when others lose hope. Their weakness is a tendency to carry every burden alone.',
          trait: 'Unshakable — Recovers from stress more efficiently.',
        ),
        CrewMember(
          role: 'Engineer',
          tagline: 'The Pragmatist',
          profile: 'Logical, resourceful, and direct. The Engineer keeps the outpost functioning, repairs damaged equipment, and finds solutions when systems fail. Their bluntness can create tension within the crew.',
          trait:
              'Technical Genius — Repairs take less time or fewer spare parts.',
        ),
        CrewMember(
          role: 'Scientist',
          tagline: 'The Curious Idealist',
          profile: 'Curious, empathetic, and driven by discovery. The Scientist investigates unusual environmental evidence and potential signs of life, sometimes pushing the boundaries of safety.',
          trait: 'Keen Observer — Finds clues and useful environmental information more efficiently.',
        ),
        CrewMember(
          role: 'Medic',
          tagline: 'The Crew’s Anchor',
          profile: 'Compassionate, disciplined, and resilient. The Medic monitors the crew’s health and morale, helping the team endure the psychological and physical pressures of Mars.',
          trait: 'Field Medic — Crew members recover from injuries and illnesses more efficiently.',
        ),
      ] {
    for (final member in crew) {
      final role = member.role;
      member.name = initial?.crewNames[role] ?? '';
      member.age = initial?.crewAges[role];
      final appearance = initial?.crewAppearance[role] ?? const {};
      member.suitColorIndex = appearance['suit'] ?? 0;
      member.visorTintIndex = appearance['visor'] ?? 0;
      member.faceStyleIndex = appearance['face'] ?? 0;
    }
    cargo.addAll(initial?.startingCargo ?? const {});
  }
  final List<CrewMember> crew;
  String? siteId;
  final Map<String, int> cargo = {};
  final int seed;
}

class Prologue extends StatefulWidget {
  const Prologue({
    super.key,
    required this.repository,
    required this.initialSave,
    this.onComplete,
  });
  final GameDataRepository repository;
  final CampaignSave initialSave;
  final ValueChanged<CampaignSave>? onComplete;
  @override
  State<Prologue> createState() => _PrologueState();
}

class _PrologueState extends State<Prologue> {
  int i = 0;
  late final int seed =
      (widget.repository.document('game_constants.json')?['rng']
              as Map?)?['default_seed']
          as int? ??
      0;
  late final Mission mission = Mission(initial: widget.initialSave, seed: seed)
    ..siteId = widget.initialSave.selectedSiteId;
  void next() => setState(() => i++);

  CampaignSave makeSave() {
    final crewNames = {
      for (final member in mission.crew) member.role: member.name.trim(),
    };
    final appearance = {
      for (final member in mission.crew)
        member.role: {
          'suit': member.suitColorIndex,
          'visor': member.visorTintIndex,
          'face': member.faceStyleIndex,
        },
    };
    final startingCargo = Map<String, int>.from(mission.cargo);
    return widget.initialSave.copyWith(
      crewNames: crewNames,
      crewAges: const {},
      crewAppearance: appearance,
      selectedSiteId: mission.siteId,
      startingCargo: startingCargo,
      inventory: {...widget.initialSave.inventory, ...startingCargo},
      buildingLevels: {
        ...widget.initialSave.buildingLevels,
        'crew_habitat': 1,
        'landing_craft': 1,
      },
      deterministicSeed: widget.initialSave.deterministicSeed ?? mission.seed,
      prologueComplete: true,
      eventHistory: [...widget.initialSave.eventHistory, 'prologue_complete'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget Function()>[
      () => CineScreen(
        cine: cine1,
        scene: PrologueScene.news,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
        onDone: next,
      ),
      () => CineScreen(
        cine: cine2,
        scene: PrologueScene.command,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
        onDone: next,
      ),
      () => CrewScreen(
        mission: mission,
        onDone: next,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
      ),
      () => SiteScreen(
        mission: mission,
        repository: widget.repository,
        seed: widget.initialSave.deterministicSeed ?? seed,
        onDone: next,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
      ),
      () => CargoScreen(
        mission: mission,
        repository: widget.repository,
        onDone: next,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
      ),
      () => CineScreen(
        cine: cine6,
        scene: PrologueScene.goodbye,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
        onDone: next,
      ),
      () => CineScreen(
        cine: cine7,
        scene: PrologueScene.launch,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
        onDone: next,
      ),
      () => CineScreen(
        cine: cine8,
        scene: PrologueScene.touchdown,
        reducedMotion: widget.initialSave.settings['reduceMotion'] == true,
        onDone: next,
      ),
    ];
    final complete = i >= steps.length;
    return Theme(
      data: _prologueTheme(),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const IgnorePointer(
              child: CustomPaint(painter: _TacticalFramePainter()),
            ),
            SafeArea(
              left: complete || i >= 2 && i <= 4,
              right: complete || i >= 2 && i <= 4,
              child: AnimatedSwitcher(
                duration:
                    widget.initialSave.settings['reduceMotion'] == true ||
                        MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : GameMotion.medium,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .98, end: 1).animate(animation),
                    child: child,
                  ),
                ),
                child: complete
                    ? MissionBeginsScreen(
                        key: const ValueKey('mission-begins'),
                        onComplete: () => widget.onComplete?.call(makeSave()),
                        reducedMotion:
                            widget.initialSave.settings['reduceMotion'] == true,
                      )
                    : KeyedSubtree(key: ValueKey(i), child: steps[i]()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CineScreen extends StatefulWidget {
  const CineScreen({
    super.key,
    required this.cine,
    required this.scene,
    required this.reducedMotion,
    required this.onDone,
  });
  final Cine cine;
  final PrologueScene scene;
  final bool reducedMotion;
  final VoidCallback onDone;
  @override
  State<CineScreen> createState() => _CineScreenState();
}

class _CineScreenState extends State<CineScreen> {
  int lineIndex = 0;
  bool endCard = false;
  bool _igniting = false;
  int _countdown = 10;
  Timer? _ignitionTimer;
  Timer? _countdownTimer;

  bool get _reducedMotion =>
      widget.reducedMotion ||
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.scene != PrologueScene.launch) return;
    if (_reducedMotion) {
      _countdownTimer?.cancel();
      _countdown = 0;
    } else {
      _countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_countdown == 0) {
          timer.cancel();
        } else {
          setState(() => _countdown--);
        }
      });
    }
  }

  void tap() {
    if (_igniting) return;
    if (endCard) return widget.onDone();
    if (lineIndex < widget.cine.lines.length - 1) {
      setState(() => lineIndex++);
    } else if (widget.cine.endCard != null) {
      setState(() => endCard = true);
    } else if (widget.scene == PrologueScene.launch && !_reducedMotion) {
      setState(() => _igniting = true);
      _ignitionTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) widget.onDone();
      });
    } else {
      widget.onDone();
    }
  }

  void skip() {
    _ignitionTimer?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _ignitionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.cine.lines[lineIndex];
    final text = Theme.of(context).textTheme;
    final visualScene = widget.cine == cine8 && lineIndex < 2
        ? PrologueScene.marsApproach
        : widget.scene;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PrologueScenery(
            scene: visualScene,
            reducedMotion: _reducedMotion,
            launching: _igniting,
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _TacticalFramePainter()),
            ),
          ),
          if (widget.scene == PrologueScene.launch)
            _launchOverlay(context, line)
          else
            Padding(
              padding: const EdgeInsets.all(GameSpacing.lg),
              child: Column(
                children: [
                  GestureDetector(
                    key: kDebugMode && widget.cine.title == cine1.title
                        ? const ValueKey('base67-debug-data-check-entry')
                        : null,
                    onLongPress: kDebugMode && widget.cine.title == cine1.title
                        ? () async {
                            final repository = await GameDataRepository.load();
                            if (!context.mounted) return;
                            await Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DataCheckScreen(repository: repository),
                              ),
                            );
                          }
                        : null,
                    child: Text(
                      widget.cine.title.toUpperCase(),
                      style: text.labelLarge?.copyWith(color: GameColors.sand),
                    ),
                  ),
                  Text(
                    widget.cine.place,
                    style: text.labelSmall?.copyWith(color: GameColors.sand),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor:
                            MediaQuery.orientationOf(context) ==
                                Orientation.landscape
                            ? .62
                            : 1,
                        alignment: Alignment.centerRight,
                        child: Center(
                          child: SingleChildScrollView(
                            child: endCard
                                ? Text(
                                    widget.cine.endCard!,
                                    key: const ValueKey('card'),
                                    textAlign: TextAlign.center,
                                    style: text.displaySmall?.copyWith(
                                      color: GameColors.sand,
                                    ),
                                  )
                                : Column(
                                    key: ValueKey(lineIndex),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (line.who != null)
                                        Text(
                                          line.who!,
                                          style: text.labelLarge?.copyWith(
                                            color: GameColors.sand,
                                          ),
                                        ),
                                      const SizedBox(height: GameSpacing.sm),
                                      _TacticalPanel(
                                        child: _TypingText(
                                          line.who == null
                                              ? line.text
                                              : '“${line.text}”',
                                          reducedMotion: _reducedMotion,
                                          textAlign: TextAlign.center,
                                          style: text.titleLarge?.copyWith(
                                            color: GameColors.paper,
                                            fontStyle: line.who == null
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Tap to continue · Skip',
                    style: text.labelMedium?.copyWith(color: GameColors.paper),
                  ),
                  Semantics(
                    button: true,
                    label: 'Skip scene',
                    child: TextButton(
                      key: const ValueKey('prologue-skip'),
                      onPressed: skip,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.skip_next_rounded),
                          ExcludeSemantics(
                            child: Opacity(
                              opacity: 0,
                              child: const Text('Skip scene'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _launchOverlay(BuildContext context, Line line) => Padding(
    padding: const EdgeInsets.all(GameSpacing.md),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cine.title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: GameColors.prologueAmber,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Semantics(
                    label: widget.cine.place,
                    child: ExcludeSemantics(
                      child: Text(
                        widget.cine.place.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: GameColors.onControlSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _TacticalPanel(
              padding: GameSpacing.xs,
              accent: GameColors.prologueTeal,
              child: Column(
                children: [
                  Text(
                    'T-00:${_countdown.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GameColors.paper,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var index = 0; index < 3; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color:
                                  index <
                                      (lineIndex *
                                          3 ~/
                                          (widget.cine.lines.length - 1))
                                  ? GameColors.prologueTeal
                                  : GameColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Align(
          alignment: MediaQuery.orientationOf(context) == Orientation.landscape
              ? Alignment.bottomLeft
              : Alignment.bottomCenter,
          child: SizedBox(
            width: MediaQuery.orientationOf(context) == Orientation.landscape
                ? MediaQuery.sizeOf(context).width * .4
                : MediaQuery.sizeOf(context).width,
            child: _TacticalPanel(
              accent: GameColors.prologueTeal,
              padding: GameSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (line.who != null)
                    Text(
                      line.who!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: GameColors.prologueTeal,
                        letterSpacing: 1.5,
                      ),
                    ),
                  _TypingText(
                    line.who == null ? line.text : '?${line.text}?',
                    reducedMotion: _reducedMotion,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: GameColors.paper),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Tap to continue · Skip',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Skip scene',
                        child: IconButton(
                          key: const ValueKey('prologue-skip'),
                          tooltip: 'Skip scene',
                          onPressed: skip,
                          icon: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.skip_next_rounded),
                              Opacity(
                                opacity: 0,
                                child: const Text('Skip scene'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class CrewScreen extends StatefulWidget {
  const CrewScreen({
    super.key,
    required this.mission,
    required this.onDone,
    this.reducedMotion = false,
  });
  final Mission mission;
  final VoidCallback onDone;
  final bool reducedMotion;
  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  late final controllers = [
    for (final member in widget.mission.crew)
      TextEditingController(text: member.name),
  ];
  bool confirmed = false;
  static const namePool = [
    'Ari',
    'Sam',
    'Riley',
    'Jordan',
    'Taylor',
    'Casey',
    'Morgan',
    'Kai',
  ];
  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get ready =>
      widget.mission.crew.every((member) => member.name.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    final filled = widget.mission.crew
        .where((member) => member.name.trim().isNotEmpty)
        .length;
    return Padding(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: _SetupColumns(
        children: [
          Semantics(
            label: 'Scene 3 -- Your Crew, Your Mission',
            child: ExcludeSemantics(
              child: Text(
                'SCENE 3 -- YOUR CREW, YOUR MISSION',
                style: styles.titleLarge?.copyWith(
                  color: GameColors.paper,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
          _DaveComms(
            message: confirmed
                ? 'Crew registration complete. Four personnel confirmed. Commander, your team is ready.'
                : 'Welcome, Commander. Crew configuration interface is ready. Please register your expedition personnel.',
            reducedMotion: widget.reducedMotion,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.mission.crew.length,
              itemBuilder: (context, index) {
                final member = widget.mission.crew[index];
                final role = CrewRole.values[index];
                return _PrologueEntrance(
                  index: index,
                  reducedMotion: widget.reducedMotion,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(GameSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 112,
                                height: 128,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const CustomPaint(
                                      size: Size(112, 128),
                                      painter: _OperatorPlatformPainter(),
                                    ),
                                    AnimatedSwitcher(
                                      duration:
                                          widget.reducedMotion ||
                                              MediaQuery.disableAnimationsOf(
                                                context,
                                              )
                                          ? Duration.zero
                                          : GameMotion.fast,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: ScaleTransition(
                                              scale: animation,
                                              child: child,
                                            ),
                                          ),
                                      child: CrewBean(
                                        key: ValueKey(
                                          '${member.suitColorIndex}-${member.visorTintIndex}-${member.faceStyleIndex}',
                                        ),
                                        role: role,
                                        suitColorIndex: member.suitColorIndex,
                                        visorTintIndex: member.visorTintIndex,
                                        faceStyleIndex: member.faceStyleIndex,
                                        size: 104,
                                        reducedMotion: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: GameSpacing.sm),
                              Expanded(
                                child: Semantics(
                                  label: '${member.role} — ${member.tagline}',
                                  child: ExcludeSemantics(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _RoleTag(role: member.role),
                                        const SizedBox(height: GameSpacing.xs),
                                        Text(
                                          member.tagline.toUpperCase(),
                                          style: styles.titleMedium?.copyWith(
                                            color: GameColors.paper,
                                            letterSpacing: .7,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            member.profile,
                            style: styles.bodyMedium?.copyWith(
                              color: GameColors.onControlSecondary,
                            ),
                          ),
                          _TacticalPanel(
                            accent: GameColors.prologueAmber,
                            padding: GameSpacing.sm,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 18,
                                  color: GameColors.prologueAmber,
                                ),
                                const SizedBox(width: GameSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Special characteristic: ${member.trait}',
                                    style: styles.bodyMedium?.copyWith(
                                      color: GameColors.paper,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextField(
                            key: ValueKey('crew-name-${member.role}'),
                            controller: controllers[index],
                            enabled: !confirmed,
                            maxLength: 20,
                            onChanged: (value) =>
                                setState(() => member.name = value.trim()),
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: confirmed
                                  ? null
                                  : () {
                                      final name =
                                          namePool[math.Random().nextInt(
                                            namePool.length,
                                          )];
                                      controllers[index].text = name;
                                      member.name = name;
                                      setState(() {});
                                    },
                              icon: const Icon(Icons.casino_outlined),
                              label: const Text('Random name'),
                            ),
                          ),
                          Wrap(
                            spacing: GameSpacing.sm,
                            runSpacing: GameSpacing.xs,
                            children: [
                              DropdownButton<int>(
                                value: member.suitColorIndex,
                                isDense: true,
                                dropdownColor: GameColors.controlRaised,
                                style: const TextStyle(color: GameColors.paper),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (
                                    var i = 0;
                                    i < crewSuitColors.length;
                                    i++
                                  )
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('Suit ${i + 1}'),
                                    ),
                                ],
                                onChanged: confirmed
                                    ? null
                                    : (value) => setState(
                                        () =>
                                            member.suitColorIndex = value ?? 0,
                                      ),
                              ),
                              DropdownButton<int>(
                                value: member.visorTintIndex,
                                isDense: true,
                                dropdownColor: GameColors.controlRaised,
                                style: const TextStyle(color: GameColors.paper),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (
                                    var i = 0;
                                    i < crewVisorColors.length;
                                    i++
                                  )
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('Visor ${i + 1}'),
                                    ),
                                ],
                                onChanged: confirmed
                                    ? null
                                    : (value) => setState(
                                        () =>
                                            member.visorTintIndex = value ?? 0,
                                      ),
                              ),
                              DropdownButton<int>(
                                value: member.faceStyleIndex,
                                isDense: true,
                                dropdownColor: GameColors.controlRaised,
                                style: const TextStyle(color: GameColors.paper),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (var i = 0; i < 3; i++)
                                    DropdownMenuItem(
                                      value: i,
                                      child: Text('Face ${i + 1}'),
                                    ),
                                ],
                                onChanged: confirmed
                                    ? null
                                    : (value) => setState(
                                        () =>
                                            member.faceStyleIndex = value ?? 0,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  width: GameSpacing.touchTarget,
                  height: GameSpacing.touchTarget,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: filled / widget.mission.crew.length,
                        strokeWidth: 3,
                        backgroundColor: GameColors.controlOutline,
                        color: GameColors.prologueTeal,
                      ),
                      Text('$filled/4', style: styles.labelSmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: GameSpacing.sm),
              Expanded(
                child: GameButton(
                  key: const ValueKey('crew-confirm'),
                  expand: true,
                  label: confirmed ? 'Continue' : 'Confirm crew',
                  onPressed: !ready
                      ? null
                      : () {
                          if (confirmed) {
                            widget.onDone();
                          } else {
                            setState(() => confirmed = true);
                          }
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SiteScreen extends StatefulWidget {
  const SiteScreen({
    super.key,
    required this.mission,
    required this.repository,
    required this.seed,
    required this.onDone,
    this.reducedMotion = false,
  });
  final Mission mission;
  final GameDataRepository repository;
  final int seed;
  final VoidCallback onDone;
  final bool reducedMotion;
  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  int secondsLeft = 60;
  String? selected;
  bool expired = false;
  bool confirmed = false;
  Timer? timer;
  List<Map<String, dynamic>> get siteRecords =>
      (widget.repository.document('sites.json')?['sites'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
  @override
  void initState() {
    super.initState();
    selected = widget.mission.siteId;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (expired || confirmed) return;
      setState(() => secondsLeft--);
      if (secondsLeft <= 0) {
        final rng = SeededRng(widget.seed);
        final index = (rng.nextDouble() * siteRecords.length).floor();
        setState(() {
          selected = siteRecords[index]['id'] as String;
          expired = true;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _risk(String id) =>
      ((widget.repository.document('site_risk.json')?['sites'] as List?) ??
              const [])
          .whereType<Map<String, dynamic>>()
          .where((risk) => risk['id'] == id)
          .firstOrNull;
  Widget _factChip(String factId) {
    final fact = widget.repository.fact(factId);
    if (fact == null) return const SizedBox.shrink();
    final label = fact.raw['label'] as String? ?? factId;
    return Padding(
      padding: const EdgeInsets.only(top: GameSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text('$label: ${fact.value}')),
          const DataChip(DataClass.nasa),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: _SetupColumns(
        children: [
          Text(
            'Scene 4 -- Four Possible Worlds',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: GameSpacing.messageViewport,
            child: SingleChildScrollView(
              child: _DaveComms(
                reducedMotion: widget.reducedMotion,
                message: confirmed
                    ? 'Landing zone confirmed. Mission parameters updated.'
                    : expired
                    ? 'The countdown ended and a site was selected at random. You can still change the choice before confirming.'
                    : secondsLeft <= 20
                    ? 'Commander, landing-site selection is required to calculate the final mission profile.'
                    : 'Landing-site selection initiated. Each region presents different environmental conditions, resource opportunities, and operational risks. Review the available assessments before confirming your destination.',
              ),
            ),
          ),
          if (!expired && !confirmed)
            Text(
              '$secondsLeft seconds remaining',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          Expanded(
            child: ListView(
              children: [for (final site in siteRecords) _siteCard(site)],
            ),
          ),
          GameButton(
            key: const ValueKey('site-confirm'),
            label: confirmed ? 'Continue' : 'Confirm landing site',
            onPressed: selected == null
                ? null
                : () {
                    if (confirmed) {
                      widget.onDone();
                    } else {
                      timer?.cancel();
                      widget.mission.siteId = selected;
                      setState(() => confirmed = true);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _siteCard(Map<String, dynamic> site) {
    final id = site['id'] as String;
    final risk = _risk(id);
    final ids =
        (site['nasa_fact_ids'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final level =
        {
          'gale': 'EASY',
          'arcadia': 'MEDIUM',
          'deuteronilus': 'HARD',
          'equatorial_plain': 'EXTREME',
        }[id] ??
        'SITE';
    final title = site['name'] as String? ?? id;
    final selectedNow = selected == id;
    return Card(
      key: ValueKey('site-$id'),
      child: InkWell(
        onTap: confirmed ? null : () => setState(() => selected = id),
        child: Padding(
          padding: const EdgeInsets.all(GameSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$title — $level',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (selectedNow)
                    const Icon(Icons.check_circle, color: GameColors.teal),
                ],
              ),
              Text(
                risk?['description'] as String? ??
                    site['card_blurb'] as String? ??
                    '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const DataChip(DataClass.game),
              for (final key in [
                'lat',
                'lon',
                'ice_depth',
                'ice_rank',
                'radiation',
                'temp_mean',
              ])
                if (ids[key] is String) _factChip(ids[key] as String),
            ],
          ),
        ),
      ),
    );
  }
}

class CargoScreen extends StatefulWidget {
  const CargoScreen({
    super.key,
    required this.mission,
    required this.repository,
    required this.onDone,
    this.reducedMotion = false,
  });
  final Mission mission;
  final GameDataRepository repository;
  final VoidCallback onDone;
  final bool reducedMotion;
  @override
  State<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends State<CargoScreen> {
  bool confirmed = false;
  List<Map<String, dynamic>> get equipment =>
      (widget.repository.document('equipment.json')?['equipment'] as List? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .toList();
  List<Map<String, dynamic>> get levelOne =>
      (widget.repository.document('levels.json')?['levels'] as List? ??
              const [])
          .whereType<Map<String, dynamic>>()
          .where((level) => level['order'] == 1)
          .toList();
  Set<String> get permitted => {
    for (final item in levelOne.expand(
      (level) => (level['adds'] as List? ?? const []),
    ))
      item as String,
  };
  int get budget => levelOne.firstOrNull?['budget'] as int? ?? 0;
  int get cost => equipment.fold(
    0,
    (sum, item) =>
        sum +
        ((widget.mission.cargo[item['id']] ?? 0) * (item['cost'] as int? ?? 0)),
  );
  @override
  void initState() {
    super.initState();
    if (widget.mission.cargo.isEmpty) {
      final note =
          (widget.repository.document('levels.json')?['_meta']
                  as Map?)?['budget_check']
              as String? ??
          '';
      final match = RegExp(
        r'(\d+) panels.*?(\d+) batteries',
        caseSensitive: false,
      ).firstMatch(note);
      final panelId =
          equipment
                  .where((item) => item['name'] == 'Solar panel')
                  .firstOrNull?['id']
              as String?;
      final batteryId =
          equipment
                  .where((item) => item['name'] == 'Battery')
                  .firstOrNull?['id']
              as String?;
      if (match != null && panelId != null && batteryId != null) {
        widget.mission.cargo[panelId] = int.parse(match.group(1)!);
        widget.mission.cargo[batteryId] = int.parse(match.group(2)!);
      }
    }
  }

  Map<String, dynamic>? _availableAt(String itemId) {
    final buildings =
        (widget.repository.document('buildings.json')?['buildings'] as List? ??
                const [])
            .whereType<Map<String, dynamic>>();
    final levels = (widget.repository.campaign['levels'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    for (final building in buildings) {
      if ((building['required_equipment_ids'] as List? ?? const []).contains(
        itemId,
      )) {
        final levelId = building['introduced_level_id'];
        return levels.where((level) => level['id'] == levelId).firstOrNull;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final panels = widget.mission.cargo['solar_panel'] ?? 0;
    final batteries = widget.mission.cargo['battery'] ?? 0;
    final panelData =
        equipment.where((item) => item['id'] == 'solar_panel').firstOrNull ??
        const <String, dynamic>{};
    final batteryData =
        equipment.where((item) => item['id'] == 'battery').firstOrNull ??
        const <String, dynamic>{};
    final peakKw = (panelData['peak_kw'] as num?)?.toDouble();
    final capacity = (batteryData['capacity_kwh'] as num?)?.toDouble();
    return Padding(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: _SetupColumns(
        children: [
          Text(
            'Scene 5 -- Every Kilogram Counts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: GameSpacing.messageViewport,
            child: SingleChildScrollView(
              child: _DaveComms(
                reducedMotion: widget.reducedMotion,
                message: confirmed
                    ? 'Cargo manifest confirmed. Mission equipment registered.'
                    : cost > budget
                    ? 'Cargo capacity exceeded. Please revise your manifest.'
                    : 'Cargo allocation initiated. Transport capacity is limited. Commander, your equipment selections will determine the resources available to establish and maintain the outpost.',
              ),
            ),
          ),
          Text(
            'Cargo points: $cost / $budget',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const DataChip(DataClass.game),
          Expanded(
            child: ListView(
              children: [
                for (final item in equipment) _equipmentTile(item),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(GameSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live system preview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (peakKw != null)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Panel peak power = $panels × ${panelData['peak_kw']} kW = ${(panels * peakKw).toStringAsFixed(1)} kW',
                                ),
                              ),
                              const DataChip(DataClass.derived),
                            ],
                          ),
                        if (capacity != null)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Battery capacity = $batteries × ${batteryData['capacity_kwh']} kWh = ${(batteries * capacity).toStringAsFixed(0)} kWh',
                                ),
                              ),
                              const DataChip(DataClass.game),
                            ],
                          ),
                        if (panelData['peak_kw_formula'] is String)
                          Text(
                            'Panel formula: ${panelData['peak_kw_formula']}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GameButton(
            key: const ValueKey('cargo-confirm'),
            label: confirmed ? 'Continue' : 'Confirm loadout',
            onPressed: cost > budget
                ? null
                : () {
                    if (confirmed) {
                      widget.onDone();
                    } else {
                      setState(() => confirmed = true);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _equipmentTile(Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    final allowed = permitted.contains(id);
    final count = widget.mission.cargo[id] ?? 0;
    final level = _availableAt(id);
    final subtitle = allowed
        ? '${item['cost']} points each · Max ${item['max_units'] ?? '—'} · Level 1 item'
        : 'Locked${level == null ? ' until a later mission' : ' until ${level['name']}'}';
    return Card(
      child: ListTile(
        title: Text(item['name'] as String? ?? id),
        subtitle: Text(subtitle),
        trailing: allowed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Remove ${item['name']}',
                    onPressed: confirmed || count == 0
                        ? null
                        : () => setState(
                            () => widget.mission.cargo[id] = count - 1,
                          ),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$count'),
                  IconButton(
                    tooltip: 'Add ${item['name']}',
                    onPressed:
                        confirmed || count >= (item['max_units'] as int? ?? 0)
                        ? null
                        : () => setState(
                            () => widget.mission.cargo[id] = count + 1,
                          ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              )
            : const Icon(Icons.lock_outline_rounded),
      ),
    );
  }
}

class MissionBeginsScreen extends StatelessWidget {
  const MissionBeginsScreen({
    super.key,
    required this.onComplete,
    required this.reducedMotion,
  });

  final VoidCallback onComplete;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      PrologueScenery(
        scene: PrologueScene.touchdown,
        reducedMotion: reducedMotion,
      ),
      const Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(painter: _TacticalFramePainter()),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(GameSpacing.md),
        child: Column(
          children: [
            _TypingText(
              'THE MISSION BEGINS',
              reducedMotion: reducedMotion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(color: GameColors.paper, letterSpacing: 3),
            ),
            Container(
              height: 2,
              width: 112,
              margin: const EdgeInsets.only(top: GameSpacing.xs),
              color: GameColors.prologueOrange,
            ),
            const Spacer(),
            const _TacticalPanel(
              accent: GameColors.prologueTeal,
              child: Text(
                'This is the first step for one base that will grow throughout the campaign.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GameColors.paper),
              ),
            ),
            const SizedBox(height: GameSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: GameButton(
                label: 'Go to Home Base',
                icon: Icons.rocket_launch_rounded,
                onPressed: onComplete,
                reducedMotion: reducedMotion,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TacticalPanel extends StatelessWidget {
  const _TacticalPanel({
    required this.child,
    this.padding = GameSpacing.md,
    this.accent = GameColors.prologueOrange,
  });

  final Widget child;
  final double padding;
  final Color accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TacticalPanelPainter(accent),
    child: ClipPath(
      clipper: const _CutPanelClipper(),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    ),
  );
}

Path _cutPanelPath(Rect rect, double cut) => Path()
  ..moveTo(rect.left + cut, rect.top)
  ..lineTo(rect.right - cut, rect.top)
  ..lineTo(rect.right, rect.top + cut)
  ..lineTo(rect.right, rect.bottom - cut)
  ..lineTo(rect.right - cut, rect.bottom)
  ..lineTo(rect.left + cut, rect.bottom)
  ..lineTo(rect.left, rect.bottom - cut)
  ..lineTo(rect.left, rect.top + cut)
  ..close();

class _CutPanelClipper extends CustomClipper<Path> {
  const _CutPanelClipper();
  @override
  Path getClip(Size size) => _cutPanelPath(Offset.zero & size, 12);
  @override
  bool shouldReclip(covariant _CutPanelClipper oldClipper) => false;
}

class _TacticalPanelPainter extends CustomPainter {
  const _TacticalPanelPainter(this.accent);
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final panel = _cutPanelPath(bounds.deflate(.5), 12);
    canvas.drawPath(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GameColors.prologuePanel, GameColors.prologueBackground],
        ).createShader(bounds),
    );
    canvas.drawPath(
      panel,
      Paint()
        ..color = GameColors.prologueBorder
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      Offset(12, 1),
      Offset(math.min(size.width - 12, 126), 1),
      Paint()
        ..color = accent
        ..strokeWidth = 2,
    );
    final bracket = Paint()
      ..color = accent.withValues(alpha: .75)
      ..strokeWidth = 1.2;
    for (final corner in const [
      Offset(8, 8),
      Offset(-8, 8),
      Offset(-8, -8),
      Offset(8, -8),
    ]) {
      final at = Offset(
        corner.dx < 0 ? size.width + corner.dx : corner.dx,
        corner.dy < 0 ? size.height + corner.dy : corner.dy,
      );
      canvas.drawLine(at, at.translate(corner.dx.abs() * .65, 0), bracket);
      canvas.drawLine(at, at.translate(0, corner.dy.abs() * .65), bracket);
    }
  }

  @override
  bool shouldRepaint(covariant _TacticalPanelPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

class _TacticalFramePainter extends CustomPainter {
  const _TacticalFramePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = GameColors.prologueGrid
      ..strokeWidth = .7;
    for (var x = 0.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, GameColors.prologueVignette],
          stops: [0.48, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _TacticalFramePainter oldDelegate) => false;
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.role});
  final String role;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: GameSpacing.sm,
      vertical: GameSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: GameColors.prologueTeal.withValues(alpha: .16),
      border: Border.all(color: GameColors.prologueTeal.withValues(alpha: .7)),
    ),
    child: Semantics(
      label: role,
      child: ExcludeSemantics(
        child: Text(
          role.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: GameColors.prologueTeal, letterSpacing: 1.3),
        ),
      ),
    ),
  );
}

class _OperatorPlatformPainter extends CustomPainter {
  const _OperatorPlatformPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cone = Path()
      ..moveTo(size.width * .5, 0)
      ..lineTo(size.width * .93, size.height * .89)
      ..lineTo(size.width * .07, size.height * .89)
      ..close();
    canvas.drawPath(
      cone,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GameColors.prologueTeal.withValues(alpha: .04),
            GameColors.prologueTeal.withValues(alpha: .13),
          ],
        ).createShader(Offset.zero & size),
    );
    final hex = Path()
      ..moveTo(size.width * .18, size.height * .89)
      ..lineTo(size.width * .29, size.height * .80)
      ..lineTo(size.width * .71, size.height * .80)
      ..lineTo(size.width * .82, size.height * .89)
      ..lineTo(size.width * .71, size.height * .98)
      ..lineTo(size.width * .29, size.height * .98)
      ..close();
    canvas.drawPath(
      hex,
      Paint()..color = GameColors.prologueTeal.withValues(alpha: .2),
    );
    canvas.drawPath(
      hex,
      Paint()
        ..color = GameColors.prologueTeal.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _OperatorPlatformPainter oldDelegate) => false;
}

class _TypingText extends StatefulWidget {
  const _TypingText(
    this.message, {
    required this.reducedMotion,
    this.textAlign,
    this.style,
  });
  final String message;
  final bool reducedMotion;
  final TextAlign? textAlign;
  final TextStyle? style;
  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (widget.message.length * 13).clamp(350, 2400).toInt(),
    ),
  )..forward();

  bool get _reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) {
      _reveal.stop();
      _reveal.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _TypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      if (_reduced) {
        _reveal.value = 1;
      } else {
        _reveal.duration = Duration(
          milliseconds: (widget.message.length * 13).clamp(350, 2400).toInt(),
        );
        _reveal.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _reveal,
    builder: (context, _) => ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final reveal = _reduced ? 1.0 : _reveal.value.clamp(.01, 1).toDouble();
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, reveal, 1],
        ).createShader(bounds);
      },
      child: Text(
        widget.message,
        textAlign: widget.textAlign,
        style: widget.style,
      ),
    ),
  );
}

class _DaveComms extends StatefulWidget {
  const _DaveComms({required this.message, required this.reducedMotion});
  final String message;
  final bool reducedMotion;
  @override
  State<_DaveComms> createState() => _DaveCommsState();
}

class _DaveCommsState extends State<_DaveComms>
    with SingleTickerProviderStateMixin {
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  void _start() {
    if (_reduced) {
      _typing.stop();
      _typing.value = 1;
    } else {
      _typing.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _typing.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) _start();
  }

  @override
  void didUpdateWidget(covariant _DaveComms oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _start();
    }
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _TacticalPanel(
    accent: GameColors.prologueTeal,
    padding: GameSpacing.sm,
    child: AnimatedBuilder(
      animation: _typing,
      builder: (context, _) {
        final value = _reduced ? 1.0 : _typing.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      GameColors.prologueTeal.withValues(alpha: .35),
                      GameColors.prologueTeal,
                      .5 + value * .5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: GameColors.prologueTeal.withValues(alpha: .42),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GameSpacing.xs),
                Text(
                  'DAVE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: GameColors.prologueTeal,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                CustomPaint(
                  size: const Size(82, 18),
                  painter: _WaveformPainter(value),
                ),
              ],
            ),
            const SizedBox(height: GameSpacing.xs),
            ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0, value.clamp(.01, 1).toDouble(), 1],
              ).createShader(bounds),
              child: Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: GameColors.paper,
                  fontSize: GameTypography.caption,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameColors.prologueTeal.withValues(alpha: .78)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 17; i++) {
      final x = size.width * i / 16;
      final height = 3 + math.sin(i * .8 + phase * math.pi * 5).abs() * 12;
      canvas.drawLine(
        Offset(x, (size.height - height) / 2),
        Offset(x, (size.height + height) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      phase != oldDelegate.phase;
}

class _PrologueEntrance extends StatefulWidget {
  const _PrologueEntrance({
    required this.index,
    required this.reducedMotion,
    required this.child,
  });
  final int index;
  final bool reducedMotion;
  final Widget child;
  @override
  State<_PrologueEntrance> createState() => _PrologueEntranceState();
}

class _PrologueEntranceState extends State<_PrologueEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  Timer? _stagger;
  bool get _reduced =>
      widget.reducedMotion || MediaQuery.disableAnimationsOf(context);

  void _start() {
    _stagger?.cancel();
    if (_reduced) {
      _controller.value = 1;
    } else {
      _controller.value = 0;
      _stagger = Timer(Duration(milliseconds: widget.index * 60), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.value = widget.reducedMotion ? 1 : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced) _start();
  }

  @override
  void didUpdateWidget(covariant _PrologueEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        oldWidget.reducedMotion != widget.reducedMotion) {
      _start();
    }
  }

  @override
  void dispose() {
    _stagger?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _controller.value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - _controller.value)),
        child: child,
      ),
    ),
  );
}

// Keep the original setup choices and story beside a scrollable landscape form.
class _SetupColumns extends StatelessWidget {
  const _SetupColumns({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (bounds.maxWidth < 480 ||
          MediaQuery.orientationOf(context) != Orientation.landscape) {
        return Column(children: children);
      }
      final form = children.whereType<Expanded>().single;
      final footer = children.last;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children
                          .where((item) => item != form && item != footer)
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                footer,
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(flex: 7, child: form.child),
        ],
      );
    },
  );
}
