// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_types.dart';
import '../motion/capsule_lifecycle.dart';
import '../motion/capsule_motion_controller.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme.dart';
import '../theme/capsule_toast_theme_data.dart';
import 'capsule_toast_content.dart';
import 'capsule_toast_measure.dart';
import 'capsule_toast_surface.dart';

/// Overlay that renders the active capsule toast for [coordinator].
class CapsuleToastLayer extends StatefulWidget {
  /// Creates a layer that paints the active toast for [coordinator].
  const CapsuleToastLayer({
    super.key,
    required this.coordinator,
    required this.motion,
    required this.vsync,
  });

  /// Queue coordinator whose active record is rendered.
  final CapsuleToastCoordinator coordinator;

  /// Host-owned motion controller driving capsule geometry.
  @visibleForTesting
  final CapsuleMotionController motion;

  /// Ticker provider for loading glyphs and other widget tickers.
  final TickerProvider vsync;

  @override
  State<CapsuleToastLayer> createState() => _CapsuleToastLayerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CapsuleToastCoordinator>('coordinator', coordinator),
    );
    properties.add(
      DiagnosticsProperty<CapsuleMotionController>('motion', motion),
    );
    properties.add(DiagnosticsProperty<TickerProvider>('vsync', vsync));
  }
}

class _CapsuleToastLayerState extends State<CapsuleToastLayer> {
  Size? _measuredSize;
  int? _activeToken;
  int _activeRevision = -1;
  CapsuleToastMode? _activeMode;
  CapsuleToastDismissReason? _pendingDismissal;
  bool _motionStarted = false;
  bool _syncScheduled = false;

  CapsuleMotionController get _motion => widget.motion;

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_handleCoordinatorChanged);
  }

  @override
  void didUpdateWidget(covariant CapsuleToastLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_handleCoordinatorChanged);
      widget.coordinator.addListener(_handleCoordinatorChanged);
    }
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_handleCoordinatorChanged);
    super.dispose();
  }

  void _handleCoordinatorChanged() {
    if (mounted) {
      _syncMotion();
    } else {
      _scheduleMotionSync();
    }
    setState(() {});
  }

  void _scheduleMotionSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncMotion();
    });
  }

  Duration? _resolveHoldDuration(
    CapsuleToastData data,
    CapsuleToastMotionTheme motionTheme,
  ) {
    if (data.persistent) {
      return null;
    }
    return data.displayDuration ?? motionTheme.durationFor(data.type);
  }

  void _resetTracking() {
    _motionStarted = false;
    _activeToken = null;
    _activeRevision = -1;
    _activeMode = null;
    _pendingDismissal = null;
    _measuredSize = null;
  }

  void _syncMotion() {
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null) {
      _resetTracking();
      return;
    }

    final CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
      context,
    ).merge(record.data.theme);
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record.data.motionTheme);
    _motion.updateMotionTheme(motionTheme);

    final Size seed = visualTheme.seedSize ?? const Size(84, 34);
    final Size target = _measuredSize ?? seed;
    final Duration? holdDuration = _resolveHoldDuration(
      record.data,
      motionTheme,
    );

    final bool tokenChanged = _activeToken != record.token;
    final bool revisionChanged = _activeRevision != record.revision;
    final bool modeChanged = _activeMode != record.desiredMode;

    if (!_motionStarted || tokenChanged) {
      if (_motionStarted && tokenChanged) {
        final CapsuleLifecycleState state = _motion.value.state;
        final bool needsFreshEntrance =
            state == CapsuleLifecycleState.hidden ||
            state == CapsuleLifecycleState.collapsing;
        if (needsFreshEntrance) {
          // After exit (or mid-exit swap), begin entrance — replace-from-hidden
          // never calls begin, so _advance would no-op and the toast stays
          // invisible. Mid-exit must also cancel collapsing so finishActiveExit
          // cannot complete the newly promoted record.
          _measuredSize = null;
          _motion.show(
            target: seed,
            mode: record.desiredMode,
            holdDuration: holdDuration,
          );
        } else {
          // Visible retarget: keep spring position and velocity.
          _motion.replace(
            target: target,
            mode: record.desiredMode,
            holdDuration: holdDuration,
          );
        }
      } else {
        _motion.show(
          target: target,
          mode: record.desiredMode,
          holdDuration: holdDuration,
        );
      }
      _motionStarted = true;
      _activeToken = record.token;
      _activeRevision = record.revision;
      _activeMode = record.desiredMode;
      _pendingDismissal = null;
    } else if (revisionChanged) {
      _motion.resolve(
        target: target,
        mode: record.desiredMode,
        holdDuration: holdDuration,
      );
      _activeRevision = record.revision;
      _activeMode = record.desiredMode;
    } else if (modeChanged) {
      if (record.desiredMode == CapsuleToastMode.expanded) {
        _motion.expand(target);
      } else {
        _motion.collapse(target);
      }
      _activeMode = record.desiredMode;
    } else if (_measuredSize != null) {
      _motion.retarget(_measuredSize!);
    }

    final CapsuleToastDismissReason? pending = record.pendingDismissal;
    if (pending != null && pending != _pendingDismissal) {
      _pendingDismissal = pending;
      _motion.dismiss(pending, velocity: record.dismissalVelocity);
    }
  }

  void _handleSizeChanged(Size size) {
    if (_measuredSize == size) {
      return;
    }
    _measuredSize = size;
    if (!_motionStarted) {
      _scheduleMotionSync();
      return;
    }
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null) {
      return;
    }
    if (_activeToken != record.token ||
        _activeRevision != record.revision ||
        _activeMode != record.desiredMode) {
      _scheduleMotionSync();
      return;
    }
    _motion.retarget(size);
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null) {
      if (_motionStarted) {
        _resetTracking();
      }
      return const SizedBox.shrink();
    }

    if (!_motionStarted ||
        _activeToken != record.token ||
        _activeRevision != record.revision ||
        _activeMode != record.desiredMode ||
        record.pendingDismissal != _pendingDismissal) {
      _scheduleMotionSync();
    }

    final ThemeData appTheme = Theme.of(context);
    final CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
      context,
    ).merge(record.data.theme);
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record.data.motionTheme);

    final double topInset = visualTheme.useSafeArea!
        ? MediaQuery.viewPaddingOf(context).top + visualTheme.verticalOffset!
        : visualTheme.verticalOffset!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: visualTheme.horizontalInset!,
          end: visualTheme.horizontalInset!,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double measureMaxWidth = math.min(
              visualTheme.maximumWidth!,
              constraints.maxWidth,
            );

            return AnimatedBuilder(
              animation: _motion,
              child: DefaultTextStyle.merge(
                style: appTheme.textTheme.bodyMedium,
                child: CapsuleToastContent(
                  record: record,
                  coordinator: widget.coordinator,
                  visualTheme: visualTheme,
                  motionTheme: motionTheme,
                  vsync: widget.vsync,
                ),
              ),
              builder: (BuildContext context, Widget? child) {
                final CapsuleMotionSnapshot snapshot = _motion.value;
                return Padding(
                  padding: EdgeInsets.only(
                    top: topInset + snapshot.verticalOffset,
                  ),
                  child: Opacity(
                    opacity: snapshot.opacity,
                    child: Transform.scale(
                      scale: snapshot.scale,
                      alignment: Alignment.topCenter,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox.fromSize(
                          size: snapshot.size,
                          child: CapsuleToastSurface(
                            theme: visualTheme,
                            measureMaxWidth: measureMaxWidth,
                            liveSize: snapshot.size,
                            child: CapsuleToastMeasure(
                              onSizeChanged: _handleSizeChanged,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
