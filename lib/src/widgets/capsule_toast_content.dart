// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
import '../model/capsule_toast_data.dart';
import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme_data.dart';
import 'capsule_toast_action_button.dart';
import 'capsule_toast_animated_slot.dart';
import 'capsule_toast_glyph.dart';

/// Composes the default live-region announcement for [toast].
String composeCapsuleToastAnnouncement(CapsuleToastData toast) {
  if (toast.semanticAnnouncement case final String announcement) {
    return announcement;
  }
  final String prefix = switch (toast.type) {
    CapsuleToastType.success => 'Success.',
    CapsuleToastType.information => 'Information.',
    CapsuleToastType.warning => 'Warning.',
    CapsuleToastType.error => 'Error.',
    CapsuleToastType.loading => 'Loading.',
    CapsuleToastType.neutral => 'Notice.',
    CapsuleToastType.custom => 'Notice.',
  };
  return <String>[
    prefix,
    if (toast.title case final String title) title,
    if (toast.message case final String message) message,
  ].join(' ');
}

/// Structured capsule toast content for compact and expanded layouts.
class CapsuleToastContent extends StatelessWidget {
  /// Creates structured content for [record].
  const CapsuleToastContent({
    super.key,
    required this.record,
    required this.coordinator,
    required this.visualTheme,
    required this.motionTheme,
    required this.vsync,
  });

  /// Active toast record being rendered.
  final CapsuleToastRecord record;

  /// Queue coordinator for action routing.
  final CapsuleToastCoordinator coordinator;

  /// Resolved visual theme for this record.
  final CapsuleToastThemeData visualTheme;

  /// Resolved motion theme for this record.
  final CapsuleToastMotionTheme motionTheme;

  /// Ticker provider for loading glyphs.
  final TickerProvider vsync;

  @override
  Widget build(BuildContext context) {
    final CapsuleToastData data = record.data;
    final TextDirection direction =
        data.textDirection ?? Directionality.of(context);
    return Directionality(
      textDirection: direction,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final CapsuleToastMode mode = record.desiredMode;
          return switch (mode) {
            CapsuleToastMode.compact => _buildCompact(
              context,
              data,
              constraints,
            ),
            CapsuleToastMode.expanded => _buildExpanded(
              context,
              data,
              constraints,
            ),
          };
        },
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    CapsuleToastData data,
    BoxConstraints constraints,
  ) {
    if (data.compactBuilder != null) {
      return data.compactBuilder!(
        context,
        CapsuleToastContentContext(
          toast: data,
          mode: CapsuleToastMode.compact,
          visualTheme: visualTheme,
          motionTheme: motionTheme,
          manager: coordinator,
          handle: record.handle,
          constraints: constraints,
        ),
      );
    }

    final TextStyle titleStyle = visualTheme.titleTextStyle!.copyWith(
      color: visualTheme.foregroundColor,
    );

    return Padding(
      padding: visualTheme.compactPadding!,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: visualTheme.compactMinimumHeight!,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CapsuleToastAnimatedSlot(
              slot: CapsuleToastSlot.icon,
              child: _buildLeadingIcon(data),
            ),
            SizedBox(width: visualTheme.compactSpacing),
            Flexible(
              child: CapsuleToastAnimatedSlot(
                slot: CapsuleToastSlot.title,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: visualTheme.compactTitleMaximumWidth!,
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      data.title ?? '',
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            if (data.compactAction != null) ...<Widget>[
              SizedBox(width: visualTheme.compactSpacing),
              CapsuleToastAnimatedSlot(
                slot: CapsuleToastSlot.action,
                child: CapsuleToastActionButton(
                  action: data.compactAction!,
                  coordinator: coordinator,
                  token: record.token,
                  theme: visualTheme,
                  height: visualTheme.compactActionHeight!,
                  padding: visualTheme.compactActionPadding!,
                  style: visualTheme.compactActionStyle,
                  compact: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded(
    BuildContext context,
    CapsuleToastData data,
    BoxConstraints constraints,
  ) {
    if (data.expandedBuilder != null) {
      return data.expandedBuilder!(
        context,
        CapsuleToastContentContext(
          toast: data,
          mode: CapsuleToastMode.expanded,
          visualTheme: visualTheme,
          motionTheme: motionTheme,
          manager: coordinator,
          handle: record.handle,
          constraints: constraints,
        ),
      );
    }
    if (data.compactBuilder != null) {
      return data.compactBuilder!(
        context,
        CapsuleToastContentContext(
          toast: data,
          mode: CapsuleToastMode.expanded,
          visualTheme: visualTheme,
          motionTheme: motionTheme,
          manager: coordinator,
          handle: record.handle,
          constraints: constraints,
        ),
      );
    }

    final TextStyle titleStyle = visualTheme.titleTextStyle!.copyWith(
      color: visualTheme.foregroundColor,
    );
    final TextStyle messageStyle = visualTheme.messageTextStyle!.copyWith(
      color: visualTheme.secondaryForegroundColor,
    );

    return Padding(
      padding: visualTheme.expandedPadding!,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CapsuleToastAnimatedSlot(
            slot: CapsuleToastSlot.icon,
            child: _buildLeadingIcon(data),
          ),
          SizedBox(width: visualTheme.expandedSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (data.title != null)
                  CapsuleToastAnimatedSlot(
                    slot: CapsuleToastSlot.title,
                    child: ExcludeSemantics(
                      child: Text(data.title!, style: titleStyle),
                    ),
                  ),
                if (data.message != null) ...<Widget>[
                  SizedBox(height: visualTheme.messageSpacing),
                  CapsuleToastAnimatedSlot(
                    slot: CapsuleToastSlot.message,
                    child: ExcludeSemantics(
                      child: Text(data.message!, style: messageStyle),
                    ),
                  ),
                ],
                if (data.primaryAction != null ||
                    data.secondaryAction != null) ...<Widget>[
                  SizedBox(height: visualTheme.actionTopSpacing),
                  CapsuleToastAnimatedSlot(
                    slot: CapsuleToastSlot.action,
                    child: Wrap(
                      spacing: visualTheme.actionSpacing!,
                      runSpacing: visualTheme.actionSpacing!,
                      children: <Widget>[
                        if (data.primaryAction != null)
                          CapsuleToastActionButton(
                            action: data.primaryAction!,
                            coordinator: coordinator,
                            token: record.token,
                            theme: visualTheme,
                            height: visualTheme.expandedActionHeight!,
                            padding: visualTheme.primaryActionPadding!,
                            style: visualTheme.primaryActionStyle,
                          ),
                        if (data.secondaryAction != null)
                          CapsuleToastActionButton(
                            action: data.secondaryAction!,
                            coordinator: coordinator,
                            token: record.token,
                            theme: visualTheme,
                            height: visualTheme.expandedActionHeight!,
                            padding: visualTheme.secondaryActionPadding!,
                            style: visualTheme.secondaryActionStyle,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastRecord>('record', record));
    properties.add(
      DiagnosticsProperty<CapsuleToastThemeData>('visualTheme', visualTheme),
    );
  }

  Widget _buildLeadingIcon(CapsuleToastData data) {
    return _CapsuleToastLeadingIcon(
      data: data,
      theme: visualTheme,
      vsync: vsync,
      compact: record.desiredMode == CapsuleToastMode.compact,
    );
  }
}

class _CapsuleToastLeadingIcon extends StatelessWidget {
  const _CapsuleToastLeadingIcon({
    required this.data,
    required this.theme,
    required this.vsync,
    required this.compact,
  });

  final CapsuleToastData data;
  final CapsuleToastThemeData theme;
  final TickerProvider vsync;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact
        ? theme.compactIconSize!
        : theme.expandedIconSize!;
    final Color accent = theme.accents!.colorFor(data.type);
    final Color tint = theme.tints!.colorFor(data.type);

    Widget icon;
    if (data.iconBuilder != null) {
      icon = SizedBox(
        width: iconSize,
        height: iconSize,
        child: Center(child: data.iconBuilder!(context)),
      );
    } else if (data.icon != null) {
      icon = SizedBox(
        width: iconSize,
        height: iconSize,
        child: Icon(data.icon, color: accent, size: iconSize * 0.55),
      );
    } else {
      final CapsuleToastGlyph resolved = resolveCapsuleToastGlyph(
        data.glyph,
        data.type,
      );
      icon = CapsuleToastGlyphWidget(
        glyph: resolved,
        color: accent,
        size: 20,
        theme: theme,
      );
    }

    return ExcludeSemantics(
      child: Container(
        width: iconSize,
        height: iconSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
        child: icon,
      ),
    );
  }
}
