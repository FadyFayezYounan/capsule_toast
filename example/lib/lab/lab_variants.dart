// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/widgets.dart';

/// The status and transformation events exercised by the lab.
enum LabVariant {
  /// Reminder created — the canonical success event.
  success,

  /// Calendar synced.
  info,

  /// Saved without a due date.
  warning,

  /// Reminder could not be saved.
  error,

  /// Connectivity restored.
  online,

  /// An item moved to Done.
  completed,

  /// Changes persisted, with no semantic accent.
  saved,

  /// In-flight work that later resolves into [success].
  loading,
}

/// Copy for one variant in a single reading direction.
@immutable
class LabCopy {
  /// Creates copy for one variant.
  const LabCopy({
    required this.title,
    this.message,
    this.compactAction,
    this.action,
  });

  /// Compact and expanded headline.
  final String title;

  /// Expanded supporting line.
  final String? message;

  /// Compact chip label.
  final String? compactAction;

  /// Expanded primary button label.
  final String? action;
}

/// Panel button label for [variant].
String labVariantLabel(LabVariant variant) {
  return switch (variant) {
    LabVariant.success => 'Success',
    LabVariant.info => 'Information',
    LabVariant.warning => 'Warning',
    LabVariant.error => 'Error',
    LabVariant.online => 'Connection restored',
    LabVariant.completed => 'Item completed',
    LabVariant.saved => 'Changes saved',
    LabVariant.loading => 'Saving → Created',
  };
}

/// Hold duration for [variant], matching the reference timings.
Duration labVariantHold(LabVariant variant) {
  return switch (variant) {
    LabVariant.success => const Duration(milliseconds: 2300),
    LabVariant.info => const Duration(milliseconds: 2400),
    LabVariant.warning => const Duration(milliseconds: 3600),
    LabVariant.error => const Duration(milliseconds: 3800),
    LabVariant.online => const Duration(milliseconds: 2200),
    LabVariant.completed => const Duration(milliseconds: 2200),
    LabVariant.saved => const Duration(milliseconds: 1900),
    LabVariant.loading => Duration.zero,
  };
}

/// Copy for [variant] in the requested reading direction.
LabCopy labVariantCopy(LabVariant variant, {required bool rtl}) {
  return switch (variant) {
    LabVariant.success =>
      rtl
          ? const LabCopy(
              title: 'تم إنشاء التذكير',
              message: 'سنُذكّرك غدًا الساعة ٦:٠٠ مساءً.',
              compactAction: 'عرض',
              action: 'عرض التذكير',
            )
          : const LabCopy(
              title: 'Reminder created',
              message: 'We’ll notify you tomorrow at 6:00 PM.',
              compactAction: 'View',
              action: 'View reminder',
            ),
    LabVariant.info =>
      rtl
          ? const LabCopy(
              title: 'تمت مزامنة التقويم',
              message: 'أُضيفت ٣ مواعيد إلى القادم.',
              compactAction: 'فتح',
              action: 'عرض المواعيد',
            )
          : const LabCopy(
              title: 'Calendar synced',
              message: '3 appointments were added to Upcoming.',
              compactAction: 'Open',
              action: 'See appointments',
            ),
    LabVariant.warning =>
      rtl
          ? const LabCopy(
              title: 'تم الحفظ بدون تاريخ',
              message: 'أضِف تاريخًا حتى نتمكن من تذكيرك.',
              compactAction: 'إضافة',
              action: 'إضافة تاريخ',
            )
          : const LabCopy(
              title: 'Saved without a date',
              message: 'Add a due date so we can remind you.',
              compactAction: 'Add',
              action: 'Add due date',
            ),
    LabVariant.error =>
      rtl
          ? const LabCopy(
              title: 'تعذّر حفظ التذكير',
              message: 'تحقق من الاتصال وحاول مرة أخرى.',
              compactAction: 'إعادة',
              action: 'إعادة المحاولة',
            )
          : const LabCopy(
              title: 'Couldn’t save reminder',
              message: 'Check your connection and try again.',
              compactAction: 'Retry',
              action: 'Try again',
            ),
    LabVariant.online =>
      rtl
          ? const LabCopy(
              title: 'عاد الاتصال',
              message: 'اكتمل رفع آخر عمليتي التقاط.',
            )
          : const LabCopy(
              title: 'Back online',
              message: 'Your last 2 captures finished uploading.',
            ),
    LabVariant.completed =>
      rtl
          ? const LabCopy(
              title: 'تم وضع علامة مكتمل',
              message: 'انتقل تجديد تأمين السيارة إلى المنجز.',
            )
          : const LabCopy(
              title: 'Marked complete',
              message: 'Car insurance renewal moved to Done.',
            ),
    LabVariant.saved =>
      rtl
          ? const LabCopy(title: 'تم حفظ التغييرات')
          : const LabCopy(title: 'Changes saved'),
    LabVariant.loading =>
      rtl
          ? const LabCopy(title: 'جارٍ حفظ التذكير…')
          : const LabCopy(title: 'Saving reminder…'),
  };
}

/// Builds toast data for [variant].
///
/// The capsule stays neutral across every variant; status is carried by the
/// glyph shape plus a single accent, so [CapsuleToastGlyph] is pinned
/// explicitly where it diverges from the semantic type.
CapsuleToastData buildLabToast(
  LabVariant variant, {
  required bool rtl,
  CapsuleToastMode mode = CapsuleToastMode.compact,
  VoidCallback? onAction,
}) {
  final LabCopy copy = labVariantCopy(variant, rtl: rtl);
  final TextDirection? direction = rtl ? TextDirection.rtl : null;
  final Duration hold = labVariantHold(variant);

  CapsuleToastAction? compactAction() {
    if (copy.compactAction == null) {
      return null;
    }
    return CapsuleToastAction(
      label: copy.compactAction!,
      onPressed: () => onAction?.call(),
    );
  }

  CapsuleToastAction? primaryAction() {
    if (copy.action == null) {
      return null;
    }
    return CapsuleToastAction(
      label: copy.action!,
      onPressed: () => onAction?.call(),
    );
  }

  CapsuleToastAction? secondaryAction() {
    if (copy.action == null) {
      return null;
    }
    return CapsuleToastAction(
      label: rtl ? 'تجاهل' : 'Dismiss',
      onPressed: () => onAction?.call(),
    );
  }

  return switch (variant) {
    LabVariant.success => CapsuleToastData.success(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      compactAction: compactAction(),
      primaryAction: primaryAction(),
      secondaryAction: secondaryAction(),
      displayDuration: hold,
      textDirection: direction,
    ),
    LabVariant.info => CapsuleToastData.information(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      compactAction: compactAction(),
      primaryAction: primaryAction(),
      secondaryAction: secondaryAction(),
      displayDuration: hold,
      textDirection: direction,
    ),
    LabVariant.warning => CapsuleToastData.warning(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      compactAction: compactAction(),
      primaryAction: primaryAction(),
      secondaryAction: secondaryAction(),
      displayDuration: hold,
      textDirection: direction,
    ),
    LabVariant.error => CapsuleToastData.error(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      compactAction: compactAction(),
      primaryAction: primaryAction(),
      secondaryAction: secondaryAction(),
      displayDuration: hold,
      textDirection: direction,
    ),
    // Reads as information, but the connectivity glyph tells the real story.
    LabVariant.online => CapsuleToastData.information(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      glyph: CapsuleToastGlyph.connectivity,
      displayDuration: hold,
      textDirection: direction,
    ),
    LabVariant.completed => CapsuleToastData.success(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      displayDuration: hold,
      textDirection: direction,
    ),
    // Neutral accent, success shape.
    LabVariant.saved => CapsuleToastData.neutral(
      title: copy.title,
      message: copy.message,
      initialMode: mode,
      glyph: CapsuleToastGlyph.success,
      displayDuration: hold,
      textDirection: direction,
    ),
    LabVariant.loading => CapsuleToastData.loading(
      title: copy.title,
      initialMode: mode,
      textDirection: direction,
    ),
  };
}
