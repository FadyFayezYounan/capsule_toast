// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../model/capsule_toast_action.dart';
import '../theme/capsule_toast_theme_data.dart';

/// Tappable action control inside a capsule toast.
class CapsuleToastActionButton extends StatefulWidget {
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
  State<CapsuleToastActionButton> createState() =>
      _CapsuleToastActionButtonState();
}

class _CapsuleToastActionButtonState extends State<CapsuleToastActionButton> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: 'capsule_toast.action.${widget.action.label}',
  );

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _invoke() {
    widget.coordinator.invokeAction(widget.token, widget.action);
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle resolvedStyle = _resolveButtonStyle();
    const Set<WidgetState> states = <WidgetState>{};
    final Color backgroundColor =
        resolvedStyle.backgroundColor?.resolve(states) ??
        widget.theme.actionSurfaceColor!;
    final Color foregroundColor =
        resolvedStyle.foregroundColor?.resolve(states) ??
        widget.theme.foregroundColor!;
    final TextStyle textStyle =
        resolvedStyle.textStyle?.resolve(states) ??
        widget.theme.actionTextStyle!.copyWith(color: foregroundColor);
    final EdgeInsetsGeometry resolvedPadding =
        resolvedStyle.padding?.resolve(states) ?? widget.padding;
    final Size? minimumSize = resolvedStyle.minimumSize?.resolve(states);
    final double minHeight = minimumSize?.height ?? widget.height;
    final OutlinedBorder? shape = resolvedStyle.shape?.resolve(states);
    final double borderRadius = switch (shape) {
      RoundedRectangleBorder border =>
        border.borderRadius.resolve(Directionality.of(context)).topLeft.x,
      StadiumBorder() => minHeight / 2,
      _ => minHeight / 2,
    };

    return Semantics(
      button: true,
      label: widget.action.semanticLabel ?? widget.action.label,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _invoke();
              return null;
            },
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (ButtonActivateIntent intent) {
              _invoke();
              return null;
            },
          ),
        },
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              focusNode: _focusNode,
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: _invoke,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: (_) {},
                onVerticalDragUpdate: (_) {},
                onVerticalDragEnd: (_) {},
                child: Ink(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Padding(
                    padding: resolvedPadding.resolve(
                      Directionality.of(context),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      // Hugs the label: actions are pills sized to their text,
                      // not full-width bars.
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          widget.action.label,
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
        ),
      ),
    );
  }

  ButtonStyle _resolveButtonStyle() {
    final ButtonStyle defaults = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll<Color?>(
        widget.theme.actionSurfaceColor,
      ),
      foregroundColor: WidgetStatePropertyAll<Color?>(
        widget.theme.foregroundColor,
      ),
      textStyle: WidgetStatePropertyAll<TextStyle?>(
        widget.theme.actionTextStyle!.copyWith(
          color: widget.theme.foregroundColor,
        ),
      ),
      minimumSize: WidgetStatePropertyAll<Size?>(Size(0, widget.height)),
      padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(widget.padding),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    // The caller's style wins; `defaults` only fills the gaps. `merge` keeps
    // the receiver's non-null fields, so the override has to be the receiver.
    return widget.style?.merge(defaults) ?? defaults;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CapsuleToastAction>('action', widget.action),
    );
    properties.add(IntProperty('token', widget.token));
    properties.add(DoubleProperty('height', widget.height));
    properties.add(DiagnosticsProperty<bool>('compact', widget.compact));
  }
}
