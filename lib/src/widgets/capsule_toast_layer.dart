// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

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
import 'capsule_toast_animated_slot.dart';

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
  Size? _compactSize;
  Size? _expandedSize;
  int? _activeToken;
  int _activeRevision = -1;
  CapsuleToastMode? _activeMode;
  CapsuleToastDismissReason? _pendingDismissal;
  bool _motionStarted = false;
  bool _syncScheduled = false;
  bool _pointerDown = false;
  bool _hovering = false;
  bool _dragging = false;
  bool _longPressActive = false;
  double _dragDy = 0;
  bool _entranceHapticFired = false;
  bool _resolveHapticPending = false;
  final FocusNode _capsuleFocusNode = FocusNode(
    debugLabel: 'capsule_toast.surface',
  )..skipTraversal = true;
  final FocusScopeNode _toastFocusScope = FocusScopeNode(
    debugLabel: 'capsule_toast.scope',
  );

  CapsuleMotionController get _motion => widget.motion;

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_handleCoordinatorChanged);
    _motion.addListener(_handleMotionChanged);
  }

  @override
  void didUpdateWidget(covariant CapsuleToastLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_handleCoordinatorChanged);
      widget.coordinator.addListener(_handleCoordinatorChanged);
    }
    if (oldWidget.motion != widget.motion) {
      oldWidget.motion.removeListener(_handleMotionChanged);
      widget.motion.addListener(_handleMotionChanged);
    }
  }

  @override
  void dispose() {
    _motion.removeListener(_handleMotionChanged);
    widget.coordinator.removeListener(_handleCoordinatorChanged);
    _capsuleFocusNode.dispose();
    _toastFocusScope.dispose();
    super.dispose();
  }

  void _handleCoordinatorChanged() {
    // Sync tracking immediately (mode changes defer spring retarget until
    // measure). Then rebuild so expanded/collapsed content is laid out in the
    // same frame the gesture ends — before a subsequent pump(duration).
    if (mounted) {
      _syncMotion();
      setState(() {});
    } else {
      _scheduleMotionSync();
    }
  }

  void _handleMotionChanged() {
    _maybeTriggerHaptic();
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
    _compactSize = null;
    _expandedSize = null;
    _pointerDown = false;
    _hovering = false;
    _dragging = false;
    _longPressActive = false;
    _dragDy = 0;
    _entranceHapticFired = false;
    _resolveHapticPending = false;
    _syncInteractionPaused();
  }

  void _syncInteractionPaused() {
    _motion.setInteractionPaused(
      _pointerDown || _hovering || _dragging || _longPressActive,
    );
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
    _motion.setReducedMotion(_isReducedMotion(motionTheme));

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
      _entranceHapticFired = false;
      _resolveHapticPending = false;
      _dragDy = 0;
      _dragging = false;
      _longPressActive = false;
      final bool hasActions =
          record.data.compactAction != null ||
          record.data.primaryAction != null ||
          record.data.secondaryAction != null;
      if (hasActions) {
        WidgetsBinding.instance.addPostFrameCallback((Duration _) {
          if (!mounted || _activeToken != record.token) {
            return;
          }
          _toastFocusScope.requestFocus();
        });
      }
    } else if (revisionChanged) {
      _motion.resolve(
        target: target,
        mode: record.desiredMode,
        holdDuration: holdDuration,
      );
      _activeRevision = record.revision;
      _activeMode = record.desiredMode;
      _resolveHapticPending = true;
    } else if (modeChanged) {
      // Retarget immediately so a following pump(duration) advances springs
      // toward the new mode. tester.tap does not pump after pointer-up, so
      // waiting for measure alone leaves the ticker on the old size.
      _activeMode = record.desiredMode;
      final Size current = _motion.value.size;
      if (record.desiredMode == CapsuleToastMode.expanded) {
        final Size guess =
            _expandedSize ??
            Size(current.width, math.max(current.height + 30, 80));
        _motion.expand(guess);
      } else {
        final Size guess = _compactSize ?? current;
        _motion.collapse(guess);
      }
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
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record != null) {
      if (record.desiredMode == CapsuleToastMode.compact) {
        _compactSize = size;
      } else {
        _expandedSize = size;
      }
    }
    if (!_motionStarted) {
      _scheduleMotionSync();
      return;
    }
    if (record == null) {
      return;
    }
    if (_activeToken != record.token || _activeRevision != record.revision) {
      _scheduleMotionSync();
      return;
    }
    if (_activeMode != record.desiredMode) {
      _scheduleMotionSync();
      return;
    }

    final CapsuleLifecycleState state = _motion.value.state;
    if (record.desiredMode == CapsuleToastMode.expanded &&
        state != CapsuleLifecycleState.expanded &&
        state != CapsuleLifecycleState.collapsing &&
        state != CapsuleLifecycleState.hidden) {
      _motion.expand(size);
      return;
    }
    if (record.desiredMode == CapsuleToastMode.compact &&
        state == CapsuleLifecycleState.expanded) {
      _motion.collapse(size);
      return;
    }
    _motion.retarget(size);
  }

  void _toggleMode(CapsuleToastRecord record) {
    if (record.desiredMode == CapsuleToastMode.compact) {
      widget.coordinator.expand(record.token);
    } else {
      widget.coordinator.collapse(record.token);
    }
  }

  void _expand(CapsuleToastRecord record) {
    widget.coordinator.expand(record.token);
  }

  void _startDrag(DragStartDetails details) {
    _dragging = true;
    _dragDy = 0;
    _syncInteractionPaused();
    _motion.beginDrag();
  }

  void _updateDrag(
    DragUpdateDetails details,
    CapsuleToastMotionTheme motionTheme,
  ) {
    _dragDy += details.delta.dy;
    final double resistance = motionTheme.downwardDragResistance ?? 0.22;
    final double visual = _dragDy < 0 ? _dragDy : _dragDy * resistance;
    _motion.updateDragOffset(visual);
  }

  void _finishDrag(
    DragEndDetails details,
    CapsuleToastRecord record,
    CapsuleToastMotionTheme motionTheme,
  ) {
    final double resistance = motionTheme.downwardDragResistance ?? 0.22;
    final double visual = _dragDy < 0 ? _dragDy : _dragDy * resistance;
    final double dismissalDistance = motionTheme.dismissalDistance ?? 26;
    final double dismissalVelocity = motionTheme.dismissalVelocity ?? 420;
    final double velocity = details.primaryVelocity ?? 0;
    final bool shouldDismiss =
        visual <= -dismissalDistance || -velocity >= dismissalVelocity;

    _dragging = false;
    _dragDy = 0;
    _pointerDown = false;
    _longPressActive = false;
    _syncInteractionPaused();

    if (shouldDismiss) {
      widget.coordinator.requestDismiss(
        record.token,
        CapsuleToastDismissReason.swiped,
        velocity: velocity.abs(),
      );
    } else {
      _motion.cancelDrag();
    }
  }

  void _cancelDrag() {
    _dragging = false;
    _dragDy = 0;
    _pointerDown = false;
    _longPressActive = false;
    _syncInteractionPaused();
    _motion.cancelDrag();
  }

  /// Distance the leading icon travels from the capsule centre to its rest
  /// position, signed for [textDirection].
  ///
  /// Derived from the measured target width for the desired mode so the icon
  /// tracks where it will come to rest, not where the spring happens to be.
  double _resolveIconTravel({
    required CapsuleToastRecord record,
    required CapsuleToastThemeData visualTheme,
    required TextDirection textDirection,
    required Size liveSize,
  }) {
    final bool compact = record.desiredMode == CapsuleToastMode.compact;
    final Size? modeSize = compact ? _compactSize : _expandedSize;
    final double targetWidth = (modeSize ?? _measuredSize ?? liveSize).width;
    final EdgeInsets padding =
        (compact ? visualTheme.compactPadding! : visualTheme.expandedPadding!)
            .resolve(textDirection);
    final double startInset = textDirection == TextDirection.rtl
        ? padding.right
        : padding.left;
    final double iconSize = compact
        ? visualTheme.compactIconSize!
        : visualTheme.expandedIconSize!;
    final double iconCenter = startInset + iconSize / 2;
    final double sign = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    return (targetWidth / 2 - iconCenter) * sign;
  }

  bool _isReducedMotion(CapsuleToastMotionTheme motionTheme) {
    return switch (motionTheme.reducedMotionPolicy ??
        CapsuleToastReducedMotionPolicy.system) {
      CapsuleToastReducedMotionPolicy.always => true,
      CapsuleToastReducedMotionPolicy.never => false,
      CapsuleToastReducedMotionPolicy.system => MediaQuery.disableAnimationsOf(
        context,
      ),
    };
  }

  bool _shouldTriggerHaptic(CapsuleToastMotionTheme motionTheme) {
    if (motionTheme.hapticPolicy !=
        CapsuleToastHapticPolicy.supportedPlatforms) {
      return false;
    }
    if (_isReducedMotion(motionTheme)) {
      return false;
    }
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _maybeTriggerHaptic() {
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null || !mounted) {
      return;
    }
    final CapsuleMotionSnapshot snapshot = _motion.value;
    if (!snapshot.isSettled) {
      return;
    }
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record.data.motionTheme);
    if (!_shouldTriggerHaptic(motionTheme)) {
      _entranceHapticFired = true;
      _resolveHapticPending = false;
      return;
    }
    if (!_entranceHapticFired) {
      _entranceHapticFired = true;
      _resolveHapticPending = false;
      HapticFeedback.lightImpact();
      return;
    }
    if (_resolveHapticPending) {
      _resolveHapticPending = false;
      HapticFeedback.lightImpact();
    }
  }

  Widget _buildInteractiveCapsule({
    required CapsuleToastRecord record,
    required CapsuleToastMotionTheme motionTheme,
    required Widget child,
  }) {
    // Own focus scope so action controls are reachable by Tab even though the
    // toast layer sits beside (not inside) the navigator route FocusScope.
    return FocusScope(
      node: _toastFocusScope,
      child: FocusTraversalGroup(
        child: FocusableActionDetector(
          focusNode: _capsuleFocusNode,
          descendantsAreFocusable: true,
          descendantsAreTraversable: true,
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                // Only toggle when the capsule surface itself is focused —
                // action buttons handle ActivateIntent with their own Actions.
                if (_capsuleFocusNode.hasFocus) {
                  _toggleMode(record);
                }
                return null;
              },
            ),
          },
          child: MouseRegion(
            onEnter: (_) {
              _hovering = true;
              _syncInteractionPaused();
            },
            onExit: (_) {
              _hovering = false;
              _syncInteractionPaused();
            },
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) {
                _pointerDown = true;
                _syncInteractionPaused();
              },
              onPointerUp: (_) {
                _pointerDown = false;
                _longPressActive = false;
                _syncInteractionPaused();
              },
              onPointerCancel: (_) {
                _pointerDown = false;
                _longPressActive = false;
                _dragging = false;
                _syncInteractionPaused();
              },
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  TapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer
                      >(TapGestureRecognizer.new, (
                        TapGestureRecognizer recognizer,
                      ) {
                        recognizer
                          ..onTapDown = (TapDownDetails _) {
                            _pointerDown = true;
                            _syncInteractionPaused();
                          }
                          ..onTapCancel = () {
                            // Pointer may still be down for long-press/drag;
                            // Listener onPointerUp clears the pause.
                          }
                          ..onTapUp = (TapUpDetails _) {
                            _capsuleFocusNode.requestFocus();
                            _toggleMode(record);
                          };
                      }),
                  LongPressGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        LongPressGestureRecognizer
                      >(
                        () => LongPressGestureRecognizer(
                          duration:
                              motionTheme.longPressDuration ??
                              const Duration(milliseconds: 320),
                        ),
                        (LongPressGestureRecognizer recognizer) {
                          recognizer
                            ..onLongPressStart = (LongPressStartDetails _) {
                              _longPressActive = true;
                              _pointerDown = true;
                              _syncInteractionPaused();
                              _expand(record);
                            }
                            ..onLongPressEnd = (LongPressEndDetails _) {
                              _longPressActive = false;
                              _syncInteractionPaused();
                            };
                        },
                      ),
                  VerticalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        VerticalDragGestureRecognizer
                      >(VerticalDragGestureRecognizer.new, (
                        VerticalDragGestureRecognizer recognizer,
                      ) {
                        recognizer
                          ..onStart = _startDrag
                          ..onUpdate = (DragUpdateDetails details) {
                            _updateDrag(details, motionTheme);
                          }
                          ..onEnd = (DragEndDetails details) {
                            _finishDrag(details, record, motionTheme);
                          }
                          ..onCancel = _cancelDrag;
                      }),
                },
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
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
    final bool reducedMotion = _isReducedMotion(motionTheme);
    _motion.setReducedMotion(reducedMotion);

    final double topInset = visualTheme.useSafeArea!
        ? MediaQuery.viewPaddingOf(context).top + visualTheme.verticalOffset!
        : visualTheme.verticalOffset!;

    final TextDirection textDirection =
        record.data.textDirection ?? Directionality.of(context);
    final String announcement = composeCapsuleToastAnnouncement(record.data);

    // Keep gesture detectors outside AnimatedBuilder so recognizers are not
    // recreated on every spring tick.
    final Widget interactiveChild = _buildInteractiveCapsule(
      record: record,
      motionTheme: motionTheme,
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
    );

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
              child: interactiveChild,
              builder: (BuildContext context, Widget? child) {
                final CapsuleMotionSnapshot snapshot = _motion.value;
                final double iconTravel = _resolveIconTravel(
                  record: record,
                  visualTheme: visualTheme,
                  textDirection: textDirection,
                  liveSize: snapshot.size,
                );
                return Transform.translate(
                  offset: Offset(0, snapshot.verticalOffset),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Opacity(
                        opacity: snapshot.opacity,
                        // Scales about the capsule's own centre, matching the
                        // reference's default transform origin.
                        child: Transform.scale(
                          scale: snapshot.scale,
                          alignment: Alignment.center,
                          child: SizedBox.fromSize(
                            size: snapshot.size,
                            child: CapsuleToastAnimationScope(
                              contentElapsed: _motion.contentElapsed,
                              revealing: _motion.contentRevealing,
                              reducedMotion: reducedMotion,
                              motionTheme: motionTheme,
                              textDirection: textDirection,
                              capsuleSize: snapshot.size,
                              iconTravel: iconTravel,
                              child: CapsuleToastSurface(
                                theme: visualTheme,
                                measureMaxWidth: measureMaxWidth,
                                liveSize: snapshot.size,
                                semanticsLabel: announcement,
                                child: CapsuleToastMeasure(
                                  onSizeChanged: _handleSizeChanged,
                                  child: child,
                                ),
                              ),
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
