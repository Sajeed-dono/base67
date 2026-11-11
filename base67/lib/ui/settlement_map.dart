import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'crew_bean.dart';
import 'crew_movement.dart';
import 'settlement_camera.dart';
import 'mars_base_painter.dart';
import 'mars_terrain.dart';
import 'theme.dart';
import '../data/models/data_class.dart';
import 'data_class_chip.dart';

/// The existing Mars map with a separate cheap actor layer and controls below.
/// No progression/controller mutation callback is accepted by this widget.
class SettlementMap extends StatefulWidget {
  const SettlementMap({
    super.key,
    required this.facilities,
    required this.crew,
    this.movement,
    this.reducedMotion = false,
    this.night = false,
    this.storm = false,
    this.dust = 0,
    this.height = GameSpacing.homeMapHeight,
    this.onManage,
  });
  final List<MarsFacility> facilities;
  final List<MapCrew> crew;
  final CrewMovement? movement;
  final bool reducedMotion, night, storm;
  final double dust, height;
  final ValueChanged<String>? onManage;

  @override
  State<SettlementMap> createState() => _SettlementMapState();
}

class _SceneRepaint extends ChangeNotifier {
  void invalidate() => notifyListeners();
}

class _SettlementMapState extends State<SettlementMap>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CrewMovement movement = widget.movement ?? CrewMovement();
  late final Ticker _ticker = createTicker(_tick);
  final FocusNode _focus = FocusNode(debugLabel: 'Settlement movement');
  final Set<LogicalKeyboardKey> _keys = {};
  final camera = SettlementCamera();
  final _view = _SceneRepaint();
  ui.Picture? _terrain;
  String? _terrainKey;
  final _buildingPictures = <String, ui.Picture>{};
  final _buildingKeys = <String, String>{};
  double _gestureZoom = 1;
  bool _lookAround = false;
  String? _inspectedId;
  Duration? _previous;
  bool _foreground = true;
  bool _wakePending = false;
  bool _wasActive = false;
  bool get _active =>
      _foreground &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_active && _wasActive) {
      _stopInput();
    }
    _wasActive = _active;
    _afterLayout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stopInput();
      _ticker.stop();
    } else {
      _wake();
    }
  }

  void _tick(Duration elapsed) {
    final last = _previous;
    _previous = elapsed;
    if (!mounted || !_active) {
      _ticker.stop();
      return;
    }
    // Actor-only painting at at most 30 fps; no terrain or screen rebuild.
    if (last != null && (elapsed - last).inMicroseconds < 33333) {
      _previous = last;
      return;
    }
    final dt = last == null ? 0.0 : (elapsed - last).inMicroseconds / 1000000;
    movement.tick(dt);
    final selected = movement.actors[movement.selected];
    if (selected != null &&
        camera.follow(
          selected.position,
          dt,
          reducedMotion: movement.reducedMotion,
        )) {
      _view.invalidate();
    }
    if (!movement.needsFrames &&
        !(selected != null && camera.needsFollow(selected.position))) {
      _ticker.stop();
      _previous = null;
    }
  }

  void _wake() {
    if (!mounted || !_active) {
      return;
    }
    if (!_ticker.isActive &&
        (movement.needsFrames ||
            camera.needsFollow(
              movement.actors[movement.selected]?.position ?? camera.center,
            ))) {
      _previous = null;
      _ticker.start();
    }
  }

  void _afterLayout() {
    if (_wakePending) {
      return;
    }
    _wakePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _wakePending = false;
      if (mounted) {
        _wake();
      }
    });
  }

  void _stopInput() {
    _keys.clear();
    movement.input(Offset.zero);
  }

  void _cacheBuildings() {
    final ids = widget.facilities.map((site) => site.id).toSet();
    for (final id in _buildingPictures.keys.toList()) {
      if (!ids.contains(id)) {
        _buildingPictures.remove(id)?.dispose();
        _buildingKeys.remove(id);
      }
    }
    for (final site in widget.facilities) {
      final key =
          '${site.position}:${site.label}:${site.count}:${site.level}:'
          '${site.condition}:${site.damagedUnits}:${site.available}:'
          '${site.referenceOnly}:${site.jobProgress}:${widget.dust}';
      if (_buildingKeys[site.id] == key) continue;
      _buildingPictures.remove(site.id)?.dispose();
      final recorder = ui.PictureRecorder();
      MarsBasePainter.paintFacility(
        Canvas(recorder),
        SettlementView.world,
        site,
        panelDust: widget.dust,
      );
      _buildingPictures[site.id] = recorder.endRecording();
      _buildingKeys[site.id] = key;
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final Set<LogicalKeyboardKey> supported = {
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowRight,
    };
    if (!supported.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyUpEvent) {
      _keys.remove(event.logicalKey);
    } else {
      _keys.add(event.logicalKey);
    }
    bool down(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        _keys.contains(a) || _keys.contains(b);
    movement.input(
      Offset(
        (down(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight)
                ? 1.0
                : 0) -
            (down(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft)
                ? 1.0
                : 0),
        (down(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown)
                ? 1.0
                : 0) -
            (down(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp)
                ? 1.0
                : 0),
      ),
    );
    _wake();
    setState(() {});
    return KeyEventResult.handled;
  }

  void _select(MapCrew member) {
    _stopInput();
    movement.select(member.id);
    camera.following = true;
    _focus.requestFocus();
    _wake();
    setState(() {});
  }

  void _zoom(double factor) {
    camera.zoomAt(camera.zoom * factor, camera.viewport.center(Offset.zero));
    _view.invalidate();
    _wake();
  }

  Future<void> _inspectCrew() async {
    final actor = movement.actors[movement.selected];
    if (actor == null) return;
    _stopInput();
    final member = actor.member;
    final route = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GameSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CrewBean(
                    role: member.role,
                    mood: member.mood,
                    suitColorIndex: member.suit,
                    visorTintIndex: member.visor,
                    faceStyleIndex: member.face,
                    size: GameSpacing.missionCrewSize,
                    reducedMotion: true,
                  ),
                ),
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${member.role.name[0].toUpperCase()}${member.role.name.substring(1)}',
                ),
                const SizedBox(height: GameSpacing.sm),
                Text(switch (member.role) {
                  CrewRole.commander =>
                    'Coordinates plans and helps the crew compare trade-offs.',
                  CrewRole.engineer => 'Builds and repairs equipment through the existing job plans.',
                  CrewRole.scientist => 'Studies evidence. Research and survey activities unlock later.',
                  CrewRole.medic => 'Looks after the crew. Care and drill activities unlock later.',
                }),
                const SizedBox(height: GameSpacing.md),
                Text(
                  'Current assignment: ${member.task?.replaceAll('_', ' ') ?? 'Available / resting'}',
                ),
                Text('Destination: ${movement.destinationLabel}'),
                if (member.remainingLabel != null) ...[
                  Text(member.remainingLabel!),
                  const DataClassChip(DataClass.game),
                ],
                if (member.progress != null)
                  LinearProgressIndicator(value: member.progress),
                const SizedBox(height: GameSpacing.md),
                const Text(
                  'Direct control and exterior visits do not cancel or complete assigned work. Build and Crew use the existing job rules.',
                ),
                if (widget.onManage != null)
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, '/crew'),
                    child: const Text('Manage crew responsibilities'),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to settlement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && route != null) widget.onManage?.call(route);
  }

  String _stateLabel(MarsFacility site) => site.referenceOnly && site.count == 0
      ? 'Station site / no construction recipe'
      : site.condition == 'underConstruction'
      ? 'Construction in progress'
      : site.count == 0
      ? site.available
            ? 'Available to build'
            : 'Not installed / locked'
      : '${site.condition.replaceAll(RegExp(r'(?=[A-Z])'), ' ').toLowerCase()} / ${site.count} installed';

  void _inspectAt(Offset screenPoint) {
    final point = camera.screenToWorld(screenPoint);
    final candidates = <(double, VoidCallback)>[];
    final actors = movement.actors.values.toList()
      ..sort((a, b) => b.position.dy.compareTo(a.position.dy));
    for (final actor in actors) {
      final body = Rect.fromCenter(
        center: actor.position.translate(0, -GameSpacing.mapAstronaut / 2),
        width: GameSpacing.touchTarget / camera.zoom,
        height: GameSpacing.touchTarget / camera.zoom,
      );
      if (body.contains(point)) {
        candidates.add((
          (point - body.center).distanceSquared,
          () => _select(actor.member),
        ));
      }
    }
    final sites = widget.facilities.toList()
      ..sort((a, b) => b.position.dy.compareTo(a.position.dy));
    for (final site in sites) {
      final hull = SettlementLayout.hull(site, SettlementView.world);
      final target = Rect.fromCenter(
        center: hull.center,
        width: math.max(hull.width, GameSpacing.touchTarget / camera.zoom),
        height: math.max(hull.height, GameSpacing.touchTarget / camera.zoom),
      );
      if (target.contains(point)) {
        candidates.add((
          (point - target.center).distanceSquared,
          () {
            _inspect(site);
          },
        ));
      }
    }
    // Minimum touch targets can overlap at overview zoom. Pick the closest
    // visual anchor so a nearby astronaut cannot make a building unselectable.
    candidates.sort((a, b) => a.$1.compareTo(b.$1));
    if (candidates.isNotEmpty) {
      candidates.first.$2();
    }
  }

  Future<void> _inspect(MarsFacility site) async {
    _stopInput();
    setState(() => _inspectedId = site.id);
    final actor = movement.actors[movement.selected];
    final canApproach =
        site.count > 0 ||
        actor?.member.task == 'construction' &&
            SettlementLayout.painterId(actor?.member.target ?? '') == site.id;
    final route = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.min(
              SettlementView.inspectionMaxHeight,
              MediaQuery.sizeOf(context).height * .7,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GameSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(site.label, style: Theme.of(context).textTheme.titleLarge),
                Text(_stateLabel(site)),
                Text(
                  'Installed: ${site.count} / damaged: ${site.damagedUnits} / visual tier: ${site.level}',
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: DataClassChip(DataClass.game),
                ),
                if (site.jobLabel != null) ...[
                  Text(
                    'Saved work: ${site.jobLabel!.replaceAll('_', ' ')}. This is the last checked job snapshot.',
                  ),
                  LinearProgressIndicator(value: site.jobProgress),
                ],
                const SizedBox(height: GameSpacing.sm),
                Text(
                  'Selected: ${actor?.member.name ?? 'No astronaut'}. Task: ${actor?.member.task ?? 'available'}.',
                ),
                const Text(
                  'Approach the exterior to look around. Walking never repairs, produces resources or completes work.',
                ),
                const SizedBox(height: GameSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'locate'),
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Show on map'),
                ),
                FilledButton(
                  onPressed: canApproach
                      ? () => Navigator.pop(context, 'approach')
                      : null,
                  child: const Text('Approach facility'),
                ),
                if (!canApproach)
                  const Text(
                    'Unavailable: this facility is not installed. Use an existing plan before visiting.',
                  ),
                if (widget.onManage != null) ...[
                  if (!site.referenceOnly && site.id != 'landing_craft')
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, '/build'),
                      child: const Text('Build, upgrade or repair plans'),
                    ),
                  if (site.id == 'research_lab')
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context, '/research'),
                      child: const Text('Review research plans'),
                    ),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, '/crew'),
                    child: const Text('Review crew assignments'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close inspection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (route == 'approach') {
      movement.approach(site.id);
      camera.following = true;
      _wake();
    } else if (route == 'locate') {
      camera.frame(
        Offset(
          site.position.dx * SettlementView.world.width,
          site.position.dy * SettlementView.world.height,
        ),
      );
      _view.invalidate();
    } else if (route != null) {
      widget.onManage?.call(route);
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_wasActive) {
      _stopInput();
    }
    _ticker.dispose();
    _focus.dispose();
    _view.dispose();
    _terrain?.dispose();
    for (final picture in _buildingPictures.values) {
      picture.dispose();
    }
    if (widget.movement == null) {
      movement.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        widget.reducedMotion ||
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Focus(
      focusNode: _focus,
      onKeyEvent: _key,
      onFocusChange: (focused) {
        if (!focused && _wasActive) {
          _stopInput();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (_active) {
                movement.configure(
                  SettlementView.world,
                  widget.facilities,
                  widget.crew,
                  reduceMotion: reduced,
                );
                camera.layout(
                  Size(constraints.maxWidth, widget.height),
                  movement.actors[movement.selected]?.position ??
                      SettlementView.world.center(Offset.zero),
                );
                _afterLayout();
              }
              final terrainKey = '${widget.night}:${widget.storm}';
              if (_terrain == null || _terrainKey != terrainKey) {
                _terrain?.dispose();
                final recorder = ui.PictureRecorder();
                MarsBasePainter(
                  facilities: const [],
                  sunset: widget.night,
                  storm: widget.storm,
                  terrainOnly: true,
                ).paint(Canvas(recorder), SettlementView.world);
                _terrain = recorder.endRecording();
                _terrainKey = terrainKey;
              }
              _cacheBuildings();
              return Semantics(
                image: true,
                label:
                    'Mars settlement. Enable Look around to drag or pinch; zoom buttons are always available. '
                    'Select a building to inspect. Select a crew role below to move an astronaut.',
                child: ClipRect(
                  child: GestureDetector(
                    key: const ValueKey('settlement-viewport'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (event) => _inspectAt(event.localPosition),
                    onScaleStart: !_lookAround
                        ? null
                        : (_) {
                            _stopInput();
                            _gestureZoom = camera.zoom;
                          },
                    onScaleUpdate: !_lookAround
                        ? null
                        : (details) {
                            camera.pan(details.focalPointDelta);
                            camera.zoomAt(
                              _gestureZoom * details.scale,
                              details.localFocalPoint,
                            );
                            _view.invalidate();
                          },
                    child: RepaintBoundary(
                      child: SizedBox(
                        height: widget.height,
                        child: CustomPaint(
                          painter: _SettlementScenePainter(
                            movement: movement,
                            camera: camera,
                            terrain: _terrain!,
                            buildings: Map.unmodifiable(_buildingPictures),
                            facilities: widget.facilities,
                            dust: widget.dust,
                            storm: widget.storm,
                            selectedFacility: _inspectedId,
                            repaint: Listenable.merge([movement, _view]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GameSpacing.sm),
            child: Wrap(
              spacing: GameSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                IconButton(
                  tooltip: _lookAround ? 'Scroll page' : 'Look around',
                  isSelected: _lookAround,
                  icon: const Icon(Icons.pan_tool_outlined),
                  onPressed: () {
                    _stopInput();
                    setState(() => _lookAround = !_lookAround);
                  },
                ),
                IconButton(
                  tooltip: 'Zoom in',
                  onPressed: () => _zoom(SettlementView.zoomStep),
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Zoom out',
                  onPressed: () => _zoom(1 / SettlementView.zoomStep),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: 'Follow selected astronaut',
                  onPressed: () {
                    camera.following = true;
                    _wake();
                    setState(() {});
                  },
                  icon: const Icon(Icons.my_location),
                ),
                IconButton(
                  tooltip: 'Settlement overview',
                  onPressed: () {
                    camera.overview();
                    _view.invalidate();
                    setState(() {});
                  },
                  icon: const Icon(Icons.map_outlined),
                ),
                Text(
                  _lookAround
                      ? 'Camera: drag / pinch. Scroll page exits.'
                      : 'Page scroll enabled. Look around unlocks the camera.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(GameSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Settlement crew',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Visual movement only. Assignments stay active.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Selected: ${widget.crew.where((c) => c.id == movement.selected).firstOrNull?.name ?? 'No astronaut'}'
                  ' - ${movement.selected}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                Text(
                  'Task: ${widget.crew.where((c) => c.id == movement.selected).firstOrNull?.task?.replaceAll('_', ' ') ?? 'available'}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Destination: ${movement.destinationLabel}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.crew
                        .where((c) => c.id == movement.selected)
                        .firstOrNull
                        ?.progress
                    case final double progress)
                  LinearProgressIndicator(value: progress),
                if (widget.crew
                        .where((c) => c.id == movement.selected)
                        .firstOrNull
                        ?.remainingLabel
                    case final String remaining) ...[
                  Text(remaining),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: DataClassChip(DataClass.game),
                  ),
                ],
                const SizedBox(height: GameSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('inspect-selected-crew'),
                  onPressed: movement.actors[movement.selected] == null
                      ? null
                      : _inspectCrew,
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Inspect selected astronaut'),
                ),
                const SizedBox(height: GameSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: GameSpacing.xs,
                            runSpacing: GameSpacing.xs,
                            children: [
                              for (final member in widget.crew)
                                Semantics(
                                  selected: movement.selected == member.id,
                                  button: true,
                                  label:
                                      'Control ${member.name}, ${member.role.name}',
                                  child: Tooltip(
                                    message:
                                        '${member.name} - ${member.role.name}',
                                    child: SizedBox(
                                      width: GameSpacing.touchTarget,
                                      height: GameSpacing.touchTarget,
                                      child: OutlinedButton(
                                        key: ValueKey('select-${member.id}'),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(
                                            GameSpacing.touchTarget,
                                            GameSpacing.touchTarget,
                                          ),
                                          backgroundColor:
                                              movement.selected == member.id
                                              ? GameColors.tealLight
                                              : null,
                                        ),
                                        onPressed: () => _select(member),
                                        child: Icon(switch (member.role) {
                                          CrewRole.commander => Icons.star,
                                          CrewRole.engineer => Icons.build,
                                          CrewRole.scientist => Icons.science,
                                          CrewRole.medic =>
                                            Icons.medical_services,
                                        }),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: GameSpacing.sm),
                          Text(
                            movement.manual
                                ? 'DIRECT CONTROL'
                                : movement.visiting
                                ? 'APPROACHING'
                                : 'AUTONOMOUS',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            'WASD / arrows',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Tooltip(
                            message:
                                'Return to assignment. Work has stayed active.',
                            child: OutlinedButton(
                              key: const ValueKey('release-crew'),
                              onPressed: () {
                                _stopInput();
                                movement.release();
                                _focus.unfocus();
                                _wake();
                                setState(() {});
                              },
                              child: const Text('Auto walk'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: GameSpacing.sm),
                    VirtualCrewJoystick(
                      onStep: (direction) {
                        movement.nudge(direction);
                        _focus.requestFocus();
                        _wake();
                        setState(() {});
                      },
                      onDirection: (direction) {
                        if (!movement.manual && direction != Offset.zero) {
                          movement.select(movement.selected);
                          setState(() {});
                        }
                        movement.input(direction);
                        _focus.requestFocus();
                        _wake();
                      },
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text('Facilities and interactions'),
                  children: [
                    for (final facility in widget.facilities)
                      ListTile(
                        title: Text(
                          facility.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_stateLabel(facility)),
                        trailing: const Icon(Icons.info_outline),
                        onTap: () => _inspect(facility),
                      ),
                  ],
                ),
                ValueListenableBuilder<String>(
                  valueListenable: movement.feedback,
                  builder: (context, value, _) => Text(
                    value,
                    key: const ValueKey('movement-status'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drag joystick plus discrete semantic directions for switch/screen-reader
/// users. Pointer cancellation and lift always stop the direct velocity.
class VirtualCrewJoystick extends StatefulWidget {
  const VirtualCrewJoystick({
    super.key,
    required this.onDirection,
    required this.onStep,
  });
  final ValueChanged<Offset> onDirection;
  final ValueChanged<Offset> onStep;
  @override
  State<VirtualCrewJoystick> createState() => _VirtualCrewJoystickState();
}

class _VirtualCrewJoystickState extends State<VirtualCrewJoystick> {
  Offset _value = Offset.zero;
  int? _pointer;
  void _update(Offset local) {
    final center = const Offset(
      GameSpacing.joystick / 2,
      GameSpacing.joystick / 2,
    );
    final delta =
        (local - center) /
        ((GameSpacing.joystick - GameSpacing.joystickKnob) / 2);
    _value = delta.distance > 1 ? delta / delta.distance : delta;
    setState(() {});
    widget.onDirection(_value);
  }

  void _stop() {
    _pointer = null;
    _value = Offset.zero;
    setState(() {});
    widget.onDirection(Offset.zero);
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Listener(
        key: const ValueKey('crew-joystick'),
        onPointerDown: (e) {
          if (_pointer == null) {
            _pointer = e.pointer;
            _update(e.localPosition);
          }
        },
        onPointerMove: (e) {
          if (_pointer == e.pointer) {
            _update(e.localPosition);
          }
        },
        onPointerUp: (e) {
          if (_pointer == e.pointer) {
            _stop();
          }
        },
        onPointerCancel: (e) {
          if (_pointer == e.pointer) {
            _stop();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) {},
          onPanUpdate: (_) {},
          onPanEnd: (_) {},
          onPanCancel: _stop,
          child: Semantics(
            label: 'Movement joystick. Drag in a direction; lift to stop.',
            child: Container(
              width: GameSpacing.joystick,
              height: GameSpacing.joystick,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GameColors.tealLight,
                border: Border.all(color: GameColors.teal),
              ),
              child: Center(
                child: Transform.translate(
                  offset:
                      _value *
                      ((GameSpacing.joystick - GameSpacing.joystickKnob) / 2),
                  child: Container(
                    width: GameSpacing.joystickKnob,
                    height: GameSpacing.joystickKnob,
                    decoration: const BoxDecoration(
                      color: GameColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.open_with, color: GameColors.paper),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (final row in const [
            (Icons.arrow_back, 'left', Offset(-1, 0)),
            (Icons.arrow_upward, 'up', Offset(0, -1)),
            (Icons.arrow_downward, 'down', Offset(0, 1)),
            (Icons.arrow_forward, 'right', Offset(1, 0)),
          ])
            SizedBox(
              width: GameSpacing.touchTarget,
              height: GameSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Move ${row.$2}',
                icon: Icon(row.$1),
                onPressed: () => widget.onStep(row.$3),
              ),
            ),
        ],
      ),
    ],
  );
}

class _SettlementScenePainter extends CustomPainter {
  _SettlementScenePainter({
    required this.movement,
    required this.camera,
    required this.terrain,
    required this.buildings,
    required this.facilities,
    required this.dust,
    required this.storm,
    required this.selectedFacility,
    required Listenable repaint,
  }) : super(repaint: repaint);
  final CrewMovement movement;
  final SettlementCamera camera;
  final ui.Picture terrain;
  final Map<String, ui.Picture> buildings;
  final List<MarsFacility> facilities;
  final double dust;
  final bool storm;
  final String? selectedFacility;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final origin = camera.worldToScreen(Offset.zero);
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(camera.zoom);
    canvas.drawPicture(terrain);
    final layers = <(double, VoidCallback)>[
      for (final site in facilities)
        (
          site.position.dy * SettlementView.world.height + 20,
          () {
            if (site.id == selectedFacility) {
              canvas.drawOval(
                SettlementLayout.hull(site, SettlementView.world).inflate(4),
                Paint()
                  ..color = GameColors.sand
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
            }
            final picture = buildings[site.id];
            if (picture != null) canvas.drawPicture(picture);
          },
        ),
      for (final actor in movement.actors.values)
        (actor.position.dy, () => _paintActor(canvas, actor)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final layer in layers) {
      layer.$2();
    }
    MarsTerrain.atmosphere(
      canvas,
      SettlementView.world,
      seconds: movement.animationSeconds,
      reducedMotion: movement.reducedMotion,
      storm: storm,
    );
    canvas.restore();
  }

  void _paintActor(Canvas canvas, MovingCrew actor) {
    final member = actor.member;
    const width = GameSpacing.mapAstronaut;
    const height = width * 1.16;
    if (member.id == movement.selected) {
      canvas.drawOval(
        Rect.fromCenter(
          center: actor.position,
          width: width,
          height: width / 3,
        ),
        Paint()
          ..color = GameColors.sand
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final working = movement.atAssignment(actor) && member.task != null;
    if (working) {
      canvas.drawCircle(
        actor.position.translate(width / 2, -height / 2),
        4,
        Paint()..color = GameColors.tealLight,
      );
    }
    canvas.save();
    canvas.translate(
      actor.position.dx - width / 2,
      actor.position.dy - height * .88,
    );
    CrewBeanPainter(
      role: member.role,
      mood: working || member.task == null ? member.mood : CrewMood.okay,
      suitColor: crewSuitColors[member.suit % crewSuitColors.length],
      visorTint: crewVisorColors[member.visor % crewVisorColors.length],
      faceStyleIndex: member.face,
      breath: movement.reducedMotion
          ? 0
          : (math.sin(movement.animationSeconds * 2) + 1) / 2,
      walking: actor.walking && !movement.reducedMotion,
      walkPhase: movement.animationSeconds / CrewMotion.stride,
      facing: actor.facing,
      activity: working ? member.task : null,
      activityPhase: movement.reducedMotion ? 0 : movement.animationSeconds,
      carryingReservedEquipment: actor.walking && member.hasReservedEquipment,
    ).paint(canvas, const Size(width, height));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SettlementScenePainter oldDelegate) =>
      terrain != oldDelegate.terrain ||
      buildings.entries.any(
        (entry) => oldDelegate.buildings[entry.key] != entry.value,
      ) ||
      buildings.length != oldDelegate.buildings.length ||
      facilities != oldDelegate.facilities ||
      dust != oldDelegate.dust ||
      storm != oldDelegate.storm ||
      selectedFacility != oldDelegate.selectedFacility ||
      movement != oldDelegate.movement ||
      camera != oldDelegate.camera;
}
