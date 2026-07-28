// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';

import 'capsule_toast_motion_theme.dart';
import 'capsule_toast_theme_data.dart';

/// Provides capsule toast visual and motion themes to descendants.
class CapsuleToastTheme extends InheritedTheme {
  /// Creates a theme scope with required [data] and optional [motionTheme].
  const CapsuleToastTheme({
    super.key,
    required this.data,
    this.motionTheme,
    required super.child,
  });

  /// Visual theme overrides for descendant toasts.
  final CapsuleToastThemeData data;

  /// Motion theme overrides for descendant toasts.
  final CapsuleToastMotionTheme? motionTheme;

  /// Returns the nearest [CapsuleToastThemeData], or throws if none exists.
  static CapsuleToastThemeData of(BuildContext context) {
    final CapsuleToastTheme? theme = maybeOfWidget(context);
    assert(
      theme != null,
      'CapsuleToastTheme.of() called with a context that does not contain a '
      'CapsuleToastTheme.',
    );
    return theme!.data;
  }

  /// Returns the nearest inherited visual theme, or `null` when absent.
  static CapsuleToastThemeData? maybeOf(BuildContext context) {
    return maybeOfWidget(context)?.data;
  }

  /// Resolves visual theme from defaults, extensions, and inherited scope.
  static CapsuleToastThemeData resolve(BuildContext context) {
    CapsuleToastThemeData resolved = CapsuleToastThemeData.fallback();
    final CapsuleToastThemeData? extension = Theme.of(
      context,
    ).extension<CapsuleToastThemeData>();
    if (extension != null) {
      resolved = resolved.merge(extension);
    }
    final CapsuleToastThemeData? inherited = maybeOf(context);
    if (inherited != null) {
      resolved = resolved.merge(inherited);
    }
    return resolved;
  }

  /// Resolves motion theme from defaults, extensions, and inherited scope.
  static CapsuleToastMotionTheme resolveMotion(BuildContext context) {
    CapsuleToastMotionTheme resolved = CapsuleToastMotionTheme.fallback();
    final CapsuleToastMotionTheme? extension = Theme.of(
      context,
    ).extension<CapsuleToastMotionTheme>();
    if (extension != null) {
      resolved = resolved.merge(extension);
    }
    final CapsuleToastMotionTheme? inherited = maybeOfWidget(
      context,
    )?.motionTheme;
    if (inherited != null) {
      resolved = resolved.merge(inherited);
    }
    return resolved;
  }

  static CapsuleToastTheme? maybeOfWidget(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CapsuleToastTheme>();
  }

  @override
  bool updateShouldNotify(covariant CapsuleToastTheme oldWidget) {
    return data != oldWidget.data || motionTheme != oldWidget.motionTheme;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return CapsuleToastTheme(
      data: data,
      motionTheme: motionTheme,
      child: child,
    );
  }
}
