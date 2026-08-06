// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../manager/capsule_toast_coordinator.dart';
import '../manager/capsule_toast_record.dart';
import '../model/capsule_toast_types.dart';
import '../motion/capsule_motion_controller.dart';
import '../theme/capsule_toast_motion_theme.dart';
import '../theme/capsule_toast_theme.dart';
import '../theme/capsule_toast_theme_data.dart';
import 'capsule_toast_animated_slot.dart';
import 'capsule_toast_content.dart';
import 'capsule_toast_interaction.dart';
import 'capsule_toast_measure.dart';
import 'capsule_toast_motion_synchronizer.dart';
import 'capsule_toast_surface.dart';

/// Paints the active capsule toast for [coordinator].
///
/// Placement is not this widget's concern: `CapsuleToastViewport` positions
/// the presentation and hands down constraints already clamped to the resolved
/// horizontal inset and maximum width. This widget owns motion sequencing,
/// theme resolution, and the animated capsule surface only.
final class CapsuleToastPresentation extends StatefulWidget {
  /// Creates a presentation that paints the active toast for [coordinator].
  const CapsuleToastPresentation({
    super.key,
    required this.coordinator,
    required this.motion,
    required this.vsync,
  });

  /// Queue coordinator whose active record is rendered.
  final CapsuleToastCoordinator coordinator;

  /// Host-owned motion controller driving capsule geometry.
  @visibleForTesting
  final CapsuleMotionController motion;

  /// Ticker provider for loading glyphs and other widget tickers.
  final TickerProvider vsync;

  @override
  State<CapsuleToastPresentation> createState() =>
      _CapsuleToastPresentationState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CapsuleToastCoordinator>('coordinator', coordinator),
    );
    properties.add(
      DiagnosticsProperty<CapsuleMotionController>('motion', motion),
    );
    properties.add(DiagnosticsProperty<TickerProvider>('vsync', vsync));
  }
}

class _CapsuleToastPresentationState extends State<CapsuleToastPresentation> {
  bool _syncScheduled = false;

  late CapsuleToastMotionSynchronizer _synchronizer;

  CapsuleMotionController get _motion => widget.motion;

  @override
  void initState() {
    super.initState();
    _synchronizer = CapsuleToastMotionSynchronizer(
      coordinator: widget.coordinator,
      motion: widget.motion,
      scheduleSync: _scheduleMotionSync,
    );
    widget.coordinator.addListener(_handleCoordinatorChanged);
    _motion.addListener(_handleMotionChanged);
  }

  @override
  void didUpdateWidget(covariant CapsuleToastPresentation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinator != widget.coordinator) {
      oldWidget.coordinator.removeListener(_handleCoordinatorChanged);
      widget.coordinator.addListener(_handleCoordinatorChanged);
    }
    if (oldWidget.motion != widget.motion) {
      oldWidget.motion.removeListener(_handleMotionChanged);
      widget.motion.addListener(_handleMotionChanged);
    }
    if (oldWidget.coordinator != widget.coordinator ||
        oldWidget.motion != widget.motion) {
      _synchronizer = CapsuleToastMotionSynchronizer(
        coordinator: widget.coordinator,
        motion: widget.motion,
        scheduleSync: _scheduleMotionSync,
      );
    }
  }

  @override
  void deactivate() {
    // Unhook eagerly, before deactivation reaches descendants. Interaction
    // state now lives in a child (CapsuleToastInteraction) whose dispose()
    // calls motion.setInteractionPaused(false); the framework deactivates
    // this element before that child unmounts, so leaving the listener
    // attached until dispose() would let that notification reach a haptics
    // handler that reads an already-deactivated ancestor's Theme.
    _motion.removeListener(_handleMotionChanged);
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _motion.addListener(_handleMotionChanged);
  }

  @override
  void dispose() {
    _motion.removeListener(_handleMotionChanged);
    widget.coordinator.removeListener(_handleCoordinatorChanged);
    super.dispose();
  }

  void _handleCoordinatorChanged() {
    // Sync tracking immediately (mode changes defer spring retarget until
    // measure). Then rebuild so expanded/collapsed content is laid out in the
    // same frame the gesture ends — before a subsequent pump(duration).
    if (mounted) {
      _syncMotion();
      setState(() {});
    } else {
      _scheduleMotionSync();
    }
  }

  void _handleMotionChanged() {
    if (!mounted) {
      return;
    }
    final CapsuleToastRecord? record = widget.coordinator.active;
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record?.data.motionTheme);
    final bool reducedMotion = _isReducedMotion(motionTheme);
    _synchronizer.handleMotionChanged(
      record: record,
      motionTheme: motionTheme,
      reducedMotion: reducedMotion,
    );
  }

  void _scheduleMotionSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncMotion();
    });
  }

  void _syncMotion() {
    final CapsuleToastRecord? record = widget.coordinator.active;
    final CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
      context,
    ).merge(record?.data.theme);
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record?.data.motionTheme);
    final bool reducedMotion = _isReducedMotion(motionTheme);
    _synchronizer.synchronize(
      record: record,
      visualTheme: visualTheme,
      motionTheme: motionTheme,
      reducedMotion: reducedMotion,
    );
  }

  /// Distance the leading icon travels from the capsule centre to its rest
  /// position, signed for [textDirection].
  ///
  /// Derived from the measured target width for the desired mode so the icon
  /// tracks where it will come to rest, not where the spring happens to be.
  double _resolveIconTravel({
    required CapsuleToastRecord record,
    required CapsuleToastThemeData visualTheme,
    required TextDirection textDirection,
    required Size liveSize,
  }) {
    final bool compact = record.desiredMode == CapsuleToastMode.compact;
    final Size? modeSize = compact
        ? _synchronizer.compactSize
        : _synchronizer.expandedSize;
    final double targetWidth =
        (modeSize ?? _synchronizer.measuredSize ?? liveSize).width;
    final EdgeInsets padding =
        (compact ? visualTheme.compactPadding! : visualTheme.expandedPadding!)
            .resolve(textDirection);
    final double startInset = textDirection == TextDirection.rtl
        ? padding.right
        : padding.left;
    final double iconSize = compact
        ? visualTheme.compactIconSize!
        : visualTheme.expandedIconSize!;
    final double iconCenter = startInset + iconSize / 2;
    final double sign = textDirection == TextDirection.rtl ? -1.0 : 1.0;
    return (targetWidth / 2 - iconCenter) * sign;
  }

  bool _isReducedMotion(CapsuleToastMotionTheme motionTheme) {
    return switch (motionTheme.reducedMotionPolicy ??
        CapsuleToastReducedMotionPolicy.system) {
      CapsuleToastReducedMotionPolicy.always => true,
      CapsuleToastReducedMotionPolicy.never => false,
      CapsuleToastReducedMotionPolicy.system => MediaQuery.disableAnimationsOf(
        context,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastRecord? record = widget.coordinator.active;
    if (record == null) {
      _synchronizer.reset();
      return const SizedBox.shrink();
    }

    if (_synchronizer.needsSynchronization(record)) {
      _scheduleMotionSync();
    }

    final ThemeData appTheme = Theme.of(context);
    final CapsuleToastThemeData visualTheme = CapsuleToastTheme.resolve(
      context,
    ).merge(record.data.theme);
    final CapsuleToastMotionTheme motionTheme = CapsuleToastTheme.resolveMotion(
      context,
    ).merge(record.data.motionTheme);
    final bool reducedMotion = _isReducedMotion(motionTheme);
    _motion.setReducedMotion(reducedMotion);

    final TextDirection textDirection =
        record.data.textDirection ?? Directionality.of(context);
    final String announcement = composeCapsuleToastAnnouncement(record.data);

    // Keep gesture detectors outside AnimatedBuilder so recognizers are not
    // recreated on every spring tick.
    final Widget interactiveChild = CapsuleToastInteraction(
      record: record,
      coordinator: widget.coordinator,
      motion: _motion,
      motionTheme: motionTheme,
      child: DefaultTextStyle.merge(
        style: appTheme.textTheme.bodyMedium,
        child: CapsuleToastContent(
          record: record,
          coordinator: widget.coordinator,
          visualTheme: visualTheme,
          motionTheme: motionTheme,
          vsync: widget.vsync,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return AnimatedBuilder(
          animation: _motion,
          child: interactiveChild,
          builder: (BuildContext context, Widget? child) {
            final CapsuleMotionSnapshot snapshot = _motion.value;
            final double iconTravel = _resolveIconTravel(
              record: record,
              visualTheme: visualTheme,
              textDirection: textDirection,
              liveSize: snapshot.size,
            );
            return Transform.translate(
              offset: Offset(0, snapshot.verticalOffset),
              child: Opacity(
                opacity: snapshot.opacity,
                // Scales about the capsule's own centre, matching the
                // reference's default transform origin.
                child: Transform.scale(
                  scale: snapshot.scale,
                  alignment: Alignment.center,
                  child: SizedBox.fromSize(
                    size: snapshot.size,
                    child: CapsuleToastAnimationScope(
                      contentElapsed: _motion.contentElapsed,
                      revealing: _motion.contentRevealing,
                      reducedMotion: reducedMotion,
                      motionTheme: motionTheme,
                      textDirection: textDirection,
                      capsuleSize: snapshot.size,
                      iconTravel: iconTravel,
                      child: CapsuleToastSurface(
                        theme: visualTheme,
                        // The viewport already clamps to the resolved maximum
                        // width, so the incoming constraint is the measurement
                        // budget.
                        measureMaxWidth: constraints.maxWidth,
                        liveSize: snapshot.size,
                        semanticsLabel: announcement,
                        child: CapsuleToastMeasure(
                          // A new token drops the presentation's cached sizes,
                          // so the probe has to forget its own deduplication
                          // cache in the same beat.
                          generation: record.token,
                          onSizeChanged: _synchronizer.handleSizeChanged,
                          child: child!,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
