// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../manager/capsule_toast_coordinator.dart';

/// Temporary toast overlay replaced by the production renderer in later tasks.
class CapsuleToastLayer extends StatefulWidget {
  /// Creates a layer that paints the active toast for [coordinator].
  const CapsuleToastLayer({
    super.key,
    required this.coordinator,
    required this.vsync,
  });

  /// Queue coordinator whose active record is rendered.
  final CapsuleToastCoordinator coordinator;

  /// Ticker provider reserved for motion controllers in later tasks.
  final TickerProvider vsync;

  @override
  State<CapsuleToastLayer> createState() => _CapsuleToastLayerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CapsuleToastCoordinator>('coordinator', coordinator),
    );
    properties.add(DiagnosticsProperty<TickerProvider>('vsync', vsync));
  }
}

class _CapsuleToastLayerState extends State<CapsuleToastLayer> {
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String? title = widget.coordinator.active?.data.title;
    if (title == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        key: const ValueKey<String>('capsule_toast.layer'),
        child: Text(title),
      ),
    );
  }
}
