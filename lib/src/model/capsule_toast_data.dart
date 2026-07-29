// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../manager/capsule_toast_manager.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme_data.dart';
import 'capsule_toast_action.dart';
import 'capsule_toast_handle.dart';
import 'capsule_toast_types.dart';

/// Builds custom toast content for a layout mode.
typedef CapsuleToastContentBuilder =
    Widget Function(BuildContext context, CapsuleToastContentContext details);

/// Context passed to custom capsule toast content builders.
@immutable
class CapsuleToastContentContext with Diagnosticable {
  /// Creates content builder context for a live toast.
  const CapsuleToastContentContext({
    required this.toast,
    required this.mode,
    required this.visualTheme,
    required this.motionTheme,
    required this.manager,
    required this.handle,
    required this.constraints,
  });

  /// Toast configuration being rendered.
  final CapsuleToastData toast;

  /// Active layout mode.
  final CapsuleToastMode mode;

  /// Resolved visual theme for this toast.
  final CapsuleToastThemeData visualTheme;

  /// Resolved motion theme for this toast.
  final CapsuleToastMotionTheme motionTheme;

  /// Manager used to control the toast queue.
  final CapsuleToastManager manager;

  /// Handle for live toast commands.
  final CapsuleToastHandle handle;

  /// Layout constraints for custom content.
  final BoxConstraints constraints;

  /// Adds diagnostic properties for this content context.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CapsuleToastData>('toast', toast));
    properties.add(EnumProperty<CapsuleToastMode>('mode', mode));
    properties.add(
      DiagnosticsProperty<CapsuleToastThemeData>('visualTheme', visualTheme),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastMotionTheme>('motionTheme', motionTheme),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastManager>('manager', manager),
    );
    properties.add(DiagnosticsProperty<CapsuleToastHandle>('handle', handle));
    properties.add(
      DiagnosticsProperty<BoxConstraints>('constraints', constraints),
    );
  }
}

/// Immutable configuration for a structured capsule toast.
@immutable
class CapsuleToastData with Diagnosticable {
  CapsuleToastData._({
    required this.type,
    this.id,
    this.title,
    this.message,
    this.semanticAnnouncement,
    this.initialMode = CapsuleToastMode.compact,
    this.glyph = CapsuleToastGlyph.automatic,
    this.icon,
    this.iconBuilder,
    this.compactAction,
    this.primaryAction,
    this.secondaryAction,
    this.displayDuration,
    this.persistent = false,
    this.theme,
    this.motionTheme,
    this.compactBuilder,
    this.expandedBuilder,
    this.textDirection,
  }) : assert(
         type == CapsuleToastType.custom || title != null && title.isNotEmpty,
         'Structured capsule toasts require a non-empty title.',
       ),
       assert(
         title == null || title.isNotEmpty,
         'CapsuleToastData.title cannot be empty.',
       ),
       assert(
         message == null || message.isNotEmpty,
         'CapsuleToastData.message cannot be empty.',
       ),
       assert(
         semanticAnnouncement == null || semanticAnnouncement.isNotEmpty,
         'CapsuleToastData.semanticAnnouncement cannot be empty.',
       ),
       assert(
         type != CapsuleToastType.custom ||
             title != null ||
             semanticAnnouncement != null,
         'Custom capsule toasts require a non-empty title or semantic '
         'announcement.',
       ),
       assert(
         type != CapsuleToastType.custom ||
             compactBuilder != null ||
             expandedBuilder != null,
         'Custom capsule toasts require a compactBuilder or expandedBuilder.',
       ),
       assert(
         icon == null || iconBuilder == null,
         'CapsuleToastData.icon and iconBuilder cannot both be provided.',
       ),
       assert(
         displayDuration == null || displayDuration > Duration.zero,
         'CapsuleToastData.displayDuration must be greater than zero.',
       ),
       assert(
         !persistent || displayDuration == null,
         'Persistent capsule toasts cannot have a displayDuration.',
       );

  /// Creates success feedback toast data.
  factory CapsuleToastData.success({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.success,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates informational feedback toast data.
  factory CapsuleToastData.information({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.information,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates warning feedback toast data.
  factory CapsuleToastData.warning({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.warning,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates error feedback toast data.
  factory CapsuleToastData.error({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.error,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates loading feedback toast data.
  factory CapsuleToastData.loading({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = true,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.loading,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates neutral feedback toast data.
  factory CapsuleToastData.neutral({
    Object? id,
    required String title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    CapsuleToastGlyph glyph = CapsuleToastGlyph.automatic,
    IconData? icon,
    WidgetBuilder? iconBuilder,
    CapsuleToastAction? compactAction,
    CapsuleToastAction? primaryAction,
    CapsuleToastAction? secondaryAction,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.neutral,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      glyph: glyph,
      icon: icon,
      iconBuilder: iconBuilder,
      compactAction: compactAction,
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Creates caller-defined capsule toast content.
  factory CapsuleToastData.custom({
    Object? id,
    String? title,
    String? message,
    String? semanticAnnouncement,
    CapsuleToastMode initialMode = CapsuleToastMode.compact,
    Duration? displayDuration,
    bool persistent = false,
    CapsuleToastThemeData? theme,
    CapsuleToastMotionTheme? motionTheme,
    CapsuleToastContentBuilder? compactBuilder,
    CapsuleToastContentBuilder? expandedBuilder,
    TextDirection? textDirection,
  }) {
    return CapsuleToastData._(
      type: CapsuleToastType.custom,
      id: id,
      title: title,
      message: message,
      semanticAnnouncement: semanticAnnouncement,
      initialMode: initialMode,
      displayDuration: displayDuration,
      persistent: persistent,
      theme: theme,
      motionTheme: motionTheme,
      compactBuilder: compactBuilder,
      expandedBuilder: expandedBuilder,
      textDirection: textDirection,
    );
  }

  /// Sentinel for [copyWith] when a nullable field should stay unchanged.
  static const Object _unset = Object();

  /// Semantic category used for styling and default glyph selection.
  final CapsuleToastType type;

  /// Optional stable identifier shared with the toast handle.
  final Object? id;

  /// Primary visible title text.
  final String? title;

  /// Optional supporting message text.
  final String? message;

  /// Optional explicit screen-reader announcement.
  final String? semanticAnnouncement;

  /// Layout mode when the toast first appears.
  final CapsuleToastMode initialMode;

  /// Icon selection strategy for structured content.
  final CapsuleToastGlyph glyph;

  /// Optional leading icon data.
  final IconData? icon;

  /// Optional leading icon builder.
  final WidgetBuilder? iconBuilder;

  /// Optional action shown in compact layout.
  final CapsuleToastAction? compactAction;

  /// Optional primary action shown in expanded layout.
  final CapsuleToastAction? primaryAction;

  /// Optional secondary action shown in expanded layout.
  final CapsuleToastAction? secondaryAction;

  /// How long the toast remains visible when not [persistent].
  final Duration? displayDuration;

  /// Whether the toast stays visible until explicitly dismissed.
  final bool persistent;

  /// Optional per-toast visual theme overrides.
  final CapsuleToastThemeData? theme;

  /// Optional per-toast motion theme overrides.
  final CapsuleToastMotionTheme? motionTheme;

  /// Optional custom compact content builder.
  final CapsuleToastContentBuilder? compactBuilder;

  /// Optional custom expanded content builder.
  final CapsuleToastContentBuilder? expandedBuilder;

  /// Optional text direction override for toast content.
  final TextDirection? textDirection;

  /// Returns a copy of this toast with the given fields replaced.
  ///
  /// Pass `null` for nullable fields to clear them explicitly.
  CapsuleToastData copyWith({
    CapsuleToastType? type,
    Object? id = _unset,
    Object? title = _unset,
    Object? message = _unset,
    Object? semanticAnnouncement = _unset,
    CapsuleToastMode? initialMode,
    CapsuleToastGlyph? glyph,
    Object? icon = _unset,
    Object? iconBuilder = _unset,
    Object? compactAction = _unset,
    Object? primaryAction = _unset,
    Object? secondaryAction = _unset,
    Object? displayDuration = _unset,
    bool? persistent,
    Object? theme = _unset,
    Object? motionTheme = _unset,
    Object? compactBuilder = _unset,
    Object? expandedBuilder = _unset,
    Object? textDirection = _unset,
  }) {
    final Duration? resolvedDisplayDuration = identical(displayDuration, _unset)
        ? this.displayDuration
        : displayDuration as Duration?;
    final bool resolvedPersistent = persistent ?? this.persistent;
    return CapsuleToastData._(
      type: type ?? this.type,
      id: identical(id, _unset) ? this.id : id,
      title: identical(title, _unset) ? this.title : title as String?,
      message: identical(message, _unset) ? this.message : message as String?,
      semanticAnnouncement: identical(semanticAnnouncement, _unset)
          ? this.semanticAnnouncement
          : semanticAnnouncement as String?,
      initialMode: initialMode ?? this.initialMode,
      glyph: glyph ?? this.glyph,
      icon: identical(icon, _unset) ? this.icon : icon as IconData?,
      iconBuilder: identical(iconBuilder, _unset)
          ? this.iconBuilder
          : iconBuilder as WidgetBuilder?,
      compactAction: identical(compactAction, _unset)
          ? this.compactAction
          : compactAction as CapsuleToastAction?,
      primaryAction: identical(primaryAction, _unset)
          ? this.primaryAction
          : primaryAction as CapsuleToastAction?,
      secondaryAction: identical(secondaryAction, _unset)
          ? this.secondaryAction
          : secondaryAction as CapsuleToastAction?,
      displayDuration: resolvedDisplayDuration,
      persistent: resolvedPersistent,
      theme: identical(theme, _unset)
          ? this.theme
          : theme as CapsuleToastThemeData?,
      motionTheme: identical(motionTheme, _unset)
          ? this.motionTheme
          : motionTheme as CapsuleToastMotionTheme?,
      compactBuilder: identical(compactBuilder, _unset)
          ? this.compactBuilder
          : compactBuilder as CapsuleToastContentBuilder?,
      expandedBuilder: identical(expandedBuilder, _unset)
          ? this.expandedBuilder
          : expandedBuilder as CapsuleToastContentBuilder?,
      textDirection: identical(textDirection, _unset)
          ? this.textDirection
          : textDirection as TextDirection?,
    );
  }

  /// Adds diagnostic properties for this toast configuration.
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastType>('type', type));
    properties.add(DiagnosticsProperty<Object?>('id', id));
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('message', message));
    properties.add(
      StringProperty('semanticAnnouncement', semanticAnnouncement),
    );
    properties.add(EnumProperty<CapsuleToastMode>('initialMode', initialMode));
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
    properties.add(DiagnosticsProperty<IconData?>('icon', icon));
    properties.add(
      ObjectFlagProperty<WidgetBuilder?>.has('iconBuilder', iconBuilder),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastAction?>('compactAction', compactAction),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastAction?>('primaryAction', primaryAction),
    );
    properties.add(
      DiagnosticsProperty<CapsuleToastAction?>(
        'secondaryAction',
        secondaryAction,
      ),
    );
    properties.add(
      DiagnosticsProperty<Duration?>('displayDuration', displayDuration),
    );
    properties.add(DiagnosticsProperty<bool>('persistent', persistent));
    properties.add(DiagnosticsProperty<CapsuleToastThemeData?>('theme', theme));
    properties.add(
      DiagnosticsProperty<CapsuleToastMotionTheme?>('motionTheme', motionTheme),
    );
    properties.add(
      ObjectFlagProperty<CapsuleToastContentBuilder?>.has(
        'compactBuilder',
        compactBuilder,
      ),
    );
    properties.add(
      ObjectFlagProperty<CapsuleToastContentBuilder?>.has(
        'expandedBuilder',
        expandedBuilder,
      ),
    );
    properties.add(
      DiagnosticsProperty<TextDirection?>('textDirection', textDirection),
    );
  }

  /// Whether [other] describes the same toast configuration as this instance.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is CapsuleToastData &&
        other.type == type &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.semanticAnnouncement == semanticAnnouncement &&
        other.initialMode == initialMode &&
        other.glyph == glyph &&
        other.icon == icon &&
        other.iconBuilder == iconBuilder &&
        other.compactAction == compactAction &&
        other.primaryAction == primaryAction &&
        other.secondaryAction == secondaryAction &&
        other.displayDuration == displayDuration &&
        other.persistent == persistent &&
        other.theme == theme &&
        other.motionTheme == motionTheme &&
        other.compactBuilder == compactBuilder &&
        other.expandedBuilder == expandedBuilder &&
        other.textDirection == textDirection;
  }

  /// A hash code derived from the toast configuration fields.
  @override
  int get hashCode => Object.hash(
    type,
    id,
    title,
    message,
    semanticAnnouncement,
    initialMode,
    glyph,
    icon,
    iconBuilder,
    compactAction,
    primaryAction,
    secondaryAction,
    displayDuration,
    persistent,
    theme,
    motionTheme,
    compactBuilder,
    expandedBuilder,
    textDirection,
  );
}
