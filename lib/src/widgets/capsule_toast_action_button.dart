// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../model/capsule_toast_action.dart';
import '../theme/capsule_toast_theme_data.dart';

/// Tappable action control inside a capsule toast.
class CapsuleToastActionButton extends StatelessWidget {
  /// Creates an action button that routes presses through [coordinator].
  const CapsuleToastActionButton({
    super.key,
    required this.action,
    required this.coordinator,
    required this.token,
    required this.theme,
    required this.height,
    required this.padding,
    this.style,
    this.compact = false,
  });

  /// Action metadata and callback.
  final CapsuleToastAction action;

  /// Coordinator that owns the active toast record.
  final CapsuleToastCoordinator coordinator;

  /// Active record token used for routing.
  final int token;

  /// Resolved visual theme.
  final CapsuleToastThemeData theme;

  /// Minimum tap target height.
  final double height;

  /// Directional padding around the label.
  final EdgeInsetsGeometry padding;

  /// Optional material button style override.
  final ButtonStyle? style;

  /// Whether this action uses compact chrome.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = theme.actionTextStyle!.copyWith(
      color: theme.foregroundColor,
    );

    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      child: FocusableActionDetector(
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: () => coordinator.invokeAction(token, action),
            borderRadius: BorderRadius.circular(height / 2),
            child: Ink(
              decoration: BoxDecoration(
                color: theme.actionSurfaceColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: Padding(
                padding: padding.resolve(Directionality.of(context)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: Center(
                    child: Text(
                      action.label,
                      style: baseStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastAction>('action', action));
    properties.add(IntProperty('token', token));
    properties.add(DoubleProperty('height', height));
    properties.add(DiagnosticsProperty<bool>('compact', compact));
  }
}
