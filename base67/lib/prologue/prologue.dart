// BASE 67 — Prologue (8 scenes). Drop into a fresh `flutter create base67` project.
// Story dialogue is sourced from docs/source/BASE_67_Prologue_Preview.pdf.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/repositories/game_data_repository.dart';
import '../data/validation/data_check_screen.dart';
import '../app/campaign_save.dart';
import '../data/models/data_class.dart';
import '../sim/seeded_rng.dart';
import '../ui/crew_bean.dart';
import '../ui/game_widgets.dart';
import '../ui/prologue_scenery.dart';
import '../ui/theme.dart';

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
    final crewAges = {
      for (final member in mission.crew)
        if (member.age != null) member.role: member.age!,
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
      crewAges: crewAges,
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
      () => CrewScreen(mission: mission, onDone: next),
      () => SiteScreen(
        mission: mission,
        repository: widget.repository,
        seed: widget.initialSave.deterministicSeed ?? seed,
        onDone: next,
      ),
      () => CargoScreen(
        mission: mission,
        repository: widget.repository,
        onDone: next,
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
    return Scaffold(
      body: SafeArea(
        child: complete
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(GameSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AspectRatio(
                        aspectRatio: 2,
                        child: PrologueScenery(
                          scene: PrologueScene.touchdown,
                          reducedMotion: true,
                        ),
                      ),
                      Text(
                        'THE MISSION BEGINS',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: GameSpacing.sm),
                      const Text(
                        'This is the first step for one base that will grow throughout the campaign.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: GameSpacing.md),
                      GameButton(
                        label: 'Go to Home Base',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: () => widget.onComplete?.call(makeSave()),
                      ),
                    ],
                  ),
                ),
              )
            : KeyedSubtree(key: ValueKey(i), child: steps[i]()),
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
  void tap() {
    if (endCard) return widget.onDone();
    if (lineIndex < widget.cine.lines.length - 1) {
      setState(() => lineIndex++);
    } else if (widget.cine.endCard != null) {
      setState(() => endCard = true);
    } else {
      widget.onDone();
    }
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
            reducedMotion: widget.reducedMotion,
          ),
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
                                CinematicCaption(
                                  child: Text(
                                    line.who == null
                                        ? line.text
                                        : '“${line.text}”',
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
                Text(
                  'Tap to continue · Skip',
                  style: text.labelMedium?.copyWith(color: GameColors.paper),
                ),
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Skip scene'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key, required this.mission, required this.onDone});
  final Mission mission;
  final VoidCallback onDone;
  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  late final controllers = [
    for (final member in widget.mission.crew)
      TextEditingController(text: member.name),
  ];
  late final ageControllers = [
    for (final member in widget.mission.crew)
      TextEditingController(text: member.age?.toString() ?? ''),
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
    for (final controller in [...controllers, ...ageControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get ready => widget.mission.crew.every(
    (member) => member.name.trim().isNotEmpty && (member.age ?? 0) > 0,
  );

  @override
  Widget build(BuildContext context) {
    final styles = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(GameSpacing.md),
      child: Column(
        children: [
          Text('Scene 3 -- Your Crew, Your Mission', style: styles.titleLarge),
          DaveBubble(
            message: confirmed
                ? 'Crew registration complete. Four personnel confirmed. Commander, your team is ready.'
                : 'Welcome, Commander. Crew configuration interface is ready. Please register your expedition personnel.',
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.mission.crew.length,
              itemBuilder: (context, index) {
                final member = widget.mission.crew[index];
                final role = CrewRole.values[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(GameSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CrewBean(
                              role: role,
                              suitColorIndex: member.suitColorIndex,
                              visorTintIndex: member.visorTintIndex,
                              faceStyleIndex: member.faceStyleIndex,
                              size: 56,
                              reducedMotion: true,
                            ),
                            const SizedBox(width: GameSpacing.sm),
                            Expanded(
                              child: Text(
                                '${member.role} — ${member.tagline}',
                                style: styles.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        Text(member.profile),
                        Text(
                          'Special characteristic: ${member.trait}',
                          style: styles.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        TextField(
                          key: ValueKey('crew-name-${member.role}'),
                          controller: controllers[index],
                          enabled: !confirmed,
                          maxLength: 20,
                          onChanged: (value) =>
                              setState(() => member.name = value.trim()),
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: ValueKey('crew-age-${member.role}'),
                                controller: ageControllers[index],
                                enabled: !confirmed,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                onChanged: (value) {
                                  member.age = int.tryParse(value);
                                  setState(() {});
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Age',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: confirmed
                                  ? null
                                  : () {
                                      final name =
                                          namePool[Random().nextInt(
                                            namePool.length,
                                          )];
                                      controllers[index].text = name;
                                      member.name = name;
                                      setState(() {});
                                    },
                              child: const Text('Random name'),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: GameSpacing.sm,
                          runSpacing: GameSpacing.xs,
                          children: [
                            DropdownButton<int>(
                              value: member.suitColorIndex,
                              items: [
                                for (var i = 0; i < crewSuitColors.length; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text('Suit ${i + 1}'),
                                  ),
                              ],
                              onChanged: confirmed
                                  ? null
                                  : (value) => setState(
                                      () => member.suitColorIndex = value ?? 0,
                                    ),
                            ),
                            DropdownButton<int>(
                              value: member.visorTintIndex,
                              items: [
                                for (var i = 0; i < crewVisorColors.length; i++)
                                  DropdownMenuItem(
                                    value: i,
                                    child: Text('Visor ${i + 1}'),
                                  ),
                              ],
                              onChanged: confirmed
                                  ? null
                                  : (value) => setState(
                                      () => member.visorTintIndex = value ?? 0,
                                    ),
                            ),
                            DropdownButton<int>(
                              value: member.faceStyleIndex,
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
                                      () => member.faceStyleIndex = value ?? 0,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          GameButton(
            key: const ValueKey('crew-confirm'),
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
  });
  final Mission mission;
  final GameDataRepository repository;
  final int seed;
  final VoidCallback onDone;
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
      child: Column(
        children: [
          Text(
            'Scene 4 -- Four Possible Worlds',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: GameSpacing.messageViewport,
            child: SingleChildScrollView(
              child: DaveBubble(
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
  });
  final Mission mission;
  final GameDataRepository repository;
  final VoidCallback onDone;
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
      child: Column(
        children: [
          Text(
            'Scene 5 -- Every Kilogram Counts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: GameSpacing.messageViewport,
            child: SingleChildScrollView(
              child: DaveBubble(
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
