// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_handle.dart';
import '../model/capsule_toast_types.dart';

/// Host-facing API for showing and clearing capsule toasts.
abstract interface class CapsuleToastManager {
  /// Shows [toast] and returns a handle for live commands.
  CapsuleToastHandle show(
    CapsuleToastData toast, {
    CapsuleToastQueuePolicy queuePolicy = CapsuleToastQueuePolicy.enqueue,
  });

  /// Clears queued toasts and begins exit for the active toast.
  void clear();

  /// Number of toast records waiting behind the active toast.
  int get queueLength;
}
