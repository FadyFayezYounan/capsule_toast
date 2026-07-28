// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/capsule_toast_types.dart';

/// Delay before each slot begins retracting during the capsule exit.
///
/// The exit peels content away in the reverse of the order it arrived: the
/// action leaves first and the icon last, so the capsule looks like it is
/// swallowing the event rather than dropping it.
const Map<CapsuleToastSlot, Duration> capsuleToastRetractDelays =
    <CapsuleToastSlot, Duration>{
      CapsuleToastSlot.action: Duration.zero,
      CapsuleToastSlot.message: Duration(milliseconds: 40),
      CapsuleToastSlot.title: Duration(milliseconds: 90),
      CapsuleToastSlot.icon: Duration(milliseconds: 100),
    };

/// How long one slot takes to retract.
const Duration capsuleToastRetractInterval = Duration(milliseconds: 130);

/// How long one slot takes to retract under reduced motion.
const Duration capsuleToastReducedRetractInterval = Duration(milliseconds: 100);

/// Time from the start of an exit until the last slot has finished retracting.
Duration capsuleToastRetractDuration({required bool reducedMotion}) {
  final Duration longestDelay = capsuleToastRetractDelays.values.reduce(
    (Duration longest, Duration delay) => delay > longest ? delay : longest,
  );
  return longestDelay +
      (reducedMotion
          ? capsuleToastReducedRetractInterval
          : capsuleToastRetractInterval);
}

/// Spring timing parameters for capsule toast motion.
@immutable
class CapsuleToastSpring with Diagnosticable {
  /// Creates spring timing with positive [duration] and [bounce] in `[0, 1)`.
  const CapsuleToastSpring({required this.duration, required this.bounce});

  /// Total perceptual duration of the spring.
  final Duration duration;

  /// Bounce factor in the range `[0, 1)`.
  final double bounce;

  /// Returns a copy with the given fields replaced.
  CapsuleToastSpring copyWith({Duration? duration, double? bounce}) {
    return CapsuleToastSpring(
      duration: duration ?? this.duration,
      bounce: bounce ?? this.bounce,
    );
  }

  /// Linearly interpolates between [a] and [b] by [t].
  static CapsuleToastSpring? lerp(
    CapsuleToastSpring? a,
    CapsuleToastSpring? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return CapsuleToastSpring(
      duration: Duration(
        microseconds: lerpDouble(
          a.duration.inMicroseconds.toDouble(),
          b.duration.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      bounce: lerpDouble(a.bounce, b.bounce, t)!,
    );
  }

  /// Describes the properties of this object for debugging.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Duration>('duration', duration));
    properties.add(DoubleProperty('bounce', bounce));
  }

  /// Whether this spring is equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastSpring &&
        other.duration == duration &&
        other.bounce == bounce;
  }

  /// The hash code for this spring.
  @override
  int get hashCode => Object.hash(duration, bounce);
}

/// Motion timing, springs, and gesture thresholds for capsule toasts.
@immutable
class CapsuleToastMotionTheme extends ThemeExtension<CapsuleToastMotionTheme>
    with Diagnosticable {
  /// Creates optional motion overrides validated at construction time.
  const CapsuleToastMotionTheme({
    this.appearanceDuration,
    this.widthSpring,
    this.heightSpring,
    this.heightLead,
    this.interactiveSpring,
    this.exitSpring,
    this.reducedMotionSizeDuration,
    this.slotRevealDuration,
    this.slotDelays,
    this.successDuration,
    this.informationDuration,
    this.warningDuration,
    this.errorDuration,
    this.neutralDuration,
    this.longPressDuration,
    this.dismissalDistance,
    this.dismissalVelocity,
    this.downwardDragResistance,
    this.hapticPolicy,
    this.reducedMotionPolicy,
  }) : assert(appearanceDuration == null || appearanceDuration > Duration.zero),
       assert(
         reducedMotionSizeDuration == null ||
             reducedMotionSizeDuration > Duration.zero,
       ),
       assert(slotRevealDuration == null || slotRevealDuration > Duration.zero),
       assert(heightLead == null || heightLead >= Duration.zero),
       assert(successDuration == null || successDuration > Duration.zero),
       assert(
         informationDuration == null || informationDuration > Duration.zero,
       ),
       assert(warningDuration == null || warningDuration > Duration.zero),
       assert(errorDuration == null || errorDuration > Duration.zero),
       assert(neutralDuration == null || neutralDuration > Duration.zero),
       assert(longPressDuration == null || longPressDuration > Duration.zero),
       assert(dismissalDistance == null || dismissalDistance > 0),
       assert(dismissalVelocity == null || dismissalVelocity > 0),
       assert(
         downwardDragResistance == null ||
             (downwardDragResistance >= 0 && downwardDragResistance <= 1),
       );

  /// Reference motion values for capsule toasts.
  factory CapsuleToastMotionTheme.fallback() {
    return CapsuleToastMotionTheme(
      appearanceDuration: Duration(milliseconds: 140),
      widthSpring: CapsuleToastSpring(
        duration: Duration(milliseconds: 420),
        bounce: 0.16,
      ),
      heightSpring: CapsuleToastSpring(
        duration: Duration(milliseconds: 400),
        bounce: 0.12,
      ),
      heightLead: Duration(milliseconds: 28),
      interactiveSpring: CapsuleToastSpring(
        duration: Duration(milliseconds: 320),
        bounce: 0.18,
      ),
      exitSpring: CapsuleToastSpring(
        duration: Duration(milliseconds: 300),
        bounce: 0,
      ),
      reducedMotionSizeDuration: Duration(milliseconds: 240),
      slotRevealDuration: Duration(milliseconds: 220),
      slotDelays: <CapsuleToastSlot, Duration>{
        CapsuleToastSlot.icon: Duration.zero,
        CapsuleToastSlot.title: Duration(milliseconds: 30),
        CapsuleToastSlot.message: Duration(milliseconds: 60),
        CapsuleToastSlot.action: Duration(milliseconds: 90),
      },
      successDuration: Duration(milliseconds: 2200),
      informationDuration: Duration(milliseconds: 2400),
      warningDuration: Duration(milliseconds: 3600),
      errorDuration: Duration(milliseconds: 3800),
      neutralDuration: Duration(milliseconds: 2400),
      longPressDuration: Duration(milliseconds: 320),
      dismissalDistance: 26,
      dismissalVelocity: 420,
      downwardDragResistance: 0.22,
      hapticPolicy: CapsuleToastHapticPolicy.supportedPlatforms,
      reducedMotionPolicy: CapsuleToastReducedMotionPolicy.system,
    );
  }

  /// Duration of the initial appearance envelope.
  final Duration? appearanceDuration;

  /// Spring used when the capsule width changes.
  final CapsuleToastSpring? widthSpring;

  /// Spring used when the capsule height changes.
  final CapsuleToastSpring? heightSpring;

  /// Delay before height motion begins after width motion.
  final Duration? heightLead;

  /// Spring used for interactive resize transitions.
  final CapsuleToastSpring? interactiveSpring;

  /// Spring used when the capsule exits.
  final CapsuleToastSpring? exitSpring;

  /// Size transition duration when reduced motion is active.
  final Duration? reducedMotionSizeDuration;

  /// Duration of each content slot reveal animation.
  final Duration? slotRevealDuration;

  /// Staggered delays before each content slot reveals.
  final Map<CapsuleToastSlot, Duration>? slotDelays;

  /// Default visible duration for success toasts.
  final Duration? successDuration;

  /// Default visible duration for informational toasts.
  final Duration? informationDuration;

  /// Default visible duration for warning toasts.
  final Duration? warningDuration;

  /// Default visible duration for error toasts.
  final Duration? errorDuration;

  /// Default visible duration for neutral toasts.
  final Duration? neutralDuration;

  /// Duration a press must be held to expand the capsule.
  final Duration? longPressDuration;

  /// Vertical drag distance that dismisses the toast.
  final double? dismissalDistance;

  /// Upward flick velocity that dismisses the toast.
  final double? dismissalVelocity;

  /// Resistance applied to downward drags, in `[0, 1]`.
  final double? downwardDragResistance;

  /// When toast interactions trigger haptic feedback.
  final CapsuleToastHapticPolicy? hapticPolicy;

  /// How reduced motion preferences affect toast animation.
  final CapsuleToastReducedMotionPolicy? reducedMotionPolicy;

  /// Returns the default hold duration for [type], or `null` when persistent.
  Duration? durationFor(CapsuleToastType type) {
    return switch (type) {
      CapsuleToastType.success => successDuration,
      CapsuleToastType.information => informationDuration,
      CapsuleToastType.warning => warningDuration,
      CapsuleToastType.error => errorDuration,
      CapsuleToastType.neutral => neutralDuration,
      CapsuleToastType.loading => null,
      CapsuleToastType.custom => neutralDuration,
    };
  }

  /// Returns a copy with the given fields replaced.
  @override
  CapsuleToastMotionTheme copyWith({
    Duration? appearanceDuration,
    CapsuleToastSpring? widthSpring,
    CapsuleToastSpring? heightSpring,
    Duration? heightLead,
    CapsuleToastSpring? interactiveSpring,
    CapsuleToastSpring? exitSpring,
    Duration? reducedMotionSizeDuration,
    Duration? slotRevealDuration,
    Map<CapsuleToastSlot, Duration>? slotDelays,
    Duration? successDuration,
    Duration? informationDuration,
    Duration? warningDuration,
    Duration? errorDuration,
    Duration? neutralDuration,
    Duration? longPressDuration,
    double? dismissalDistance,
    double? dismissalVelocity,
    double? downwardDragResistance,
    CapsuleToastHapticPolicy? hapticPolicy,
    CapsuleToastReducedMotionPolicy? reducedMotionPolicy,
  }) {
    return CapsuleToastMotionTheme(
      appearanceDuration: appearanceDuration ?? this.appearanceDuration,
      widthSpring: widthSpring ?? this.widthSpring,
      heightSpring: heightSpring ?? this.heightSpring,
      heightLead: heightLead ?? this.heightLead,
      interactiveSpring: interactiveSpring ?? this.interactiveSpring,
      exitSpring: exitSpring ?? this.exitSpring,
      reducedMotionSizeDuration:
          reducedMotionSizeDuration ?? this.reducedMotionSizeDuration,
      slotRevealDuration: slotRevealDuration ?? this.slotRevealDuration,
      slotDelays: slotDelays ?? this.slotDelays,
      successDuration: successDuration ?? this.successDuration,
      informationDuration: informationDuration ?? this.informationDuration,
      warningDuration: warningDuration ?? this.warningDuration,
      errorDuration: errorDuration ?? this.errorDuration,
      neutralDuration: neutralDuration ?? this.neutralDuration,
      longPressDuration: longPressDuration ?? this.longPressDuration,
      dismissalDistance: dismissalDistance ?? this.dismissalDistance,
      dismissalVelocity: dismissalVelocity ?? this.dismissalVelocity,
      downwardDragResistance:
          downwardDragResistance ?? this.downwardDragResistance,
      hapticPolicy: hapticPolicy ?? this.hapticPolicy,
      reducedMotionPolicy: reducedMotionPolicy ?? this.reducedMotionPolicy,
    );
  }

  /// Merges non-null fields from [other] on top of this theme.
  CapsuleToastMotionTheme merge(CapsuleToastMotionTheme? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      appearanceDuration: other.appearanceDuration ?? appearanceDuration,
      widthSpring: other.widthSpring ?? widthSpring,
      heightSpring: other.heightSpring ?? heightSpring,
      heightLead: other.heightLead ?? heightLead,
      interactiveSpring: other.interactiveSpring ?? interactiveSpring,
      exitSpring: other.exitSpring ?? exitSpring,
      reducedMotionSizeDuration:
          other.reducedMotionSizeDuration ?? reducedMotionSizeDuration,
      slotRevealDuration: other.slotRevealDuration ?? slotRevealDuration,
      slotDelays: other.slotDelays ?? slotDelays,
      successDuration: other.successDuration ?? successDuration,
      informationDuration: other.informationDuration ?? informationDuration,
      warningDuration: other.warningDuration ?? warningDuration,
      errorDuration: other.errorDuration ?? errorDuration,
      neutralDuration: other.neutralDuration ?? neutralDuration,
      longPressDuration: other.longPressDuration ?? longPressDuration,
      dismissalDistance: other.dismissalDistance ?? dismissalDistance,
      dismissalVelocity: other.dismissalVelocity ?? dismissalVelocity,
      downwardDragResistance:
          other.downwardDragResistance ?? downwardDragResistance,
      hapticPolicy: other.hapticPolicy ?? hapticPolicy,
      reducedMotionPolicy: other.reducedMotionPolicy ?? reducedMotionPolicy,
    );
  }

  /// Linearly interpolates between this theme and [other] at [t].
  @override
  CapsuleToastMotionTheme lerp(
    covariant CapsuleToastMotionTheme? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return CapsuleToastMotionTheme(
      appearanceDuration: Duration(
        microseconds: lerpDouble(
          appearanceDuration!.inMicroseconds.toDouble(),
          other.appearanceDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      widthSpring: CapsuleToastSpring.lerp(widthSpring, other.widthSpring, t),
      heightSpring: CapsuleToastSpring.lerp(
        heightSpring,
        other.heightSpring,
        t,
      ),
      heightLead: Duration(
        microseconds: lerpDouble(
          heightLead!.inMicroseconds.toDouble(),
          other.heightLead!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      interactiveSpring: CapsuleToastSpring.lerp(
        interactiveSpring,
        other.interactiveSpring,
        t,
      ),
      exitSpring: CapsuleToastSpring.lerp(exitSpring, other.exitSpring, t),
      reducedMotionSizeDuration: Duration(
        microseconds: lerpDouble(
          reducedMotionSizeDuration!.inMicroseconds.toDouble(),
          other.reducedMotionSizeDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      slotRevealDuration: Duration(
        microseconds: lerpDouble(
          slotRevealDuration!.inMicroseconds.toDouble(),
          other.slotRevealDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      slotDelays: t < 0.5 ? slotDelays : other.slotDelays,
      successDuration: Duration(
        microseconds: lerpDouble(
          successDuration!.inMicroseconds.toDouble(),
          other.successDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      informationDuration: Duration(
        microseconds: lerpDouble(
          informationDuration!.inMicroseconds.toDouble(),
          other.informationDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      warningDuration: Duration(
        microseconds: lerpDouble(
          warningDuration!.inMicroseconds.toDouble(),
          other.warningDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      errorDuration: Duration(
        microseconds: lerpDouble(
          errorDuration!.inMicroseconds.toDouble(),
          other.errorDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      neutralDuration: Duration(
        microseconds: lerpDouble(
          neutralDuration!.inMicroseconds.toDouble(),
          other.neutralDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      longPressDuration: Duration(
        microseconds: lerpDouble(
          longPressDuration!.inMicroseconds.toDouble(),
          other.longPressDuration!.inMicroseconds.toDouble(),
          t,
        )!.round(),
      ),
      dismissalDistance: lerpDouble(
        dismissalDistance,
        other.dismissalDistance,
        t,
      ),
      dismissalVelocity: lerpDouble(
        dismissalVelocity,
        other.dismissalVelocity,
        t,
      ),
      downwardDragResistance: lerpDouble(
        downwardDragResistance,
        other.downwardDragResistance,
        t,
      ),
      hapticPolicy: t < 0.5 ? hapticPolicy : other.hapticPolicy,
      reducedMotionPolicy: t < 0.5
          ? reducedMotionPolicy
          : other.reducedMotionPolicy,
    );
  }

  /// Describes the properties of this object for debugging.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Duration?>('appearanceDuration', appearanceDuration),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastSpring?>('widthSpring', widthSpring),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastSpring?>('heightSpring', heightSpring),
    );
    properties.add(DiagnosticsProperty<Duration?>('heightLead', heightLead));
    properties.add(
      DiagnosticsProperty<CapsuleToastSpring?>(
        'interactiveSpring',
        interactiveSpring,
      ),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastSpring?>('exitSpring', exitSpring),
    );
    properties.add(
      DiagnosticsProperty<Duration?>(
        'reducedMotionSizeDuration',
        reducedMotionSizeDuration,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('slotRevealDuration', slotRevealDuration),
    );
    properties.add(
      DiagnosticsProperty<Map<CapsuleToastSlot, Duration>?>(
        'slotDelays',
        slotDelays,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('successDuration', successDuration),
    );
    properties.add(
      DiagnosticsProperty<Duration?>(
        'informationDuration',
        informationDuration,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('warningDuration', warningDuration),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('errorDuration', errorDuration),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('neutralDuration', neutralDuration),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('longPressDuration', longPressDuration),
    );
    properties.add(DoubleProperty('dismissalDistance', dismissalDistance));
    properties.add(DoubleProperty('dismissalVelocity', dismissalVelocity));
    properties.add(
      DoubleProperty('downwardDragResistance', downwardDragResistance),
    );
    properties.add(
      EnumProperty<CapsuleToastHapticPolicy?>('hapticPolicy', hapticPolicy),
    );
    properties.add(
      EnumProperty<CapsuleToastReducedMotionPolicy?>(
        'reducedMotionPolicy',
        reducedMotionPolicy,
      ),
    );
  }

  /// Whether this motion theme is equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastMotionTheme &&
        other.appearanceDuration == appearanceDuration &&
        other.widthSpring == widthSpring &&
        other.heightSpring == heightSpring &&
        other.heightLead == heightLead &&
        other.interactiveSpring == interactiveSpring &&
        other.exitSpring == exitSpring &&
        other.reducedMotionSizeDuration == reducedMotionSizeDuration &&
        other.slotRevealDuration == slotRevealDuration &&
        _mapEquals(other.slotDelays, slotDelays) &&
        other.successDuration == successDuration &&
        other.informationDuration == informationDuration &&
        other.warningDuration == warningDuration &&
        other.errorDuration == errorDuration &&
        other.neutralDuration == neutralDuration &&
        other.longPressDuration == longPressDuration &&
        other.dismissalDistance == dismissalDistance &&
        other.dismissalVelocity == dismissalVelocity &&
        other.downwardDragResistance == downwardDragResistance &&
        other.hapticPolicy == hapticPolicy &&
        other.reducedMotionPolicy == reducedMotionPolicy;
  }

  /// The hash code for this motion theme.
  @override
  int get hashCode => Object.hashAll(<Object?>[
    appearanceDuration,
    widthSpring,
    heightSpring,
    heightLead,
    interactiveSpring,
    exitSpring,
    reducedMotionSizeDuration,
    slotRevealDuration,
    slotDelays == null ? null : Object.hashAll(slotDelays!.entries),
    successDuration,
    informationDuration,
    warningDuration,
    errorDuration,
    neutralDuration,
    longPressDuration,
    dismissalDistance,
    dismissalVelocity,
    downwardDragResistance,
    hapticPolicy,
    reducedMotionPolicy,
  ]);
}

bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final MapEntry<K, V> entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
