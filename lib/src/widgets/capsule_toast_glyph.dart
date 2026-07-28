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
        painter: _CapsuleGlyphPainter(
          glyph: widget.glyph,
          color: widget.color,
          rotation: _controller?.value ?? 0,
        ),
      ),
    );
  }
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

class _CapsuleGlyphPainter extends CustomPainter {
  const _CapsuleGlyphPainter({
    required this.glyph,
    required this.color,
    required this.rotation,
  });

  final CapsuleToastGlyph glyph;
  final Color color;
  final double rotation;

  static const double _canvas = 20;
  static const double _stroke = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _canvas;
    canvas.save();
    canvas.scale(scale, scale);
    if (glyph == CapsuleToastGlyph.loading) {
      canvas.translate(_canvas / 2, _canvas / 2);
      canvas.rotate(rotation * 2 * math.pi);
      canvas.translate(-_canvas / 2, -_canvas / 2);
    }
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (glyph) {
      case CapsuleToastGlyph.success:
        final Path check = Path()
          ..moveTo(4.2, 10.6)
          ..lineTo(7.8, 14.2)
          ..lineTo(15.8, 6);
        canvas.drawPath(check, strokePaint);
      case CapsuleToastGlyph.information:
        canvas.drawCircle(const Offset(10, 10), 7.6, strokePaint);
        final Paint fill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9.1, 8.4, 1.8, 1.8),
            const Radius.circular(0.9),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9.1, 11.2, 1.8, 5.4),
            const Radius.circular(0.9),
          ),
          fill,
        );
      case CapsuleToastGlyph.warning:
        final Path triangle = Path()
          ..moveTo(10, 3.1)
          ..lineTo(17, 15.5)
          ..lineTo(3, 15.5)
          ..close();
        canvas.drawPath(triangle, strokePaint);
        final Paint fill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(9.1, 11.4, 1.8, 1.8),
            const Radius.circular(0.9),
          ),
          fill,
        );
      case CapsuleToastGlyph.error:
        canvas.drawCircle(const Offset(10, 10), 7.6, strokePaint);
        canvas.drawLine(
          const Offset(7.2, 7.2),
          const Offset(12.8, 12.8),
          strokePaint,
        );
        canvas.drawLine(
          const Offset(12.8, 7.2),
          const Offset(7.2, 12.8),
          strokePaint,
        );
      case CapsuleToastGlyph.connectivity:
        for (final double y in <double>[7.6, 10.6, 13.6]) {
          final double span = (13.6 - y) * 1.4 + 4;
          final Rect arcRect = Rect.fromCenter(
            center: Offset(10, y + span / 2),
            width: span * 2,
            height: span * 2,
          );
          canvas.drawArc(
            arcRect,
            math.pi * 1.15,
            math.pi * 0.7,
            false,
            strokePaint,
          );
        }
      case CapsuleToastGlyph.neutral:
        final Paint fill = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawCircle(const Offset(10, 10), 2.4, fill);
      case CapsuleToastGlyph.loading:
        final Paint track = Paint()
          ..color = color.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke;
        canvas.drawCircle(const Offset(10, 10), 7.2, track);
        final Paint head = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(10, 10), radius: 7.2),
          0,
          math.pi * 0.65,
          false,
          head,
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
