// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/capsule_toast_types.dart';
import '../theme/capsule_toast_theme_data.dart';

// One full rotation of the loading spinner, in milliseconds. Transcribed from
// the reference prototype, where the spinner turns a little slower than
// Material's own indeterminate indicator so it reads as calm rather than busy.
const int _kGlyphSpinnerDuration = 850;

// Every reference SVG is authored on a 20x20 viewBox. All path coordinates in
// this file are in those units and are scaled to the widget's size at paint
// time, so a glyph can be drawn at any size without retuning its numbers.
const double _kGlyphCanvasSize = 20;

/// Paints one glyph inside a 20-unit canvas, matching the reference SVGs.
///
/// Every path below is a transcription of the corresponding `<svg>` in the
/// prototype, including its own stroke width — the reference varies stroke per
/// path (a 2.3 checkmark beside a 1.7 circle), so a single shared width reads
/// visibly wrong at these sizes.
class _CapsuleToastGlyphPainter extends CustomPainter {
  _CapsuleToastGlyphPainter({
    required this.glyph,
    required this.color,
    required this.rotation,
  }) : super(repaint: rotation);

  final CapsuleToastGlyph glyph;
  final Color color;

  /// Drives the loading spinner, and repaints this painter as it ticks.
  ///
  /// Ignored by every glyph other than [CapsuleToastGlyph.loading]. Passing
  /// this animation to `super.repaint` is what makes the spinner turn: reading
  /// its value without subscribing to it once left the arc frozen, because the
  /// ticker ran but nothing ever asked for a frame.
  final Animation<double> rotation;

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

  // M4.2 10.6l3.6 3.6L15.8 6 — stroke 2.3
  void _paintSuccess(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(4.2, 10.6)
        ..lineTo(7.8, 14.2)
        ..lineTo(15.8, 6),
      _stroke(2.3),
    );
  }

  // circle r7.6 stroke 1.7 · dot at (10, 6.2) r1.05 · stem M10 9v5
  void _paintInformation(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
    canvas.drawCircle(const Offset(10, 6.2), 1.05, _fill);
    canvas.drawLine(const Offset(10, 9), const Offset(10, 14), _stroke(1.9));
  }

  // triangle stroke 1.7 · stem M10 7.9v3.5 · dot at (10, 13.4) r0.95
  void _paintWarning(Canvas canvas) {
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
  }

  // circle r7.6 stroke 1.7 · cross 7.4→12.6 stroke 1.8
  void _paintError(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 7.6, _stroke(1.7));
    final Paint cross = _stroke(1.8);
    canvas.drawLine(const Offset(7.4, 7.4), const Offset(12.6, 12.6), cross);
    canvas.drawLine(const Offset(12.6, 7.4), const Offset(7.4, 12.6), cross);
  }

  // Three arcs over a dot, stroke 1.6 — the reference's offline glyph.
  void _paintConnectivity(Canvas canvas) {
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
  }

  void _paintNeutral(Canvas canvas) {
    canvas.drawCircle(const Offset(10, 10), 2.4, _fill);
  }

  // Track at 0.22 alpha with a quarter-turn head, both stroke 2. The head
  // starts at twelve o'clock: `M10 2.8 a7.2 7.2 0 0 1 7.2 7.2`.
  void _paintLoading(Canvas canvas) {
    canvas.translate(_kGlyphCanvasSize / 2, _kGlyphCanvasSize / 2);
    canvas.rotate(rotation.value * 2 * math.pi);
    canvas.translate(-_kGlyphCanvasSize / 2, -_kGlyphCanvasSize / 2);
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
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / _kGlyphCanvasSize;
    canvas.save();
    canvas.scale(scale, scale);

    switch (glyph) {
      case CapsuleToastGlyph.success:
        _paintSuccess(canvas);
      case CapsuleToastGlyph.information:
        _paintInformation(canvas);
      case CapsuleToastGlyph.warning:
        _paintWarning(canvas);
      case CapsuleToastGlyph.error:
        _paintError(canvas);
      case CapsuleToastGlyph.connectivity:
        _paintConnectivity(canvas);
      case CapsuleToastGlyph.neutral:
        _paintNeutral(canvas);
      case CapsuleToastGlyph.loading:
        _paintLoading(canvas);
      case CapsuleToastGlyph.automatic:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CapsuleToastGlyphPainter oldPainter) {
    return oldPainter.glyph != glyph ||
        oldPainter.color != color ||
        oldPainter.rotation != rotation;
  }
}

/// A status glyph for a capsule toast, painted from the package's reference
/// vector artwork.
///
/// There are two kinds of glyph:
///
///  * _Static_. [CapsuleToastGlyph.success], [CapsuleToastGlyph.information],
///    [CapsuleToastGlyph.warning], [CapsuleToastGlyph.error],
///    [CapsuleToastGlyph.connectivity], and [CapsuleToastGlyph.neutral] each
///    paint a fixed shape and never animate.
///  * _Animated_. [CapsuleToastGlyph.loading] paints an arc over a dimmed
///    track, turning once every [defaultAnimationDuration].
///
/// [CapsuleToastGlyph.automatic] paints nothing. Resolve it against a
/// [CapsuleToastType] with [CapsuleToastGlyph.resolveFor] before constructing
/// this widget.
///
/// The glyph is drawn in [color] at [size], or at a per-glyph optical default
/// when [size] is null. It has no background of its own; the tinted circle
/// behind it in a capsule toast is painted by the caller.
///
/// ## Theming
///
/// [theme] is an already-resolved [CapsuleToastThemeData] rather than a value
/// read from the [BuildContext], because toasts render in an overlay where the
/// inherited theme is not reliably reachable.
///
/// A [CapsuleToastThemeData.glyphBuilder] replaces every glyph except
/// [CapsuleToastGlyph.loading] and [CapsuleToastGlyph.connectivity], which have
/// no equivalent in a caller's icon set. A
/// [CapsuleToastThemeData.spinnerBuilder] replaces
/// [CapsuleToastGlyph.loading]; when one is supplied this widget leaves its own
/// animation stopped rather than scheduling frames nothing paints.
///
/// ## Animation
///
/// The spinner is driven by an [AnimationController] this widget creates and
/// owns. To freeze it — in a golden test, or a specimen gallery — wrap this
/// widget in a [TickerMode] with `enabled` set to false, which mutes the
/// ticker without changing what is painted.
///
/// See also:
///
///  * [CapsuleToastGlyph], the set of shapes this widget can paint.
///  * [CapsuleToastThemeData.glyphBuilder], for replacing those shapes.
///  * [CapsuleToastThemeData.spinnerBuilder], for replacing the spinner.
///  * [CircularProgressIndicator], the Material indeterminate spinner this
///    widget's loading glyph is modelled on.
class CapsuleToastGlyphIcon extends StatefulWidget {
  /// Creates a capsule toast status glyph.
  ///
  /// The [glyph] is painted in [color] at [size], or at a per-glyph optical
  /// default when [size] is null. The [size] must be greater than zero.
  const CapsuleToastGlyphIcon({
    super.key,
    required this.glyph,
    required this.color,
    required this.theme,
    this.size,
  }) : assert(size == null || size > 0);

  /// Which shape to paint.
  ///
  /// [CapsuleToastGlyph.automatic] paints nothing; resolve it with
  /// [CapsuleToastGlyph.resolveFor] first.
  final CapsuleToastGlyph glyph;

  /// The stroke and fill color of the glyph.
  ///
  /// The loading glyph's track is painted in this color at 22% alpha.
  final Color color;

  /// The resolved theme supplying the optional glyph and spinner builders.
  final CapsuleToastThemeData theme;

  /// The logical width and height of the glyph canvas.
  ///
  /// If null, each glyph is painted at its own optical default. The reference
  /// sizes the shapes individually rather than normalising them: the check is
  /// the lightest shape so it can afford to be smallest, while the triangle
  /// and the signal arcs need the extra room to read at a glance.
  final double? size;

  /// The default duration of one full rotation of the loading spinner.
  ///
  /// Used for the [AnimationController] this widget creates and owns.
  static const Duration defaultAnimationDuration = Duration(
    milliseconds: _kGlyphSpinnerDuration,
  );

  @override
  State<CapsuleToastGlyphIcon> createState() => _CapsuleToastGlyphIconState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<CapsuleToastGlyph>('glyph', glyph));
    properties.add(ColorProperty('color', color));
    properties.add(DoubleProperty('size', size, defaultValue: null));
  }
}

class _CapsuleToastGlyphIconState extends State<CapsuleToastGlyphIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: CapsuleToastGlyphIcon.defaultAnimationDuration,
      vsync: this,
    );
    _updateControllerAnimatingStatus();
  }

  @override
  void didUpdateWidget(CapsuleToastGlyphIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateControllerAnimatingStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The spinner turns only when this widget is the thing drawing it: a
  // theme-supplied spinnerBuilder replaces the arc entirely, so leaving the
  // controller repeating behind one would schedule frames nothing paints.
  void _updateControllerAnimatingStatus() {
    final bool animating =
        widget.glyph == CapsuleToastGlyph.loading &&
        widget.theme.spinnerBuilder == null;
    if (animating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!animating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size =
        widget.size ?? _CapsuleToastGlyphIconDefaults(widget.glyph).size;

    final CapsuleToastGlyphBuilder? glyphBuilder = widget.theme.glyphBuilder;
    if (glyphBuilder != null &&
        widget.glyph != CapsuleToastGlyph.loading &&
        widget.glyph != CapsuleToastGlyph.connectivity) {
      return glyphBuilder(context, widget.glyph, widget.color, size);
    }

    final CapsuleToastSpinnerBuilder? spinnerBuilder =
        widget.theme.spinnerBuilder;
    if (widget.glyph == CapsuleToastGlyph.loading && spinnerBuilder != null) {
      return spinnerBuilder(context, widget.color, size);
    }

    return SizedBox(
      key: ValueKey<String>('capsule.${widget.glyph.name}.glyph'),
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CapsuleToastGlyphPainter(
          glyph: widget.glyph,
          color: widget.color,
          rotation: _controller,
        ),
      ),
    );
  }
}

// Hand coded defaults transcribed from the reference SVGs.
//
// The reference sizes each glyph individually rather than normalising them:
// the check is the lightest shape so it can afford to be smallest, while the
// triangle and the signal arcs need the extra room to read at a glance. Every
// glyph shares the same 20-unit canvas, so this is purely optical balance.
class _CapsuleToastGlyphIconDefaults {
  const _CapsuleToastGlyphIconDefaults(this.glyph);

  final CapsuleToastGlyph glyph;

  double get size => switch (glyph) {
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
