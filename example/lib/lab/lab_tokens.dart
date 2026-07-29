// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the interactive capsule toast lab.
///
/// The cool blue/slate treatment gives the example a distinct visual identity
/// while keeping its motion, layout, and interactions focused on the package.
abstract final class Lab {
  // ── Surfaces ──
  /// Pale blue-gray page background.
  static const Color bg = Color(0xFFEEF3F8);

  /// Recessed blue-gray surface behind frozen specimens.
  static const Color bgDeep = Color(0xFFE2EAF2);

  /// Crisp near-white card fill.
  static const Color card = Color(0xFFF8FAFC);

  /// Cool slate fill for nested chips and tracks.
  static const Color cardAlt = Color(0xFFE6EDF5);

  /// Low-emphasis blue-gray hairline stroke.
  static const Color hairline = Color(0x33566B85);

  /// Faint blue-gray divider stroke.
  static const Color divider = Color(0x1F566B85);

  /// Inactive blue-gray toggle track.
  static const Color toggleTrack = Color(0x38566B85);

  /// Solid outline for secondary control buttons.
  static const Color buttonBorder = Color(0xFF7187A6);

  /// Contrasting outline for primary control buttons.
  static const Color primaryButtonBorder = Color(0xFF8FA7D4);

  // ── Dark app surfaces ──
  // From the reference dark token sheet. These dress the phone canvas only;
  // the lab chrome around it stays light on purpose.

  /// Neutral charcoal app background.
  static const Color darkBg = Color(0xFF20201E);

  /// Raised card / row fill.
  static const Color darkCard = Color(0xFF2C2C2A);

  /// Hairline stroke, `rgba(249,249,247,0.10)`.
  static const Color darkHairline = Color(0x1AF9F9F7);

  /// Primary text on charcoal.
  static const Color darkInk = Color(0xFFF9F9F7);

  /// Muted body text on charcoal.
  static const Color darkMuted = Color(0xFF9A9A94);

  // ── Type ──
  /// Deep navy primary text.
  static const Color ink = Color(0xFF172033);

  /// Slate secondary heading text.
  static const Color ink2 = Color(0xFF334155);

  /// Muted slate body text.
  static const Color muted = Color(0xFF526174);

  /// Faint blue-gray supporting text.
  static const Color muted2 = Color(0xFF607086);

  // ── Accents ──
  /// Indigo accent used for the eyebrow and timeline bands.
  static const Color amber = Color(0xFF526FA8);

  /// Teal accent used for active toggles and the live state dot.
  static const Color sage = Color(0xFF3F8884);

  /// Indigo timeline band at 16 percent opacity.
  static const Color bandAmber = Color(0x29526FA8);

  /// Teal timeline band at 16 percent opacity.
  static const Color bandSage = Color(0x293F8884);

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
