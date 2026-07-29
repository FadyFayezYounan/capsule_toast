// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/capsule_toast_theme_data.dart';

/// Key identifying the live capsule surface for tests and diagnostics.
const Key capsuleSurfaceKey = ValueKey<String>('capsule_toast.surface');

/// Decorated, clipped capsule chrome around structured toast content.
class CapsuleToastSurface extends StatelessWidget {
  /// Creates a capsule surface styled with resolved [theme].
  const CapsuleToastSurface({
    super.key,
    required this.theme,
    required this.child,
    this.measureMaxWidth,
    this.liveSize,
    this.semanticsLabel,
  });

  /// Fully resolved visual theme for this surface.
  final CapsuleToastThemeData theme;

  /// Structured toast content painted inside the capsule.
  final Widget child;

  /// Maximum width used when measuring unconstrained content.
  final double? measureMaxWidth;

  /// Live spring-driven size used for clipping and corner radius.
  final Size? liveSize;

  /// Live-region announcement for the active toast.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth =
            measureMaxWidth ??
            math.min(
              theme.maximumWidth!,
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : theme.maximumWidth!,
            );
        final Size? clipSize = liveSize;

        final Widget surface;
        if (clipSize == null ||
            !constraints.hasTightWidth ||
            !constraints.hasTightHeight) {
          surface = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _CapsuleToastSurfaceBody(theme: theme, child: child),
          );
        } else {
          // Tight constraints are the live spring size, so the chrome is drawn
          // on the springing box itself and content overflows inside it. The
          // capsule is then the thing that moves: it grows around content on
          // the way out and shrinks around it on the way back, revealing and
          // absorbing the event from the inside out.
          surface = _CapsuleToastSurfaceBody(
            theme: theme,
            liveHeight: clipSize.height,
            overflowMaxWidth: maxWidth,
            child: child,
          );
        }

        return Semantics(
          key: capsuleSurfaceKey,
          container: true,
          liveRegion: true,
          label: semanticsLabel,
          explicitChildNodes: true,
          child: RepaintBoundary(child: surface),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastThemeData>('theme', theme));
    properties.add(DoubleProperty('measureMaxWidth', measureMaxWidth));
    properties.add(DiagnosticsProperty<Size?>('liveSize', liveSize));
    properties.add(StringProperty('semanticsLabel', semanticsLabel));
  }
}

class _CapsuleToastSurfaceBody extends StatefulWidget {
  const _CapsuleToastSurfaceBody({
    required this.theme,
    required this.child,
    this.liveHeight,
    this.overflowMaxWidth,
  });

  final CapsuleToastThemeData theme;
  final Widget child;
  final double? liveHeight;

  /// When non-null, content is centred at its natural size and allowed to
  /// overflow the capsule, which clips it.
  final double? overflowMaxWidth;

  @override
  State<_CapsuleToastSurfaceBody> createState() =>
      _CapsuleToastSurfaceBodyState();
}

class _CapsuleToastSurfaceBodyState extends State<_CapsuleToastSurfaceBody> {
  Size? _laidOutSize;
  bool _readScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) => _readSize());
  }

  void _readSize() {
    if (!mounted) {
      return;
    }
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _laidOutSize == box.size) {
      return;
    }
    setState(() => _laidOutSize = box.size);
  }

  // SizeChangedLayoutNotification is dispatched from inside layout, where this
  // box is an ancestor of the notifier: its size is off limits and setState is
  // a forbidden mid-frame rebuild. Both wait for the frame to end.
  void _handleSizeChanged() {
    if (_readScheduled) {
      return;
    }
    _readScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _readScheduled = false;
      _readSize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double radiusHeight =
        widget.liveHeight ?? _laidOutSize?.height ?? widget.theme.radiusCap!;
    final double radius = math.min(radiusHeight / 2, widget.theme.radiusCap!);
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    Widget content = NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        _handleSizeChanged();
        return false;
      },
      child: SizeChangedLayoutNotifier(child: widget.child),
    );
    if (widget.overflowMaxWidth case final double overflowMaxWidth) {
      content = OverflowBox(
        alignment: Alignment.center,
        minWidth: 0,
        maxWidth: overflowMaxWidth,
        minHeight: 0,
        maxHeight: double.infinity,
        child: content,
      );
    }

    // Fill, hairline and shadow belong to the capsule, so they are painted on
    // this box and the clip goes inside them. Clipping the decoration instead
    // would pin the visible pill to the content's size — it would snap to the
    // collapsed shape the instant the mode changed while only an invisible
    // window animated, and the shadow would be clipped away entirely.
    return DecoratedBox(
      key: const ValueKey<String>('capsule_toast.decoration'),
      decoration: BoxDecoration(
        color: widget.theme.surfaceColor,
        border: Border.all(
          color: widget.theme.borderColor!,
          width: widget.theme.borderWidth!,
        ),
        borderRadius: borderRadius,
        boxShadow: widget.theme.shadows,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: content),
    );
  }
}
