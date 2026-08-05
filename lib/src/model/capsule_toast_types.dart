// Copyright 2026 The Capsule Toast Authors. All rights reserved.

/// Semantic categories for capsule toast content and styling.
enum CapsuleToastType {
  /// Positive completion or success feedback.
  success,

  /// Neutral informational feedback.
  information,

  /// Cautionary feedback that is not an error.
  warning,

  /// Error or failure feedback.
  error,

  /// Ongoing work with no guaranteed end time.
  loading,

  /// Brand-neutral feedback without a semantic accent.
  neutral,

  /// Fully caller-defined styling and content.
  custom,
}

/// Layout mode for a toast capsule.
enum CapsuleToastMode {
  /// The compact single-line or minimal capsule layout.
  compact,

  /// The expanded multi-line capsule layout.
  expanded,
}

/// Whether a toast may toggle between compact and expanded layout.
enum CapsuleToastExpansionPolicy {
  /// Toggles between compact and expanded via tap, long-press, or the
  /// handle (today's behavior).
  adaptive,

  /// Locked to compact — cannot expand via any interaction or handle call.
  compactOnly,

  /// Locked to expanded — cannot collapse via any interaction or handle
  /// call.
  expandedOnly,
}

/// Queue behavior when a new toast is shown while others are active.
enum CapsuleToastQueuePolicy {
  /// Append the toast to the FIFO queue.
  enqueue,

  /// Replace the active toast with the new one.
  replace,

  /// Clear the queue and show only the new toast.
  clearAndShow,
}

/// Icon selection for structured toast content.
enum CapsuleToastGlyph {
  /// Choose an icon from the toast [CapsuleToastType].
  automatic,

  /// Success glyph.
  success,

  /// Information glyph.
  information,

  /// Warning glyph.
  warning,

  /// Error glyph.
  error,

  /// Connectivity or network glyph.
  connectivity,

  /// Loading or progress glyph.
  loading,

  /// Neutral glyph.
  neutral;

  /// The glyph to paint for [type].
  ///
  /// [automatic] resolves to the glyph matching [type];
  /// [CapsuleToastType.custom] has no glyph of its own and resolves to
  /// [neutral]. Any other value is returned unchanged, so a caller can pass a
  /// user-supplied glyph through without checking it first.
  ///
  /// The result is never [automatic].
  CapsuleToastGlyph resolveFor(CapsuleToastType type) {
    if (this != CapsuleToastGlyph.automatic) {
      return this;
    }
    return switch (type) {
      CapsuleToastType.success => CapsuleToastGlyph.success,
      CapsuleToastType.information => CapsuleToastGlyph.information,
      CapsuleToastType.warning => CapsuleToastGlyph.warning,
      CapsuleToastType.error => CapsuleToastGlyph.error,
      CapsuleToastType.loading => CapsuleToastGlyph.loading,
      CapsuleToastType.neutral => CapsuleToastGlyph.neutral,
      CapsuleToastType.custom => CapsuleToastGlyph.neutral,
    };
  }
}

/// Named content regions within a toast capsule.
enum CapsuleToastSlot {
  /// Leading icon region.
  icon,

  /// Primary title region.
  title,

  /// Secondary message region.
  message,

  /// Action button region.
  action,
}

/// Reason a toast was removed from the screen or queue.
enum CapsuleToastDismissReason {
  /// The display duration elapsed.
  timedOut,

  /// The user dismissed the toast explicitly.
  dismissed,

  /// The user swiped the toast away.
  swiped,

  /// The user selected an action button.
  actionSelected,

  /// A newer toast replaced this one.
  replaced,

  /// The queue was cleared.
  cleared,

  /// The queue rejected the toast due to capacity.
  queueOverflow,

  /// The host widget was disposed.
  hostDisposed,
}

/// How reduced motion preferences are applied to toast motion.
enum CapsuleToastReducedMotionPolicy {
  /// Follow the platform reduced-motion setting.
  system,

  /// Always use reduced motion.
  always,

  /// Never use reduced motion.
  never,
}

/// When toast interactions trigger haptic feedback.
enum CapsuleToastHapticPolicy {
  /// Never trigger haptics.
  none,

  /// Trigger haptics on platforms that support them.
  supportedPlatforms,
}
