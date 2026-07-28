// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_motion_theme.dart';
import 'capsule_easing.dart';
import 'capsule_geometry.dart';
import 'capsule_lifecycle.dart';
import 'damped_spring.dart';
import 'lifecycle_clock.dart';

/// Immutable view of the live capsule motion state.
@immutable
final class CapsuleMotionSnapshot {
  /// Creates a snapshot of the current capsule presentation.
  const CapsuleMotionSnapshot({
    required this.state,
    required this.size,
    required this.opacity,
    required this.verticalOffset,
    required this.scale,
    required this.contentProgress,
    required this.isSettled,
  });

  /// Current lifecycle phase.
  final CapsuleLifecycleState state;

  /// Live capsule size in logical pixels.
  final Size size;

  /// Live opacity in `[0, 1]`.
  final double opacity;

  /// Live vertical offset in logical pixels.
  final double verticalOffset;

  /// Live scale factor around the capsule center.
  final double scale;

  /// Content reveal progress in `[0, 1]`.
  final double contentProgress;

  /// Whether geometry and envelopes have settled in a visible phase.
  final bool isSettled;
}

/// Ticker-owned spring and envelope engine for one continuous capsule.
final class CapsuleMotionController extends ChangeNotifier {
  /// Creates a controller driven by the given ticker provider and motion theme.
  CapsuleMotionController({
    required this._vsync,
    required this._motionTheme,
    required this._onHoldElapsed,
    required this._onExitCompleted,
  }) : _geometry = CapsuleGeometry(
         width: DampedSpring(value: _seedWidth),
         height: DampedSpring(value: _seedHeight),
         verticalOffset: DampedSpring(value: 0),
       );

  static const double _seedWidth = 84;
  static const double _seedHeight = 34;
  static const double _seedVerticalOffset = -8;
  static const double _seedScale = 0.92;
  static const double _exitFadeStartMs = 200;
  static const double _exitCompleteMs = 340;
  static const double _exitSizeAtMs = 160;
  static const double _exitFadeDurationMs = 140;
  static const double _exitUpwardTravel = 6;
  static const double _exitVelocityKickScale = 0.03;
  static const double _exitVelocityKickCap = 40;

  final TickerProvider _vsync;
  final VoidCallback _onHoldElapsed;
  final VoidCallback _onExitCompleted;
  final CapsuleGeometry _geometry;
  final CapsuleLifecycle _lifecycle = CapsuleLifecycle();
  final LifecycleClock _holdClock = LifecycleClock();

  CapsuleToastMotionTheme _motionTheme;
  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;

  Size? _pendingHeightTarget;
  Duration _heightLeadRemaining = Duration.zero;
  Duration _appearanceElapsed = Duration.zero;
  Duration _contentElapsed = Duration.zero;
  Duration _exitElapsed = Duration.zero;
  bool _appearanceComplete = true;
  bool _contentEnvelopeActive = false;
  bool _exitSizeRetargeted = false;
  bool _exitFadeStarted = false;
  bool _exitCompleted = false;
  bool _holdStarted = false;
  bool _interactionPaused = false;
  bool _dragging = false;
  bool _usingExitSpring = false;
  bool _usingInteractiveSpring = false;
  bool _pendingExpandAfterAppear = false;
  bool _reducedMotion = false;
  Duration? _holdDuration;
  double _scale = 1;
  double _envelopeOpacity = 0;
  double _envelopeOffset = 0;
  double _contentProgress = 0;
  Offset _contentTravel = Offset.zero;

  /// Current motion snapshot for rendering.
  CapsuleMotionSnapshot get value {
    return CapsuleMotionSnapshot(
      state: _lifecycle.state,
      size: Size(_geometry.width.value, _geometry.height.value),
      opacity: _envelopeOpacity.clamp(0.0, 1.0),
      // The lifecycle envelope and the interactive drag translate the capsule
      // independently, exactly as the reference composes `ty + drag`. Keeping
      // them separate is what lets an exit begin from wherever the finger left
      // the capsule instead of snapping back to rest first.
      verticalOffset: _envelopeOffset + _geometry.verticalOffset.value,
      scale: _scale,
      contentProgress: _contentProgress.clamp(0.0, 1.0),
      isSettled: _isVisiblySettled,
    );
  }

  /// Width spring velocity for tests.
  @visibleForTesting
  double get debugWidthVelocity => _geometry.width.velocity;

  /// Whether width or height currently overshoots its target.
  @visibleForTesting
  bool get debugHasOvershoot {
    return _geometry.width.value > _geometry.width.target + 0.06 ||
        _geometry.height.value > _geometry.height.target + 0.06;
  }

  /// Whether the hold clock is currently running (possibly paused).
  @visibleForTesting
  bool get debugHoldStarted => _holdStarted;

  /// Whether interaction currently pauses the hold clock.
  @visibleForTesting
  bool get debugInteractionPaused => _interactionPaused;

  /// Directional content travel remaining for tests.
  @visibleForTesting
  Offset get debugContentTravel => _contentTravel;

  /// Starts entrance from the seed geometry toward [target].
  ///
  /// Interrupts an in-progress exit without invoking [onExitCompleted], so a
  /// mid-exit token swap cannot complete the newly active record.
  void show({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    if (_lifecycle.state != CapsuleLifecycleState.hidden) {
      // Whatever the outgoing toast was doing — settled, mid-expand, or
      // half-way through its exit — a replacement ends it here. Abandoning
      // rather than dismissing matters: the coordinator has already completed
      // the outgoing record, so firing the exit callback now would complete
      // the incoming one instead.
      _lifecycle.abandon();
    }
    _holdDuration = holdDuration;
    _holdStarted = false;
    _holdClock.reset();
    _dragging = false;
    _interactionPaused = false;
    _usingExitSpring = false;
    _usingInteractiveSpring = false;
    _exitElapsed = Duration.zero;
    _exitSizeRetargeted = false;
    _exitFadeStarted = false;
    _exitCompleted = false;
    _pendingExpandAfterAppear = mode == CapsuleToastMode.expanded;
    _lifecycle.begin(mode);
    _jumpToSeed();
    _appearanceElapsed = Duration.zero;
    _appearanceComplete = false;
    _contentElapsed = Duration.zero;
    _contentEnvelopeActive = true;
    _contentProgress = 0;
    _geometry.width.retarget(target.width);
    _pendingHeightTarget = Size(target.width, target.height);
    _heightLeadRemaining = _motionTheme.heightLead ?? Duration.zero;
    _ensureTicker();
    _publish();
  }

  /// Retargets size without resetting lifecycle or hold progress.
  ///
  /// Also hands the springs back to the width and height presets. The
  /// interactive spring is a one-frame bridge, not a mode: the reference
  /// retunes to it inside `expand`, then retunes straight back the moment new
  /// dimensions arrive, which is always the very next frame. Letting it stick
  /// runs every later expand, collapse, and resolution at 320ms/0.18 bounce
  /// instead of the 420ms/0.16 and 400ms/0.12 the design actually uses —
  /// quicker and springier than intended, which is exactly what reads as
  /// wrong next to the reference.
  void retarget(Size target) {
    _usingInteractiveSpring = false;
    _geometry.width.retarget(target.width);
    if (_heightLeadRemaining > Duration.zero && _pendingHeightTarget != null) {
      _pendingHeightTarget = target;
    } else {
      _geometry.height.retarget(target.height);
      _pendingHeightTarget = null;
    }
    _ensureTicker();
    _publish();
  }

  /// Resolves loading content while preserving geometry continuity.
  ///
  /// This is the only content change that keeps the capsule moving. A new
  /// token re-seeds through [show]; only a resolution — loading becoming its
  /// outcome — is one continuous object changing what it says.
  void resolve({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    if (_needsFreshEntrance) {
      show(target: target, mode: mode, holdDuration: holdDuration);
      return;
    }
    _prepareContinuousContentChange(
      target: target,
      mode: mode,
      holdDuration: holdDuration,
    );
  }

  bool get _needsFreshEntrance {
    return _lifecycle.state == CapsuleLifecycleState.hidden ||
        _lifecycle.state == CapsuleLifecycleState.collapsing;
  }

  /// Expands toward [target] without clearing spring velocity.
  void expand(Size target) {
    _usingInteractiveSpring = true;
    _usingExitSpring = false;
    if (_lifecycle.state == CapsuleLifecycleState.compact) {
      _lifecycle.expand();
      _pendingExpandAfterAppear = false;
    } else if (_lifecycle.state == CapsuleLifecycleState.seed) {
      _pendingExpandAfterAppear = true;
    }
    _resetHoldAndContentReveal();
    _retargetImmediate(target);
    _ensureTicker();
    _publish();
  }

  /// Collapses toward [target] without clearing spring velocity.
  void collapse(Size target) {
    _usingInteractiveSpring = true;
    _usingExitSpring = false;
    if (_lifecycle.state == CapsuleLifecycleState.expanded) {
      _lifecycle.collapse();
    }
    _pendingExpandAfterAppear = false;
    _resetHoldAndContentReveal();
    _retargetImmediate(target);
    _ensureTicker();
    _publish();
  }

  /// Begins an interactive vertical drag.
  void beginDrag() {
    if (_lifecycle.state == CapsuleLifecycleState.hidden ||
        _lifecycle.state == CapsuleLifecycleState.collapsing) {
      return;
    }
    _dragging = true;
    _usingInteractiveSpring = true;
    _usingExitSpring = false;
    _publish();
  }

  /// Tracks the pointer with 1:1 / resisted [offset] during a drag.
  void updateDragOffset(double offset) {
    if (!_dragging) {
      beginDrag();
    }
    _geometry.verticalOffset.jumpTo(offset);
    _publish();
  }

  /// Ends a drag by springing back to rest with the interactive spring.
  void cancelDrag() {
    if (!_dragging &&
        _geometry.verticalOffset.target == 0 &&
        _geometry.verticalOffset.isSettled) {
      return;
    }
    _dragging = false;
    _usingInteractiveSpring = true;
    _usingExitSpring = false;
    _geometry.verticalOffset.retarget(0);
    _ensureTicker();
    _publish();
  }

  /// Begins the exit sequence for [reason].
  void dismiss(CapsuleToastDismissReason reason, {double velocity = 0}) {
    if (_lifecycle.state == CapsuleLifecycleState.hidden ||
        _lifecycle.state == CapsuleLifecycleState.collapsing) {
      return;
    }
    if (_lifecycle.state == CapsuleLifecycleState.seed) {
      _forceAppear();
    }
    _dragging = false;
    _interactionPaused = false;
    _lifecycle.requestDismiss(reason);
    _exitElapsed = Duration.zero;
    _exitSizeRetargeted = false;
    _exitFadeStarted = false;
    _exitCompleted = false;
    _holdClock.reset();
    _holdStarted = false;
    // The retract envelope is a fresh clock starting at the dismissal, not a
    // continuation of the reveal's. Without this reset the very first exit
    // frame reads as already past the end of the envelope and every slot
    // vanishes at once instead of peeling away action-first.
    _contentElapsed = Duration.zero;
    _contentEnvelopeActive = true;
    // Retune to the exit spring now, but retarget to the seed only once the
    // content has begun retracting (see [_advanceExit]). Between those two
    // moments the capsule keeps its current target and simply stops bouncing.
    _usingExitSpring = true;
    _usingInteractiveSpring = false;
    // A flick carries the capsule further along its own travel and then holds
    // there for the fade, rather than springing back to rest.
    final double kick = velocity == 0
        ? 0
        : -math.min(
            _exitVelocityKickCap,
            velocity.abs() * _exitVelocityKickScale,
          );
    _geometry.verticalOffset.jumpTo(_geometry.verticalOffset.value + kick);
    _ensureTicker();
    _publish();
  }

  /// Pauses or resumes the post-settlement hold clock.
  void setInteractionPaused(bool paused) {
    _interactionPaused = paused;
    if (paused) {
      _holdClock.pause();
    } else {
      _holdClock.resume();
      if (!_holdStarted) {
        _maybeStartHold();
      }
      // Always restart the ticker on resume — settlement may have idled the
      // ticker while the pointer was down with the hold clock paused.
      _ensureTicker();
    }
    _publish();
  }

  /// Updates spring timing from a newly resolved motion theme.
  void updateMotionTheme(CapsuleToastMotionTheme value) {
    _motionTheme = value;
  }

  /// Enables or disables the reduced-motion presentation policy.
  void setReducedMotion(bool value) {
    if (_reducedMotion == value) {
      return;
    }
    _reducedMotion = value;
    if (_reducedMotion) {
      _contentTravel = Offset.zero;
      _scale = 1;
      if (!_appearanceComplete) {
        _envelopeOffset = 0;
      }
    }
  }

  /// Elapsed time within the active content reveal or retract envelope.
  Duration get contentElapsed => _contentElapsed;

  /// Whether the content envelope is currently revealing (versus exiting).
  bool get contentRevealing {
    return _lifecycle.state != CapsuleLifecycleState.collapsing;
  }

  /// Whether reduced motion is currently active for this controller.
  bool get reducedMotion => _reducedMotion;

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void _prepareContinuousContentChange({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    _holdDuration = holdDuration;
    _usingExitSpring = false;
    // A resolution is a dimension change like any other, so it runs on the
    // width and height springs rather than inheriting an earlier expand's
    // interactive tuning.
    _usingInteractiveSpring = false;
    _resetHoldAndContentReveal();
    if (_lifecycle.state == CapsuleLifecycleState.compact &&
        mode == CapsuleToastMode.expanded) {
      _lifecycle.expand();
    } else if (_lifecycle.state == CapsuleLifecycleState.expanded &&
        mode == CapsuleToastMode.compact) {
      _lifecycle.collapse();
    } else if (_lifecycle.state == CapsuleLifecycleState.seed) {
      _pendingExpandAfterAppear = mode == CapsuleToastMode.expanded;
    }
    _retargetImmediate(target);
    _ensureTicker();
    _publish();
  }

  void _resetHoldAndContentReveal() {
    _holdStarted = false;
    _holdClock.reset();
    _contentElapsed = Duration.zero;
    _contentEnvelopeActive = true;
    _contentProgress = 0;
    _contentTravel = Offset.zero;
  }

  void _jumpToSeed() {
    _geometry.width.jumpTo(_seedWidth);
    _geometry.height.jumpTo(_seedHeight);
    // The drag spring always starts at rest; only the envelope carries the
    // seed's upward offset.
    _geometry.verticalOffset.jumpTo(0);
    _envelopeOpacity = 0;
    if (_reducedMotion) {
      _envelopeOffset = 0;
      _scale = 1;
    } else {
      _envelopeOffset = _seedVerticalOffset;
      _scale = _seedScale;
    }
    _contentProgress = 0;
    _contentTravel = Offset.zero;
  }

  void _retargetImmediate(Size target) {
    _pendingHeightTarget = null;
    _heightLeadRemaining = Duration.zero;
    _geometry.width.retarget(target.width);
    _geometry.height.retarget(target.height);
  }

  void _forceAppear() {
    _appearanceComplete = true;
    _appearanceElapsed =
        _motionTheme.appearanceDuration ?? const Duration(milliseconds: 140);
    _envelopeOpacity = 1;
    _envelopeOffset = 0;
    _scale = 1;
    // Deliberately leaves the drag spring alone — a capsule dismissed straight
    // out of seed may already be under the finger.
    if (_pendingHeightTarget != null) {
      _geometry.height.retarget(_pendingHeightTarget!.height);
      _pendingHeightTarget = null;
      _heightLeadRemaining = Duration.zero;
    }
    if (_lifecycle.state == CapsuleLifecycleState.seed) {
      _lifecycle.didAppear();
      if (_pendingExpandAfterAppear) {
        _lifecycle.expand();
        _pendingExpandAfterAppear = false;
      }
    }
  }

  void _ensureTicker() {
    if (_ticker != null) {
      if (!_ticker!.isActive) {
        _lastElapsed = Duration.zero;
        _ticker!.start();
      }
      return;
    }
    _lastElapsed = Duration.zero;
    _ticker = _vsync.createTicker(_onTick)..start();
  }

  void _stopTickerIfIdle() {
    if (!_isIdle || _ticker == null) {
      return;
    }
    _ticker!.stop();
    _ticker!.dispose();
    _ticker = null;
    _lastElapsed = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    final Duration dt = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    if (dt <= Duration.zero) {
      return;
    }
    // Slice large ticker gaps into bounded frames so widget tests that
    // `pump` long durations still integrate the full spring timeline while
    // each spring.advance call remains clamped to 1/24s.
    const Duration maxStep = Duration(microseconds: 41667);
    Duration remaining = dt;
    while (remaining > Duration.zero) {
      final Duration step = remaining > maxStep ? maxStep : remaining;
      remaining -= step;
      _advance(step);
      if (_lifecycle.state == CapsuleLifecycleState.hidden && _exitCompleted) {
        break;
      }
    }
    _publish();
    _stopTickerIfIdle();
  }

  void _advance(Duration elapsed) {
    if (_lifecycle.state == CapsuleLifecycleState.collapsing) {
      _advanceExit(elapsed);
      return;
    }
    if (_lifecycle.state == CapsuleLifecycleState.hidden) {
      return;
    }

    _advanceAppearance(elapsed);
    _advanceHeightLead(elapsed);
    _advanceSprings(elapsed);
    _advanceContent(elapsed, revealing: true);
    _maybeSettleAndStartHold();
    _advanceHold(elapsed);
  }

  void _advanceAppearance(Duration elapsed) {
    if (_appearanceComplete) {
      return;
    }
    final Duration appearanceDuration =
        _motionTheme.appearanceDuration ?? const Duration(milliseconds: 140);
    _appearanceElapsed += elapsed;
    final double t =
        (_appearanceElapsed.inMicroseconds / appearanceDuration.inMicroseconds)
            .clamp(0.0, 1.0);
    final double curved = capsuleEaseOut.transform(t);
    // The entrance fade only ever brightens, matching the reference's
    // `op = max(op, inP)` guard.
    _envelopeOpacity = math.max(_envelopeOpacity, curved);
    if (_reducedMotion) {
      _envelopeOffset = 0;
      _scale = 1;
    } else {
      _envelopeOffset =
          _seedVerticalOffset + (0 - _seedVerticalOffset) * curved;
      _scale = _seedScale + (1 - _seedScale) * curved;
    }
    if (t >= 1) {
      _appearanceComplete = true;
      _envelopeOpacity = 1;
      _envelopeOffset = 0;
      _scale = 1;
    }
  }

  void _advanceHeightLead(Duration elapsed) {
    if (_pendingHeightTarget == null || _heightLeadRemaining <= Duration.zero) {
      return;
    }
    if (_reducedMotion) {
      _geometry.height.retarget(_pendingHeightTarget!.height);
      _pendingHeightTarget = null;
      _heightLeadRemaining = Duration.zero;
      return;
    }
    _heightLeadRemaining -= elapsed;
    if (_heightLeadRemaining <= Duration.zero) {
      _geometry.height.retarget(_pendingHeightTarget!.height);
      _pendingHeightTarget = null;
      _heightLeadRemaining = Duration.zero;
    }
  }

  void _advanceSprings(Duration elapsed) {
    final CapsuleToastSpring widthSpring = _springForWidth;
    final CapsuleToastSpring heightSpring = _springForHeight;
    _geometry.width.advance(elapsed, widthSpring);
    _geometry.height.advance(elapsed, heightSpring);
    // The drag spring only settles back to rest outside the exit — during a
    // collapse it stays frozen wherever the gesture (and its flick) left it.
    if (_appearanceComplete &&
        _lifecycle.state != CapsuleLifecycleState.collapsing) {
      _geometry.verticalOffset.advance(elapsed, heightSpring);
    }
  }

  CapsuleToastSpring get _reducedMotionSpring {
    return CapsuleToastSpring(
      duration:
          _motionTheme.reducedMotionSizeDuration ??
          const Duration(milliseconds: 240),
      bounce: 0,
    );
  }

  CapsuleToastSpring get _springForWidth {
    if (_reducedMotion) {
      return _reducedMotionSpring;
    }
    if (_usingExitSpring) {
      return _motionTheme.exitSpring!;
    }
    if (_usingInteractiveSpring) {
      return _motionTheme.interactiveSpring!;
    }
    return _motionTheme.widthSpring!;
  }

  CapsuleToastSpring get _springForHeight {
    if (_reducedMotion) {
      return _reducedMotionSpring;
    }
    if (_usingExitSpring) {
      return _motionTheme.exitSpring!;
    }
    if (_usingInteractiveSpring) {
      return _motionTheme.interactiveSpring!;
    }
    return _motionTheme.heightSpring!;
  }

  void _advanceContent(Duration elapsed, {required bool revealing}) {
    if (!_contentEnvelopeActive) {
      return;
    }
    final Duration slotReveal =
        _motionTheme.slotRevealDuration ?? const Duration(milliseconds: 220);
    final Duration maxDelay =
        _motionTheme.slotDelays?.values.fold<Duration>(
          Duration.zero,
          (Duration longest, Duration delay) =>
              delay > longest ? delay : longest,
        ) ??
        const Duration(milliseconds: 90);
    final Duration total = revealing
        ? slotReveal + maxDelay
        : capsuleToastRetractDuration(reducedMotion: _reducedMotion);

    _contentElapsed += elapsed;
    final double t = (_contentElapsed.inMicroseconds / total.inMicroseconds)
        .clamp(0.0, 1.0);
    if (revealing) {
      _contentProgress = t;
      final double remaining = 1 - t;
      _contentTravel = _reducedMotion
          ? Offset.zero
          : Offset(10 * remaining, 3 * remaining);
      if (t >= 1) {
        _contentProgress = 1;
        _contentTravel = Offset.zero;
        _contentEnvelopeActive = false;
      }
    } else {
      _contentProgress = 1 - t;
      final double remaining = t;
      _contentTravel = _reducedMotion
          ? Offset.zero
          : Offset(10 * remaining, 3 * remaining);
      if (t >= 1) {
        _contentProgress = 0;
        _contentTravel = Offset.zero;
        _contentEnvelopeActive = false;
      }
    }
  }

  void _maybeSettleAndStartHold() {
    if (_lifecycle.state != CapsuleLifecycleState.seed) {
      _maybeStartHold();
      return;
    }
    if (!_appearanceComplete ||
        _pendingHeightTarget != null ||
        !_geometry.width.isSettled ||
        !_geometry.height.isSettled) {
      return;
    }
    _lifecycle.didAppear();
    if (_pendingExpandAfterAppear) {
      _lifecycle.expand();
      _pendingExpandAfterAppear = false;
    }
    _maybeStartHold();
  }

  void _maybeStartHold() {
    if (_holdStarted ||
        _holdDuration == null ||
        !_isVisiblySettled ||
        _lifecycle.state == CapsuleLifecycleState.collapsing ||
        _lifecycle.state == CapsuleLifecycleState.hidden) {
      return;
    }
    _holdStarted = true;
    _holdClock.start(_holdDuration!);
    if (_interactionPaused) {
      _holdClock.pause();
    }
    _ensureTicker();
  }

  void _advanceHold(Duration elapsed) {
    if (!_holdStarted) {
      return;
    }
    if (_holdClock.advance(elapsed)) {
      _holdStarted = false;
      _holdClock.reset();
      _onHoldElapsed();
    }
  }

  void _advanceExit(Duration elapsed) {
    _exitElapsed += elapsed;
    final double exitMs = _exitElapsed.inMicroseconds / 1000;

    _advanceContent(elapsed, revealing: false);

    if (!_exitSizeRetargeted && exitMs >= _exitSizeAtMs) {
      _exitSizeRetargeted = true;
      _geometry.width.retarget(_seedWidth);
      _geometry.height.retarget(_seedHeight);
    }

    if (!_exitFadeStarted && exitMs >= _exitFadeStartMs) {
      _exitFadeStarted = true;
    }

    _advanceSprings(elapsed);

    if (_exitFadeStarted) {
      final double fadeT = ((exitMs - _exitFadeStartMs) / _exitFadeDurationMs)
          .clamp(0.0, 1.0);
      final double curved = capsuleEaseOut.transform(fadeT);
      _envelopeOpacity = 1 - curved;
      // Composes on top of the frozen drag offset rather than replacing it, so
      // a flicked capsule keeps travelling from where it was released.
      _envelopeOffset = _reducedMotion ? 0 : -_exitUpwardTravel * curved;
    }

    if (!_exitCompleted && exitMs >= _exitCompleteMs) {
      _exitCompleted = true;
      _envelopeOpacity = 0;
      _lifecycle.didHide();
      _holdClock.reset();
      _holdStarted = false;
      _contentEnvelopeActive = false;
      _contentProgress = 0;
      _onExitCompleted();
    }
  }

  bool get _isVisiblySettled {
    return _appearanceComplete &&
        _pendingHeightTarget == null &&
        _geometry.width.isSettled &&
        _geometry.height.isSettled &&
        (_lifecycle.state == CapsuleLifecycleState.compact ||
            _lifecycle.state == CapsuleLifecycleState.expanded);
  }

  bool get _isIdle {
    if (_lifecycle.state == CapsuleLifecycleState.collapsing) {
      return false;
    }
    if (_lifecycle.state == CapsuleLifecycleState.hidden) {
      return true;
    }
    if (_dragging || _interactionPaused) {
      // Keep the ticker alive while the pointer is down so resume does not
      // depend on recreating a ticker between gesture.up and the next pump.
      return false;
    }
    if (!_appearanceComplete || _contentEnvelopeActive) {
      return false;
    }
    if (_pendingHeightTarget != null) {
      return false;
    }
    if (!_geometry.isSettled) {
      return false;
    }
    if (_holdStarted) {
      return false;
    }
    return true;
  }

  void _publish() {
    notifyListeners();
  }
}
