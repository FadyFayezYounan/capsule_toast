// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/capsule_toast_types.dart';
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
    required this.capsuleBodyKey,
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

  /// Live capsule size used for icon center travel.
  final Size capsuleSize;

  /// Key identifying the capsule body coordinate space.
  final GlobalKey capsuleBodyKey;

  /// Returns the nearest animation scope, or asserts when absent.
  static CapsuleToastAnimationScope of(BuildContext context) {
    final CapsuleToastAnimationScope? scope = maybeOf(context);
    assert(
      scope != null,
      'CapsuleToastAnimatedSlot requires a CapsuleToastAnimationScope '
      'ancestor installed by CapsuleToastLayer.',
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
        capsuleSize != oldWidget.capsuleSize;
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

  static const Map<CapsuleToastSlot, Duration> _exitDelays =
      <CapsuleToastSlot, Duration>{
        CapsuleToastSlot.action: Duration.zero,
        CapsuleToastSlot.message: Duration(milliseconds: 40),
        CapsuleToastSlot.title: Duration(milliseconds: 90),
        CapsuleToastSlot.icon: Duration(milliseconds: 100),
      };

  @override
  Widget build(BuildContext context) {
    final CapsuleToastAnimationScope? scope =
        CapsuleToastAnimationScope.maybeOf(context);
    if (scope == null) {
      return child;
    }

    final double progress = _slotProgress(scope);
    if (scope.reducedMotion) {
      return Opacity(opacity: progress.clamp(0.0, 1.0), child: child);
    }

    if (slot == CapsuleToastSlot.icon) {
      return _IconSlotMotion(progress: progress, scope: scope, child: child);
    }

    final double curved = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final double remaining = 1 - curved;
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
      child: Opacity(opacity: curved, child: child),
    );
  }

  double _slotProgress(CapsuleToastAnimationScope scope) {
    final Duration delay = scope.revealing
        ? (scope.motionTheme.slotDelays?[slot] ?? _defaultEnterDelays[slot]!)
        : _exitDelays[slot]!;
    final Duration interval = scope.revealing
        ? (scope.motionTheme.slotRevealDuration ??
              const Duration(milliseconds: 220))
        : (scope.reducedMotion
              ? const Duration(milliseconds: 100)
              : const Duration(milliseconds: 130));
    final int localMicros =
        scope.contentElapsed.inMicroseconds - delay.inMicroseconds;
    if (scope.revealing) {
      if (localMicros <= 0) {
        return 0;
      }
      return (localMicros / interval.inMicroseconds).clamp(0.0, 1.0);
    }
    if (localMicros <= 0) {
      return 1;
    }
    final double t = (localMicros / interval.inMicroseconds).clamp(0.0, 1.0);
    return 1 - t;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastSlot>('slot', slot));
  }
}

class _IconSlotMotion extends StatefulWidget {
  const _IconSlotMotion({
    required this.progress,
    required this.scope,
    required this.child,
  });

  final double progress;
  final CapsuleToastAnimationScope scope;
  final Widget child;

  @override
  State<_IconSlotMotion> createState() => _IconSlotMotionState();
}

class _IconSlotMotionState extends State<_IconSlotMotion> {
  Offset _restFromCenter = Offset.zero;
  bool _restCaptured = false;

  @override
  void didUpdateWidget(covariant _IconSlotMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope.capsuleSize != widget.scope.capsuleSize) {
      _restCaptured = false;
    }
  }

  void _captureRest(BuildContext measureContext) {
    if (widget.progress < 1) {
      return;
    }
    final RenderBox? iconBox = measureContext.findRenderObject() as RenderBox?;
    final RenderBox? capsuleBox =
        widget.scope.capsuleBodyKey.currentContext?.findRenderObject()
            as RenderBox?;
    if (iconBox == null ||
        capsuleBox == null ||
        !iconBox.hasSize ||
        !capsuleBox.hasSize) {
      return;
    }
    final Offset iconCenter = iconBox.localToGlobal(
      iconBox.size.center(Offset.zero),
      ancestor: capsuleBox,
    );
    final Offset capsuleCenter = capsuleBox.size.center(Offset.zero);
    final Offset next = iconCenter - capsuleCenter;
    if (_restCaptured && (next - _restFromCenter).distance < 0.5) {
      return;
    }
    setState(() {
      _restFromCenter = next;
      _restCaptured = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double t = widget.progress.clamp(0.0, 1.0);
    final double curved = Curves.easeOut.transform(t);
    final double opacity = (t / 0.625).clamp(0.0, 1.0);
    final double scale = 0.92 + 0.08 * curved;
    final double inlineSign = widget.scope.textDirection == TextDirection.rtl
        ? -1.0
        : 1.0;
    final Offset travel = _restCaptured
        ? -_restFromCenter * (1 - curved)
        : Offset(
            inlineSign * widget.scope.capsuleSize.width * 0.22 * (1 - curved),
            0,
          );

    return Transform.translate(
      offset: travel,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Builder(
            builder: (BuildContext measureContext) {
              WidgetsBinding.instance.addPostFrameCallback((Duration _) {
                if (mounted) {
                  _captureRest(measureContext);
                }
              });
              return widget.child;
            },
          ),
        ),
      ),
    );
  }
}
