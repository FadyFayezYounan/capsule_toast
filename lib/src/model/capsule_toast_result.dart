// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';

import 'capsule_toast_action.dart';
import 'capsule_toast_types.dart';

/// Completion value emitted when a toast closes.
@immutable
class CapsuleToastResult with Diagnosticable {
  /// Creates a result describing how [reason] ended the toast lifecycle.
  const CapsuleToastResult({required this.reason, this.action});

  /// Why the toast was dismissed or removed.
  final CapsuleToastDismissReason reason;

  /// The action selected when [reason] is
  /// [CapsuleToastDismissReason.actionSelected].
  final CapsuleToastAction? action;

  /// Adds diagnostic properties for this dismiss result.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastDismissReason>('reason', reason));
    properties.add(DiagnosticsProperty<CapsuleToastAction?>('action', action));
  }

  /// Whether [other] describes the same dismiss outcome as this instance.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastResult &&
        other.reason == reason &&
        other.action == action;
  }

  /// A hash code derived from [reason] and [action].
  @override
  int get hashCode => Object.hash(reason, action);
}
