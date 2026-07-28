// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_motion_theme.dart';
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
  /// Creates a controller driven by [vsync] using [motionTheme].
  CapsuleMotionController({
    required TickerProvider vsync,
    required CapsuleToastMotionTheme motionTheme,
    required VoidCallback onHoldElapsed,
    required VoidCallback onExitCompleted,
  }) : _vsync = vsync,
       _motionTheme = motionTheme,
       _onHoldElapsed = onHoldElapsed,
       _onExitCompleted = onExitCompleted,
       _geometry = CapsuleGeometry(
         width: DampedSpring(value: _seedWidth),
         height: DampedSpring(value: _seedHeight),
         opacity: DampedSpring(value: 0),
         verticalOffset: DampedSpring(value: _seedVerticalOffset),
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
  bool _usingExitSpring = false;
  bool _usingInteractiveSpring = false;
  bool _pendingExpandAfterAppear = false;
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
      verticalOffset: _envelopeOffset,
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

  /// Directional content travel remaining for tests.
  @visibleForTesting
  Offset get debugContentTravel => _contentTravel;

  /// Starts entrance from the seed geometry toward [target].
  void show({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    _holdDuration = holdDuration;
    _holdStarted = false;
    _holdClock.reset();
    _usingExitSpring = false;
    _usingInteractiveSpring = false;
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
  void retarget(Size target) {
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

  /// Replaces content while preserving geometry position and velocity.
  void replace({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    _prepareContinuousContentChange(
      target: target,
      mode: mode,
      holdDuration: holdDuration,
    );
  }

  /// Resolves loading content while preserving geometry continuity.
  void resolve({
    required Size target,
    required CapsuleToastMode mode,
    Duration? holdDuration,
  }) {
    _prepareContinuousContentChange(
      target: target,
      mode: mode,
      holdDuration: holdDuration,
    );
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
    _holdStarted = false;
    _holdClock.reset();
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
    _holdStarted = false;
    _holdClock.reset();
    _retargetImmediate(target);
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
    _lifecycle.requestDismiss(reason);
    _exitElapsed = Duration.zero;
    _exitSizeRetargeted = false;
    _exitFadeStarted = false;
    _exitCompleted = false;
    _holdClock.reset();
    _holdStarted = false;
    _contentEnvelopeActive = true;
    if (velocity != 0) {
      _geometry.verticalOffset.velocity = -velocity.abs();
    }
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
    }
    if (!paused && _holdStarted && !_isIdle) {
      _ensureTicker();
    }
    _publish();
  }

  /// Updates spring timing from a newly resolved motion theme.
  void updateMotionTheme(CapsuleToastMotionTheme value) {
    _motionTheme = value;
  }

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
    _holdStarted = false;
    _holdClock.reset();
    _usingExitSpring = false;
    _contentElapsed = Duration.zero;
    _contentEnvelopeActive = true;
    _contentProgress = 0;
    _contentTravel = Offset.zero;
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

  void _jumpToSeed() {
    _geometry.width.jumpTo(_seedWidth);
    _geometry.height.jumpTo(_seedHeight);
    _geometry.opacity.jumpTo(0);
    _geometry.verticalOffset.jumpTo(_seedVerticalOffset);
    _envelopeOpacity = 0;
    _envelopeOffset = _seedVerticalOffset;
    _scale = _seedScale;
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
    _geometry.opacity.jumpTo(1);
    _geometry.verticalOffset.jumpTo(0);
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
    final double curved = Curves.easeOut.transform(t);
    _envelopeOpacity = curved;
    _envelopeOffset = _seedVerticalOffset + (0 - _seedVerticalOffset) * curved;
    _scale = _seedScale + (1 - _seedScale) * curved;
    _geometry.opacity.jumpTo(_envelopeOpacity);
    _geometry.verticalOffset.jumpTo(_envelopeOffset);
    if (t >= 1) {
      _appearanceComplete = true;
      _envelopeOpacity = 1;
      _envelopeOffset = 0;
      _scale = 1;
      _geometry.opacity.jumpTo(1);
      _geometry.verticalOffset.jumpTo(0);
    }
  }

  void _advanceHeightLead(Duration elapsed) {
    if (_pendingHeightTarget == null || _heightLeadRemaining <= Duration.zero) {
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
    if (_appearanceComplete &&
        _lifecycle.state != CapsuleLifecycleState.collapsing) {
      _geometry.opacity.advance(elapsed, widthSpring);
      _geometry.verticalOffset.advance(elapsed, heightSpring);
      _envelopeOpacity = _geometry.opacity.value;
      _envelopeOffset = _geometry.verticalOffset.value;
    }
  }

  CapsuleToastSpring get _springForWidth {
    if (_usingExitSpring) {
      return _motionTheme.exitSpring!;
    }
    if (_usingInteractiveSpring) {
      return _motionTheme.interactiveSpring!;
    }
    return _motionTheme.widthSpring!;
  }

  CapsuleToastSpring get _springForHeight {
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
        : const Duration(milliseconds: 160);

    _contentElapsed += elapsed;
    final double t = (_contentElapsed.inMicroseconds / total.inMicroseconds)
        .clamp(0.0, 1.0);
    if (revealing) {
      _contentProgress = t;
      final double remaining = 1 - t;
      _contentTravel = Offset(10 * remaining, 3 * remaining);
      if (t >= 1) {
        _contentProgress = 1;
        _contentTravel = Offset.zero;
        _contentEnvelopeActive = false;
      }
    } else {
      _contentProgress = 1 - t;
      final double remaining = t;
      _contentTravel = Offset(10 * remaining, 3 * remaining);
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
      _usingExitSpring = true;
      _usingInteractiveSpring = false;
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
      final double curved = Curves.easeOut.transform(fadeT);
      _envelopeOpacity = 1 - curved;
      _envelopeOffset = -_exitUpwardTravel * curved;
      _scale = 1;
      _geometry.opacity.jumpTo(_envelopeOpacity);
      _geometry.verticalOffset.jumpTo(_envelopeOffset);
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
    if (!_appearanceComplete || _contentEnvelopeActive) {
      return false;
    }
    if (_pendingHeightTarget != null) {
      return false;
    }
    if (!_geometry.isSettled) {
      return false;
    }
    if (_holdStarted && !_interactionPaused) {
      return false;
    }
    return true;
  }

  void _publish() {
    notifyListeners();
  }
}
