// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'capsule_toast_action.dart';
import 'capsule_toast_types.dart';

/// Immutable configuration for a structured capsule toast.
@immutable
class CapsuleToastData with Diagnosticable {
  const CapsuleToastData._({
    required this.type,
    this.id,
    required this.title,
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
    this.textDirection,
  }) : assert(title != ''),
       assert(message != ''),
       assert(semanticAnnouncement != ''),
       assert(icon == null || iconBuilder == null),
       assert(!persistent || displayDuration == null);

  /// Creates success feedback toast data.
  const CapsuleToastData.success({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Creates informational feedback toast data.
  const CapsuleToastData.information({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Creates warning feedback toast data.
  const CapsuleToastData.warning({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Creates error feedback toast data.
  const CapsuleToastData.error({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Creates loading feedback toast data.
  const CapsuleToastData.loading({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Creates neutral feedback toast data.
  const CapsuleToastData.neutral({
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
    TextDirection? textDirection,
  }) : this._(
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
         textDirection: textDirection,
       );

  /// Sentinel for [copyWith] when a nullable field should stay unchanged.
  static const Object _unset = Object();

  /// Semantic category used for styling and default glyph selection.
  final CapsuleToastType type;

  /// Optional stable identifier shared with the toast handle.
  final Object? id;

  /// Primary visible title text.
  final String title;

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

  /// Optional text direction override for toast content.
  final TextDirection? textDirection;

  /// Returns a copy of this toast with the given fields replaced.
  ///
  /// Pass `null` for nullable fields to clear them explicitly.
  CapsuleToastData copyWith({
    CapsuleToastType? type,
    Object? id = _unset,
    String? title,
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
    Object? textDirection = _unset,
  }) {
    return CapsuleToastData._(
      type: type ?? this.type,
      id: identical(id, _unset) ? this.id : id,
      title: title ?? this.title,
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
      displayDuration: identical(displayDuration, _unset)
          ? this.displayDuration
          : displayDuration as Duration?,
      persistent: persistent ?? this.persistent,
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
    textDirection,
  );
}
