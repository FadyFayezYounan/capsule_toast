// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/capsule_toast_types.dart';

/// Builds a structured glyph for capsule toast content.
typedef CapsuleToastGlyphBuilder =
    Widget Function(
      BuildContext context,
      CapsuleToastGlyph glyph,
      Color color,
      double size,
    );

/// Builds a loading spinner for capsule toast content.
typedef CapsuleToastSpinnerBuilder =
    Widget Function(BuildContext context, Color color, double size);

/// Semantic accent colors for capsule toast types.
@immutable
class CapsuleToastAccents with Diagnosticable {
  /// Creates accent colors for every toast semantic type.
  const CapsuleToastAccents({
    required this.success,
    required this.information,
    required this.warning,
    required this.error,
    required this.loading,
    required this.neutral,
    required this.custom,
  });

  /// Accent for [CapsuleToastType.success].
  final Color success;

  /// Accent for [CapsuleToastType.information].
  final Color information;

  /// Accent for [CapsuleToastType.warning].
  final Color warning;

  /// Accent for [CapsuleToastType.error].
  final Color error;

  /// Accent for [CapsuleToastType.loading].
  final Color loading;

  /// Accent for [CapsuleToastType.neutral].
  final Color neutral;

  /// Accent for [CapsuleToastType.custom].
  final Color custom;

  /// Returns the accent color for [type].
  Color colorFor(CapsuleToastType type) {
    return switch (type) {
      CapsuleToastType.success => success,
      CapsuleToastType.information => information,
      CapsuleToastType.warning => warning,
      CapsuleToastType.error => error,
      CapsuleToastType.loading => loading,
      CapsuleToastType.neutral => neutral,
      CapsuleToastType.custom => custom,
    };
  }

  /// Returns a copy with the given fields replaced.
  CapsuleToastAccents copyWith({
    Color? success,
    Color? information,
    Color? warning,
    Color? error,
    Color? loading,
    Color? neutral,
    Color? custom,
  }) {
    return CapsuleToastAccents(
      success: success ?? this.success,
      information: information ?? this.information,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      loading: loading ?? this.loading,
      neutral: neutral ?? this.neutral,
      custom: custom ?? this.custom,
    );
  }

  /// Linearly interpolates between [a] and [b] by [t].
  static CapsuleToastAccents? lerp(
    CapsuleToastAccents? a,
    CapsuleToastAccents? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return CapsuleToastAccents(
      success: Color.lerp(a.success, b.success, t)!,
      information: Color.lerp(a.information, b.information, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      loading: Color.lerp(a.loading, b.loading, t)!,
      neutral: Color.lerp(a.neutral, b.neutral, t)!,
      custom: Color.lerp(a.custom, b.custom, t)!,
    );
  }

  /// Describes the properties of this object for debugging.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('success', success));
    properties.add(ColorProperty('information', information));
    properties.add(ColorProperty('warning', warning));
    properties.add(ColorProperty('error', error));
    properties.add(ColorProperty('loading', loading));
    properties.add(ColorProperty('neutral', neutral));
    properties.add(ColorProperty('custom', custom));
  }

  /// Whether these accent colors are equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastAccents &&
        other.success == success &&
        other.information == information &&
        other.warning == warning &&
        other.error == error &&
        other.loading == loading &&
        other.neutral == neutral &&
        other.custom == custom;
  }

  /// The hash code for these accent colors.
  @override
  int get hashCode => Object.hash(
    success,
    information,
    warning,
    error,
    loading,
    neutral,
    custom,
  );
}

/// Semantic surface tints for capsule toast types.
@immutable
class CapsuleToastTints with Diagnosticable {
  /// Creates tint colors for every toast semantic type.
  const CapsuleToastTints({
    required this.success,
    required this.information,
    required this.warning,
    required this.error,
    required this.loading,
    required this.neutral,
    required this.custom,
  });

  /// Tint for [CapsuleToastType.success].
  final Color success;

  /// Tint for [CapsuleToastType.information].
  final Color information;

  /// Tint for [CapsuleToastType.warning].
  final Color warning;

  /// Tint for [CapsuleToastType.error].
  final Color error;

  /// Tint for [CapsuleToastType.loading].
  final Color loading;

  /// Tint for [CapsuleToastType.neutral].
  final Color neutral;

  /// Tint for [CapsuleToastType.custom].
  final Color custom;

  /// Returns the tint color for [type].
  Color colorFor(CapsuleToastType type) {
    return switch (type) {
      CapsuleToastType.success => success,
      CapsuleToastType.information => information,
      CapsuleToastType.warning => warning,
      CapsuleToastType.error => error,
      CapsuleToastType.loading => loading,
      CapsuleToastType.neutral => neutral,
      CapsuleToastType.custom => custom,
    };
  }

  /// Returns a copy with the given fields replaced.
  CapsuleToastTints copyWith({
    Color? success,
    Color? information,
    Color? warning,
    Color? error,
    Color? loading,
    Color? neutral,
    Color? custom,
  }) {
    return CapsuleToastTints(
      success: success ?? this.success,
      information: information ?? this.information,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      loading: loading ?? this.loading,
      neutral: neutral ?? this.neutral,
      custom: custom ?? this.custom,
    );
  }

  /// Linearly interpolates between [a] and [b] by [t].
  static CapsuleToastTints? lerp(
    CapsuleToastTints? a,
    CapsuleToastTints? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return CapsuleToastTints(
      success: Color.lerp(a.success, b.success, t)!,
      information: Color.lerp(a.information, b.information, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      error: Color.lerp(a.error, b.error, t)!,
      loading: Color.lerp(a.loading, b.loading, t)!,
      neutral: Color.lerp(a.neutral, b.neutral, t)!,
      custom: Color.lerp(a.custom, b.custom, t)!,
    );
  }

  /// Describes the properties of this object for debugging.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('success', success));
    properties.add(ColorProperty('information', information));
    properties.add(ColorProperty('warning', warning));
    properties.add(ColorProperty('error', error));
    properties.add(ColorProperty('loading', loading));
    properties.add(ColorProperty('neutral', neutral));
    properties.add(ColorProperty('custom', custom));
  }

  /// Whether these tint colors are equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastTints &&
        other.success == success &&
        other.information == information &&
        other.warning == warning &&
        other.error == error &&
        other.loading == loading &&
        other.neutral == neutral &&
        other.custom == custom;
  }

  /// The hash code for these tint colors.
  @override
  int get hashCode => Object.hash(
    success,
    information,
    warning,
    error,
    loading,
    neutral,
    custom,
  );
}

/// Visual styling tokens for capsule toasts.
@immutable
class CapsuleToastThemeData extends ThemeExtension<CapsuleToastThemeData>
    with Diagnosticable {
  /// Creates optional visual overrides validated at construction time.
  const CapsuleToastThemeData({
    this.surfaceColor,
    this.foregroundColor,
    this.secondaryForegroundColor,
    this.borderColor,
    this.borderWidth,
    this.actionSurfaceColor,
    this.accents,
    this.tints,
    this.shadows,
    this.titleTextStyle,
    this.messageTextStyle,
    this.actionTextStyle,
    this.glyphBuilder,
    this.spinnerBuilder,
    this.compactPadding,
    this.expandedPadding,
    this.compactSpacing,
    this.expandedSpacing,
    this.messageSpacing,
    this.actionSpacing,
    this.actionTopSpacing,
    this.seedSize,
    this.compactMinimumHeight,
    this.maximumWidth,
    this.horizontalInset,
    this.radiusCap,
    this.compactIconSize,
    this.expandedIconSize,
    this.compactTitleMaximumWidth,
    this.compactActionHeight,
    this.expandedActionHeight,
    this.compactActionPadding,
    this.primaryActionPadding,
    this.secondaryActionPadding,
    this.compactActionStyle,
    this.primaryActionStyle,
    this.secondaryActionStyle,
    this.useSafeArea,
    this.verticalOffset,
  }) : assert(borderWidth == null || borderWidth >= 0),
       assert(compactSpacing == null || compactSpacing >= 0),
       assert(expandedSpacing == null || expandedSpacing >= 0),
       assert(messageSpacing == null || messageSpacing >= 0),
       assert(actionSpacing == null || actionSpacing >= 0),
       assert(actionTopSpacing == null || actionTopSpacing >= 0),
       assert(compactMinimumHeight == null || compactMinimumHeight > 0),
       assert(maximumWidth == null || maximumWidth > 0),
       assert(horizontalInset == null || horizontalInset >= 0),
       assert(radiusCap == null || radiusCap > 0),
       assert(compactIconSize == null || compactIconSize > 0),
       assert(expandedIconSize == null || expandedIconSize > 0),
       assert(compactTitleMaximumWidth == null || compactTitleMaximumWidth > 0),
       assert(compactActionHeight == null || compactActionHeight > 0),
       assert(expandedActionHeight == null || expandedActionHeight > 0);

  static const Color _shadowColor = Color.fromRGBO(20, 14, 6, 0.16);

  /// Reference visual values for capsule toasts.
  factory CapsuleToastThemeData.fallback() {
    return CapsuleToastThemeData(
      surfaceColor: const Color(0xFF161614),
      foregroundColor: const Color(0xFFF9F9F7),
      secondaryForegroundColor: const Color(0x9EF9F9F7),
      borderColor: const Color(0x12F9F9F7),
      borderWidth: 0.5,
      actionSurfaceColor: const Color(0x1AF9F9F7),
      accents: const CapsuleToastAccents(
        success: Color(0xFFB9CCA8),
        information: Color(0xFFAFC4D7),
        warning: Color(0xFFE5BE85),
        error: Color(0xFFE8A695),
        loading: Color(0xC7F9F9F7),
        neutral: Color(0xC7F9F9F7),
        custom: Color(0xC7F9F9F7),
      ),
      tints: const CapsuleToastTints(
        success: Color(0x2995A584),
        information: Color(0x298AA4BD),
        warning: Color(0x29D89858),
        error: Color(0x2ED67D65),
        loading: Color(0x14F9F9F7),
        neutral: Color(0x14F9F9F7),
        custom: Color(0x14F9F9F7),
      ),
      shadows: const <BoxShadow>[
        BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: _shadowColor),
        BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: _shadowColor),
      ],
      titleTextStyle: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
      ),
      messageTextStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: -0.05,
      ),
      actionTextStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      ),
      compactPadding: const EdgeInsetsDirectional.fromSTEB(5, 5, 14, 5),
      expandedPadding: const EdgeInsetsDirectional.fromSTEB(14, 14, 16, 14),
      compactSpacing: 10,
      expandedSpacing: 12,
      messageSpacing: 3,
      actionSpacing: 8,
      actionTopSpacing: 9,
      seedSize: const Size(84, 34),
      compactMinimumHeight: 44,
      maximumWidth: 340,
      horizontalInset: 16,
      radiusCap: 34,
      compactIconSize: 34,
      expandedIconSize: 34,
      compactTitleMaximumWidth: 210,
      compactActionHeight: 24,
      expandedActionHeight: 30,
      compactActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 10,
      ),
      primaryActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 14,
      ),
      secondaryActionPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
      ),
      useSafeArea: true,
      verticalOffset: 15,
    );
  }

  /// Capsule surface fill color.
  final Color? surfaceColor;

  /// Primary content color.
  final Color? foregroundColor;

  /// Secondary content color.
  final Color? secondaryForegroundColor;

  /// Border stroke color.
  final Color? borderColor;

  /// Border stroke width.
  final double? borderWidth;

  /// Action button surface color.
  final Color? actionSurfaceColor;

  /// Semantic accent colors.
  final CapsuleToastAccents? accents;

  /// Semantic surface tints.
  final CapsuleToastTints? tints;

  /// Drop shadows behind the capsule.
  final List<BoxShadow>? shadows;

  /// Title typography.
  final TextStyle? titleTextStyle;

  /// Message typography.
  final TextStyle? messageTextStyle;

  /// Action label typography.
  final TextStyle? actionTextStyle;

  /// Optional structured glyph builder.
  final CapsuleToastGlyphBuilder? glyphBuilder;

  /// Optional loading spinner builder.
  final CapsuleToastSpinnerBuilder? spinnerBuilder;

  /// Padding in compact layout.
  final EdgeInsetsGeometry? compactPadding;

  /// Padding in expanded layout.
  final EdgeInsetsGeometry? expandedPadding;

  /// Spacing between compact content regions.
  final double? compactSpacing;

  /// Spacing between expanded content regions.
  final double? expandedSpacing;

  /// Spacing between title and message.
  final double? messageSpacing;

  /// Spacing between message and actions.
  final double? actionSpacing;

  /// Spacing above the action row in expanded layout.
  final double? actionTopSpacing;

  /// Initial capsule size before content measurement.
  final Size? seedSize;

  /// Minimum height of the compact capsule.
  final double? compactMinimumHeight;

  /// Maximum capsule width.
  final double? maximumWidth;

  /// Horizontal inset from the window edge.
  final double? horizontalInset;

  /// Maximum corner radius.
  final double? radiusCap;

  /// Leading icon size in compact layout.
  final double? compactIconSize;

  /// Leading icon size in expanded layout.
  final double? expandedIconSize;

  /// Maximum title width in compact layout.
  final double? compactTitleMaximumWidth;

  /// Action control height in compact layout.
  final double? compactActionHeight;

  /// Action control height in expanded layout.
  final double? expandedActionHeight;

  /// Horizontal padding for compact actions.
  final EdgeInsetsGeometry? compactActionPadding;

  /// Horizontal padding for primary actions.
  final EdgeInsetsGeometry? primaryActionPadding;

  /// Horizontal padding for secondary actions.
  final EdgeInsetsGeometry? secondaryActionPadding;

  /// Button style for compact actions.
  final ButtonStyle? compactActionStyle;

  /// Button style for primary actions.
  final ButtonStyle? primaryActionStyle;

  /// Button style for secondary actions.
  final ButtonStyle? secondaryActionStyle;

  /// Whether the host respects the system safe area.
  final bool? useSafeArea;

  /// Additional vertical offset below the safe area.
  final double? verticalOffset;

  /// Returns a copy with the given fields replaced.
  @override
  CapsuleToastThemeData copyWith({
    Color? surfaceColor,
    Color? foregroundColor,
    Color? secondaryForegroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? actionSurfaceColor,
    CapsuleToastAccents? accents,
    CapsuleToastTints? tints,
    List<BoxShadow>? shadows,
    TextStyle? titleTextStyle,
    TextStyle? messageTextStyle,
    TextStyle? actionTextStyle,
    CapsuleToastGlyphBuilder? glyphBuilder,
    CapsuleToastSpinnerBuilder? spinnerBuilder,
    EdgeInsetsGeometry? compactPadding,
    EdgeInsetsGeometry? expandedPadding,
    double? compactSpacing,
    double? expandedSpacing,
    double? messageSpacing,
    double? actionSpacing,
    double? actionTopSpacing,
    Size? seedSize,
    double? compactMinimumHeight,
    double? maximumWidth,
    double? horizontalInset,
    double? radiusCap,
    double? compactIconSize,
    double? expandedIconSize,
    double? compactTitleMaximumWidth,
    double? compactActionHeight,
    double? expandedActionHeight,
    EdgeInsetsGeometry? compactActionPadding,
    EdgeInsetsGeometry? primaryActionPadding,
    EdgeInsetsGeometry? secondaryActionPadding,
    ButtonStyle? compactActionStyle,
    ButtonStyle? primaryActionStyle,
    ButtonStyle? secondaryActionStyle,
    bool? useSafeArea,
    double? verticalOffset,
  }) {
    return CapsuleToastThemeData(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      secondaryForegroundColor:
          secondaryForegroundColor ?? this.secondaryForegroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      actionSurfaceColor: actionSurfaceColor ?? this.actionSurfaceColor,
      accents: accents ?? this.accents,
      tints: tints ?? this.tints,
      shadows: shadows ?? this.shadows,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      messageTextStyle: messageTextStyle ?? this.messageTextStyle,
      actionTextStyle: actionTextStyle ?? this.actionTextStyle,
      glyphBuilder: glyphBuilder ?? this.glyphBuilder,
      spinnerBuilder: spinnerBuilder ?? this.spinnerBuilder,
      compactPadding: compactPadding ?? this.compactPadding,
      expandedPadding: expandedPadding ?? this.expandedPadding,
      compactSpacing: compactSpacing ?? this.compactSpacing,
      expandedSpacing: expandedSpacing ?? this.expandedSpacing,
      messageSpacing: messageSpacing ?? this.messageSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      actionTopSpacing: actionTopSpacing ?? this.actionTopSpacing,
      seedSize: seedSize ?? this.seedSize,
      compactMinimumHeight: compactMinimumHeight ?? this.compactMinimumHeight,
      maximumWidth: maximumWidth ?? this.maximumWidth,
      horizontalInset: horizontalInset ?? this.horizontalInset,
      radiusCap: radiusCap ?? this.radiusCap,
      compactIconSize: compactIconSize ?? this.compactIconSize,
      expandedIconSize: expandedIconSize ?? this.expandedIconSize,
      compactTitleMaximumWidth:
          compactTitleMaximumWidth ?? this.compactTitleMaximumWidth,
      compactActionHeight: compactActionHeight ?? this.compactActionHeight,
      expandedActionHeight: expandedActionHeight ?? this.expandedActionHeight,
      compactActionPadding: compactActionPadding ?? this.compactActionPadding,
      primaryActionPadding: primaryActionPadding ?? this.primaryActionPadding,
      secondaryActionPadding:
          secondaryActionPadding ?? this.secondaryActionPadding,
      compactActionStyle: compactActionStyle ?? this.compactActionStyle,
      primaryActionStyle: primaryActionStyle ?? this.primaryActionStyle,
      secondaryActionStyle: secondaryActionStyle ?? this.secondaryActionStyle,
      useSafeArea: useSafeArea ?? this.useSafeArea,
      verticalOffset: verticalOffset ?? this.verticalOffset,
    );
  }

  /// Merges non-null fields from [other] on top of this theme.
  CapsuleToastThemeData merge(CapsuleToastThemeData? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      surfaceColor: other.surfaceColor ?? surfaceColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      secondaryForegroundColor:
          other.secondaryForegroundColor ?? secondaryForegroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      actionSurfaceColor: other.actionSurfaceColor ?? actionSurfaceColor,
      accents: other.accents ?? accents,
      tints: other.tints ?? tints,
      shadows: other.shadows ?? shadows,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      messageTextStyle: other.messageTextStyle ?? messageTextStyle,
      actionTextStyle: other.actionTextStyle ?? actionTextStyle,
      glyphBuilder: other.glyphBuilder ?? glyphBuilder,
      spinnerBuilder: other.spinnerBuilder ?? spinnerBuilder,
      compactPadding: other.compactPadding ?? compactPadding,
      expandedPadding: other.expandedPadding ?? expandedPadding,
      compactSpacing: other.compactSpacing ?? compactSpacing,
      expandedSpacing: other.expandedSpacing ?? expandedSpacing,
      messageSpacing: other.messageSpacing ?? messageSpacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      actionTopSpacing: other.actionTopSpacing ?? actionTopSpacing,
      seedSize: other.seedSize ?? seedSize,
      compactMinimumHeight: other.compactMinimumHeight ?? compactMinimumHeight,
      maximumWidth: other.maximumWidth ?? maximumWidth,
      horizontalInset: other.horizontalInset ?? horizontalInset,
      radiusCap: other.radiusCap ?? radiusCap,
      compactIconSize: other.compactIconSize ?? compactIconSize,
      expandedIconSize: other.expandedIconSize ?? expandedIconSize,
      compactTitleMaximumWidth:
          other.compactTitleMaximumWidth ?? compactTitleMaximumWidth,
      compactActionHeight: other.compactActionHeight ?? compactActionHeight,
      expandedActionHeight: other.expandedActionHeight ?? expandedActionHeight,
      compactActionPadding: other.compactActionPadding ?? compactActionPadding,
      primaryActionPadding: other.primaryActionPadding ?? primaryActionPadding,
      secondaryActionPadding:
          other.secondaryActionPadding ?? secondaryActionPadding,
      compactActionStyle: other.compactActionStyle ?? compactActionStyle,
      primaryActionStyle: other.primaryActionStyle ?? primaryActionStyle,
      secondaryActionStyle: other.secondaryActionStyle ?? secondaryActionStyle,
      useSafeArea: other.useSafeArea ?? useSafeArea,
      verticalOffset: other.verticalOffset ?? verticalOffset,
    );
  }

  /// Linearly interpolates between this theme and [other] at [t].
  @override
  CapsuleToastThemeData lerp(covariant CapsuleToastThemeData? other, double t) {
    if (other == null) {
      return this;
    }
    return CapsuleToastThemeData(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      foregroundColor: Color.lerp(foregroundColor, other.foregroundColor, t),
      secondaryForegroundColor: Color.lerp(
        secondaryForegroundColor,
        other.secondaryForegroundColor,
        t,
      ),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      actionSurfaceColor: Color.lerp(
        actionSurfaceColor,
        other.actionSurfaceColor,
        t,
      ),
      accents: CapsuleToastAccents.lerp(accents, other.accents, t),
      tints: CapsuleToastTints.lerp(tints, other.tints, t),
      shadows: t < 0.5 ? shadows : other.shadows,
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      messageTextStyle: TextStyle.lerp(
        messageTextStyle,
        other.messageTextStyle,
        t,
      ),
      actionTextStyle: TextStyle.lerp(
        actionTextStyle,
        other.actionTextStyle,
        t,
      ),
      glyphBuilder: t < 0.5 ? glyphBuilder : other.glyphBuilder,
      spinnerBuilder: t < 0.5 ? spinnerBuilder : other.spinnerBuilder,
      compactPadding: EdgeInsetsGeometry.lerp(
        compactPadding,
        other.compactPadding,
        t,
      ),
      expandedPadding: EdgeInsetsGeometry.lerp(
        expandedPadding,
        other.expandedPadding,
        t,
      ),
      compactSpacing: lerpDouble(compactSpacing, other.compactSpacing, t),
      expandedSpacing: lerpDouble(expandedSpacing, other.expandedSpacing, t),
      messageSpacing: lerpDouble(messageSpacing, other.messageSpacing, t),
      actionSpacing: lerpDouble(actionSpacing, other.actionSpacing, t),
      actionTopSpacing: lerpDouble(actionTopSpacing, other.actionTopSpacing, t),
      seedSize: Size.lerp(seedSize, other.seedSize, t),
      compactMinimumHeight: lerpDouble(
        compactMinimumHeight,
        other.compactMinimumHeight,
        t,
      ),
      maximumWidth: lerpDouble(maximumWidth, other.maximumWidth, t),
      horizontalInset: lerpDouble(horizontalInset, other.horizontalInset, t),
      radiusCap: lerpDouble(radiusCap, other.radiusCap, t),
      compactIconSize: lerpDouble(compactIconSize, other.compactIconSize, t),
      expandedIconSize: lerpDouble(expandedIconSize, other.expandedIconSize, t),
      compactTitleMaximumWidth: lerpDouble(
        compactTitleMaximumWidth,
        other.compactTitleMaximumWidth,
        t,
      ),
      compactActionHeight: lerpDouble(
        compactActionHeight,
        other.compactActionHeight,
        t,
      ),
      expandedActionHeight: lerpDouble(
        expandedActionHeight,
        other.expandedActionHeight,
        t,
      ),
      compactActionPadding: EdgeInsetsGeometry.lerp(
        compactActionPadding,
        other.compactActionPadding,
        t,
      ),
      primaryActionPadding: EdgeInsetsGeometry.lerp(
        primaryActionPadding,
        other.primaryActionPadding,
        t,
      ),
      secondaryActionPadding: EdgeInsetsGeometry.lerp(
        secondaryActionPadding,
        other.secondaryActionPadding,
        t,
      ),
      compactActionStyle: ButtonStyle.lerp(
        compactActionStyle,
        other.compactActionStyle,
        t,
      ),
      primaryActionStyle: ButtonStyle.lerp(
        primaryActionStyle,
        other.primaryActionStyle,
        t,
      ),
      secondaryActionStyle: ButtonStyle.lerp(
        secondaryActionStyle,
        other.secondaryActionStyle,
        t,
      ),
      useSafeArea: t < 0.5 ? useSafeArea : other.useSafeArea,
      verticalOffset: lerpDouble(verticalOffset, other.verticalOffset, t),
    );
  }

  /// Describes the properties of this object for debugging.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('surfaceColor', surfaceColor));
    properties.add(ColorProperty('foregroundColor', foregroundColor));
    properties.add(
      ColorProperty('secondaryForegroundColor', secondaryForegroundColor),
    );
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(DoubleProperty('borderWidth', borderWidth));
    properties.add(ColorProperty('actionSurfaceColor', actionSurfaceColor));
    properties.add(
      DiagnosticsProperty<CapsuleToastAccents?>('accents', accents),
    );
    properties.add(DiagnosticsProperty<CapsuleToastTints?>('tints', tints));
    properties.add(IterableProperty<BoxShadow>('shadows', shadows));
    properties.add(
      DiagnosticsProperty<TextStyle?>('titleTextStyle', titleTextStyle),
    );
    properties.add(
      DiagnosticsProperty<TextStyle?>('messageTextStyle', messageTextStyle),
    );
    properties.add(
      DiagnosticsProperty<TextStyle?>('actionTextStyle', actionTextStyle),
    );
    properties.add(
      ObjectFlagProperty<CapsuleToastGlyphBuilder?>.has(
        'glyphBuilder',
        glyphBuilder,
      ),
    );
    properties.add(
      ObjectFlagProperty<CapsuleToastSpinnerBuilder?>.has(
        'spinnerBuilder',
        spinnerBuilder,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'compactPadding',
        compactPadding,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'expandedPadding',
        expandedPadding,
      ),
    );
    properties.add(DoubleProperty('compactSpacing', compactSpacing));
    properties.add(DoubleProperty('expandedSpacing', expandedSpacing));
    properties.add(DoubleProperty('messageSpacing', messageSpacing));
    properties.add(DoubleProperty('actionSpacing', actionSpacing));
    properties.add(DoubleProperty('actionTopSpacing', actionTopSpacing));
    properties.add(DiagnosticsProperty<Size?>('seedSize', seedSize));
    properties.add(
      DoubleProperty('compactMinimumHeight', compactMinimumHeight),
    );
    properties.add(DoubleProperty('maximumWidth', maximumWidth));
    properties.add(DoubleProperty('horizontalInset', horizontalInset));
    properties.add(DoubleProperty('radiusCap', radiusCap));
    properties.add(DoubleProperty('compactIconSize', compactIconSize));
    properties.add(DoubleProperty('expandedIconSize', expandedIconSize));
    properties.add(
      DoubleProperty('compactTitleMaximumWidth', compactTitleMaximumWidth),
    );
    properties.add(DoubleProperty('compactActionHeight', compactActionHeight));
    properties.add(
      DoubleProperty('expandedActionHeight', expandedActionHeight),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'compactActionPadding',
        compactActionPadding,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'primaryActionPadding',
        primaryActionPadding,
      ),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry?>(
        'secondaryActionPadding',
        secondaryActionPadding,
      ),
    );
    properties.add(
      DiagnosticsProperty<ButtonStyle?>(
        'compactActionStyle',
        compactActionStyle,
      ),
    );
    properties.add(
      DiagnosticsProperty<ButtonStyle?>(
        'primaryActionStyle',
        primaryActionStyle,
      ),
    );
    properties.add(
      DiagnosticsProperty<ButtonStyle?>(
        'secondaryActionStyle',
        secondaryActionStyle,
      ),
    );
    properties.add(DiagnosticsProperty<bool?>('useSafeArea', useSafeArea));
    properties.add(DoubleProperty('verticalOffset', verticalOffset));
  }

  /// Whether this visual theme is equal to [other].
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastThemeData &&
        other.surfaceColor == surfaceColor &&
        other.foregroundColor == foregroundColor &&
        other.secondaryForegroundColor == secondaryForegroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.actionSurfaceColor == actionSurfaceColor &&
        other.accents == accents &&
        other.tints == tints &&
        _listEquals(other.shadows, shadows) &&
        other.titleTextStyle == titleTextStyle &&
        other.messageTextStyle == messageTextStyle &&
        other.actionTextStyle == actionTextStyle &&
        other.glyphBuilder == glyphBuilder &&
        other.spinnerBuilder == spinnerBuilder &&
        other.compactPadding == compactPadding &&
        other.expandedPadding == expandedPadding &&
        other.compactSpacing == compactSpacing &&
        other.expandedSpacing == expandedSpacing &&
        other.messageSpacing == messageSpacing &&
        other.actionSpacing == actionSpacing &&
        other.actionTopSpacing == actionTopSpacing &&
        other.seedSize == seedSize &&
        other.compactMinimumHeight == compactMinimumHeight &&
        other.maximumWidth == maximumWidth &&
        other.horizontalInset == horizontalInset &&
        other.radiusCap == radiusCap &&
        other.compactIconSize == compactIconSize &&
        other.expandedIconSize == expandedIconSize &&
        other.compactTitleMaximumWidth == compactTitleMaximumWidth &&
        other.compactActionHeight == compactActionHeight &&
        other.expandedActionHeight == expandedActionHeight &&
        other.compactActionPadding == compactActionPadding &&
        other.primaryActionPadding == primaryActionPadding &&
        other.secondaryActionPadding == secondaryActionPadding &&
        other.compactActionStyle == compactActionStyle &&
        other.primaryActionStyle == primaryActionStyle &&
        other.secondaryActionStyle == secondaryActionStyle &&
        other.useSafeArea == useSafeArea &&
        other.verticalOffset == verticalOffset;
  }

  /// The hash code for this visual theme.
  @override
  int get hashCode => Object.hashAll(<Object?>[
    surfaceColor,
    foregroundColor,
    secondaryForegroundColor,
    borderColor,
    borderWidth,
    actionSurfaceColor,
    accents,
    tints,
    shadows == null ? null : Object.hashAll(shadows!),
    titleTextStyle,
    messageTextStyle,
    actionTextStyle,
    glyphBuilder,
    spinnerBuilder,
    compactPadding,
    expandedPadding,
    compactSpacing,
    expandedSpacing,
    messageSpacing,
    actionSpacing,
    actionTopSpacing,
    seedSize,
    compactMinimumHeight,
    maximumWidth,
    horizontalInset,
    radiusCap,
    compactIconSize,
    expandedIconSize,
    compactTitleMaximumWidth,
    compactActionHeight,
    expandedActionHeight,
    compactActionPadding,
    primaryActionPadding,
    secondaryActionPadding,
    compactActionStyle,
    primaryActionStyle,
    secondaryActionStyle,
    useSafeArea,
    verticalOffset,
  ]);
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
