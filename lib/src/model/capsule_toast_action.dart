// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Callback invoked when a toast action button is pressed.
typedef CapsuleToastActionCallback = FutureOr<void> Function();

/// Describes a tappable action shown on a toast capsule.
@immutable
class CapsuleToastAction with Diagnosticable {
  /// Creates a toast action with the given [label] and [onPressed] handler.
  const CapsuleToastAction({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.dismissOnInvoke = true,
  }) : assert(label != '');

  /// Visible action label.
  final String label;

  /// Handler invoked when the action is activated.
  final CapsuleToastActionCallback onPressed;

  /// Optional accessibility label when [label] is insufficient.
  final String? semanticLabel;

  /// Whether the toast dismisses after [onPressed] completes.
  final bool dismissOnInvoke;

  /// Adds diagnostic properties for this action.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label));
    properties.add(StringProperty('semanticLabel', semanticLabel));
    properties.add(
      DiagnosticsProperty<bool>('dismissOnInvoke', dismissOnInvoke),
    );
    properties.add(
      ObjectFlagProperty<CapsuleToastActionCallback>('onPressed', onPressed),
    );
  }

  /// Whether [other] describes the same action configuration as this instance.
  ///
  /// [onPressed] is not compared; only [label], [semanticLabel], and
  /// [dismissOnInvoke] participate in equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastAction &&
        other.label == label &&
        other.semanticLabel == semanticLabel &&
        other.dismissOnInvoke == dismissOnInvoke;
  }

  /// A hash code derived from [label], [semanticLabel], and [dismissOnInvoke].
  @override
  int get hashCode => Object.hash(label, semanticLabel, dismissOnInvoke);
}
