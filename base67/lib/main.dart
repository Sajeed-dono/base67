// BASE 67 — Prologue (8 scenes). Drop into a fresh `flutter create base67` project.
// Story text is taken from the finalized prologue. Values marked PLACEHOLDER are
// NOT specified in the draft (see its Appendix) and must be replaced by design.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const Base67App());

const rust = Color(0xFFB7410E);
const ink = Color(0xFF0B0A0F);

class Base67App extends StatelessWidget {
  const Base67App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'BASE 67',
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: ink,
      colorScheme: const ColorScheme.dark(primary: rust),
    ),
    home: const Prologue(),
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

const cine1 = Cine('Scene 1 — The Last Year', 'BLACK SCREEN', [
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
  'Scene 2 — The Calling',
  'INT. SPACE OPERATIONS FACILITY — NIGHT',
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
  'Scene 6 — The Final Goodbye',
  'INT. LAUNCH PREPARATION AREA',
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

const cine7 = Cine('Scene 7 — Departure', 'EXT. LAUNCH FACILITY — DAWN', [
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

const cine8 = Cine('Scene 8 — Touchdown', 'INT. SPACECRAFT — MARS APPROACH', [
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
  final String role, tagline, profile, trait;
  String name = '';
  int age = 30; // PLACEHOLDER default; age range not specified
  CrewMember(this.role, this.tagline, this.profile, this.trait);
}

class Site {
  final String name, level, desc, pro, con;
  const Site(this.name, this.level, this.desc, this.pro, this.con);
}

// Advantages/disadvantages are PROVISIONAL in the draft.
const sites = [
  Site(
    'Gale Crater',
    'EASY',
    'A region of scientific interest with terrain that offers a comparatively manageable introduction to the mission.',
    'A useful starting point for scientific exploration and establishing initial operations.',
    'The selected route and surrounding terrain may restrict access to some resources and exploration areas.',
  ),
  Site(
    'Arcadia Planitia',
    'MEDIUM',
    'Broad plains that offer opportunities for establishing an outpost and investigating potential subsurface resources.',
    'Relatively open terrain and the possibility of valuable resources beneath the surface.',
    'Resource availability is uncertain, and environmental conditions may complicate long-term operations.',
  ),
  Site(
    'Deuteronilus Mensae',
    'HARD',
    'A rugged region of cliffs, landforms, and potential ice-bearing terrain.',
    'Possible access to water ice and scientifically valuable geological features.',
    'Difficult terrain, greater operational challenges, and potentially hazardous exploration.',
  ),
  Site(
    'Equatorial Plain',
    'EXTREME',
    'A demanding destination where survival depends on careful preparation and resource management.',
    'Potential opportunities for scientific investigation and a challenging environment in which to establish the outpost.',
    'Uncertain resources and environmental conditions that may place additional pressure on the crew and equipment.',
  ),
];

class CargoItem {
  final String name, group;
  final double
  kg; // PLACEHOLDER — per-item weights are not specified in the draft
  int qty = 0;
  CargoItem(this.name, this.group, this.kg);
}

const double cargoCapacityKg =
    1000; // PLACEHOLDER — capacity not specified in the draft

class Mission {
  final crew = [
    CrewMember(
      'The Commander',
      'The Determined Leader',
      'Courageous, responsible, and focused under pressure. Their strength is the ability to keep moving when others lose hope. Their weakness is a tendency to carry every burden alone.',
      'Unshakable — Recovers from stress more efficiently.',
    ),
    CrewMember(
      'The Engineer',
      'The Pragmatist',
      'Logical, resourceful, and direct. The Engineer keeps the outpost functioning, repairs damaged equipment, and finds solutions when systems fail. Their bluntness can create tension within the crew.',
      'Technical Genius — Repairs take less time or fewer spare parts.',
    ),
    CrewMember(
      'The Scientist',
      'The Curious Idealist',
      'Curious, empathetic, and driven by discovery. The Scientist investigates unusual environmental evidence and potential signs of life, sometimes pushing the boundaries of safety.',
      'Keen Observer — Finds clues and useful environmental information more efficiently.',
    ),
    CrewMember(
      'The Medic',
      'The Crew’s Anchor',
      'Compassionate, disciplined, and resilient. The Medic monitors the crew’s health and morale, helping the team endure the psychological and physical pressures of Mars.',
      'Field Medic — Crew members recover from injuries and illnesses more efficiently.',
    ),
  ];
  Site? site;
  final cargo = [
    CargoItem('Solar panels', 'POWER', 100),
    CargoItem('Batteries', 'POWER', 150),
    CargoItem('Greenhouse equipment', 'FOOD', 200),
    CargoItem('Radiation shielding', 'RADIATION PROTECTION', 250),
    CargoItem('Spare parts', 'REPAIRS', 80),
    CargoItem('Life-support system', 'AIR AND WATER', 220),
    CargoItem('Water-management system', 'AIR AND WATER', 180),
  ];
  double get load => cargo.fold(0.0, (s, c) => s + c.kg * c.qty);
}

// ---------------------------------------------------------------- flow

class Prologue extends StatefulWidget {
  const Prologue({super.key});
  @override
  State<Prologue> createState() => _PrologueState();
}

class _PrologueState extends State<Prologue> {
  int i = 0;
  final m = Mission();
  void next() => setState(() => i++);

  @override
  Widget build(BuildContext context) {
    final steps = <Widget Function()>[
      () => CineScreen(cine: cine1, onDone: next),
      () => CineScreen(cine: cine2, onDone: next),
      () => CrewScreen(m: m, onDone: next),
      () => SiteScreen(m: m, onDone: next),
      () => CargoScreen(m: m, onDone: next),
      () => CineScreen(cine: cine6, onDone: next),
      () => CineScreen(cine: cine7, onDone: next),
      () => CineScreen(cine: cine8, onDone: next),
    ];
    final body = i < steps.length
        ? KeyedSubtree(key: ValueKey(i), child: steps[i]())
        : const Center(
            child: Text('Prologue complete — hand off to the main game here.'),
          );
    return Scaffold(body: SafeArea(child: body));
  }
}

// ---------------------------------------------------------------- cinematic

class CineScreen extends StatefulWidget {
  final Cine cine;
  final VoidCallback onDone;
  const CineScreen({super.key, required this.cine, required this.onDone});
  @override
  State<CineScreen> createState() => _CineScreenState();
}

class _CineScreenState extends State<CineScreen> {
  int n = 0;
  bool card = false;

  void tap() {
    if (card) return widget.onDone();
    if (n < widget.cine.lines.length - 1) {
      setState(() => n++);
    } else if (widget.cine.endCard != null) {
      setState(() => card = true);
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.cine.lines[n];
    final t = Theme.of(context).textTheme;
    final Widget content = card
        ? Text(
            widget.cine.endCard!,
            key: const ValueKey('card'),
            textAlign: TextAlign.center,
            style: t.displaySmall!.copyWith(letterSpacing: 6, color: rust),
          )
        : Column(
            key: ValueKey(n),
            mainAxisSize: MainAxisSize.min,
            children: [
              if (l.who != null)
                Text(
                  l.who!,
                  style: t.labelLarge!.copyWith(color: rust, letterSpacing: 3),
                ),
              const SizedBox(height: 12),
              Text(
                l.who == null ? l.text : '“${l.text}”',
                textAlign: TextAlign.center,
                style: t.titleLarge!.copyWith(
                  fontStyle: l.who == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                  height: 1.4,
                ),
              ),
            ],
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.cine.title.toUpperCase(),
              style: t.labelMedium!.copyWith(color: rust, letterSpacing: 2),
            ),
            Text(widget.cine.place, style: t.labelSmall),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: content,
                ),
              ),
            ),
            const Text(
              'tap to continue',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

Widget daveBar(String s) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(12),
  margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    border: Border.all(color: rust),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    'DAVE (V.O.): “$s”',
    style: const TextStyle(fontStyle: FontStyle.italic),
  ),
);

// ---------------------------------------------------------------- scene 3

class CrewScreen extends StatefulWidget {
  final Mission m;
  final VoidCallback onDone;
  const CrewScreen({super.key, required this.m, required this.onDone});
  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  late final ctrls = widget.m.crew.map((_) => TextEditingController()).toList();
  bool done = false;
  bool get ready => ctrls.every((c) => c.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final c in ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crew = widget.m.crew;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          daveBar(
            done
                ? 'Crew registration complete. Four personnel confirmed. Commander, your team is ready.'
                : 'Welcome, Commander. Crew configuration interface is ready. Please register your expedition personnel.',
          ),
          Expanded(
            child: ListView.builder(
              itemCount: crew.length,
              itemBuilder: (_, k) {
                final c = crew[k];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.role.toUpperCase()} — ${c.tagline.toUpperCase()}',
                          style: const TextStyle(
                            color: rust,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(c.profile),
                        const SizedBox(height: 6),
                        Text(
                          'Special characteristic: ${c.trait}',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ctrls[k],
                                enabled: !done,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            DropdownButton<int>(
                              value: c.age,
                              items: [
                                for (var a = 21; a <= 60; a++)
                                  DropdownMenuItem(value: a, child: Text('$a')),
                              ], // PLACEHOLDER range
                              onChanged: done
                                  ? null
                                  : (v) => setState(() => c.age = v!),
                            ),
                          ],
                        ),
                        // TODO: face, body and spacesuit customization (needs art assets).
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: !ready
                ? null
                : () {
                    if (!done) {
                      for (var k = 0; k < crew.length; k++) {
                        crew[k].name = ctrls[k].text.trim();
                      }
                      setState(() => done = true);
                    } else {
                      widget.onDone();
                    }
                  },
            child: Text(done ? 'Continue' : 'Confirm crew'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- scene 4

class SiteScreen extends StatefulWidget {
  final Mission m;
  final VoidCallback onDone;
  const SiteScreen({super.key, required this.m, required this.onDone});
  @override
  State<SiteScreen> createState() => _SiteScreenState();
}

class _SiteScreenState extends State<SiteScreen> {
  int left = 60;
  int? sel;
  bool locked = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (locked) return;
      setState(() => left--);
      if (left <= 0)
        lock(Random().nextInt(sites.length)); // random site if time runs out
    });
  }

  void lock(int k) {
    timer?.cancel();
    widget.m.site = sites[k];
    setState(() {
      sel = k;
      locked = true;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          daveBar(
            locked
                ? 'Landing zone confirmed. Mission parameters updated.'
                : left > 0 && left <= 20
                ? 'Commander, landing-site selection is required to calculate the final mission profile.'
                : 'Landing-site selection initiated. Review the available assessments before confirming your destination.',
          ),
          if (!locked)
            Text(
              '$left SECONDS REMAINING',
              style: const TextStyle(color: rust, fontWeight: FontWeight.bold),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: sites.length,
              itemBuilder: (_, k) {
                final s = sites[k];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: sel == k ? rust : Colors.white12,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: locked ? null : () => setState(() => sel = k),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${k + 1}. ${s.name.toUpperCase()} — ${s.level}',
                            style: const TextStyle(
                              color: rust,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(s.desc),
                          Text('Advantages: ${s.pro}'),
                          Text('Disadvantages: ${s.con}'),
                          const Text(
                            'Provisional — align with resource/environment simulation.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: locked
                ? widget.onDone
                : (sel == null ? null : () => lock(sel!)),
            child: Text(locked ? 'Continue' : 'Confirm landing site'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- scene 5

class CargoScreen extends StatefulWidget {
  final Mission m;
  final VoidCallback onDone;
  const CargoScreen({super.key, required this.m, required this.onDone});
  @override
  State<CargoScreen> createState() => _CargoScreenState();
}

class _CargoScreenState extends State<CargoScreen> {
  bool confirmed = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final over = m.load > cargoCapacityKg;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          daveBar(
            confirmed
                ? 'Cargo manifest confirmed. Mission equipment registered.'
                : over
                ? 'Cargo capacity exceeded. Please revise your manifest.'
                : 'Cargo allocation initiated. Capacity is a mission constraint: more equipment in one area reduces the space available for another.',
          ),
          LinearProgressIndicator(
            value: (m.load / cargoCapacityKg).clamp(0, 1),
            color: over ? Colors.redAccent : rust,
            minHeight: 10,
          ),
          Text(
            '${m.load.toStringAsFixed(0)} / ${cargoCapacityKg.toStringAsFixed(0)} kg',
            style: TextStyle(color: over ? Colors.redAccent : null),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final c in m.cargo)
                  ListTile(
                    title: Text(c.name),
                    subtitle: Text(
                      '${c.group} · ${c.kg.toStringAsFixed(0)} kg each',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: confirmed || c.qty == 0
                              ? null
                              : () => setState(() => c.qty--),
                        ),
                        Text('${c.qty}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: confirmed
                              ? null
                              : () => setState(() => c.qty++),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          FilledButton(
            onPressed: over
                ? null
                : () => confirmed
                      ? widget.onDone()
                      : setState(() => confirmed = true),
            child: Text(confirmed ? 'Continue' : 'Confirm loadout'),
          ),
        ],
      ),
    );
  }
}
