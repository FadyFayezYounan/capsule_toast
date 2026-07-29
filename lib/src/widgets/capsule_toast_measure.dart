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
    required this.generation,
    required this.onSizeChanged,
    super.child,
  });

  /// Identifies the content being measured.
  ///
  /// Reporting is deduplicated against the previous size, so a new toast whose
  /// content happens to lay out to the size the outgoing one had — re-firing
  /// the same toast always does — would report nothing. Changing [generation]
  /// drops that cache so the listener hears the size again.
  final int generation;

  /// Called after layout when the child's size differs from the previous frame.
  final CapsuleToastSizeChanged onSizeChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCapsuleToastMeasure(
      generation: generation,
      onSizeChanged: onSizeChanged,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderCapsuleToastMeasure renderObject,
  ) {
    renderObject
      ..onSizeChanged = onSizeChanged
      ..generation = generation;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('generation', generation));
    properties.add(
      ObjectFlagProperty<CapsuleToastSizeChanged>.has(
        'onSizeChanged',
        onSizeChanged,
      ),
    );
  }
}

class RenderCapsuleToastMeasure extends RenderProxyBox {
  RenderCapsuleToastMeasure({
    required this.onSizeChanged,
    required this._generation,
  });

  CapsuleToastSizeChanged onSizeChanged;

  Size? _lastReportedSize;
  int _generation;

  /// Content generation being measured; see [CapsuleToastMeasure.generation].
  int get generation => _generation;
  set generation(int value) {
    if (_generation == value) {
      return;
    }
    _generation = value;
    _lastReportedSize = null;
    // Layout is what reports, so ask for it: identical content under identical
    // constraints is otherwise clean and never lays out again.
    markNeedsLayout();
  }

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
