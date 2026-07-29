// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';
import 'package:capsule_toast/src/manager/capsule_toast_coordinator.dart';
import 'package:capsule_toast/src/manager/capsule_toast_record.dart';
import 'package:capsule_toast/src/motion/capsule_motion_controller.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_animated_slot.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_content.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_layer.dart';
import 'package:capsule_toast/src/widgets/capsule_toast_surface.dart';

export 'package:capsule_toast/src/motion/capsule_motion_controller.dart'
    show CapsuleMotionController, CapsuleMotionSnapshot;
export 'package:capsule_toast/src/widgets/capsule_toast_surface.dart'
    show capsuleHighlightKey, capsuleSurfaceKey;

/// No-op action callback for const test fixtures.
void noop() {}

/// Brand-neutral canvas behind golden toast boards.
const Color goldenCanvasColor = Color(0xFFE4E5E8);

/// Logical golden surface size matching a common phone viewport.
const Size goldenSurfaceSize = Size(390, 844);

/// Repaint boundary key for exact-pixel golden captures.
const Key goldenBoundaryKey = ValueKey<String>('capsule_toast.golden_boundary');

/// Bundles manager, handle, and motion controller for widget tests.
final class ToastTestHarness {
  /// Creates a harness around one pumped toast presentation.
  const ToastTestHarness({
    required this.manager,
    required this.handle,
    required this.motion,
  });

  /// Host-owned toast manager.
  final CapsuleToastManager manager;

  /// Handle for the toast shown by [pumpToastHarness].
  final CapsuleToastHandle handle;

  /// Host-owned motion controller driving the active capsule.
  final CapsuleMotionController motion;
}

/// Installs a zero-tolerance golden comparator rooted at `test/`.
void installExactGoldenComparator() {
  final GoldenFileComparator previous = goldenFileComparator;
  // Anchor under test/ so `goldens/...` resolves to `test/goldens/...`.
  goldenFileComparator = _ExactGoldenFileComparator(
    Uri.file('${Directory.current.path}/test/golden_anchor.dart'),
  );
  addTearDown(() {
    goldenFileComparator = previous;
  });
}

/// Fixes the test surface to [goldenSurfaceSize] at device pixel ratio 1.
void configureGoldenSurface(WidgetTester tester) {
  tester.view.physicalSize = goldenSurfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Wraps [child] in a [MaterialApp] with a [CapsuleToastHost] installed via
/// [MaterialApp.builder].
Widget capsuleToastTestApp({required Widget home}) {
  return MaterialApp(
    builder: (BuildContext context, Widget? child) {
      return CapsuleToastHost(child: child!);
    },
    home: home,
  );
}

/// Pumps [toast] through the host and returns the command [BuildContext].
Future<BuildContext> pumpToast(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  EdgeInsets viewPadding = EdgeInsets.zero,
}) async {
  late BuildContext commandContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            viewPadding: viewPadding,
            padding: viewPadding,
            textScaler: textScaler,
            disableAnimations: disableAnimations,
          ),
          child: Directionality(
            textDirection: textDirection,
            child: CapsuleToastHost(child: child!),
          ),
        );
      },
      home: Builder(
        builder: (BuildContext context) {
          commandContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  CapsuleToastHost.of(commandContext).show(toast);
  await tester.pump();
  if (settle) {
    // Advance through the reference settle window in steps so bounce springs
    // can reach settlement (a single long pump can leave lifecycle in seed).
    // Avoid pumpAndSettle so persistent loading glyphs and hold clocks do not
    // hang the harness.
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  return commandContext;
}

/// Pumps [toast] and returns manager, handle, and motion for inspection.
Future<ToastTestHarness> pumpToastHarness(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  final BuildContext context = await pumpToast(
    tester,
    toast,
    settle: settle,
    brightness: brightness,
    disableAnimations: disableAnimations,
    textDirection: textDirection,
    textScaler: textScaler,
  );
  final CapsuleToastManager manager = CapsuleToastHost.of(context);
  final CapsuleToastLayer layer = tester.widget(find.byType(CapsuleToastLayer));
  return ToastTestHarness(
    manager: manager,
    handle: layer.coordinator.active!.handle,
    motion: layer.motion,
  );
}

/// Pumps a brand-neutral grid of settled toast surfaces for golden capture.
Future<void> pumpGoldenGrid(
  WidgetTester tester,
  List<CapsuleToastData> toasts, {
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  Size? seedClipSize,
}) async {
  configureGoldenSurface(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'FlutterTest', useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(
          size: goldenSurfaceSize,
          devicePixelRatio: 1,
          textScaler: textScaler,
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: TickerMode(
            enabled: false,
            child: ColoredBox(
              color: goldenCanvasColor,
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: goldenSurfaceSize.width,
                maxWidth: goldenSurfaceSize.width,
                minHeight: 0,
                maxHeight: double.infinity,
                child: RepaintBoundary(
                  key: goldenBoundaryKey,
                  child: ColoredBox(
                    color: goldenCanvasColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      child: _GoldenToastBoard(
                        toasts: toasts,
                        seedClipSize: seedClipSize,
                        reducedMotion: disableAnimations,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Allow surface radius measurement post-frame callbacks to settle.
  await tester.pump();
  await tester.pump();
}

/// Current spring-driven capsule size.
Size capsuleSize(WidgetTester tester) => capsuleMotion(tester).size;

/// Current capsule opacity from the motion snapshot.
double capsuleOpacity(WidgetTester tester) => capsuleMotion(tester).opacity;

/// Current motion snapshot for the active capsule.
CapsuleMotionSnapshot capsuleMotion(WidgetTester tester) {
  final CapsuleToastLayer layer = tester.widget(find.byType(CapsuleToastLayer));
  return layer.motion.value;
}

/// Zero-tolerance golden comparator (any differing pixel fails).
final class _ExactGoldenFileComparator extends LocalFileComparator {
  _ExactGoldenFileComparator(super.testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed || result.diffPercent > 0) {
      final String error = await generateFailureOutput(result, golden, basedir);
      result.dispose();
      throw FlutterError(error);
    }
    result.dispose();
    return true;
  }
}

class _GoldenToastBoard extends StatefulWidget {
  const _GoldenToastBoard({
    required this.toasts,
    this.seedClipSize,
    this.reducedMotion = false,
  });

  final List<CapsuleToastData> toasts;
  final Size? seedClipSize;
  final bool reducedMotion;

  @override
  State<_GoldenToastBoard> createState() => _GoldenToastBoardState();
}

class _GoldenToastBoardState extends State<_GoldenToastBoard>
    with TickerProviderStateMixin {
  late final CapsuleToastCoordinator _coordinator;
  late final List<CapsuleToastRecord> _records;
  final List<GlobalKey> _bodyKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _coordinator = CapsuleToastCoordinator();
    _records = <CapsuleToastRecord>[
      for (int i = 0; i < widget.toasts.length; i++)
        CapsuleToastRecord.create(
          token: i + 1,
          data: widget.toasts[i],
          delegate: _coordinator,
        ),
    ];
    _bodyKeys.addAll(
      List<GlobalKey>.generate(
        widget.toasts.length,
        (int index) => GlobalKey(debugLabel: 'golden.body.$index'),
      ),
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CapsuleToastThemeData visualTheme = CapsuleToastThemeData.fallback();
    final CapsuleToastMotionTheme motionTheme =
        CapsuleToastMotionTheme.fallback();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < _records.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 20),
          _buildTile(
            record: _records[i],
            bodyKey: _bodyKeys[i],
            visualTheme: visualTheme.merge(_records[i].data.theme),
            motionTheme: motionTheme.merge(_records[i].data.motionTheme),
          ),
        ],
      ],
    );
  }

  Widget _buildTile({
    required CapsuleToastRecord record,
    required GlobalKey bodyKey,
    required CapsuleToastThemeData visualTheme,
    required CapsuleToastMotionTheme motionTheme,
  }) {
    final TextDirection direction =
        record.data.textDirection ?? Directionality.of(context);
    final Size? clipSize = widget.seedClipSize;
    final Widget content = Directionality(
      textDirection: direction,
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium,
        child: CapsuleToastContent(
          record: record,
          coordinator: _coordinator,
          visualTheme: visualTheme,
          motionTheme: motionTheme,
          vsync: this,
        ),
      ),
    );

    final Widget surface = CapsuleToastSurface(
      theme: visualTheme,
      measureMaxWidth: visualTheme.maximumWidth,
      liveSize: clipSize,
      semanticsLabel: composeCapsuleToastAnnouncement(record.data),
      child: content,
    );

    final Widget scoped = CapsuleToastAnimationScope(
      contentElapsed: const Duration(seconds: 1),
      revealing: true,
      reducedMotion: widget.reducedMotion,
      motionTheme: motionTheme,
      textDirection: direction,
      capsuleSize:
          clipSize ??
          Size(visualTheme.maximumWidth!, visualTheme.compactMinimumHeight!),
      // Specimens are captured fully revealed, where travel has resolved to 0.
      iconTravel: 0,
      child: KeyedSubtree(key: bodyKey, child: surface),
    );

    if (clipSize == null) {
      return scoped;
    }
    return SizedBox(
      width: clipSize.width,
      height: clipSize.height,
      child: scoped,
    );
  }
}
