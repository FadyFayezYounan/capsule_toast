// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'capsule_toast_data.dart';
import 'capsule_toast_result.dart';

/// Commands routed from a visible toast back to its host coordinator.
abstract interface class CapsuleToastHandleDelegate {
  /// Requests expanded layout for the toast identified by [token].
  void expand(int token);

  /// Requests compact layout for the toast identified by [token].
  void collapse(int token);

  /// Replaces unresolved toast data for the toast identified by [token].
  void resolve(int token, CapsuleToastData toast);

  /// Requests dismissal for the toast identified by [token].
  void dismiss(int token);
}

/// Live command surface for one shown toast record.
abstract interface class CapsuleToastHandle {
  /// Optional stable identifier copied from the toast data.
  Object? get id;

  /// Completes once when the toast record finishes its lifecycle.
  Future<CapsuleToastResult> get closed;

  /// Whether [closed] has already completed.
  bool get isClosed;

  /// Requests expanded layout for this toast when it is active.
  void expand();

  /// Requests compact layout for this toast when it is active.
  void collapse();

  /// Replaces unresolved toast content while preserving this handle.
  void resolve(CapsuleToastData toast);

  /// Requests explicit dismissal of this toast when it is active.
  void dismiss();
}
