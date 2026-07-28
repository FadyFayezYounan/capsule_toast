// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  });

  /// Fully resolved visual theme for this surface.
  final CapsuleToastThemeData theme;

  /// Structured toast content painted inside the capsule.
  final Widget child;

  /// Maximum width used when measuring unconstrained content.
  final double? measureMaxWidth;

  /// Live spring-driven size used for clipping and corner radius.
  final Size? liveSize;

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
        final Widget body = _CapsuleToastSurfaceBody(
          theme: theme,
          liveHeight: clipSize?.height,
          child: child,
        );

        if (clipSize == null ||
            !constraints.hasTightWidth ||
            !constraints.hasTightHeight) {
          return RepaintBoundary(
            key: capsuleSurfaceKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          );
        }

        return RepaintBoundary(
          key: capsuleSurfaceKey,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              math.min(clipSize.height / 2, theme.radiusCap!),
            ),
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minWidth: 0,
              maxWidth: maxWidth,
              minHeight: 0,
              maxHeight: double.infinity,
              child: body,
            ),
          ),
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
  }
}

class _CapsuleToastSurfaceBody extends StatefulWidget {
  const _CapsuleToastSurfaceBody({
    required this.theme,
    required this.child,
    this.liveHeight,
  });

  final CapsuleToastThemeData theme;
  final Widget child;
  final double? liveHeight;

  @override
  State<_CapsuleToastSurfaceBody> createState() =>
      _CapsuleToastSurfaceBodyState();
}

class _CapsuleToastSurfaceBodyState extends State<_CapsuleToastSurfaceBody> {
  Size? _laidOutSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration _) {
      _handleSizeChanged();
    });
  }

  void _handleSizeChanged() {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final Size size = box.size;
    if (_laidOutSize == size) {
      return;
    }
    setState(() => _laidOutSize = size);
  }

  @override
  Widget build(BuildContext context) {
    final double radiusHeight =
        widget.liveHeight ?? _laidOutSize?.height ?? widget.theme.radiusCap!;
    final double radius = math.min(radiusHeight / 2, widget.theme.radiusCap!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (SizeChangedLayoutNotification notification) {
          _handleSizeChanged();
          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: DecoratedBox(
            key: const ValueKey<String>('capsule_toast.decoration'),
            decoration: BoxDecoration(
              color: widget.theme.surfaceColor,
              border: Border.all(
                color: widget.theme.borderColor!,
                width: widget.theme.borderWidth!,
              ),
              boxShadow: widget.theme.shadows,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
