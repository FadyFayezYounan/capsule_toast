// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';

import 'lab_variants.dart';

/// Frozen capsule interiors used by the component-state gallery.
///
/// These mirror the package's structured content at rest, drawn straight from
/// [CapsuleToastThemeData.fallback] so a specimen and a live toast cannot drift
/// apart.
abstract final class LabSpecimens {
  static CapsuleToastThemeData get _theme => CapsuleToastThemeData.fallback();

  /// Leading icon disc for [type].
  static Widget icon(CapsuleToastType type, {bool spinning = false}) {
    final CapsuleToastThemeData theme = _theme;
    final double size = theme.compactIconSize!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.tints!.colorFor(type),
        shape: BoxShape.circle,
      ),
      child: CapsuleToastGlyphWidget(
        glyph: CapsuleToastGlyph.automatic.resolveFor(type),
        color: theme.accents!.colorFor(type),
        size: 20,
        theme: theme,
        tickerEnabled: spinning,
      ),
    );
  }

  /// The 84×34 seed capsule interior — a single accent dot.
  static Widget seed() {
    final CapsuleToastThemeData theme = _theme;
    return SizedBox(
      width: theme.seedSize!.width,
      height: theme.seedSize!.height,
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: theme.accents!.success,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  /// Compact interior: icon, truncating title, optional chip.
  static Widget compact({
    required CapsuleToastType type,
    required String title,
    String? chipLabel,
    bool spinning = false,
    TextDirection direction = TextDirection.ltr,
  }) {
    final CapsuleToastThemeData theme = _theme;
    return Directionality(
      textDirection: direction,
      child: Padding(
        padding: theme.compactPadding!,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: theme.compactMinimumHeight!,
            maxWidth: theme.maximumWidth!,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon(type, spinning: spinning),
              SizedBox(width: theme.compactSpacing),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: theme.compactTitleMaximumWidth!,
                  ),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.titleTextStyle!.copyWith(
                      color: theme.foregroundColor,
                    ),
                  ),
                ),
              ),
              if (chipLabel != null) ...<Widget>[
                SizedBox(width: theme.compactSpacing),
                Container(
                  height: theme.compactActionHeight,
                  alignment: Alignment.center,
                  padding: theme.compactActionPadding,
                  decoration: BoxDecoration(
                    color: theme.actionSurfaceColor,
                    borderRadius: BorderRadius.circular(
                      theme.compactActionHeight! / 2,
                    ),
                  ),
                  child: Text(
                    chipLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.foregroundColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Expanded interior: icon, title, supporting line, action row.
  static Widget expanded({
    required CapsuleToastType type,
    required LabCopy copy,
    TextDirection direction = TextDirection.ltr,
  }) {
    final CapsuleToastThemeData theme = _theme;
    return Directionality(
      textDirection: direction,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.maximumWidth!),
        child: Padding(
          padding: theme.expandedPadding!,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon(type),
              SizedBox(width: theme.expandedSpacing),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      copy.title,
                      style: theme.expandedTitleTextStyle!.copyWith(
                        color: theme.foregroundColor,
                      ),
                    ),
                    if (copy.message != null) ...<Widget>[
                      SizedBox(height: theme.messageSpacing),
                      Text(
                        copy.message!,
                        style: theme.messageTextStyle!.copyWith(
                          color: theme.secondaryForegroundColor,
                        ),
                      ),
                    ],
                    if (copy.action != null) ...<Widget>[
                      SizedBox(height: theme.actionTopSpacing),
                      Wrap(
                        spacing: theme.actionSpacing!,
                        runSpacing: 8,
                        children: <Widget>[
                          _pill(
                            label: copy.action!,
                            background: theme.foregroundColor!,
                            foreground: const Color(0xFF1A1714),
                            weight: FontWeight.w600,
                            padding: theme.primaryActionPadding!,
                            height: theme.expandedActionHeight!,
                          ),
                          _pill(
                            label: direction == TextDirection.rtl
                                ? 'تجاهل'
                                : 'Dismiss',
                            background: const Color(0x00000000),
                            foreground: theme.secondaryForegroundColor!,
                            weight: FontWeight.w500,
                            padding: theme.secondaryActionPadding!,
                            height: theme.expandedActionHeight!,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
    required FontWeight weight,
    required EdgeInsetsGeometry padding,
    required double height,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: weight,
          letterSpacing: -0.1,
          color: foreground,
        ),
      ),
    );
  }
}
