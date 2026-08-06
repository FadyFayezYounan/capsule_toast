// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_manager.dart';
import '../motion/capsule_motion_controller.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme.dart';
import '../widgets/capsule_toast_presentation.dart';
import '../widgets/capsule_toast_viewport.dart';

/// Application-owned host that exposes toast queue control to descendants.
class CapsuleToastHost extends StatefulWidget {
  /// Creates a host that retains at most [maximumQueueLength] queued toasts.
  const CapsuleToastHost({
    super.key,
    this.maximumQueueLength = 20,
    required this.child,
  }) : assert(maximumQueueLength >= 0);

  /// Maximum queued records behind the active toast.
  final int maximumQueueLength;

  /// Application content rendered beneath the toast layer.
  final Widget child;

  /// Returns the nearest host-owned [CapsuleToastManager].
  ///
  /// Throws a [FlutterError] when no host is installed above [context].
  static CapsuleToastManager of(BuildContext context) {
    final _CapsuleToastScope? scope = context
        .getInheritedWidgetOfExactType<_CapsuleToastScope>();
    if (scope != null) {
      return scope.manager;
    }
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary(
        'CapsuleToastHost.of() called with a context that does not contain a '
        'CapsuleToastHost.',
      ),
      ErrorDescription(
        'No CapsuleToastHost ancestor could be found starting from the context '
        'that was passed to CapsuleToastHost.of().',
      ),
      ErrorHint(
        'Install a CapsuleToastHost above the context that calls '
        'CapsuleToastHost.of(), typically through MaterialApp.builder:',
      ),
      ErrorDescription(
        "MaterialApp(\n"
        "  builder: (context, child) {\n"
        "    return CapsuleToastHost(child: child!);\n"
        "  },\n"
        "  home: ...,\n"
        ")",
      ),
      context.describeElement('The context used was'),
    ]);
  }

  /// Returns the nearest host-owned manager, or `null` when absent.
  static CapsuleToastManager? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CapsuleToastScope>()
        ?.manager;
  }

  @override
  State<CapsuleToastHost> createState() => _CapsuleToastHostState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('maximumQueueLength', maximumQueueLength));
  }
}

class _CapsuleToastHostState extends State<CapsuleToastHost>
    with TickerProviderStateMixin {
  late final CapsuleToastCoordinator _coordinator;
  CapsuleMotionController? _motion;

  // Owned for the lifetime of this state so the toast layer gets its own
  // Overlay ancestor: the layer sits beside `widget.child` (see build()
  // below), not inside its Navigator, so toast content that needs
  // Overlay.of(context) (Tooltip, PopupMenuButton, text-selection toolbars,
  // ...) would otherwise throw "No Overlay widget found". Created once,
  // since Overlay.initialEntries is only consumed on first mount; the
  // builder reads _motion lazily because didChangeDependencies always runs
  // before this entry's builder is first invoked.
  late final OverlayEntry _toastEntry = OverlayEntry(
    builder: (BuildContext context) => CapsuleToastViewport(
      coordinator: _coordinator,
      child: CapsuleToastPresentation(
        coordinator: _coordinator,
        motion: _motion!,
        vsync: this,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _coordinator = CapsuleToastCoordinator(
      maximumQueueLength: widget.maximumQueueLength,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    );
    final CapsuleMotionController? existing = _motion;
    if (existing == null) {
      _motion = CapsuleMotionController(
        vsync: this,
        motionTheme: motionTheme,
        onHoldElapsed: _coordinator.timeoutActive,
        onExitCompleted: _coordinator.finishActiveExit,
      );
    } else {
      existing.updateMotionTheme(motionTheme);
    }
  }

  @override
  void didUpdateWidget(covariant CapsuleToastHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.maximumQueueLength != oldWidget.maximumQueueLength) {
      _coordinator.updateMaximumQueueLength(widget.maximumQueueLength);
    }
  }

  @override
  void dispose() {
    _toastEntry
      ..remove()
      ..dispose();
    _motion?.dispose();
    _motion = null;
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CapsuleToastScope(
      manager: _coordinator,
      child: CustomMultiChildLayout(
        delegate: _CapsuleToastHostLayout(),
        children: <Widget>[
          LayoutId(id: _CapsuleToastHostSlot.body, child: widget.child),
          LayoutId(
            id: _CapsuleToastHostSlot.presentation,
            child: Overlay(initialEntries: <OverlayEntry>[_toastEntry]),
          ),
        ],
      ),
    );
  }
}

enum _CapsuleToastHostSlot { body, presentation }

class _CapsuleToastHostLayout extends MultiChildLayoutDelegate {
  _CapsuleToastHostLayout();

  @override
  void performLayout(Size size) {
    final BoxConstraints constraints = BoxConstraints.tight(size);
    layoutChild(_CapsuleToastHostSlot.body, constraints);
    positionChild(_CapsuleToastHostSlot.body, Offset.zero);
    layoutChild(_CapsuleToastHostSlot.presentation, constraints);
    positionChild(_CapsuleToastHostSlot.presentation, Offset.zero);
  }

  @override
  bool shouldRelayout(_CapsuleToastHostLayout oldDelegate) => false;
}

class _CapsuleToastScope extends InheritedWidget {
  const _CapsuleToastScope({required this.manager, required super.child});

  final CapsuleToastManager manager;

  @override
  bool updateShouldNotify(covariant _CapsuleToastScope oldWidget) {
    return false;
  }
}
