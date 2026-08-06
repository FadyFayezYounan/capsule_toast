// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_types.dart';
import '../motion/capsule_lifecycle.dart';
import '../motion/capsule_motion_controller.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme_data.dart';

/// Reconciles [CapsuleToastCoordinator] records against [CapsuleMotionController]
/// state.
///
/// Owns seeding, replacement, mode retargeting, dismissal sync, measured-size
/// caching, and haptics so `CapsuleToastLayer` can stay focused on layout.
final class CapsuleToastMotionSynchronizer {
  /// Creates a synchronizer driving [motion] from [coordinator]'s records.
  CapsuleToastMotionSynchronizer({
    required this.coordinator,
    required this.motion,
    required this.scheduleSync,
  });

  /// Queue coordinator whose active record is synchronized.
  final CapsuleToastCoordinator coordinator;

  /// Host-owned motion controller driving capsule geometry.
  final CapsuleMotionController motion;

  /// Schedules a post-frame synchronization pass.
  final VoidCallback scheduleSync;

  Size? _measuredSize;
  Size? _compactSize;
  Size? _expandedSize;
  int? _activeToken;
  int _activeRevision = -1;
  CapsuleToastMode? _activeMode;
  CapsuleToastDismissReason? _pendingDismissal;
  bool _motionStarted = false;
  bool _entranceHapticFired = false;
  bool _resolveHapticPending = false;

  /// Most recently measured content size for the active record.
  Size? get measuredSize => _measuredSize;

  /// Cached content size the last time the active record was compact.
  Size? get compactSize => _compactSize;

  /// Cached content size the last time the active record was expanded.
  Size? get expandedSize => _expandedSize;

  Duration? _resolveHoldDuration(
    CapsuleToastData data,
    CapsuleToastMotionTheme motionTheme,
  ) {
    if (data.persistent) {
      return null;
    }
    return data.displayDuration ?? motionTheme.durationFor(data.type);
  }

  /// Whether [record] requires a synchronization pass before the next build.
  bool needsSynchronization(CapsuleToastRecord? record) {
    return !_motionStarted ||
        _activeToken != record?.token ||
        _activeRevision != record?.revision ||
        _activeMode != record?.desiredMode ||
        record?.pendingDismissal != _pendingDismissal;
  }

  /// Reconciles [motion] with [record] using the resolved [visualTheme],
  /// [motionTheme], and [reducedMotion] state.
  void synchronize({
    required CapsuleToastRecord? record,
    required CapsuleToastThemeData visualTheme,
    required CapsuleToastMotionTheme motionTheme,
    required bool reducedMotion,
  }) {
    if (record == null) {
      reset();
      return;
    }

    motion.updateMotionTheme(motionTheme);
    motion.setReducedMotion(reducedMotion);

    final Size seed = visualTheme.seedSize ?? const Size(84, 34);
    motion.updateSeedSize(seed);
    final Size target = _measuredSize ?? seed;
    final Duration? holdDuration = _resolveHoldDuration(
      record.data,
      motionTheme,
    );

    final bool tokenChanged = _activeToken != record.token;
    final bool revisionChanged = _activeRevision != record.revision;
    final bool modeChanged = _activeMode != record.desiredMode;

    if (!_motionStarted || tokenChanged) {
      if (_motionStarted && tokenChanged) {
        // A new token is a new event, never a continuation of the old one, so
        // it always re-seeds: geometry snaps back to the resolved theme seed at
        // zero opacity and replays the entrance. The reference gets this from
        // swapping `item` identity, which re-runs its seeding effect. Sizes
        // measured for the outgoing content are dropped — the probes report
        // the incoming content's own sizes on the next layout.
        _measuredSize = null;
        _compactSize = null;
        _expandedSize = null;
        motion.show(
          target: seed,
          mode: record.desiredMode,
          holdDuration: holdDuration,
        );
      } else {
        motion.show(
          target: target,
          mode: record.desiredMode,
          holdDuration: holdDuration,
        );
      }
      _motionStarted = true;
      _activeToken = record.token;
      _activeRevision = record.revision;
      _activeMode = record.desiredMode;
      _pendingDismissal = null;
      _entranceHapticFired = false;
      _resolveHapticPending = false;
    } else if (revisionChanged) {
      motion.resolve(
        target: target,
        mode: record.desiredMode,
        holdDuration: holdDuration,
      );
      _activeRevision = record.revision;
      _activeMode = record.desiredMode;
      _resolveHapticPending = true;
    } else if (modeChanged) {
      // Retarget immediately so a following pump(duration) advances springs
      // toward the new mode. tester.tap does not pump after pointer-up, so
      // waiting for measure alone leaves the ticker on the old size.
      // Retarget immediately so a following pump(duration) advances springs
      // toward the new mode. tester.tap does not pump after pointer-up, so
      // waiting for measure alone leaves the ticker on the old size.
      //
      // Each mode's size is cached the first time it is laid out, so after one
      // round trip the target is exact. Before that, hold the current size
      // rather than estimating: measure lands next frame either way, and an
      // invented target would aim the spring somewhere the capsule is never
      // going.
      _activeMode = record.desiredMode;
      final Size current = motion.value.size;
      if (record.desiredMode == CapsuleToastMode.expanded) {
        motion.expand(_expandedSize ?? current);
      } else {
        motion.collapse(_compactSize ?? current);
      }
    } else if (_measuredSize != null) {
      motion.retarget(_measuredSize!);
    }

    final CapsuleToastDismissReason? pending = record.pendingDismissal;
    if (pending != null && pending != _pendingDismissal) {
      _pendingDismissal = pending;
      motion.dismiss(pending, velocity: record.dismissalVelocity);
    }
  }

  /// Reconciles a fresh [size] measurement of the active record's content.
  void handleSizeChanged(Size size) {
    if (_measuredSize == size) {
      return;
    }
    _measuredSize = size;
    final CapsuleToastRecord? record = coordinator.active;
    if (record != null) {
      if (record.desiredMode == CapsuleToastMode.compact) {
        _compactSize = size;
      } else {
        _expandedSize = size;
      }
    }
    if (!_motionStarted) {
      scheduleSync();
      return;
    }
    if (record == null) {
      return;
    }
    if (_activeToken != record.token || _activeRevision != record.revision) {
      scheduleSync();
      return;
    }
    if (_activeMode != record.desiredMode) {
      scheduleSync();
      return;
    }

    final CapsuleLifecycleState state = motion.value.state;
    if (record.desiredMode == CapsuleToastMode.expanded &&
        state != CapsuleLifecycleState.expanded &&
        state != CapsuleLifecycleState.collapsing &&
        state != CapsuleLifecycleState.hidden) {
      motion.expand(size);
      return;
    }
    if (record.desiredMode == CapsuleToastMode.compact &&
        state == CapsuleLifecycleState.expanded) {
      motion.collapse(size);
      return;
    }
    motion.retarget(size);
  }

  bool _shouldTriggerHaptic(
    CapsuleToastMotionTheme motionTheme,
    bool reducedMotion,
  ) {
    if (motionTheme.hapticPolicy !=
        CapsuleToastHapticPolicy.supportedPlatforms) {
      return false;
    }
    if (reducedMotion) {
      return false;
    }
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Fires entrance/resolve haptics for [record] once [motion] settles, using
  /// the resolved [motionTheme] and [reducedMotion] state.
  void handleMotionChanged({
    required CapsuleToastRecord? record,
    required CapsuleToastMotionTheme motionTheme,
    required bool reducedMotion,
  }) {
    if (record == null) {
      return;
    }
    final CapsuleMotionSnapshot snapshot = motion.value;
    if (!snapshot.isSettled) {
      return;
    }
    if (!_shouldTriggerHaptic(motionTheme, reducedMotion)) {
      _entranceHapticFired = true;
      _resolveHapticPending = false;
      return;
    }
    if (!_entranceHapticFired) {
      _entranceHapticFired = true;
      _resolveHapticPending = false;
      HapticFeedback.lightImpact();
      return;
    }
    if (_resolveHapticPending) {
      _resolveHapticPending = false;
      HapticFeedback.lightImpact();
    }
  }

  /// Clears all tracked motion, token, revision, size, dismissal, and haptic
  /// state.
  void reset() {
    _motionStarted = false;
    _activeToken = null;
    _activeRevision = -1;
    _activeMode = null;
    _pendingDismissal = null;
    _measuredSize = null;
    _compactSize = null;
    _expandedSize = null;
    _entranceHapticFired = false;
    _resolveHapticPending = false;
  }
}
