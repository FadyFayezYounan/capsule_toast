// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Notifies listeners when the measured capsule size changes.
typedef CapsuleToastSizeChanged = void Function(Size size);

/// Reports [child] layout size after each frame when it changes.
class CapsuleToastMeasure extends SingleChildRenderObjectWidget {
  /// Creates a measure wrapper that invokes [onSizeChanged] after layout.
  const CapsuleToastMeasure({
    super.key,
    required this.onSizeChanged,
    super.child,
  });

  /// Called after layout when the child's size differs from the previous frame.
  final CapsuleToastSizeChanged onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCapsuleToastMeasure(onSizeChanged: onSizeChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderCapsuleToastMeasure renderObject,
  ) {
    renderObject.onSizeChanged = onSizeChanged;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<CapsuleToastSizeChanged>.has(
        'onSizeChanged',
        onSizeChanged,
      ),
    );
  }
}

class RenderCapsuleToastMeasure extends RenderProxyBox {
  RenderCapsuleToastMeasure({required this.onSizeChanged});

  CapsuleToastSizeChanged onSizeChanged;

  Size? _lastReportedSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size size = child?.size ?? Size.zero;
    if (_lastReportedSize == size) {
      return;
    }
    _lastReportedSize = size;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      if (!attached) {
        return;
      }
      onSizeChanged(size);
    });
  }
}
