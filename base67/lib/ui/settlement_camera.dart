import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'theme.dart';

/// View-only transform. Camera motion never changes world positions or paths.
class SettlementCamera {
  SettlementCamera({this.world = SettlementView.world});
  final Size world;
  Size viewport = Size.zero;
  Offset center = Offset.zero;
  double zoom = SettlementView.initialZoom;
  bool following = true;
  bool _initialized = false;

  double get minimumZoom => viewport.isEmpty
      ? .1
      : math.min(viewport.width / world.width, viewport.height / world.height);

  void layout(Size next, Offset focus) {
    viewport = next;
    zoom = zoom
        .clamp(minimumZoom, math.max(minimumZoom, SettlementView.maxZoom))
        .toDouble();
    if (!_initialized) {
      center = focus;
      _initialized = true;
    }
    center = _bounded(center);
  }

  Offset _bounded(Offset point) {
    double axis(double value, double extent, double view) =>
        view / zoom >= extent
        ? extent / 2
        : value.clamp(view / zoom / 2, extent - view / zoom / 2).toDouble();
    return Offset(
      axis(point.dx, world.width, viewport.width),
      axis(point.dy, world.height, viewport.height),
    );
  }

  Offset worldToScreen(Offset point) =>
      (point - center) * zoom + viewport.center(Offset.zero);
  Offset screenToWorld(Offset point) =>
      (point - viewport.center(Offset.zero)) / zoom + center;

  void pan(Offset screenDelta) {
    following = false;
    center = _bounded(center - screenDelta / zoom);
  }

  void zoomAt(double value, Offset screenAnchor) {
    final before = screenToWorld(screenAnchor);
    zoom = value
        .clamp(minimumZoom, math.max(minimumZoom, SettlementView.maxZoom))
        .toDouble();
    center = _bounded(
      before - (screenAnchor - viewport.center(Offset.zero)) / zoom,
    );
  }

  void overview() {
    following = false;
    zoom = minimumZoom;
    center = world.center(Offset.zero);
  }

  /// Explicit accessible alternative to dragging to a facility. Never moves an
  /// astronaut or changes their task. Uses the same bounds as pan and follow.
  void frame(Offset point) {
    following = false;
    zoomAt(
      math.max(zoom, SettlementView.initialZoom),
      viewport.center(Offset.zero),
    );
    center = _bounded(point);
  }

  bool needsFollow(Offset point) =>
      following &&
      (_bounded(point) - center).distance > SettlementView.cameraEpsilon;

  bool follow(Offset point, double seconds, {required bool reducedMotion}) {
    if (!needsFollow(point)) {
      return false;
    }
    final target = _bounded(point);
    // Reduced motion tracks position directly; no catch-up sweep or zoom loop.
    center = reducedMotion
        ? target
        : Offset.lerp(
            center,
            target,
            1 -
                math.exp(
                  -SettlementView.followResponse *
                      seconds.clamp(0, CrewMotion.maxFrameSeconds),
                ),
          )!;
    if ((center - target).distance <= SettlementView.cameraEpsilon) {
      center = target;
    }
    return true;
  }
}
