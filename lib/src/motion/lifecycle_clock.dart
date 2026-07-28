// Copyright 2026 The Capsule Toast Authors. All rights reserved.

/// Pausable hold timer for auto-dismiss eligibility.
final class LifecycleClock {
  int _elapsedMicros = 0;
  int _durationMicros = 0;
  bool _running = false;
  bool _paused = false;

  /// Starts counting toward [duration], resetting prior elapsed time.
  void start(Duration duration) {
    _durationMicros = duration.inMicroseconds;
    _elapsedMicros = 0;
    _running = true;
    _paused = false;
  }

  /// Stops accumulating elapsed time until [resume].
  void pause() {
    _paused = true;
  }

  /// Resumes accumulating elapsed time after [pause].
  void resume() {
    _paused = false;
  }

  /// Clears duration, elapsed time, and running or paused state.
  void reset() {
    _durationMicros = 0;
    _elapsedMicros = 0;
    _running = false;
    _paused = false;
  }

  /// Adds [elapsed] when running and unpaused; returns whether hold completed.
  bool advance(Duration elapsed) {
    if (!_running || _paused || _durationMicros == 0) {
      return false;
    }
    _elapsedMicros += elapsed.inMicroseconds;
    return _elapsedMicros >= _durationMicros;
  }
}
