// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../theme/capsule_toast_theme.dart';
import '../theme/capsule_toast_theme_data.dart';

enum _CapsuleToastViewportSlot { toast }

final class CapsuleToastViewport extends StatelessWidget {
  const CapsuleToastViewport({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final CapsuleToastCoordinator coordinator;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final CapsuleToastThemeData theme = CapsuleToastTheme.resolve(
          context,
        ).merge(coordinator.active?.data.theme);
        final double topInset = theme.useSafeArea!
            ? MediaQuery.viewPaddingOf(context).top + theme.verticalOffset!
            : theme.verticalOffset!;

        return CustomMultiChildLayout(
          delegate: _CapsuleToastViewportLayout(
            topInset: topInset,
            horizontalInset: theme.horizontalInset!,
            maximumWidth: theme.maximumWidth!,
          ),
          children: <Widget>[
            LayoutId(id: _CapsuleToastViewportSlot.toast, child: child!),
          ],
        );
      },
    );
  }
}

class _CapsuleToastViewportLayout extends MultiChildLayoutDelegate {
  _CapsuleToastViewportLayout({
    required this.topInset,
    required this.horizontalInset,
    required this.maximumWidth,
  });

  final double topInset;
  final double horizontalInset;
  final double maximumWidth;

  @override
  void performLayout(Size size) {
    if (!hasChild(_CapsuleToastViewportSlot.toast)) {
      return;
    }
    final double availableWidth = math.max(0, size.width - horizontalInset * 2);
    final double availableHeight = math.max(0, size.height - topInset);
    final Size toastSize = layoutChild(
      _CapsuleToastViewportSlot.toast,
      BoxConstraints(
        maxWidth: math.min(maximumWidth, availableWidth),
        maxHeight: availableHeight,
      ),
    );
    positionChild(
      _CapsuleToastViewportSlot.toast,
      Offset((size.width - toastSize.width) / 2, topInset),
    );
  }

  @override
  bool shouldRelayout(_CapsuleToastViewportLayout oldDelegate) {
    return topInset != oldDelegate.topInset ||
        horizontalInset != oldDelegate.horizontalInset ||
        maximumWidth != oldDelegate.maximumWidth;
  }
}
