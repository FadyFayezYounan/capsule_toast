// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_theme_data.dart';

/// Structured semantic glyph for capsule toast content.
class CapsuleToastGlyphWidget extends StatefulWidget {
  /// Creates a glyph painted at [size] with [color].
  const CapsuleToastGlyphWidget({
    super.key,
    required this.glyph,
    required this.color,
    required this.size,
    required this.theme,
    this.tickerEnabled = true,
  });

  /// Which glyph shape to draw.
  final CapsuleToastGlyph glyph;

  /// Stroke and fill color.
  final Color color;

  /// Logical width and height of the glyph canvas.
  final double size;

  /// Resolved theme providing optional custom builders.
  final CapsuleToastThemeData theme;

  /// Whether loading spinners may attach a ticker.
  final bool tickerEnabled;

  @override
  State<CapsuleToastGlyphWidget> createState() =>
      _CapsuleToastGlyphWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
    properties.add(ColorProperty('color', color));
    properties.add(DoubleProperty('size', size));
    properties.add(DiagnosticsProperty<bool>('tickerEnabled', tickerEnabled));
  }
}

class _CapsuleToastGlyphWidgetState extends State<CapsuleToastGlyphWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant CapsuleToastGlyphWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController();
  }

  void _syncController() {
    final bool needsTicker =
        widget.tickerEnabled && widget.glyph == CapsuleToastGlyph.loading;
    if (needsTicker) {
      _controller ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 850),
      )..repeat();
      return;
    }
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastGlyphBuilder? builder = widget.theme.glyphBuilder;
    if (builder != null &&
        widget.glyph != CapsuleToastGlyph.loading &&
        widget.glyph != CapsuleToastGlyph.connectivity) {
      return builder(context, widget.glyph, widget.color, widget.size);
    }
    if (widget.glyph == CapsuleToastGlyph.loading) {
      final CapsuleToastSpinnerBuilder? spinnerBuilder =
          widget.theme.spinnerBuilder;
      if (spinnerBuilder != null) {
        return spinnerBuilder(context, widget.color, widget.size);
      }
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      key: ValueKey<String>('capsule.${widget.glyph.name}.glyph'),
      child: CustomPaint(
        // The spinner repaints straight off the controller. Reading
        // `_controller.value` without subscribing to it is what left the
        // spinner frozen: the ticker ran, but nothing ever asked for a frame.
        painter: _CapsuleGlyphPainter(
          glyph: widget.glyph,
          color: widget.color,
          rotation: _controller,
        ),
      ),
    );
  }
}

/// Side length [glyph] is drawn at inside the tinted icon circle.
///
/// The reference sizes each glyph individually rather than normalising them:
/// the check is the lightest shape so it can afford to be smallest, while the
/// triangle and the signal arcs need the extra room to read at a glance. Every
/// glyph shares the same 20-unit canvas, so this is purely optical balance.
double capsuleToastGlyphSize(CapsuleToastGlyph glyph) {
  return switch (glyph) {
    CapsuleToastGlyph.success => 15,
    CapsuleToastGlyph.information => 16,
    CapsuleToastGlyph.warning => 17,
    CapsuleToastGlyph.error => 16,
    CapsuleToastGlyph.connectivity => 17,
    CapsuleToastGlyph.loading => 18,
    CapsuleToastGlyph.neutral => 16,
    CapsuleToastGlyph.automatic => 16,
  };
}

/// Resolves [glyph] from toast [type] when [glyph] is [CapsuleToastGlyph.automatic].
CapsuleToastGlyph resolveCapsuleToastGlyph(
  CapsuleToastGlyph glyph,
  CapsuleToastType type,
) {
  if (glyph != CapsuleToastGlyph.automatic) {
    return glyph;
  }
  return switch (type) {
    CapsuleToastType.success => CapsuleToastGlyph.success,
    CapsuleToastType.information => CapsuleToastGlyph.information,
    CapsuleToastType.warning => CapsuleToastGlyph.warning,
    CapsuleToastType.error => CapsuleToastGlyph.error,
    CapsuleToastType.loading => CapsuleToastGlyph.loading,
    CapsuleToastType.neutral => CapsuleToastGlyph.neutral,
    CapsuleToastType.custom => CapsuleToastGlyph.neutral,
  };
}

/// Paints one glyph inside a 20-unit canvas, matching the reference SVGs.
///
/// Every path below is a transcription of the corresponding `<svg>` in the
/// prototype, including its own stroke width — the reference varies stroke per
/// path (a 2.3 checkmark beside a 1.7 circle), so a single shared width reads
/// visibly wrong at these sizes.
class _CapsuleGlyphPainter extends CustomPainter {
  _CapsuleGlyphPainter({
    required this.glyph,
    required this.color,
    required this.rotation,
  }) : super(repaint: rotation);

  final CapsuleToastGlyph glyph;
  final Color color;

  /// Drives the loading spinner, and repaints this painter as it ticks.
  final Animation<double>? rotation;

  static const double _canvas = 20;

  Paint _stroke(double width) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _canvas;
    canvas.save();
    canvas.scale(scale, scale);

    switch (glyph) {
      // M4.2 10.6l3.6 3.6L15.8 6 — stroke 2.3
      case CapsuleToastGlyph.success:
        canvas.drawPath(
          Path()
            ..moveTo(4.2, 10.6)
            ..lineTo(7.8, 14.2)
            ..lineTo(15.8, 6),
          _stroke(2.3),
        );

      // circle r7.6 stroke 1.7 · dot at (10, 6.2) r1.05 · stem M10 9v5
      case CapsuleToastGlyph.information:
        canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
        canvas.drawCircle(const Offset(10, 6.2), 1.05, _fill);
        canvas.drawLine(
          const Offset(10, 9),
          const Offset(10, 14),
          _stroke(1.9),
        );

      // triangle stroke 1.7 · stem M10 7.9v3.5 · dot at (10, 13.4) r0.95
      case CapsuleToastGlyph.warning:
        canvas.drawPath(
          Path()
            ..moveTo(10, 3.1)
            ..lineTo(17, 15.5)
            ..lineTo(3, 15.5)
            ..close(),
          _stroke(1.7),
        );
        canvas.drawLine(
          const Offset(10, 7.9),
          const Offset(10, 11.4),
          _stroke(1.8),
        );
        canvas.drawCircle(const Offset(10, 13.4), 0.95, _fill);

      // circle r7.6 stroke 1.7 · cross 7.4→12.6 stroke 1.8
      case CapsuleToastGlyph.error:
        canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
        final Paint cross = _stroke(1.8);
        canvas.drawLine(
          const Offset(7.4, 7.4),
          const Offset(12.6, 12.6),
          cross,
        );
        canvas.drawLine(
          const Offset(12.6, 7.4),
          const Offset(7.4, 12.6),
          cross,
        );

      // Three arcs over a dot, stroke 1.6 — the reference's offline glyph.
      case CapsuleToastGlyph.connectivity:
        final Paint arcs = _stroke(1.6);
        for (final double y in <double>[7.6, 10.6, 13.6]) {
          final double span = (13.6 - y) * 1.4 + 4;
          canvas.drawArc(
            Rect.fromCenter(
              center: Offset(10, y + span / 2),
              width: span * 2,
              height: span * 2,
            ),
            math.pi * 1.15,
            math.pi * 0.7,
            false,
            arcs,
          );
        }
        canvas.drawCircle(const Offset(10, 16.4), 1.05, _fill);

      case CapsuleToastGlyph.neutral:
        canvas.drawCircle(const Offset(10, 10), 2.4, _fill);

      // Track at 0.22 alpha with a quarter-turn head, both stroke 2. The head
      // starts at twelve o'clock: `M10 2.8 a7.2 7.2 0 0 1 7.2 7.2`.
      case CapsuleToastGlyph.loading:
        canvas.translate(_canvas / 2, _canvas / 2);
        canvas.rotate((rotation?.value ?? 0) * 2 * math.pi);
        canvas.translate(-_canvas / 2, -_canvas / 2);
        canvas.drawCircle(
          const Offset(10, 10),
          7.2,
          _stroke(2)..color = color.withValues(alpha: 0.22),
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(10, 10), radius: 7.2),
          -math.pi / 2,
          math.pi / 2,
          false,
          _stroke(2),
        );

      case CapsuleToastGlyph.automatic:
        break;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CapsuleGlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.rotation != rotation;
  }
}
