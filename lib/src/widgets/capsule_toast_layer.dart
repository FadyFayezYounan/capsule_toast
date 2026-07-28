// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
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
  Size? _liveSize;
  int? _activeToken;
  int _activeRevision = -1;

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

  void _handleSizeChanged(Size size) {
    if (_liveSize == size) {
      return;
    }
    setState(() => _liveSize = size);
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null) {
      return const SizedBox.shrink();
    }

    if (_activeToken != record.token || _activeRevision != record.revision) {
      _activeToken = record.token;
      _activeRevision = record.revision;
      _liveSize = null;
    }

    final ThemeData appTheme = Theme.of(context);
    CapsuleToastTheme.maybeOfWidget(context);

    CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
      context,
    ).merge(record.data.theme);
    CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
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
          top: topInset,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: CapsuleToastMeasure(
            onSizeChanged: _handleSizeChanged,
            child: CapsuleToastSurface(
              theme: visualTheme,
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
            ),
          ),
        ),
      ),
    );
  }
}
