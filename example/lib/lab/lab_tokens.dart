// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mirrored from the reference motion prototype.
///
/// Values are transcribed verbatim from the design system's token sheet so the
/// lab and the prototype can be compared side by side.
abstract final class Lab {
  // ── Surfaces ──
  /// Warm off-white page background.
  static const Color bg = Color(0xFFF4EFE7);

  /// Recessed surface behind frozen specimens.
  static const Color bgDeep = Color(0xFFEDE6DA);

  /// Soft beige card fill.
  static const Color card = Color(0xFFFBF7EF);

  /// Slightly deeper fill for nested chips and tracks.
  static const Color cardAlt = Color(0xFFF2EADC);

  /// Hairline stroke, `rgba(60,45,30,0.10)`.
  static const Color hairline = Color(0x1A3C2D1E);

  /// Divider stroke, `rgba(60,45,30,0.06)`.
  static const Color divider = Color(0x0F3C2D1E);

  /// Inactive toggle track, `rgba(60,45,30,0.14)`.
  static const Color toggleTrack = Color(0x243C2D1E);

  // ── Type ──
  /// Charcoal primary text.
  static const Color ink = Color(0xFF1F1A14);

  /// Secondary heading text.
  static const Color ink2 = Color(0xFF3D352A);

  /// Muted body text.
  static const Color muted = Color(0xFF7A6F60);

  /// Faintest supporting text.
  static const Color muted2 = Color(0xFF9C9486);

  // ── Accents ──
  /// Amber accent used for the eyebrow and timeline bands.
  static const Color amber = Color(0xFFC0833D);

  /// Sage accent used for active toggles and the live state dot.
  static const Color sage = Color(0xFF7E8E6D);

  /// Amber timeline band, `rgba(192,131,61,0.16)`.
  static const Color bandAmber = Color(0x29C0833D);

  /// Sage timeline band, `rgba(126,142,109,0.16)`.
  static const Color bandSage = Color(0x297E8E6D);

  /// Panel column width from the reference layout.
  static const double panelWidth = 430;

  /// Phone canvas size from the reference layout.
  static const Size phoneSize = Size(390, 844);

  /// Full timeline span in milliseconds.
  static const int timelineTotalMs = 3160;

  /// Inter at the given optical settings.
  ///
  /// The reference uses variable-weight Inter; Flutter quantises to the nearest
  /// hundred, so 460/540/560 all resolve to the neighbouring named weight.
  static TextStyle font({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Uppercase section eyebrow.
  static TextStyle get sectionTitle =>
      font(size: 11, weight: FontWeight.w600, color: muted, letterSpacing: 0.7);

  /// Supporting note under a section title.
  static TextStyle get sectionNote =>
      font(size: 12, color: muted2, letterSpacing: -0.05);
}
