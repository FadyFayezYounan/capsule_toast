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
    final ButtonStyle resolvedStyle = _resolveButtonStyle();
    const Set<WidgetState> states = <WidgetState>{};
    final Color backgroundColor =
        resolvedStyle.backgroundColor?.resolve(states) ??
        theme.actionSurfaceColor!;
    final Color foregroundColor =
        resolvedStyle.foregroundColor?.resolve(states) ??
        theme.foregroundColor!;
    final TextStyle textStyle =
        resolvedStyle.textStyle?.resolve(states) ??
        theme.actionTextStyle!.copyWith(color: foregroundColor);
    final EdgeInsetsGeometry resolvedPadding =
        resolvedStyle.padding?.resolve(states) ?? padding;
    final Size? minimumSize = resolvedStyle.minimumSize?.resolve(states);
    final double minHeight = minimumSize?.height ?? height;
    final OutlinedBorder? shape = resolvedStyle.shape?.resolve(states);
    final double borderRadius = switch (shape) {
      RoundedRectangleBorder border =>
        border.borderRadius.resolve(Directionality.of(context)).topLeft.x,
      StadiumBorder() => minHeight / 2,
      _ => minHeight / 2,
    };

    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      child: FocusableActionDetector(
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: () => coordinator.invokeAction(token, action),
            borderRadius: BorderRadius.circular(borderRadius),
            child: Ink(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Padding(
                padding: resolvedPadding.resolve(Directionality.of(context)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Center(
                    child: Text(
                      action.label,
                      style: textStyle,
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

  ButtonStyle _resolveButtonStyle() {
    final ButtonStyle defaults = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color?>(theme.actionSurfaceColor),
      foregroundColor: WidgetStatePropertyAll<Color?>(theme.foregroundColor),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        theme.actionTextStyle!.copyWith(color: theme.foregroundColor),
      ),
      minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return defaults.merge(style);
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
