// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';

import 'lab_tokens.dart';

/// A titled panel section with an optional supporting note.
class PanelSection extends StatelessWidget {
  /// Creates a section labelled [title].
  const PanelSection({
    super.key,
    required this.title,
    this.note,
    required this.child,
  });

  /// Uppercase section eyebrow.
  final String title;

  /// Optional supporting sentence under the title.
  final String? note;

  /// Section body.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title.toUpperCase(), style: Lab.sectionTitle),
        if (note != null) ...<Widget>[
          const SizedBox(height: 3),
          Text(note!, style: Lab.sectionNote),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Pill button used throughout the control panel.
class LabButton extends StatelessWidget {
  /// Creates a pill button labelled [label].
  const LabButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  /// Button text.
  final String label;

  /// Press handler.
  final VoidCallback onPressed;

  /// Whether this is the filled, high-emphasis variant.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: primary ? Lab.ink : Lab.card,
        borderRadius: BorderRadius.circular(999),
        elevation: primary ? 1 : 0,
        shadowColor: const Color(0x24000000),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: primary
                  ? null
                  : Border.all(color: Lab.hairline, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: Lab.font(
                    size: 13,
                    weight: FontWeight.w600,
                    color: primary ? Lab.bg : Lab.ink,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled switch row with a supporting hint.
class LabToggle extends StatelessWidget {
  /// Creates a toggle labelled [label].
  const LabToggle({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  /// Toggle title.
  final String label;

  /// Supporting explanation.
  final String hint;

  /// Current value.
  final bool value;

  /// Change handler.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Lab.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Lab.hairline, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: Lab.font(
                          size: 13,
                          weight: FontWeight.w600,
                          letterSpacing: -0.15,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        hint,
                        style: Lab.font(size: 11.5, color: Lab.muted2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _TrackSwitch(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackSwitch extends StatelessWidget {
  const _TrackSwitch({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 40,
      height: 24,
      decoration: BoxDecoration(
        color: value ? Lab.sage : Lab.toggleTrack,
        borderRadius: BorderRadius.circular(999),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 190),
        curve: const Cubic(0.2, 0.8, 0.2, 1),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  offset: Offset(0, 1),
                  blurRadius: 2,
                  color: Color(0x29000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented picker used for the playback-speed control.
class LabSegmentedPicker<T> extends StatelessWidget {
  /// Creates a picker over [options].
  const LabSegmentedPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Available choices, in display order.
  final List<({T value, String label})> options;

  /// Currently selected value.
  final T value;

  /// Selection handler.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Lab.cardAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: <Widget>[
          for (final ({T value, String label}) option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.value),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(
                    right: option == options.last ? 0 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: option.value == value
                        ? Lab.card
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: option.value == value
                        ? const <BoxShadow>[
                            BoxShadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Color(0x1A3C2814),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option.label,
                    style: Lab.font(
                      size: 12,
                      weight: FontWeight.w600,
                      color: option.value == value ? Lab.ink : Lab.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One annotated phase of the capsule lifecycle.
@immutable
class LabPhase {
  /// Creates a phase annotation.
  const LabPhase({
    required this.id,
    required this.name,
    required this.fromMs,
    required this.toMs,
    required this.detail,
  });

  /// Single-letter phase marker.
  final String id;

  /// Phase name.
  final String name;

  /// Phase start on the reference timeline.
  final int fromMs;

  /// Phase end on the reference timeline.
  final int toMs;

  /// Annotation copy.
  final String detail;
}

/// The reference lifecycle phases, verbatim from the motion spec.
const List<LabPhase> labPhases = <LabPhase>[
  LabPhase(
    id: 'A',
    name: 'Appearance',
    fromMs: 0,
    toMs: 140,
    detail:
        'seed capsule 84×34 · y −8→0 · scale 0.92→1 · opacity 0→1 · '
        'ease-out 140 ms',
  ),
  LabPhase(
    id: 'B',
    name: 'Shape expansion',
    fromMs: 60,
    toMs: 420,
    detail:
        'width spring 420 ms / bounce 0.16 · height spring 400 ms / '
        'bounce 0.12, delayed 28 ms · radius = min(h/2, 34)',
  ),
  LabPhase(
    id: 'C',
    name: 'Content reveal',
    fromMs: 110,
    toMs: 380,
    detail:
        'icon 0 ms → title 30 → support 60 → action 90 · each 220 ms '
        'ease-out · x 10 pt · y 3 pt · scale 0.96→1 · clipped',
  ),
  LabPhase(
    id: 'D',
    name: 'Settle',
    fromMs: 380,
    toMs: 520,
    detail:
        'spring tail, no repeat wobble · overshoot ≈ 3% · haptic cue at rest',
  ),
  LabPhase(
    id: 'E',
    name: 'Hold',
    fromMs: 520,
    toMs: 2820,
    detail:
        'success / info 2.3 s · warning 3.6 s · error 3.8 s · loading until '
        'resolved · paused while touched',
  ),
  LabPhase(
    id: 'F',
    name: 'Collapse & exit',
    fromMs: 2820,
    toMs: 3160,
    detail:
        'action → support → title/icon retract toward centre · shape springs '
        'to seed 300 ms bounce 0 · seed rises 6 pt, fades 140 ms',
  ),
];

/// Motion annotation track plus its per-phase legend.
class LabTimeline extends StatelessWidget {
  /// Creates a timeline whose playhead sits at [playheadMs].
  const LabTimeline({super.key, required this.playheadMs});

  /// Playhead position in milliseconds, or null when hidden.
  final int? playheadMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double scale = constraints.maxWidth / Lab.timelineTotalMs;
                return Stack(
                  children: <Widget>[
                    const Positioned.fill(
                      child: ColoredBox(color: Lab.cardAlt),
                    ),
                    for (int i = 0; i < labPhases.length; i++)
                      Positioned(
                        left: labPhases[i].fromMs * scale,
                        width:
                            (labPhases[i].toMs - labPhases[i].fromMs) * scale,
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: i.isOdd ? Lab.bandSage : Lab.bandAmber,
                            border: const Border(
                              left: BorderSide(color: Color(0x243C2D1E)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              labPhases[i].id,
                              style: Lab.font(
                                size: 10.5,
                                weight: FontWeight.w700,
                                color: Lab.ink2,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (playheadMs != null)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 120),
                        left: playheadMs! * scale,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(color: Lab.ink),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final LabPhase phase in labPhases)
          Padding(
            padding: EdgeInsets.only(bottom: phase == labPhases.last ? 0 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 12,
                  child: Text(
                    phase.id,
                    style: Lab.font(
                      size: 11,
                      weight: FontWeight.w700,
                      color: Lab.ink2,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                SizedBox(
                  width: 96,
                  child: Text(
                    phase.name,
                    style: Lab.font(
                      size: 11.5,
                      weight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                          text: '${phase.fromMs}–${phase.toMs} ms',
                          style: Lab.font(
                            size: 11.5,
                            weight: FontWeight.w600,
                            color: Lab.ink2,
                            height: 1.42,
                          ),
                        ),
                        TextSpan(
                          text: ' · ${phase.detail}',
                          style: Lab.font(
                            size: 11.5,
                            color: Lab.muted,
                            height: 1.42,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Frozen capsule specimen with a label and dimension caption.
class LabSpecimen extends StatelessWidget {
  /// Creates a specimen labelled [label].
  const LabSpecimen({
    super.key,
    required this.label,
    required this.dimensions,
    required this.child,
    this.width,
  });

  /// Specimen name.
  final String label;

  /// Dimension caption.
  final String dimensions;

  /// Capsule content.
  final Widget child;

  /// Fixed capsule width, when the specimen is not content-driven.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final CapsuleToastThemeData theme = CapsuleToastThemeData.fallback();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: <Widget>[
            Text(
              label,
              style: Lab.font(
                size: 11.5,
                weight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
            Text(dimensions, style: Lab.font(size: 10.5, color: Lab.muted2)),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Lab.bgDeep,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(theme.radiusCap!),
                border: Border.all(
                  color: theme.borderColor!,
                  width: theme.borderWidth!,
                ),
                boxShadow: theme.shadows,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
