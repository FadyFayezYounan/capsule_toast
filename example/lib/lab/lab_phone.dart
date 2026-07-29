// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';

import 'lab_tokens.dart';
import 'lab_variants.dart';

/// Device frame that hosts the live capsule, matching the prototype canvas.
class LabPhoneFrame extends StatelessWidget {
  /// Creates a phone frame wrapping [child].
  const LabPhoneFrame({super.key, required this.child, this.dark = false});

  /// Screen content, including the toast host.
  final Widget child;

  /// Whether the previewed application is in its dark appearance.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Lab.phoneSize.width,
      height: Lab.phoneSize.height,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(48),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            offset: Offset(0, 40),
            blurRadius: 80,
            color: Color(0x2E000000),
          ),
        ],
        border: Border.all(color: const Color(0x1F000000)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: child),
          // Dynamic island.
          Positioned(
            top: 11,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 126,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          // Status bar.
          Positioned(
            top: 21,
            left: 32,
            right: 32,
            child: DefaultTextStyle(
              style: Lab.font(
                size: 17,
                weight: FontWeight.w600,
                height: 22 / 17,
                color: dark ? Lab.darkInk : Lab.ink,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('9:41'),
                  Opacity(
                    opacity: 0.8,
                    child: Text('▮▮▮', style: Lab.font(size: 12)),
                  ),
                ],
              ),
            ),
          ),
          // Home indicator.
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 139,
                height: 5,
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0x59FFFFFF)
                      : const Color(0x40000000),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder app screen the capsule floats above.
class LabPhoneScreen extends StatelessWidget {
  /// Creates the stand-in screen.
  const LabPhoneScreen({super.key, this.dark = false});

  /// Whether the previewed application is in its dark appearance.
  final bool dark;

  static const List<({String title, String subtitle})> _rows =
      <({String title, String subtitle})>[
        (title: 'Car insurance renewal', subtitle: 'Due in 3 days'),
        (title: 'Passport photo', subtitle: 'Vault · Documents'),
        (title: 'Dentist appointment', subtitle: 'Tomorrow · 6:00 PM'),
        (title: 'Electricity bill', subtitle: 'Paid · last week'),
      ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dark ? Lab.darkBg : Lab.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 110, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Today',
              style: Lab.font(
                size: 30,
                weight: FontWeight.w600,
                letterSpacing: -1,
                color: dark ? Lab.darkInk : Lab.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final ({String title, String subtitle}) row in _rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? Lab.darkCard : Lab.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dark ? Lab.darkHairline : Lab.hairline,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        row.title,
                        style: Lab.font(
                          size: 14,
                          weight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: dark ? Lab.darkInk : Lab.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.subtitle,
                        style: Lab.font(
                          size: 12,
                          color: dark ? Lab.darkMuted : Lab.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// In-phone trigger dock for driving the prototype without leaving the canvas.
class LabDemoDock extends StatelessWidget {
  /// Creates the dock.
  const LabDemoDock({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.onFire,
    required this.onFireExpanded,
    this.dark = false,
  });

  /// Whether the previewed application is in its dark appearance.
  final bool dark;

  /// Whether the dock is expanded.
  final bool open;

  /// Called to show or hide the dock.
  final ValueChanged<bool> onOpenChanged;

  /// Called with the variant to trigger.
  final ValueChanged<LabVariant> onFire;

  /// Called to trigger the expanded-entry demo.
  final VoidCallback onFireExpanded;

  static const List<List<LabVariant>> _rows = <List<LabVariant>>[
    <LabVariant>[LabVariant.success, LabVariant.info, LabVariant.warning],
    <LabVariant>[LabVariant.error, LabVariant.loading],
  ];

  static const Color _chip = Color(0x1AF9F9F7);
  static const Color _fg = Color(0xFFF9F9F7);

  // The reference dock lifts with the app: on a dark canvas the near-black
  // panel would vanish, so it warms and lightens the same way the capsule does.
  static const Color _darkChip = Color(0x21F9F6F0);
  static const Color _darkPanel = Color(0xEB2C2822);
  static const Color _darkRim = Color(0x24F9F6F0);
  static const Color _darkShadow = Color(0x80000000);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      bottom: 40,
      child: open ? _buildPanel() : _buildCollapsed(),
    );
  }

  Widget _buildPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? _darkPanel : const Color(0xEB161614),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: dark ? _darkRim : const Color(0x14F9F9F7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            offset: const Offset(0, 10),
            blurRadius: 30,
            color: dark ? _darkShadow : const Color(0x3D140E06),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 1, 4, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'PROTOTYPE TRIGGERS',
                  style: Lab.font(
                    size: 10,
                    weight: FontWeight.w600,
                    color: const Color(0x70F9F9F7),
                    letterSpacing: 0.7,
                  ),
                ),
                GestureDetector(
                  onTap: () => onOpenChanged(false),
                  child: Text(
                    'Hide',
                    style: Lab.font(
                      size: 11,
                      weight: FontWeight.w600,
                      color: const Color(0x80F9F9F7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final List<LabVariant> row in _rows)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: <Widget>[
                  for (final LabVariant variant in row) ...<Widget>[
                    Expanded(
                      child: _dockChip(
                        label: _shortLabel(variant),
                        onTap: () => onFire(variant),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (row.length < 3)
                    Expanded(
                      child: _dockChip(
                        label: 'Expanded',
                        onTap: onFireExpanded,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _shortLabel(LabVariant variant) {
    return switch (variant) {
      LabVariant.loading => 'Loading',
      _ => labVariantLabel(variant),
    };
  }

  Widget _dockChip({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: dark ? _darkChip : _chip,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Lab.font(
            size: 11.5,
            weight: FontWeight.w600,
            color: _fg,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    return Center(
      child: GestureDetector(
        onTap: () => onOpenChanged(true),
        child: Container(
          height: 30,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: dark ? _darkPanel : const Color(0xE6161614),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: dark ? _darkRim : const Color(0x14F9F9F7),
            ),
          ),
          child: Text(
            'Show demo triggers',
            style: Lab.font(
              size: 11.5,
              weight: FontWeight.w600,
              color: const Color(0xCCF9F9F7),
            ),
          ),
        ),
      ),
    );
  }
}
