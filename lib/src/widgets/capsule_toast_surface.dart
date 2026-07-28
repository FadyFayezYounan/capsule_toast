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
  });

  /// Fully resolved visual theme for this surface.
  final CapsuleToastThemeData theme;

  /// Structured toast content painted inside the capsule.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = math.min(
          theme.maximumWidth!,
          constraints.maxWidth - 2 * theme.horizontalInset!,
        );
        return RepaintBoundary(
          key: capsuleSurfaceKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: _CapsuleToastSurfaceBody(theme: theme, child: child),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastThemeData>('theme', theme));
  }
}

class _CapsuleToastSurfaceBody extends StatefulWidget {
  const _CapsuleToastSurfaceBody({required this.theme, required this.child});

  final CapsuleToastThemeData theme;
  final Widget child;

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
    final double radius = _laidOutSize == null
        ? widget.theme.radiusCap!
        : math.min(_laidOutSize!.height / 2, widget.theme.radiusCap!);

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
