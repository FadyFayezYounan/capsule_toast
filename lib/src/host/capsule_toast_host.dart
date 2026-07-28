// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_manager.dart';
import '../widgets/capsule_toast_layer.dart';

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

  @override
  void initState() {
    super.initState();
    _coordinator = CapsuleToastCoordinator(
      maximumQueueLength: widget.maximumQueueLength,
    );
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
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CapsuleToastScope(
      manager: _coordinator,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          widget.child,
          CapsuleToastLayer(coordinator: _coordinator, vsync: this),
        ],
      ),
    );
  }
}

class _CapsuleToastScope extends InheritedWidget {
  const _CapsuleToastScope({required this.manager, required super.child});

  final CapsuleToastManager manager;

  @override
  bool updateShouldNotify(covariant _CapsuleToastScope oldWidget) {
    return false;
  }
}
