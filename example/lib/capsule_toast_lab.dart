// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:async';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'lab/lab_panel.dart';
import 'lab/lab_phone.dart';
import 'lab/lab_specimens.dart';
import 'lab/lab_tokens.dart';
import 'lab/lab_variants.dart';

/// Interactive motion lab for the capsule toast package.
class CapsuleToastExampleApp extends StatelessWidget {
  /// Creates the example application root.
  const CapsuleToastExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capsule Toast',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Lab.amber,
          surface: Lab.bg,
        ),
        scaffoldBackgroundColor: Lab.bg,
        // The package deliberately ships no font family, so capsule content
        // inherits whatever the app supplies. The reference is set in Inter.
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: const CapsuleToastLabPage(),
    );
  }
}

/// Named lifecycle phases surfaced by the lab's state readout.
enum LabPhaseName {
  /// No capsule on screen.
  hidden,

  /// The 84×34 seed, before content is revealed.
  seed,

  /// Settled compact layout.
  compact,

  /// Settled expanded layout.
  expanded,

  /// Retracting toward the seed and fading out.
  collapsing,
}

/// The motion prototype: a live capsule beside its annotated control panel.
class CapsuleToastLabPage extends StatefulWidget {
  /// Creates the lab page.
  const CapsuleToastLabPage({super.key});

  @override
  State<CapsuleToastLabPage> createState() => _CapsuleToastLabPageState();
}

class _CapsuleToastLabPageState extends State<CapsuleToastLabPage> {
  /// Vertical inset that lands the capsule at 62 pt inside the phone canvas,
  /// once the host adds its own 15 pt offset.
  static const double _phoneTopInset = 47;

  /// Time from show to the point the entrance is considered at rest.
  static const Duration _settle = Duration(milliseconds: 520);

  bool _rtl = false;
  bool _reducedMotion = false;
  bool _dockOpen = true;
  double _speed = 1;
  LabVariant? _lastFired;
  LabPhaseName _phase = LabPhaseName.hidden;

  CapsuleToastManager? _manager;
  CapsuleToastHandle? _active;
  final List<Timer> _timers = <Timer>[];

  @override
  void dispose() {
    _cancelTimers();
    timeDilation = 1;
    super.dispose();
  }

  // ── Clock ──

  /// Scales [duration] by the inspection speed so scripted steps stay in sync
  /// with the dilated capsule clock.
  Duration _scaled(Duration duration) {
    return Duration(microseconds: (duration.inMicroseconds / _speed).round());
  }

  void _later(Duration delay, VoidCallback action) {
    _timers.add(Timer(_scaled(delay), action));
  }

  void _cancelTimers() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _setPhase(LabPhaseName phase) {
    if (!mounted || _phase == phase) {
      return;
    }
    setState(() => _phase = phase);
  }

  // ── Triggers ──

  void _fire(
    LabVariant variant, {
    CapsuleToastMode mode = CapsuleToastMode.compact,
  }) {
    final CapsuleToastManager? manager = _manager;
    if (manager == null) {
      return;
    }
    _cancelTimers();
    setState(() => _lastFired = variant);

    final CapsuleToastHandle handle = manager.show(
      buildLabToast(variant, rtl: _rtl, mode: mode),
      queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
    );
    _active = handle;
    _setPhase(LabPhaseName.seed);
    _later(const Duration(milliseconds: 120), () {
      _setPhase(
        mode == CapsuleToastMode.expanded
            ? LabPhaseName.expanded
            : LabPhaseName.compact,
      );
    });

    if (variant == LabVariant.loading) {
      // Persistent while in flight, then the same capsule morphs into success.
      _later(const Duration(milliseconds: 1700), () {
        handle.resolve(
          buildLabToast(LabVariant.success, rtl: _rtl, mode: mode),
        );
        _markCollapseAfter(labVariantHold(LabVariant.success));
      });
    } else {
      _markCollapseAfter(labVariantHold(variant));
    }

    unawaited(
      handle.closed.then((CapsuleToastResult _) {
        if (identical(_active, handle)) {
          _active = null;
          _setPhase(LabPhaseName.hidden);
        }
      }),
    );
  }

  /// Flags the collapse phase once the hold clock is due to elapse.
  void _markCollapseAfter(Duration hold) {
    if (hold == Duration.zero) {
      return;
    }
    _later(_settle + hold, () => _setPhase(LabPhaseName.collapsing));
  }

  void _queueThree() {
    final CapsuleToastManager? manager = _manager;
    if (manager == null) {
      return;
    }
    _cancelTimers();
    setState(() => _lastFired = LabVariant.saved);
    _active = manager.show(
      buildLabToast(LabVariant.saved, rtl: _rtl),
      queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
    );
    manager.show(buildLabToast(LabVariant.completed, rtl: _rtl));
    manager.show(buildLabToast(LabVariant.online, rtl: _rtl));
    _setPhase(LabPhaseName.seed);
    _later(
      const Duration(milliseconds: 120),
      () => _setPhase(LabPhaseName.compact),
    );
  }

  void _expandCurrent() {
    _active?.expand();
    _setPhase(LabPhaseName.expanded);
  }

  void _collapseCurrent() {
    _active?.collapse();
    _setPhase(LabPhaseName.compact);
  }

  void _dismissCurrent() {
    if (_active == null) {
      return;
    }
    _cancelTimers();
    _active?.dismiss();
    _setPhase(LabPhaseName.collapsing);
  }

  void _replay() {
    _fire(_lastFired ?? LabVariant.success);
  }

  void _setSpeed(double value) {
    setState(() {
      _speed = value;
      timeDilation = 1 / value;
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Lab.bg,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 44, 40, 64),
          child: Center(
            child: Wrap(
              spacing: 44,
              runSpacing: 44,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: <Widget>[_buildPhoneColumn(), _buildPanel()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LabPhoneFrame(child: _buildPhoneContents()),
        const SizedBox(height: 14),
        _buildStateReadout(),
      ],
    );
  }

  Widget _buildPhoneContents() {
    // The host reads the ambient MediaQuery, so the phone canvas supplies its
    // own safe area and reduced-motion setting rather than the desktop window's.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Lab.phoneSize,
        padding: const EdgeInsets.only(top: _phoneTopInset),
        viewPadding: const EdgeInsets.only(top: _phoneTopInset),
        viewInsets: EdgeInsets.zero,
        disableAnimations: _reducedMotion,
      ),
      child: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: CapsuleToastHost(
          child: Builder(
            builder: (BuildContext hostContext) {
              _manager ??= CapsuleToastHost.of(hostContext);
              return Stack(
                children: <Widget>[
                  const Positioned.fill(child: LabPhoneScreen()),
                  LabDemoDock(
                    open: _dockOpen,
                    onOpenChanged: (bool value) =>
                        setState(() => _dockOpen = value),
                    onFire: _fire,
                    onFireExpanded: () => _fire(
                      LabVariant.success,
                      mode: CapsuleToastMode.expanded,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStateReadout() {
    final bool live = _phase != LabPhaseName.hidden;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Lab.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Lab.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: live ? Lab.sage : Lab.muted2,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'state: ${_phase.name}',
                style: Lab.font(
                  size: 12,
                  weight: FontWeight.w600,
                  color: Lab.ink2,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'tap to expand · hold to expand · swipe up to dismiss',
          style: Lab.font(size: 11.5, color: Lab.muted2),
        ),
      ],
    );
  }

  Widget _buildPanel() {
    return SizedBox(
      width: Lab.panelWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildHeader(),
          const SizedBox(height: 26),
          _buildStatusVariants(),
          const SizedBox(height: 26),
          _buildTransformations(),
          const SizedBox(height: 26),
          _buildReplay(),
          const SizedBox(height: 26),
          _buildAdaptations(),
          const SizedBox(height: 26),
          PanelSection(
            title: 'Motion annotations',
            note: 'Timings are targets; the springs decide the exact curve.',
            child: LabTimeline(playheadMs: _playheadMs),
          ),
          const SizedBox(height: 26),
          PanelSection(
            title: 'Component states',
            note: 'Frozen specimens of each named state.',
            child: _buildGallery(),
          ),
          const SizedBox(height: 26),
          _buildRules(),
        ],
      ),
    );
  }

  int? get _playheadMs {
    return switch (_phase) {
      LabPhaseName.hidden => null,
      LabPhaseName.seed => 0,
      LabPhaseName.compact || LabPhaseName.expanded => 110,
      LabPhaseName.collapsing => 2820,
    };
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'LIFEOPS · MOTION PROTOTYPE',
          style: Lab.font(
            size: 11,
            weight: FontWeight.w600,
            color: Lab.amber,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Capsule Toast',
          style: Lab.font(
            size: 27,
            weight: FontWeight.w600,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'One continuous capsule that grows to hold an event, reveals it from '
          'the inside out, then absorbs it again. Geometry is spring-driven '
          'and interruptible — a state change mid-flight keeps the current '
          'size and velocity.',
          style: Lab.font(
            size: 13.5,
            color: Lab.muted,
            height: 1.5,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusVariants() {
    const List<LabVariant> variants = <LabVariant>[
      LabVariant.success,
      LabVariant.info,
      LabVariant.warning,
      LabVariant.error,
      LabVariant.online,
      LabVariant.completed,
      LabVariant.saved,
    ];
    return PanelSection(
      title: 'Status variants',
      note:
          'Capsule stays neutral; status reads from glyph shape + a single '
          'accent.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (final LabVariant variant in variants)
            LabButton(
              label: labVariantLabel(variant),
              primary: variant == LabVariant.success,
              onPressed: () => _fire(variant),
            ),
        ],
      ),
    );
  }

  Widget _buildTransformations() {
    return PanelSection(
      title: 'Transformations',
      note: 'The same capsule is reused — never dismissed and re-created.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          LabButton(
            label: labVariantLabel(LabVariant.loading),
            onPressed: () => _fire(LabVariant.loading),
          ),
          LabButton(
            label: 'Open expanded',
            onPressed: () =>
                _fire(LabVariant.success, mode: CapsuleToastMode.expanded),
          ),
          LabButton(label: 'Expand current', onPressed: _expandCurrent),
          LabButton(label: 'Collapse current', onPressed: _collapseCurrent),
          LabButton(label: 'Queue 3 events', onPressed: _queueThree),
          LabButton(label: 'Dismiss now', onPressed: _dismissCurrent),
        ],
      ),
    );
  }

  Widget _buildReplay() {
    final String last = _lastFired == null
        ? 'success'
        : _lastFired!.name.toLowerCase();
    return PanelSection(
      title: 'Replay',
      note:
          'Re-run the last trigger, or slow the clock to inspect the '
          'spring tail.',
      child: Row(
        children: <Widget>[
          LabButton(label: '↻ Replay $last', primary: true, onPressed: _replay),
          const SizedBox(width: 8),
          Expanded(
            child: LabSegmentedPicker<double>(
              value: _speed,
              onChanged: _setSpeed,
              options: const <({double value, String label})>[
                (value: 1, label: '1×'),
                (value: 0.35, label: '0.35×'),
                (value: 0.15, label: '0.15×'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptations() {
    return PanelSection(
      title: 'Adaptations',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LabToggle(
            label: 'Reduced motion',
            hint: 'No overshoot, no stretch — opacity + smooth size only',
            value: _reducedMotion,
            onChanged: (bool value) => setState(() => _reducedMotion = value),
          ),
          const SizedBox(height: 8),
          LabToggle(
            label: 'Right-to-left',
            hint: 'Mirrors layout and content travel; origin stays centred',
            value: _rtl,
            onChanged: (bool value) {
              setState(() => _rtl = value);
              if (_active != null) {
                _fire(_lastFired ?? LabVariant.success);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    final TextDirection ltr = TextDirection.ltr;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        LabSpecimen(
          label: 'seed',
          dimensions: '84 × 34 · r 17',
          width: 84,
          child: LabSpecimens.seed(),
        ),
        const SizedBox(height: 12),
        LabSpecimen(
          label: 'compact',
          dimensions: 'content-driven · h 44 · r 22',
          child: LabSpecimens.compact(
            type: CapsuleToastType.success,
            title: labVariantCopy(LabVariant.success, rtl: false).title,
            chipLabel: labVariantCopy(
              LabVariant.success,
              rtl: false,
            ).compactAction,
            direction: ltr,
          ),
        ),
        const SizedBox(height: 12),
        LabSpecimen(
          label: 'expanded',
          dimensions: '≤ 340 · h auto · r 34',
          child: LabSpecimens.expanded(
            type: CapsuleToastType.success,
            copy: labVariantCopy(LabVariant.success, rtl: false),
            direction: ltr,
          ),
        ),
        const SizedBox(height: 12),
        LabSpecimen(
          label: 'loading',
          dimensions: 'persistent · morphs into success',
          child: LabSpecimens.compact(
            type: CapsuleToastType.loading,
            title: labVariantCopy(LabVariant.loading, rtl: false).title,
            direction: ltr,
          ),
        ),
        const SizedBox(height: 12),
        LabSpecimen(
          label: 'compact · RTL mirrored',
          dimensions: 'origin stays centred',
          child: LabSpecimens.compact(
            type: CapsuleToastType.success,
            title: labVariantCopy(LabVariant.success, rtl: true).title,
            chipLabel: labVariantCopy(
              LabVariant.success,
              rtl: true,
            ).compactAction,
            direction: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildRules() {
    const List<String> rules = <String>[
      'One capsule at a time — extra events queue behind the current '
          'lifecycle.',
      'Radius tracks half the live height (capped at 34) so corners never go '
          'sharp.',
      'Auto-dismiss pauses while the capsule is touched; warning and error '
          'wait 3.6–3.8 s.',
      'Width is content-driven, capped at 340 pt (≈87% of the 390 pt canvas), '
          'and the compact line truncates.',
      'Announced through a polite live region; actions are labelled and never '
          'colour-only.',
    ];
    return PanelSection(
      title: 'Rules',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final String rule in rules)
            Padding(
              padding: EdgeInsets.only(bottom: rule == rules.last ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 18,
                    child: Text(
                      '•',
                      style: Lab.font(
                        size: 12.5,
                        color: Lab.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rule,
                      style: Lab.font(
                        size: 12.5,
                        color: Lab.muted,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
