// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/capsule_toast_types.dart';
import '../motion/capsule_easing.dart';
import '../theme/capsule_toast_motion_theme.dart';

/// Inherited animation inputs for [CapsuleToastAnimatedSlot].
@immutable
class CapsuleToastAnimationScope extends InheritedWidget {
  /// Creates a scope that drives staggered content slot reveals.
  const CapsuleToastAnimationScope({
    super.key,
    required this.contentElapsed,
    required this.revealing,
    required this.reducedMotion,
    required this.motionTheme,
    required this.textDirection,
    required this.capsuleSize,
    required this.iconTravel,
    required super.child,
  });

  /// Elapsed time within the active content envelope.
  final Duration contentElapsed;

  /// Whether content is entering (`true`) or exiting (`false`).
  final bool revealing;

  /// Whether reduced-motion presentation is active.
  final bool reducedMotion;

  /// Resolved motion theme providing slot delays and intervals.
  final CapsuleToastMotionTheme motionTheme;

  /// Resolved text direction used to mirror inline travel.
  final TextDirection textDirection;

  /// Live capsule size.
  final Size capsuleSize;

  /// Horizontal distance the leading icon travels from the capsule centre to
  /// its resting position, signed for the resolved [textDirection].
  ///
  /// The icon is the one slot that does not simply slide in: it appears at the
  /// centre of the seed capsule and rides outward as the capsule widens, so
  /// this is derived from the measured target width rather than the live size.
  final double iconTravel;

  /// Returns the nearest animation scope, or asserts when absent.
  static CapsuleToastAnimationScope of(BuildContext context) {
    final CapsuleToastAnimationScope? scope = maybeOf(context);
    assert(
      scope != null,
      'CapsuleToastAnimatedSlot requires a CapsuleToastAnimationScope '
      'ancestor installed by CapsuleToastPresentation.',
    );
    return scope!;
  }

  /// Returns the nearest animation scope, or null when absent.
  static CapsuleToastAnimationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<CapsuleToastAnimationScope>();
  }

  @override
  bool updateShouldNotify(covariant CapsuleToastAnimationScope oldWidget) {
    return contentElapsed != oldWidget.contentElapsed ||
        revealing != oldWidget.revealing ||
        reducedMotion != oldWidget.reducedMotion ||
        motionTheme != oldWidget.motionTheme ||
        textDirection != oldWidget.textDirection ||
        capsuleSize != oldWidget.capsuleSize ||
        iconTravel != oldWidget.iconTravel;
  }
}

/// Animates a named content region through the capsule reveal envelope.
///
/// Custom builders wrap regions in [CapsuleToastAnimatedSlot] to opt into the
/// same staggered entrance and exit used by structured toast content.
class CapsuleToastAnimatedSlot extends StatelessWidget {
  /// Creates an animated slot for [slot] containing [child].
  const CapsuleToastAnimatedSlot({
    super.key,
    required this.slot,
    required this.child,
  });

  /// Which named content region this slot represents.
  final CapsuleToastSlot slot;

  /// Content rendered inside the slot reveal envelope.
  final Widget child;

  static const Map<CapsuleToastSlot, Duration> _defaultEnterDelays =
      <CapsuleToastSlot, Duration>{
        CapsuleToastSlot.icon: Duration.zero,
        CapsuleToastSlot.title: Duration(milliseconds: 30),
        CapsuleToastSlot.message: Duration(milliseconds: 60),
        CapsuleToastSlot.action: Duration(milliseconds: 90),
      };

  /// Opacity reaches full at 62.5% of the icon's travel, so the glyph is solid
  /// before it finishes sliding out of the centre.
  static const double _iconOpacityLead = 0.625;

  @override
  Widget build(BuildContext context) {
    final CapsuleToastAnimationScope? scope =
        CapsuleToastAnimationScope.maybeOf(context);
    if (scope == null) {
      return child;
    }

    // Already eased — the envelope curve is applied inside _slotProgress so
    // reveal and retract stay mirror images of each other.
    final double progress = _slotProgress(scope);
    if (scope.reducedMotion) {
      return Opacity(opacity: progress, child: child);
    }

    if (slot == CapsuleToastSlot.icon) {
      return Transform.translate(
        offset: Offset(scope.iconTravel * (1 - progress), 0),
        child: Transform.scale(
          scale: 0.92 + 0.08 * progress,
          child: Opacity(
            opacity: (progress / _iconOpacityLead).clamp(0.0, 1.0),
            child: child,
          ),
        ),
      );
    }

    final double remaining = 1 - progress;
    final double inlineSign = scope.textDirection == TextDirection.rtl
        ? -1.0
        : 1.0;
    final Offset travel = switch (slot) {
      CapsuleToastSlot.title => Offset(
        inlineSign * 10 * remaining,
        3 * remaining,
      ),
      CapsuleToastSlot.message => Offset(
        inlineSign * 8 * remaining,
        3 * remaining,
      ),
      CapsuleToastSlot.action => Offset(
        inlineSign * 10 * remaining,
        4 * remaining,
      ),
      CapsuleToastSlot.icon => Offset.zero,
    };

    return Transform.translate(
      offset: travel,
      child: Opacity(opacity: progress, child: child),
    );
  }

  /// Eased reveal progress for this slot, in `[0, 1]`.
  double _slotProgress(CapsuleToastAnimationScope scope) {
    final Duration delay = scope.revealing
        ? (scope.motionTheme.slotDelays?[slot] ?? _defaultEnterDelays[slot]!)
        : capsuleToastRetractDelays[slot]!;
    final Duration interval = scope.revealing
        ? (scope.motionTheme.slotRevealDuration ??
              const Duration(milliseconds: 220))
        : (scope.reducedMotion
              ? capsuleToastReducedRetractInterval
              : capsuleToastRetractInterval);
    final int localMicros =
        scope.contentElapsed.inMicroseconds - delay.inMicroseconds;
    if (scope.revealing) {
      if (localMicros <= 0) {
        return 0;
      }
      return capsuleEaseOutAt(localMicros / interval.inMicroseconds);
    }
    if (localMicros <= 0) {
      return 1;
    }
    // Retract mirrors the reveal: `1 - easeOut(t)`, never `easeOut(1 - t)`.
    return 1 - capsuleEaseOutAt(localMicros / interval.inMicroseconds);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastSlot>('slot', slot));
  }
}
