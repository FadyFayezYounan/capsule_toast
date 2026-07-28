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

class _CapsuleToastSurfaceBody extends StatelessWidget {
  const _CapsuleToastSurfaceBody({required this.theme, required this.child});

  final CapsuleToastThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CapsuleShapeClipper(radiusCap: theme.radiusCap!),
      child: DecoratedBox(
        key: const ValueKey<String>('capsule_toast.decoration'),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          border: Border.all(
            color: theme.borderColor!,
            width: theme.borderWidth!,
          ),
          boxShadow: theme.shadows,
        ),
        child: child,
      ),
    );
  }
}

class _CapsuleShapeClipper extends CustomClipper<Path> {
  const _CapsuleShapeClipper({required this.radiusCap});

  final double radiusCap;

  @override
  Path getClip(Size size) {
    final double radius = math.min(size.height / 2, radiusCap);
    return Path()..addRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
    );
  }

  @override
  bool shouldReclip(covariant _CapsuleShapeClipper oldClipper) {
    return radiusCap != oldClipper.radiusCap;
  }
}
