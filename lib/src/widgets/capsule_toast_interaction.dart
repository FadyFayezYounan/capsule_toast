// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
import '../model/capsule_toast_types.dart';
import '../motion/capsule_motion_controller.dart';
import '../theme/capsule_toast_motion_theme.dart';

/// Focus scope and gesture surface for the active capsule toast.
///
/// Owns pointer, hover, drag, long-press, and focus state so
/// `CapsuleToastLayer` can stay focused on motion sequencing and layout.
final class CapsuleToastInteraction extends StatefulWidget {
  /// Creates an interaction surface around [child] for [record].
  const CapsuleToastInteraction({
    super.key,
    required this.record,
    required this.coordinator,
    required this.motion,
    required this.motionTheme,
    required this.child,
  });

  /// Active toast record this surface toggles and dismisses.
  final CapsuleToastRecord record;

  /// Queue coordinator that mode toggles and dismissals are sent to.
  final CapsuleToastCoordinator coordinator;

  /// Host-owned motion controller driving capsule geometry.
  final CapsuleMotionController motion;

  /// Resolved motion theme supplying gesture thresholds.
  final CapsuleToastMotionTheme motionTheme;

  /// Rendered capsule content wrapped by the gesture and focus tree.
  final Widget child;

  @override
  State<CapsuleToastInteraction> createState() =>
      _CapsuleToastInteractionState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastRecord>('record', record));
    properties.add(
      DiagnosticsProperty<CapsuleToastCoordinator>('coordinator', coordinator),
    );
    properties.add(
      DiagnosticsProperty<CapsuleMotionController>('motion', motion),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastMotionTheme>('motionTheme', motionTheme),
    );
  }
}

class _CapsuleToastInteractionState extends State<CapsuleToastInteraction> {
  bool _pointerDown = false;
  bool _hovering = false;
  bool _dragging = false;
  bool _longPressActive = false;
  double _dragDy = 0;
  final FocusNode _capsuleFocusNode = FocusNode(
    debugLabel: 'capsule_toast.surface',
  );
  final FocusScopeNode _toastFocusScope = FocusScopeNode(
    debugLabel: 'capsule_toast.scope',
  );

  @override
  void initState() {
    super.initState();
    _scheduleFocusRequest();
  }

  @override
  void didUpdateWidget(covariant CapsuleToastInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record.token != widget.record.token) {
      _dragDy = 0;
      _dragging = false;
      _longPressActive = false;
      _scheduleFocusRequest();
    }
  }

  @override
  void dispose() {
    // Only clear the pause if this surface actually asserted one — the
    // motion controller is reused across records, so an unconditional call
    // would resume its hold clock (and restart its ticker) even when
    // nothing here ever paused it, leaving a dangling transient callback
    // after an otherwise-settled, already-dismissed toast is torn down.
    if (_pointerDown || _hovering || _dragging || _longPressActive) {
      widget.motion.setInteractionPaused(false);
    }
    _capsuleFocusNode.dispose();
    _toastFocusScope.dispose();
    super.dispose();
  }

  void _scheduleFocusRequest() {
    final int token = widget.record.token;
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      if (!mounted || widget.record.token != token) {
        return;
      }
      // The overlay sits beside the route's modal focus scope, so traversal
      // cannot discover it from the route. Focus the toast scope first;
      // the next Tab then reaches the capsule surface followed by actions.
      _toastFocusScope.requestFocus();
    });
  }

  void _syncInteractionPaused() {
    widget.motion.setInteractionPaused(
      _pointerDown || _hovering || _dragging || _longPressActive,
    );
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
    widget.motion.beginDrag();
  }

  void _updateDrag(
    DragUpdateDetails details,
    CapsuleToastMotionTheme motionTheme,
  ) {
    _dragDy += details.delta.dy;
    final double resistance = motionTheme.downwardDragResistance ?? 0.22;
    final double visual = _dragDy < 0 ? _dragDy : _dragDy * resistance;
    widget.motion.updateDragOffset(visual);
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
      widget.motion.cancelDrag();
    }
  }

  void _cancelDrag() {
    _dragging = false;
    _dragDy = 0;
    _pointerDown = false;
    _longPressActive = false;
    _syncInteractionPaused();
    widget.motion.cancelDrag();
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastRecord record = widget.record;
    final CapsuleToastMotionTheme motionTheme = widget.motionTheme;

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
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
