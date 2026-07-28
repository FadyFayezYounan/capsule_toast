# Capsule Toast Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a reusable, brand-neutral Flutter capsule-toast
package that matches the supplied reference design and interruptible motion.

**Architecture:** A stateful `CapsuleToastHost` owns one private coordinator,
one lifecycle/motion engine, and one rendered top-center capsule. A private
inherited scope exposes only `CapsuleToastManager`; immutable public models and
themes feed focused rendering widgets, while a deterministic ticker-driven
spring engine preserves geometry velocity across every retarget.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.x, `flutter_test`, and
`flutter_lints`; Flutter and Dart SDK libraries are the only runtime
dependencies.

## Global Constraints

- Package name: `capsule_toast`; initial public version: `0.1.0`.
- Dart constraint: `^3.12.2`; Flutter constraint: `>=3.44.0`.
- Registry: pub.dev; license: BSD 3-Clause.
- Support Android, iOS, web, Windows, macOS, and Linux.
- Treat iOS and Android as the pixel and motion fidelity targets.
- Use only Flutter and Dart SDK runtime dependencies.
- Render one top-center capsule per host; version 1 has no other placement.
- Use no global singleton, global navigator key, external controller, or
  `BuildContext` extension.
- `CapsuleToastHost` owns and disposes its queue, handles, clocks, and ticker.
- `CapsuleToastHost.of(context)` and `maybeOf(context)` are the only lookup
  APIs; lookup returns `CapsuleToastManager`, never host state.
- Keep all package copy and examples brand-neutral; include no LifeOps names.
- Inherit the application's font; bundle and download no font.
- Preserve spring position and velocity when the target changes.
- Respect safe areas, live resizing, text scale, RTL, semantics, reduced
  motion, touch, mouse, and keyboard input.
- Every new Dart file uses the header
  `// Copyright 2026 The Capsule Toast Authors. All rights reserved.`
- Every public class and member has dartdoc; public widgets implement
  `debugFillProperties`; immutable UI types implement Flutter-style
  diagnostics, equality, `hashCode`, and the specified copy/merge/lerp APIs.
- Format to 80 columns where practical and keep imports grouped as Dart,
  Flutter, then local.

---

## File Map

### Public entry point

- `lib/capsule_toast.dart` — the sole public barrel; exports only supported API.

### Models and manager

- `lib/src/model/capsule_toast_action.dart` — immutable action description.
- `lib/src/model/capsule_toast_data.dart` — toast factories, content builders,
  duration and rendering overrides.
- `lib/src/model/capsule_toast_handle.dart` — public command handle and its
  private command delegate contract.
- `lib/src/model/capsule_toast_result.dart` — completion value and dismissal
  reasons.
- `lib/src/model/capsule_toast_types.dart` — semantic type, mode, queue policy,
  slot, reduced-motion, and haptic enums.
- `lib/src/manager/capsule_toast_manager.dart` — narrow public manager
  interface.
- `lib/src/manager/capsule_toast_record.dart` — internal record, completer, and
  command generation.
- `lib/src/manager/capsule_toast_coordinator.dart` — FIFO policy, active record,
  handle routing, completion, and promotion.

### Theme

- `lib/src/theme/capsule_toast_theme.dart` — public `InheritedTheme` and
  resolution helpers.
- `lib/src/theme/capsule_toast_theme_data.dart` — immutable visual overrides
  and resolved reference defaults.
- `lib/src/theme/capsule_toast_motion_theme.dart` — spring presets, timing,
  gesture, haptic, and reduced-motion configuration.

### Motion and lifecycle

- `lib/src/motion/damped_spring.dart` — deterministic bounded-step scalar
  spring.
- `lib/src/motion/capsule_geometry.dart` — width, height, opacity, and vertical
  offset spring state.
- `lib/src/motion/lifecycle_clock.dart` — pausable hold clock.
- `lib/src/motion/capsule_lifecycle.dart` — legal lifecycle states and
  transition intents.
- `lib/src/motion/capsule_motion_controller.dart` — ticker owner that integrates
  geometry, content envelope, hold time, and lifecycle settlement.

### Host and rendering

- `lib/src/host/capsule_toast_host.dart` — stateful owner, private inherited
  scope, theme resolution, and layered application child.
- `lib/src/widgets/capsule_toast_layer.dart` — active-record listener,
  measurement, gestures, semantics, and motion-to-render bridge.
- `lib/src/widgets/capsule_toast_surface.dart` — clipped capsule decoration and
  continuous geometry.
- `lib/src/widgets/capsule_toast_content.dart` — compact/expanded structured
  layouts and content envelopes.
- `lib/src/widgets/capsule_toast_action_button.dart` — isolated pointer and
  keyboard action control.
- `lib/src/widgets/capsule_toast_glyph.dart` — semantic glyphs and loading
  spinner.
- `lib/src/widgets/capsule_toast_measure.dart` — post-layout target-size
  reporter with change deduplication.
- `lib/src/widgets/capsule_toast_animated_slot.dart` — public custom-content
  staggering primitive.

### Tests, example, and package material

- `test/model/capsule_toast_data_test.dart`
- `test/theme/capsule_toast_theme_test.dart`
- `test/motion/damped_spring_test.dart`
- `test/motion/capsule_lifecycle_test.dart`
- `test/manager/capsule_toast_coordinator_test.dart`
- `test/host/capsule_toast_host_test.dart`
- `test/widgets/capsule_toast_content_test.dart`
- `test/widgets/capsule_toast_interaction_test.dart`
- `test/widgets/capsule_toast_accessibility_test.dart`
- `test/widgets/capsule_toast_motion_test.dart`
- `test/widgets/capsule_toast_golden_test.dart`
- `test/support/test_app.dart`
- `test/goldens/capsule_toast_seed.png`
- `test/goldens/capsule_toast_compact_states.png`
- `test/goldens/capsule_toast_expanded_states.png`
- `test/goldens/capsule_toast_loading_resolve.png`
- `test/goldens/capsule_toast_rtl_large_text.png`
- `test/goldens/capsule_toast_reduced_motion.png`
- `example/pubspec.yaml`
- `example/lib/main.dart`
- `example/lib/capsule_toast_lab.dart`
- `example/test/capsule_toast_lab_test.dart`
- `doc/capsule_toast_overview.png`
- `README.md`, `CHANGELOG.md`, `LICENSE`, `analysis_options.yaml`, and
  `pubspec.yaml` — pub.dev-ready package metadata and documentation.

---

### Task 1: Establish the package contract and core value types

**Files:**

- Modify: `pubspec.yaml`
- Modify: `analysis_options.yaml`
- Modify: `LICENSE`
- Modify: `lib/capsule_toast.dart`
- Delete: `test/capsule_toast_test.dart`
- Create: `lib/src/model/capsule_toast_types.dart`
- Create: `lib/src/model/capsule_toast_action.dart`
- Create: `lib/src/model/capsule_toast_result.dart`
- Create: `test/model/capsule_toast_types_test.dart`

**Interfaces:**

- Produces:
  `CapsuleToastType`, `CapsuleToastMode`, `CapsuleToastQueuePolicy`,
  `CapsuleToastGlyph`, `CapsuleToastSlot`, `CapsuleToastDismissReason`,
  `CapsuleToastReducedMotionPolicy`, `CapsuleToastHapticPolicy`,
  `CapsuleToastAction`, and `CapsuleToastResult`.
- Consumes: nothing from later tasks.

- [ ] **Step 1: Write the failing public-contract tests**

```dart
test('all public behavior enums remain exhaustive and ordered', () {
  expect(CapsuleToastType.values, <CapsuleToastType>[
    CapsuleToastType.success,
    CapsuleToastType.information,
    CapsuleToastType.warning,
    CapsuleToastType.error,
    CapsuleToastType.loading,
    CapsuleToastType.neutral,
    CapsuleToastType.custom,
  ]);
  expect(CapsuleToastQueuePolicy.values, <CapsuleToastQueuePolicy>[
    CapsuleToastQueuePolicy.enqueue,
    CapsuleToastQueuePolicy.replace,
    CapsuleToastQueuePolicy.clearAndShow,
  ]);
  expect(CapsuleToastDismissReason.values.length, 8);
});

test('action defaults to dismissing when invoked', () {
  final CapsuleToastAction action = CapsuleToastAction(
    label: 'Retry',
    onPressed: () {},
  );

  expect(action.semanticLabel, isNull);
  expect(action.dismissOnInvoke, isTrue);
});
```

- [ ] **Step 2: Run the tests and verify the missing API failure**

Run:

```bash
flutter test test/model/capsule_toast_types_test.dart
```

Expected: compilation fails because the capsule-toast public types do not yet
exist.

- [ ] **Step 3: Add metadata, the BSD license, enums, action, and result**

Use these exact enum cases:

```dart
enum CapsuleToastType {
  success,
  information,
  warning,
  error,
  loading,
  neutral,
  custom,
}

enum CapsuleToastMode { compact, expanded }

enum CapsuleToastQueuePolicy { enqueue, replace, clearAndShow }

enum CapsuleToastGlyph {
  automatic,
  success,
  information,
  warning,
  error,
  connectivity,
  loading,
  neutral,
}

enum CapsuleToastSlot { icon, title, message, action }

enum CapsuleToastDismissReason {
  timedOut,
  dismissed,
  swiped,
  actionSelected,
  replaced,
  cleared,
  queueOverflow,
  hostDisposed,
}

enum CapsuleToastReducedMotionPolicy { system, always, never }

enum CapsuleToastHapticPolicy { none, supportedPlatforms }
```

Define the values with these signatures:

```dart
typedef CapsuleToastActionCallback = FutureOr<void> Function();

@immutable
class CapsuleToastAction with Diagnosticable {
  const CapsuleToastAction({
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.dismissOnInvoke = true,
  }) : assert(label != '');

  final String label;
  final CapsuleToastActionCallback onPressed;
  final String? semanticLabel;
  final bool dismissOnInvoke;
}

@immutable
class CapsuleToastResult {
  const CapsuleToastResult({
    required this.reason,
    this.action,
  });

  final CapsuleToastDismissReason reason;
  final CapsuleToastAction? action;
}
```

Update `pubspec.yaml` to version `0.1.0`, a concrete package description,
SDK constraints from Global Constraints, and topics `toast`, `notification`,
`animation`, and `ui`. Remove the empty `homepage` key and generated comments.
Export the model files from the barrel. Replace the generated license stub with
the standard BSD 3-Clause text naming
“The Capsule Toast Authors”.

- [ ] **Step 4: Format, analyze, and run the contract tests**

Run:

```bash
dart format lib test
flutter analyze
flutter test test/model/capsule_toast_types_test.dart
```

Expected: all commands pass with no diagnostics.

- [ ] **Step 5: Commit the package contract**

```bash
git add pubspec.yaml analysis_options.yaml LICENSE lib test
git commit -m "feat: define capsule toast package contract"
```

---

### Task 2: Add immutable structured toast data and handles

**Files:**

- Create: `lib/src/model/capsule_toast_data.dart`
- Create: `lib/src/model/capsule_toast_handle.dart`
- Create: `lib/src/manager/capsule_toast_manager.dart`
- Modify: `lib/capsule_toast.dart`
- Create: `test/model/capsule_toast_data_test.dart`

**Interfaces:**

- Consumes: enums, `CapsuleToastAction`, and `CapsuleToastResult` from Task 1.
- Produces:

```dart
abstract interface class CapsuleToastManager {
  CapsuleToastHandle show(
    CapsuleToastData toast, {
    CapsuleToastQueuePolicy queuePolicy = CapsuleToastQueuePolicy.enqueue,
  });
  void clear();
  int get queueLength;
}

abstract interface class CapsuleToastHandle {
  Object? get id;
  Future<CapsuleToastResult> get closed;
  bool get isClosed;
  void expand();
  void collapse();
  void resolve(CapsuleToastData toast);
  void dismiss();
}
```

- [ ] **Step 1: Write failing factory and validation tests**

```dart
test('semantic factories select type and leave copy caller-owned', () {
  const CapsuleToastData toast = CapsuleToastData.success(
    id: 'save',
    title: 'Saved',
    message: 'Your changes are available.',
  );

  expect(toast.id, 'save');
  expect(toast.type, CapsuleToastType.success);
  expect(toast.initialMode, CapsuleToastMode.compact);
  expect(toast.persistent, isFalse);
  expect(toast.title, 'Saved');
});

test('loading is persistent by default', () {
  const CapsuleToastData toast = CapsuleToastData.loading(
    title: 'Uploading',
  );

  expect(toast.type, CapsuleToastType.loading);
  expect(toast.persistent, isTrue);
});

test('persistent and explicit duration are mutually exclusive', () {
  expect(
    () => const CapsuleToastData.neutral(
      title: 'Invalid',
      persistent: true,
      displayDuration: Duration(seconds: 1),
    ),
    throwsAssertionError,
  );
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
flutter test test/model/capsule_toast_data_test.dart
```

Expected: compilation fails because `CapsuleToastData` and its builder context
are missing.

- [ ] **Step 3: Implement the public immutable model**

Give `CapsuleToastData` these fields and constructor invariants:

```dart
@immutable
class CapsuleToastData with Diagnosticable {
  const CapsuleToastData._({
    required this.type,
    this.id,
    required this.title,
    this.message,
    this.semanticAnnouncement,
    this.initialMode = CapsuleToastMode.compact,
    this.glyph = CapsuleToastGlyph.automatic,
    this.icon,
    this.iconBuilder,
    this.compactAction,
    this.primaryAction,
    this.secondaryAction,
    this.displayDuration,
    this.persistent = false,
    this.textDirection,
  }) : assert(title != ''),
       assert(message != ''),
       assert(semanticAnnouncement != ''),
       assert(icon == null || iconBuilder == null),
       assert(!persistent || displayDuration == null),
       assert(displayDuration == null || !displayDuration.isNegative);

  final CapsuleToastType type;
  final Object? id;
  final String title;
  final String? message;
  final String? semanticAnnouncement;
  final CapsuleToastMode initialMode;
  final CapsuleToastGlyph glyph;
  final IconData? icon;
  final WidgetBuilder? iconBuilder;
  final CapsuleToastAction? compactAction;
  final CapsuleToastAction? primaryAction;
  final CapsuleToastAction? secondaryAction;
  final Duration? displayDuration;
  final bool persistent;
  final TextDirection? textDirection;
}
```

Add const factories `success`, `information`, `warning`, `error`, `loading`,
and `neutral`. Every factory requires `title` and accepts `id`, `message`,
`semanticAnnouncement`, `initialMode`, `glyph`, `icon`, `iconBuilder`,
`compactAction`, `primaryAction`, `secondaryAction`, `displayDuration`,
`persistent`, and `textDirection`. `loading` defaults `persistent` to true;
the others default it to false. Task 3 adds theme overrides and custom builders
after their concrete types exist.

Add `copyWith`, field equality, `hashCode`, and diagnostics to data classes.
For nullable fields, use a private sentinel in `copyWith` so callers can
explicitly clear an override:

```dart
static const Object _unset = Object();

CapsuleToastData copyWith({
  CapsuleToastType? type,
  Object? id = _unset,
  String? title,
  Object? message = _unset,
  Object? semanticAnnouncement = _unset,
  CapsuleToastMode? initialMode,
  CapsuleToastGlyph? glyph,
  Object? icon = _unset,
  Object? iconBuilder = _unset,
  Object? compactAction = _unset,
  Object? primaryAction = _unset,
  Object? secondaryAction = _unset,
  Object? displayDuration = _unset,
  bool? persistent,
  Object? textDirection = _unset,
}) {
  return CapsuleToastData._(
    type: type ?? this.type,
    id: identical(id, _unset) ? this.id : id,
    title: title ?? this.title,
    message: identical(message, _unset) ? this.message : message as String?,
    semanticAnnouncement: identical(semanticAnnouncement, _unset)
        ? this.semanticAnnouncement
        : semanticAnnouncement as String?,
    initialMode: initialMode ?? this.initialMode,
    glyph: glyph ?? this.glyph,
    icon: identical(icon, _unset) ? this.icon : icon as IconData?,
    iconBuilder: identical(iconBuilder, _unset)
        ? this.iconBuilder
        : iconBuilder as WidgetBuilder?,
    compactAction: identical(compactAction, _unset)
        ? this.compactAction
        : compactAction as CapsuleToastAction?,
    primaryAction: identical(primaryAction, _unset)
        ? this.primaryAction
        : primaryAction as CapsuleToastAction?,
    secondaryAction: identical(secondaryAction, _unset)
        ? this.secondaryAction
        : secondaryAction as CapsuleToastAction?,
    displayDuration: identical(displayDuration, _unset)
        ? this.displayDuration
        : displayDuration as Duration?,
    persistent: persistent ?? this.persistent,
    textDirection: identical(textDirection, _unset)
        ? this.textDirection
        : textDirection as TextDirection?,
  );
}
```

- [ ] **Step 4: Run model tests and analyzer**

Run:

```bash
dart format lib test/model
flutter analyze
flutter test test/model/capsule_toast_data_test.dart
```

Expected: all tests pass and analyzer reports no issues.

- [ ] **Step 5: Commit the public data model**

```bash
git add lib test/model
git commit -m "feat: add immutable capsule toast models"
```

---

### Task 3: Implement visual and motion theming

**Files:**

- Create: `lib/src/theme/capsule_toast_theme_data.dart`
- Create: `lib/src/theme/capsule_toast_motion_theme.dart`
- Create: `lib/src/theme/capsule_toast_theme.dart`
- Modify: `lib/src/model/capsule_toast_data.dart`
- Modify: `lib/capsule_toast.dart`
- Modify: `test/model/capsule_toast_data_test.dart`
- Create: `test/theme/capsule_toast_theme_test.dart`

**Interfaces:**

- Consumes: semantic and policy enums from Task 1.
- Produces:
  `CapsuleToastTheme`, `CapsuleToastThemeData`, `CapsuleToastMotionTheme`,
  `CapsuleToastSpring`, `CapsuleToastAccents`, `CapsuleToastTints`,
  `CapsuleToastContentBuilder`, `CapsuleToastContentContext`, the `custom`
  factory, per-toast overrides, and fully resolved fallback values.

- [ ] **Step 1: Write failing resolution and interpolation tests**

```dart
testWidgets('nearest theme overrides ThemeData extension', (tester) async {
  const Color extensionColor = Color(0xFF010101);
  const Color localColor = Color(0xFF020202);
  late CapsuleToastThemeData resolved;

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          CapsuleToastThemeData(surfaceColor: extensionColor),
        ],
      ),
      home: CapsuleToastTheme(
        data: const CapsuleToastThemeData(surfaceColor: localColor),
        child: Builder(
          builder: (BuildContext context) {
            resolved = CapsuleToastTheme.resolve(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );

  expect(resolved.surfaceColor, localColor);
  expect(resolved.maximumWidth, 340);
  expect(resolved.seedSize, const Size(84, 34));
});

test('motion fallback matches the approved reference values', () {
  final CapsuleToastMotionTheme theme =
      CapsuleToastMotionTheme.fallback();

  expect(theme.appearanceDuration, const Duration(milliseconds: 140));
  expect(theme.heightLead, const Duration(milliseconds: 28));
  expect(theme.slotRevealDuration, const Duration(milliseconds: 220));
  expect(theme.longPressDuration, const Duration(milliseconds: 320));
  expect(theme.dismissalDistance, 26);
});

test('custom content requires an announcement when title is absent', () {
  expect(
    () => CapsuleToastData.custom(
      compactBuilder: (BuildContext context, CapsuleToastContentContext value) {
        return const SizedBox();
      },
    ),
    throwsAssertionError,
  );
});
```

- [ ] **Step 2: Run the tests and verify the missing-theme failure**

Run:

```bash
flutter test test/theme/capsule_toast_theme_test.dart
```

Expected: compilation fails because the public theme types do not exist.

- [ ] **Step 3: Implement Flutter-style theme data**

Use these exact resolved visual defaults:

```dart
const Color surface = Color(0xFF161614);
const Color foreground = Color(0xFFF9F9F7);
const Color secondaryForeground = Color(0x9EF9F9F7);
const Color border = Color(0x12F9F9F7);
const Color actionSurface = Color(0x1AF9F9F7);
const Size seedSize = Size(84, 34);
const double compactMinimumHeight = 44;
const double maximumWidth = 340;
const double radiusCap = 34;
```

Use these additional reference defaults:

| Token | Value |
| --- | --- |
| border width | 0.5 |
| shadows | offset (0, 2), blur 6 and offset (0, 10), blur 30, both `rgba(20,14,6,0.16)` |
| compact padding | directional `fromSTEB(5, 5, 14, 5)` |
| expanded padding | directional `fromSTEB(14, 14, 16, 14)` |
| compact / expanded spacing | 10 / 12 |
| message / action spacing | 3 / 8 |
| action top spacing | 9 |
| compact / expanded icon size | 34 / 34 |
| compact title maximum width | 210 |
| compact / expanded action height | 24 / 30 |
| compact / primary / secondary horizontal action padding | 10 / 14 / 12 |
| horizontal window inset | 16 |
| safe-area vertical offset | 15 |
| compact title | 13.5 px, weight 600, letter spacing -0.15 |
| expanded title | 14.5 px, weight 600, height 1.25, letter spacing -0.2 |
| message | 12.5 px, weight 500, height 1.35, letter spacing -0.05 |
| action | 12.5 px, weight 600, letter spacing -0.1 |

Use these exact reference accents and tints:

| Type | Accent | Tint |
| --- | --- | --- |
| success | `#B9CCA8` | `rgba(149,165,132,0.16)` |
| information | `#AFC4D7` | `rgba(138,164,189,0.16)` |
| warning | `#E5BE85` | `rgba(216,152,88,0.16)` |
| error | `#E8A695` | `rgba(214,125,101,0.18)` |
| loading | `rgba(249,249,247,0.78)` | `rgba(249,249,247,0.08)` |
| neutral | `rgba(249,249,247,0.78)` | `rgba(249,249,247,0.08)` |
| custom | `rgba(249,249,247,0.78)` | `rgba(249,249,247,0.08)` |

`CapsuleToastThemeData` extends
`ThemeExtension<CapsuleToastThemeData>` and exposes nullable override fields for surface,
foreground, secondary foreground, border, action surface, semantic accents,
semantic tints, shadows, title/message/action text styles, glyph/spinner
builders, compact and expanded padding and spacing, icon sizes, action sizes
and styles, seed size, compact minimum height, maximum width, horizontal inset,
radius cap, safe-area use, and vertical offset. Provide:

```dart
typedef CapsuleToastGlyphBuilder = Widget Function(
  BuildContext context,
  CapsuleToastGlyph glyph,
  Color color,
  double size,
);

typedef CapsuleToastSpinnerBuilder = Widget Function(
  BuildContext context,
  Color color,
  double size,
);

const CapsuleToastThemeData({
  this.surfaceColor,
  this.foregroundColor,
  this.secondaryForegroundColor,
  this.borderColor,
  this.borderWidth,
  this.actionSurfaceColor,
  this.accents,
  this.tints,
  this.shadows,
  this.titleTextStyle,
  this.messageTextStyle,
  this.actionTextStyle,
  this.glyphBuilder,
  this.spinnerBuilder,
  this.compactPadding,
  this.expandedPadding,
  this.compactSpacing,
  this.expandedSpacing,
  this.messageSpacing,
  this.actionSpacing,
  this.actionTopSpacing,
  this.seedSize,
  this.compactMinimumHeight,
  this.maximumWidth,
  this.horizontalInset,
  this.radiusCap,
  this.compactIconSize,
  this.expandedIconSize,
  this.compactTitleMaximumWidth,
  this.compactActionHeight,
  this.expandedActionHeight,
  this.compactActionPadding,
  this.primaryActionPadding,
  this.secondaryActionPadding,
  this.compactActionStyle,
  this.primaryActionStyle,
  this.secondaryActionStyle,
  this.useSafeArea,
  this.verticalOffset,
});

factory CapsuleToastThemeData.fallback();
CapsuleToastThemeData copyWith({
  Color? surfaceColor,
  Color? foregroundColor,
  Color? secondaryForegroundColor,
  Color? borderColor,
  double? borderWidth,
  Color? actionSurfaceColor,
  CapsuleToastAccents? accents,
  CapsuleToastTints? tints,
  List<BoxShadow>? shadows,
  TextStyle? titleTextStyle,
  TextStyle? messageTextStyle,
  TextStyle? actionTextStyle,
  CapsuleToastGlyphBuilder? glyphBuilder,
  CapsuleToastSpinnerBuilder? spinnerBuilder,
  EdgeInsetsGeometry? compactPadding,
  EdgeInsetsGeometry? expandedPadding,
  double? compactSpacing,
  double? expandedSpacing,
  double? messageSpacing,
  double? actionSpacing,
  double? actionTopSpacing,
  Size? seedSize,
  double? compactMinimumHeight,
  double? maximumWidth,
  double? horizontalInset,
  double? radiusCap,
  double? compactIconSize,
  double? expandedIconSize,
  double? compactTitleMaximumWidth,
  double? compactActionHeight,
  double? expandedActionHeight,
  EdgeInsetsGeometry? compactActionPadding,
  EdgeInsetsGeometry? primaryActionPadding,
  EdgeInsetsGeometry? secondaryActionPadding,
  ButtonStyle? compactActionStyle,
  ButtonStyle? primaryActionStyle,
  ButtonStyle? secondaryActionStyle,
  bool? useSafeArea,
  double? verticalOffset,
});
CapsuleToastThemeData merge(CapsuleToastThemeData? other);
@override
CapsuleToastThemeData lerp(
  covariant CapsuleToastThemeData? other,
  double t,
);
```

Define `CapsuleToastAccents` with this exact surface:

```dart
const CapsuleToastAccents({
  required this.success,
  required this.information,
  required this.warning,
  required this.error,
  required this.loading,
  required this.neutral,
  required this.custom,
});

final Color success;
final Color information;
final Color warning;
final Color error;
final Color loading;
final Color neutral;
final Color custom;

Color colorFor(CapsuleToastType type);
```

`CapsuleToastTints` has the same seven named fields and
`colorFor(CapsuleToastType type)` exhaustive switch. Both types implement
`copyWith`, static `lerp`, equality, `hashCode`, and diagnostics.

Merge semantics are “non-null values in `other` win”. Resolve in this order:
fallback → `ThemeData.extensions` → nearest `CapsuleToastTheme`; per-toast
overrides are merged by the layer later.

Constructor asserts reject negative padding, spacing, insets, border width,
dimensions, icon sizes, action sizes, and radius cap. Widths and heights must
be greater than zero when supplied; vertical offset may be negative.

- [ ] **Step 4: Implement motion theme values and validation**

Define `CapsuleToastSpring` as:

```dart
@immutable
class CapsuleToastSpring with Diagnosticable {
  const CapsuleToastSpring({
    required this.duration,
    required this.bounce,
  }) : assert(duration > Duration.zero),
       assert(bounce >= 0 && bounce < 1);

  final Duration duration;
  final double bounce;
}
```

Use these motion fallback values:

| Field | Value |
| --- | --- |
| `appearanceDuration` | 140 ms |
| `widthSpring` | 420 ms, bounce 0.16 |
| `heightSpring` | 400 ms, bounce 0.12 |
| `interactiveSpring` | 320 ms, bounce 0.18 |
| `exitSpring` | 300 ms, bounce 0 |
| `reducedMotionSizeDuration` | 240 ms |
| `slotDelays` | icon 0, title 30, message 60, action 90 ms |
| success hold | 2200 ms |
| information hold | 2400 ms |
| warning hold | 3600 ms |
| error hold | 3800 ms |
| neutral hold | 2400 ms |
| loading hold | persistent |
| haptic policy | supported mobile platforms |
| reduced-motion policy | follow system |
| upward velocity threshold | 420 logical pixels/second |
| downward drag resistance | 0.22 |

`CapsuleToastMotionTheme` extends
`ThemeExtension<CapsuleToastMotionTheme>` and has nullable fields with this
exact surface:

```dart
const CapsuleToastMotionTheme({
  this.appearanceDuration,
  this.widthSpring,
  this.heightSpring,
  this.heightLead,
  this.interactiveSpring,
  this.exitSpring,
  this.reducedMotionSizeDuration,
  this.slotRevealDuration,
  this.slotDelays,
  this.successDuration,
  this.informationDuration,
  this.warningDuration,
  this.errorDuration,
  this.neutralDuration,
  this.longPressDuration,
  this.dismissalDistance,
  this.dismissalVelocity,
  this.downwardDragResistance,
  this.hapticPolicy,
  this.reducedMotionPolicy,
});

factory CapsuleToastMotionTheme.fallback();

CapsuleToastMotionTheme copyWith({
  Duration? appearanceDuration,
  CapsuleToastSpring? widthSpring,
  CapsuleToastSpring? heightSpring,
  Duration? heightLead,
  CapsuleToastSpring? interactiveSpring,
  CapsuleToastSpring? exitSpring,
  Duration? reducedMotionSizeDuration,
  Duration? slotRevealDuration,
  Map<CapsuleToastSlot, Duration>? slotDelays,
  Duration? successDuration,
  Duration? informationDuration,
  Duration? warningDuration,
  Duration? errorDuration,
  Duration? neutralDuration,
  Duration? longPressDuration,
  double? dismissalDistance,
  double? dismissalVelocity,
  double? downwardDragResistance,
  CapsuleToastHapticPolicy? hapticPolicy,
  CapsuleToastReducedMotionPolicy? reducedMotionPolicy,
});

Duration? durationFor(CapsuleToastType type);
CapsuleToastMotionTheme merge(CapsuleToastMotionTheme? other);
@override
CapsuleToastMotionTheme lerp(
  covariant CapsuleToastMotionTheme? other,
  double t,
);
```

Motion-theme asserts require positive spring and transition durations,
non-negative slot delays, positive dismissal distance and velocity, and
`downwardDragResistance` in the inclusive range 0–1.

Implement equality, `hashCode`, and diagnostics for both themes and their
nested value types. `CapsuleToastTheme` extends `InheritedTheme`, has a const
constructor with required `data`, optional `motionTheme`, then `child`,
implements `wrap`, and exposes `of`, `maybeOf`, `resolve`, and
`resolveMotion`.

- [ ] **Step 5: Add custom builders and per-toast theme overrides**

Now extend `CapsuleToastData` with nullable `theme`, `motionTheme`,
`compactBuilder`, and `expandedBuilder` fields. Add them to all structured
factories and `copyWith`. Define:

```dart
typedef CapsuleToastContentBuilder = Widget Function(
  BuildContext context,
  CapsuleToastContentContext details,
);

@immutable
class CapsuleToastContentContext {
  const CapsuleToastContentContext({
    required this.toast,
    required this.mode,
    required this.visualTheme,
    required this.motionTheme,
    required this.manager,
    required this.handle,
    required this.constraints,
  });

  final CapsuleToastData toast;
  final CapsuleToastMode mode;
  final CapsuleToastThemeData visualTheme;
  final CapsuleToastMotionTheme motionTheme;
  final CapsuleToastManager manager;
  final CapsuleToastHandle handle;
  final BoxConstraints constraints;
}
```

Change `CapsuleToastData.title` to `String?` and add `CapsuleToastData.custom`.
The custom factory asserts that a missing title has an explicit non-empty
semantic announcement and at least one custom builder. Structured factories
continue to require a non-empty title.

The final `copyWith` signature is:

```dart
CapsuleToastData copyWith({
  CapsuleToastType? type,
  Object? id = _unset,
  Object? title = _unset,
  Object? message = _unset,
  Object? semanticAnnouncement = _unset,
  CapsuleToastMode? initialMode,
  CapsuleToastGlyph? glyph,
  Object? icon = _unset,
  Object? iconBuilder = _unset,
  Object? compactAction = _unset,
  Object? primaryAction = _unset,
  Object? secondaryAction = _unset,
  Object? displayDuration = _unset,
  bool? persistent,
  Object? theme = _unset,
  Object? motionTheme = _unset,
  Object? compactBuilder = _unset,
  Object? expandedBuilder = _unset,
  Object? textDirection = _unset,
});
```

- [ ] **Step 6: Run focused tests and quality checks**

Run:

```bash
dart format lib/src/theme test/theme lib/capsule_toast.dart
flutter analyze
flutter test test/theme/capsule_toast_theme_test.dart
```

Expected: the theme resolution and fallback tests pass.

- [ ] **Step 7: Commit theming**

```bash
git add lib test/theme
git commit -m "feat: add capsule toast themes"
```

---

### Task 4: Build the bounded, interruptible spring engine

**Files:**

- Create: `lib/src/motion/damped_spring.dart`
- Create: `lib/src/motion/capsule_geometry.dart`
- Create: `test/motion/damped_spring_test.dart`

**Interfaces:**

- Consumes: `CapsuleToastSpring` from Task 3.
- Produces:

```dart
final class DampedSpring {
  DampedSpring({required double value});
  double value;
  double velocity;
  double target;
  bool get isSettled;
  void retarget(double target);
  void jumpTo(double value);
  void advance(Duration elapsed, CapsuleToastSpring description);
}

final class CapsuleGeometry {
  final DampedSpring width;
  final DampedSpring height;
  final DampedSpring opacity;
  final DampedSpring verticalOffset;
}
```

- [ ] **Step 1: Write failing deterministic spring tests**

```dart
test('retarget preserves current velocity', () {
  final DampedSpring spring = DampedSpring(value: 84)
    ..retarget(280)
    ..advance(
      const Duration(milliseconds: 80),
      const CapsuleToastSpring(
        duration: Duration(milliseconds: 420),
        bounce: 0.16,
      ),
    );
  final double velocityBeforeRetarget = spring.velocity;

  spring.retarget(180);

  expect(spring.velocity, velocityBeforeRetarget);
  expect(spring.value, isNot(180));
});

test('large frame gaps produce the same bounded integration', () {
  const CapsuleToastSpring description = CapsuleToastSpring(
    duration: Duration(milliseconds: 400),
    bounce: 0.12,
  );
  final DampedSpring largeGap = DampedSpring(value: 34)..retarget(120);
  final DampedSpring clampedGap = DampedSpring(value: 34)..retarget(120);

  largeGap.advance(const Duration(milliseconds: 100), description);
  clampedGap.advance(const Duration(microseconds: 41667), description);

  expect(largeGap.value, closeTo(clampedGap.value, 0.01));
  expect(largeGap.velocity, closeTo(clampedGap.velocity, 0.01));
});

test('a settled spring stops exactly at its target', () {
  final DampedSpring spring = DampedSpring(value: 0)..retarget(100);
  for (int index = 0; index < 300; index += 1) {
    spring.advance(
      const Duration(milliseconds: 4),
      const CapsuleToastSpring(
        duration: Duration(milliseconds: 300),
        bounce: 0,
      ),
    );
  }

  expect(spring.isSettled, isTrue);
  expect(spring.value, 100);
  expect(spring.velocity, 0);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
flutter test test/motion/damped_spring_test.dart
```

Expected: compilation fails because `DampedSpring` is missing.

- [ ] **Step 3: Implement deterministic semi-implicit integration**

Convert the perceptual duration and bounce as follows:

```dart
final double responseSeconds =
    description.duration.inMicroseconds / Duration.microsecondsPerSecond;
final double angularFrequency = 2 * math.pi / responseSeconds;
final double dampingRatio = 1 - description.bounce;
```

Clamp one reported frame gap to 1/24 second, divide it into substeps no larger than
`1 / 240` second, and integrate each substep:

```dart
final double displacement = target - value;
final double acceleration =
    angularFrequency * angularFrequency * displacement -
    2 * dampingRatio * angularFrequency * velocity;
velocity += acceleration * stepSeconds;
value += velocity * stepSeconds;
```

Settle when distance is at most `0.06` logical pixel and absolute velocity is
at most `0.6` logical pixel/second, then snap value to target and velocity to zero.
`retarget` changes only the target. `jumpTo` sets value and target together and
zeros velocity. `CapsuleGeometry` owns four independent springs and exposes
`isSettled`.

- [ ] **Step 4: Run spring tests and analyzer**

Run:

```bash
dart format lib/src/motion test/motion
flutter analyze
flutter test test/motion/damped_spring_test.dart
```

Expected: all spring invariants pass.

- [ ] **Step 5: Commit the spring engine**

```bash
git add lib/src/motion test/motion
git commit -m "feat: add interruptible capsule springs"
```

---

### Task 5: Implement lifecycle state and the pausable hold clock

**Files:**

- Create: `lib/src/motion/lifecycle_clock.dart`
- Create: `lib/src/motion/capsule_lifecycle.dart`
- Create: `test/motion/capsule_lifecycle_test.dart`

**Interfaces:**

- Consumes: `CapsuleToastMode` and `CapsuleToastDismissReason`.
- Produces:

```dart
enum CapsuleLifecycleState {
  hidden,
  seed,
  compact,
  expanded,
  collapsing,
}

final class LifecycleClock {
  void start(Duration duration);
  void pause();
  void resume();
  void reset();
  bool advance(Duration elapsed);
}

final class CapsuleLifecycle {
  CapsuleLifecycleState get state;
  CapsuleToastMode get mode;
  CapsuleToastDismissReason? get pendingDismissal;
  void begin(CapsuleToastMode mode);
  void didAppear();
  void expand();
  void collapse();
  void requestDismiss(CapsuleToastDismissReason reason);
  void didHide();
}
```

- [ ] **Step 1: Write failing transition and clock tests**

```dart
test('lifecycle follows hidden seed compact expanded collapse hidden', () {
  final CapsuleLifecycle lifecycle = CapsuleLifecycle();

  lifecycle.begin(CapsuleToastMode.compact);
  expect(lifecycle.state, CapsuleLifecycleState.seed);
  lifecycle.didAppear();
  expect(lifecycle.state, CapsuleLifecycleState.compact);
  lifecycle.expand();
  expect(lifecycle.state, CapsuleLifecycleState.expanded);
  lifecycle.collapse();
  expect(lifecycle.state, CapsuleLifecycleState.compact);
  lifecycle.requestDismiss(CapsuleToastDismissReason.dismissed);
  expect(lifecycle.state, CapsuleLifecycleState.collapsing);
  lifecycle.didHide();
  expect(lifecycle.state, CapsuleLifecycleState.hidden);
});

test('hold clock excludes paused time', () {
  final LifecycleClock clock = LifecycleClock()
    ..start(const Duration(seconds: 2));

  expect(clock.advance(const Duration(seconds: 1)), isFalse);
  clock.pause();
  expect(clock.advance(const Duration(seconds: 5)), isFalse);
  clock.resume();
  expect(clock.advance(const Duration(seconds: 1)), isTrue);
});
```

- [ ] **Step 2: Run the tests and verify they fail**

Run:

```bash
flutter test test/motion/capsule_lifecycle_test.dart
```

Expected: compilation fails because lifecycle types are missing.

- [ ] **Step 3: Implement explicit legal transitions**

Use exhaustive switch expressions for legal state changes. In debug builds,
invalid calls throw `FlutterError.fromParts` containing the current state,
requested transition, and legal alternatives. In release builds, invalid calls
are safe no-ops. `begin` clears the previous dismissal reason, `requestDismiss`
stores exactly the first reason, and `didHide` resets the lifecycle.

Implement `LifecycleClock` with integer microseconds:

```dart
bool advance(Duration elapsed) {
  if (!_running || _paused || _duration == Duration.zero) {
    return false;
  }
  _elapsed += elapsed;
  return _elapsed >= _duration;
}
```

`start` resets elapsed time. `reset` clears duration, elapsed time, running, and
paused state.

- [ ] **Step 4: Run lifecycle tests and all motion tests**

Run:

```bash
dart format lib/src/motion test/motion
flutter analyze
flutter test test/motion
```

Expected: all lifecycle and spring tests pass.

- [ ] **Step 5: Commit lifecycle behavior**

```bash
git add lib/src/motion test/motion
git commit -m "feat: add capsule toast lifecycle clock"
```

---

### Task 6: Implement queueing, handles, replacement, and completion

**Files:**

- Create: `lib/src/manager/capsule_toast_record.dart`
- Create: `lib/src/manager/capsule_toast_coordinator.dart`
- Modify: `lib/src/model/capsule_toast_handle.dart`
- Create: `test/manager/capsule_toast_coordinator_test.dart`

**Interfaces:**

- Consumes: manager and handle contracts from Task 2.
- Produces:

```dart
final class CapsuleToastRecord {
  final int token;
  CapsuleToastData data;
  CapsuleToastMode desiredMode;
  int revision;
  CapsuleToastDismissReason? pendingDismissal;
  CapsuleToastAction? selectedAction;
  double dismissalVelocity;
  bool get isUnresolved;
  CapsuleToastHandle get handle;
}

final class CapsuleToastCoordinator extends ChangeNotifier
    implements CapsuleToastManager {
  CapsuleToastCoordinator({this.maximumQueueLength = 20});
  CapsuleToastRecord? get active;
  int get queueLength;
  void updateMaximumQueueLength(int value);
  void invokeAction(int token, CapsuleToastAction action);
  void requestDismiss(
    int token,
    CapsuleToastDismissReason reason, {
    double velocity = 0,
  });
  void timeoutActive();
  void finishActiveExit();
  void disposeWithReason(CapsuleToastDismissReason reason);
}
```

- [ ] **Step 1: Write failing FIFO, policy, and handle tests**

```dart
test('enqueue is FIFO and queueLength excludes active', () async {
  final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
  final CapsuleToastHandle first = coordinator.show(
    const CapsuleToastData.neutral(title: 'First'),
  );
  coordinator.show(const CapsuleToastData.neutral(title: 'Second'));
  coordinator.show(const CapsuleToastData.neutral(title: 'Third'));

  expect(coordinator.active!.data.title, 'First');
  expect(coordinator.queueLength, 2);
  first.dismiss();
  coordinator.finishActiveExit();
  expect(coordinator.active!.data.title, 'Second');
});

test('replace completes old handle and retains queued order', () async {
  final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
  final CapsuleToastHandle first = coordinator.show(
    const CapsuleToastData.neutral(title: 'First'),
  );
  coordinator.show(const CapsuleToastData.neutral(title: 'Queued'));
  coordinator.show(
    const CapsuleToastData.error(title: 'Replacement'),
    queuePolicy: CapsuleToastQueuePolicy.replace,
  );

  expect(
    (await first.closed).reason,
    CapsuleToastDismissReason.replaced,
  );
  expect(coordinator.active!.data.title, 'Replacement');
  expect(coordinator.queueLength, 1);
});

test('overflow removes the oldest queued record', () async {
  final CapsuleToastCoordinator coordinator =
      CapsuleToastCoordinator(maximumQueueLength: 1);
  coordinator.show(const CapsuleToastData.neutral(title: 'Active'));
  final CapsuleToastHandle overflowed = coordinator.show(
    const CapsuleToastData.neutral(title: 'Old queued'),
  );
  coordinator.show(const CapsuleToastData.neutral(title: 'New queued'));

  expect(
    (await overflowed.closed).reason,
    CapsuleToastDismissReason.queueOverflow,
  );
  expect(coordinator.queueLength, 1);
});

test('clearAndShow clears queued records and replaces active', () async {
  final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
  final CapsuleToastHandle active = coordinator.show(
    const CapsuleToastData.neutral(title: 'Active'),
  );
  final CapsuleToastHandle queued = coordinator.show(
    const CapsuleToastData.neutral(title: 'Queued'),
  );

  coordinator.show(
    const CapsuleToastData.warning(title: 'Urgent'),
    queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
  );

  expect(
    (await active.closed).reason,
    CapsuleToastDismissReason.replaced,
  );
  expect(
    (await queued.closed).reason,
    CapsuleToastDismissReason.cleared,
  );
  expect(coordinator.active!.data.title, 'Urgent');
  expect(coordinator.queueLength, 0);
});

test('host disposal completes active and queued handles', () async {
  final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
  final CapsuleToastHandle active = coordinator.show(
    const CapsuleToastData.neutral(title: 'Active'),
  );
  final CapsuleToastHandle queued = coordinator.show(
    const CapsuleToastData.neutral(title: 'Queued'),
  );

  coordinator.disposeWithReason(CapsuleToastDismissReason.hostDisposed);

  expect(
    (await active.closed).reason,
    CapsuleToastDismissReason.hostDisposed,
  );
  expect(
    (await queued.closed).reason,
    CapsuleToastDismissReason.hostDisposed,
  );
});

test('completed handles ignore later commands', () async {
  final CapsuleToastCoordinator coordinator = CapsuleToastCoordinator();
  final CapsuleToastHandle handle = coordinator.show(
    const CapsuleToastData.loading(title: 'Loading'),
  );
  coordinator.clear();
  coordinator.finishActiveExit();
  expect(
    (await handle.closed).reason,
    CapsuleToastDismissReason.cleared,
  );

  handle.expand();
  handle.resolve(const CapsuleToastData.success(title: 'Too late'));
  handle.dismiss();

  expect(coordinator.active, isNull);
});
```

- [ ] **Step 2: Run coordinator tests and verify they fail**

Run:

```bash
flutter test test/manager/capsule_toast_coordinator_test.dart
```

Expected: compilation fails because the coordinator and concrete handle
delegate are missing.

- [ ] **Step 3: Implement records and deterministic queue policy**

Give each record a monotonically increasing private integer token. The concrete
handle sends commands back through a private `CapsuleToastHandleDelegate`:

```dart
abstract interface class CapsuleToastHandleDelegate {
  void expand(int token);
  void collapse(int token);
  void resolve(int token, CapsuleToastData toast);
  void dismiss(int token);
}
```

- [ ] **Step 4: Implement coordinator policy and completion rules**

Apply these exact rules:

- With no active record, `show` activates immediately for every policy.
- `enqueue` appends.
- `replace` completes the active result with `replaced`, swaps in the new
  record, and leaves queued records in order.
- `clearAndShow` completes queued records with `cleared`, completes the active
  result with `replaced`, and swaps in the new record.
- On overflow, complete and remove the oldest queued record before appending.
- `clear` completes queued records immediately, marks the active record for
  animated exit, and leaves its future pending until `finishActiveExit`.
- `finishActiveExit` completes the active result with its stored reason, then
  promotes exactly one queued record.
- `updateMaximumQueueLength` preserves the active record and manager identity;
  if the new limit is smaller, it completes oldest queued records with
  `queueOverflow` until the queue satisfies the new limit.
- `resolve` succeeds only for the active loading record, swaps its data in
  place, clears unresolved state, increments `revision`, and preserves the
  handle.
- `expand`, `collapse`, and handle `dismiss` affect only the matching active
  token; handle dismissal delegates to
  `requestDismiss(token, CapsuleToastDismissReason.dismissed)`.
- `timeoutActive` requests `timedOut` for the current active token.
- `requestDismiss` stores the first reason and optional upward velocity so
  later input cannot overwrite an exit already in progress.
- `invokeAction` affects only the matching active token. When dismissal is
  enabled, store `actionSelected` and the selected action before invoking the
  callback. Catch callback errors with `FlutterError.reportError`; do not wait
  for an asynchronous callback before starting dismissal.
- `disposeWithReason(hostDisposed)` completes active and queued records exactly
  once.

- [ ] **Step 5: Run coordinator and model tests**

Run:

```bash
dart format lib/src/manager lib/src/model test/manager
flutter analyze
flutter test test/model test/manager
```

Expected: all model and coordinator tests pass.

- [ ] **Step 6: Commit queueing**

```bash
git add lib/src/manager lib/src/model test/manager
git commit -m "feat: add host-owned capsule toast queue"
```

---

### Task 7: Add the stateful host and private inherited lookup

**Files:**

- Create: `lib/src/host/capsule_toast_host.dart`
- Create: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `lib/capsule_toast.dart`
- Create: `test/support/test_app.dart`
- Create: `test/host/capsule_toast_host_test.dart`

**Interfaces:**

- Consumes: `CapsuleToastCoordinator`, public manager, and theme resolution.
- Produces:

```dart
class CapsuleToastHost extends StatefulWidget {
  const CapsuleToastHost({
    super.key,
    this.maximumQueueLength = 20,
    required this.child,
  }) : assert(maximumQueueLength >= 0);

  final int maximumQueueLength;
  final Widget child;

  static CapsuleToastManager of(BuildContext context);
  static CapsuleToastManager? maybeOf(BuildContext context);
}
```

- [ ] **Step 1: Write failing lookup, ownership, and rebuild tests**

```dart
testWidgets('of returns the nearest host manager', (tester) async {
  late CapsuleToastManager outer;
  late CapsuleToastManager inner;

  await tester.pumpWidget(
    MaterialApp(
      home: CapsuleToastHost(
        child: Builder(
          builder: (BuildContext outerContext) {
            outer = CapsuleToastHost.of(outerContext);
            return CapsuleToastHost(
              child: Builder(
                builder: (BuildContext innerContext) {
                  inner = CapsuleToastHost.of(innerContext);
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    ),
  );

  expect(inner, isNot(same(outer)));
});

testWidgets('of explains how to install a missing host', (tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    Builder(
      builder: (BuildContext value) {
        context = value;
        return const SizedBox();
      },
    ),
  );

  expect(
    () => CapsuleToastHost.of(context),
    throwsA(
      isA<FlutterError>().having(
        (FlutterError error) => error.message,
        'message',
        contains('MaterialApp.builder'),
      ),
    ),
  );
  expect(CapsuleToastHost.maybeOf(context), isNull);
});

testWidgets('toast animation does not rebuild the application child',
    (tester) async {
  int builds = 0;
  late BuildContext commandContext;
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return CapsuleToastHost(child: child!);
      },
      home: Builder(
        builder: (BuildContext context) {
          builds += 1;
          commandContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  CapsuleToastHost.of(commandContext).show(
    const CapsuleToastData.success(title: 'Saved'),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));

  expect(builds, 1);
});
```

- [ ] **Step 2: Run host tests and verify they fail**

Run:

```bash
flutter test test/host/capsule_toast_host_test.dart
```

Expected: compilation fails because `CapsuleToastHost` is missing.

- [ ] **Step 3: Implement state ownership and the stable private scope**

Use `TickerProviderStateMixin`, create one coordinator in `initState`, call
`updateMaximumQueueLength` when the widget value changes in `didUpdateWidget`,
dispose it with `hostDisposed`, and call `super.dispose()` last. The coordinator
and inherited manager identity remain stable for the host state's lifetime.

Build the host as:

```dart
@override
Widget build(BuildContext context) {
  return _CapsuleToastScope(
    manager: _coordinator,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        CapsuleToastLayer(
          coordinator: _coordinator,
          vsync: this,
        ),
      ],
    ),
  );
}
```

`_CapsuleToastScope.updateShouldNotify` returns `false` because the manager
identity never changes. `maybeOf` uses
`dependOnInheritedWidgetOfExactType<_CapsuleToastScope>()`. `of` throws
`FlutterError.fromParts` with an `ErrorSummary`, installation example using
`MaterialApp.builder`, and the offending context.

For this task, `CapsuleToastLayer` listens to the coordinator and renders a
keyed, top-centered `SizedBox` containing the active title. It is replaced by
the production renderer in Tasks 8–9.

- [ ] **Step 4: Run host tests and ensure disposal leaves no callbacks**

Run:

```bash
dart format lib/src/host lib/src/widgets test/host test/support
flutter analyze
flutter test test/host/capsule_toast_host_test.dart
```

Expected: lookup, nesting, rebuild isolation, and disposal tests pass.

- [ ] **Step 5: Commit host ownership**

```bash
git add lib test/host test/support
git commit -m "feat: add inherited capsule toast host"
```

---

### Task 8: Build the measured structured capsule renderer

**Files:**

- Create: `lib/src/widgets/capsule_toast_measure.dart`
- Create: `lib/src/widgets/capsule_toast_surface.dart`
- Create: `lib/src/widgets/capsule_toast_content.dart`
- Create: `lib/src/widgets/capsule_toast_glyph.dart`
- Create: `lib/src/widgets/capsule_toast_action_button.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `test/support/test_app.dart`
- Create: `test/widgets/capsule_toast_content_test.dart`

**Interfaces:**

- Consumes: active record, resolved themes, handle, manager, and live size.
- Produces:

```dart
typedef CapsuleToastSizeChanged = void Function(Size size);

class CapsuleToastMeasure extends SingleChildRenderObjectWidget {
  const CapsuleToastMeasure({
    super.key,
    required this.onSizeChanged,
    super.child,
  });
  final CapsuleToastSizeChanged onSizeChanged;
}

const Key capsuleSurfaceKey =
    ValueKey<String>('capsule_toast.surface');
void noop() {}

Future<BuildContext> pumpToast(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
  bool disableAnimations = false,
  EdgeInsets viewPadding = EdgeInsets.zero,
});
```

- [ ] **Step 1: Write failing structured-layout tests**

```dart
testWidgets('compact content shows glyph title and compact action',
    (tester) async {
  final BuildContext context = await pumpToast(
    tester,
    const CapsuleToastData.success(
      title: 'Saved',
      compactAction: CapsuleToastAction(
        label: 'Undo',
        onPressed: noop,
      ),
    ),
  );

  expect(find.text('Saved'), findsOneWidget);
  expect(find.text('Undo'), findsOneWidget);
  expect(find.byKey(const ValueKey<String>('capsule.success.glyph')),
      findsOneWidget);
  expect(CapsuleToastHost.of(context).queueLength, 0);
});

testWidgets('expanded content shows message and two actions', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.warning(
      title: 'Connection unstable',
      message: 'Changes will sync when the network recovers.',
      initialMode: CapsuleToastMode.expanded,
      primaryAction: CapsuleToastAction(
        label: 'Retry',
        onPressed: noop,
      ),
      secondaryAction: CapsuleToastAction(
        label: 'Dismiss',
        onPressed: noop,
      ),
    ),
  );

  expect(find.text('Changes will sync when the network recovers.'),
      findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
  expect(find.text('Dismiss'), findsOneWidget);
});

testWidgets('compact remains inside a narrow viewport', (tester) async {
  tester.view.physicalSize = const Size(280, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpToast(
    tester,
    const CapsuleToastData.information(
      title: 'A very long title that must be constrained',
    ),
  );

  expect(tester.getSize(find.byKey(capsuleSurfaceKey)).width, lessThan(248));
  expect(tester.takeException(), isNull);
});

testWidgets('surface is placed below the safe-area inset', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.neutral(title: 'Safe'),
    viewPadding: const EdgeInsets.only(top: 44),
  );

  expect(
    tester.getTopLeft(find.byKey(capsuleSurfaceKey)).dy,
    greaterThanOrEqualTo(44),
  );
});

testWidgets('per-toast visual overrides win over ambient theme',
    (tester) async {
  const Color override = Color(0xFF301020);
  await pumpToast(
    tester,
    const CapsuleToastData.neutral(
      title: 'Custom surface',
      theme: CapsuleToastThemeData(surfaceColor: override),
    ),
  );

  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.byKey(const ValueKey<String>('capsule_toast.decoration')),
  );
  expect((box.decoration as BoxDecoration).color, override);
});
```

The shared `pumpToast` helper returns the command context and pumps through the
appearance envelope. Define `noop` as a top-level `void noop() {}` so action
values remain const.

- [ ] **Step 2: Run content tests and verify they fail**

Run:

```bash
flutter test test/widgets/capsule_toast_content_test.dart
```

Expected: tests fail because the production surface, glyphs, and layouts are
missing.

- [ ] **Step 3: Implement measurement and structured rendering**

`CapsuleToastMeasure` reports size from its render object only when the laid-out
size changed, scheduling the callback after the frame. It must not use
intrinsics.

At record activation, resolve both theme extensions as fallback → app
`ThemeData.extensions` → nearest `CapsuleToastTheme` → active toast override.
Re-resolve when dependencies or the active record revision change.

- [ ] **Step 4: Implement the decorated, clipped capsule surface**

Build `CapsuleToastSurface` as a `RepaintBoundary` containing a `DecoratedBox`
keyed `ValueKey<String>('capsule_toast.decoration')` with `BoxDecoration`,
whose content is clipped by `ClipRRect`, using:

```dart
final double radius = math.min(size.height / 2, theme.radiusCap!);
```

Use surface `#161614`, foreground `#F9F9F7`, 7% white border, the two resolved
shadows, and clipping on every frame. Constrain width to:

```dart
math.min(
  theme.maximumWidth!,
  constraints.maxWidth - 2 * theme.horizontalInset!,
)
```

Place the capsule at
`MediaQuery.viewPaddingOf(context).top + theme.verticalOffset!` when
`useSafeArea` is true, otherwise use only the vertical offset. Center it
horizontally with resolved directional insets.

- [ ] **Step 5: Implement structured layouts, glyphs, and actions**

Compact layout uses a `Row` with glyph, one-line ellipsized title, and optional
compact action. Expanded layout uses a leading glyph, a flexible column with
title and wrapping message, then a `Wrap` of primary and secondary actions.
Compact height is a minimum, never a hard height.

Draw default semantic glyphs with `CustomPainter` so status differs by shape:
check, circled “i”, warning triangle, circled cross, connectivity arcs, neutral
dot, and spinner. Port the supplied 20×20 SVG coordinates and stroke widths
directly: check points `(4.2,10.6)→(7.8,14.2)→(15.8,6)`, information/error
circle center `(10,10)` radius `7.6`, warning triangle
`(10,3.1)→(17,15.5)→(3,15.5)`, and connectivity arc paths at y positions
7.6, 10.6, and 13.6. The loading spinner uses a radius 7.2 track at 22% opacity
and a 0.85-second linear revolution. Use theme builders when provided. The
spinner owns a ticker only while loading and visible.

Resolve `CapsuleToastGlyph.automatic` from the semantic type with an exhaustive
switch: success→success, information→information, warning→warning,
error→error, loading→loading, neutral/custom→neutral. An explicit glyph wins;
`iconBuilder` then `icon` win over the resolved package glyph.

`CapsuleToastActionButton` uses `FocusableActionDetector`, `Semantics(button:
true)`, `InkResponse`, and its own gesture arena. Invoke action dismissal before
executing its callback. Use `FlutterError.reportError` for synchronous and
asynchronous callback failures.

- [ ] **Step 6: Run renderer tests**

Run:

```bash
dart format lib/src/widgets test/widgets test/support
flutter analyze
flutter test test/widgets/capsule_toast_content_test.dart
```

Expected: compact, expanded, action, and narrow-layout tests pass.

- [ ] **Step 7: Commit the structured renderer**

```bash
git add lib/src/widgets test/widgets test/support
git commit -m "feat: render measured capsule toast content"
```

---

### Task 9: Integrate ticker-driven geometry and continuous replacement

**Files:**

- Create: `lib/src/motion/capsule_motion_controller.dart`
- Modify: `lib/src/host/capsule_toast_host.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `lib/src/widgets/capsule_toast_surface.dart`
- Modify: `test/support/test_app.dart`
- Create: `test/widgets/capsule_toast_motion_test.dart`

**Interfaces:**

- Consumes: lifecycle, geometry springs, coordinator revisions, measured target
  size, and resolved motion theme.
- Produces:

```dart
final class CapsuleMotionSnapshot {
  final CapsuleLifecycleState state;
  final Size size;
  final double opacity;
  final double verticalOffset;
  final double scale;
  final double contentProgress;
  final bool isSettled;
}

final class CapsuleMotionController extends ChangeNotifier {
  CapsuleMotionController({
    required TickerProvider vsync,
    required CapsuleToastMotionTheme motionTheme,
    required VoidCallback onHoldElapsed,
    required VoidCallback onExitCompleted,
  });
  CapsuleMotionSnapshot get value;
  double get debugWidthVelocity;
  bool get debugHasOvershoot;
  Offset get debugContentTravel;
  void show({required Size target, required CapsuleToastMode mode});
  void retarget(Size target);
  void replace({required Size target, required CapsuleToastMode mode});
  void resolve({required Size target, required CapsuleToastMode mode});
  void expand(Size target);
  void collapse(Size target);
  void dismiss(CapsuleToastDismissReason reason, {double velocity = 0});
  void setInteractionPaused(bool paused);
  void updateMotionTheme(CapsuleToastMotionTheme value);
}

final class ToastTestHarness {
  const ToastTestHarness({
    required this.manager,
    required this.handle,
    required this.motion,
  });
  final CapsuleToastManager manager;
  final CapsuleToastHandle handle;
  final CapsuleMotionController motion;
}

Future<ToastTestHarness> pumpToastHarness(
  WidgetTester tester,
  CapsuleToastData toast, {
  bool settle = true,
  bool disableAnimations = false,
});

Size capsuleSize(WidgetTester tester);
double capsuleOpacity(WidgetTester tester);
CapsuleMotionSnapshot capsuleMotion(WidgetTester tester);
```

- [ ] **Step 1: Write failing phase and interruption tests**

```dart
testWidgets('appearance begins at seed and settles compact', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.success(title: 'Saved'),
    settle: false,
  );

  expect(capsuleSize(tester).width, closeTo(84, 0.5));
  expect(capsuleSize(tester).height, closeTo(34, 0.5));
  await tester.pump(const Duration(milliseconds: 520));
  expect(capsuleSize(tester).height, greaterThanOrEqualTo(44));
});

testWidgets('expand retarget preserves width velocity', (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.information(
      title: 'Syncing',
      message: 'Two files remain.',
    ),
    settle: false,
  );
  await tester.pump(const Duration(milliseconds: 80));
  final double before = harness.motion.debugWidthVelocity;

  harness.handle.expand();
  await tester.pump();

  expect(harness.motion.debugWidthVelocity, before);
});

testWidgets('replace keeps exactly one surface mounted', (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.loading(title: 'Uploading'),
  );
  await tester.pump(const Duration(milliseconds: 180));
  final Element surfaceBefore =
      tester.element(find.byKey(capsuleSurfaceKey));

  harness.manager.show(
    const CapsuleToastData.success(title: 'Uploaded'),
    queuePolicy: CapsuleToastQueuePolicy.replace,
  );
  await tester.pump();

  expect(find.byKey(capsuleSurfaceKey), findsOneWidget);
  expect(
    tester.element(find.byKey(capsuleSurfaceKey)),
    same(surfaceBefore),
  );
});
```

- [ ] **Step 2: Run motion tests and verify they fail**

Run:

```bash
flutter test test/widgets/capsule_toast_motion_test.dart
```

Expected: tests fail because the layer does not yet drive spring geometry.

- [ ] **Step 3: Implement the motion controller and bridge**

Modify `CapsuleToastHostState` to create and own the motion controller in
`didChangeDependencies`, update its theme on subsequent dependency changes,
pass it into `CapsuleToastLayer`, and dispose it before the coordinator. Wire
`onHoldElapsed` to `coordinator.timeoutActive` and `onExitCompleted` to
`coordinator.finishActiveExit`. Create
the ticker lazily on first motion and stop it whenever all springs,
content envelope, and hold clock are idle. Keep one `CapsuleGeometry` instance
for the controller lifetime. Never recreate it on show, replace, resolve,
resize, mode change, theme change, or exit.

- [ ] **Step 4: Implement entrance, retarget, replacement, and exit phases**

Sequence entrance:

1. Jump hidden geometry to the 84×34 seed, opacity 0, vertical offset -8, and
   scale 0.92.
2. Animate opacity, offset, and scale to 1 for 140 ms with `Curves.easeOut`.
3. Retarget width immediately to measured content.
4. Retarget height after the 28 ms height lead.
5. Mark compact/expanded settled only when springs meet their thresholds.
6. Start the hold clock after settlement.

Sequence exit:

1. Reverse content in action, message, title, icon order during the first
   160 ms.
2. At 160 ms, retarget size to the seed with the 300 ms no-bounce spring.
3. At 200 ms, fade to zero and move upward 6 pixels over 140 ms.
4. At 340 ms, mark hidden and call coordinator `finishActiveExit` exactly once.

For replace and resolve, reset content progress, keep current geometry and
velocity, measure the new content offstage, then retarget the same springs.
Expose velocity only as `@visibleForTesting` getters. When a window constraint
changes, call `retarget` without resetting lifecycle or hold progress.

- [ ] **Step 5: Bridge snapshots to the isolated capsule layer**

Drive rendering with an `AnimatedBuilder` around only the positioned capsule
layer:

```dart
return AnimatedBuilder(
  animation: motion,
  child: content,
  builder: (BuildContext context, Widget? child) {
    final CapsuleMotionSnapshot snapshot = motion.value;
    return Positioned(
      top: resolvedTop + snapshot.verticalOffset,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: snapshot.opacity,
        child: Transform.scale(
          scale: snapshot.scale,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox.fromSize(size: snapshot.size, child: child),
          ),
        ),
      ),
    );
  },
);
```

Keep the application child outside this builder. Expose the injected motion
controller from the unexported `CapsuleToastLayer` widget with an
`@visibleForTesting` field so the package's own tests can inspect velocity
without exposing motion internals from the public barrel.

- [ ] **Step 6: Run motion, host, and coordinator tests**

Run:

```bash
dart format lib/src/motion lib/src/widgets test/widgets
flutter analyze
flutter test test/motion test/manager test/host \
  test/widgets/capsule_toast_motion_test.dart
```

Expected: deterministic phase, replacement, and velocity-preservation tests
pass with one surface mounted.

- [ ] **Step 7: Commit continuous motion**

```bash
git add lib/src/motion lib/src/widgets test/widgets
git commit -m "feat: animate one continuous toast capsule"
```

---

### Task 10: Add hold timing, gestures, actions, and loading resolution

**Files:**

- Modify: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `lib/src/motion/capsule_motion_controller.dart`
- Modify: `lib/src/manager/capsule_toast_coordinator.dart`
- Create: `test/widgets/capsule_toast_interaction_test.dart`

**Interfaces:**

- Consumes: motion controller commands, coordinator handle routing, and action
  values.
- Produces: tap, long-press, drag, swipe, hold-pause, action isolation, and
  loading-to-result behavior.

- [ ] **Step 1: Write failing interaction tests**

```dart
testWidgets('tap toggles compact and expanded modes', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.information(
      title: 'Backup ready',
      message: 'Tap to see the backup details.',
    ),
  );
  final double compactHeight = capsuleSize(tester).height;

  await tester.tap(find.byKey(capsuleSurfaceKey));
  await tester.pump(const Duration(milliseconds: 520));
  final double expandedHeight = capsuleSize(tester).height;
  expect(expandedHeight, greaterThan(compactHeight));

  await tester.tap(find.byKey(capsuleSurfaceKey));
  await tester.pump(const Duration(milliseconds: 520));
  expect(capsuleSize(tester).height, closeTo(compactHeight, 1));
});

testWidgets('pressing pauses auto-dismiss', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.success(
      title: 'Saved',
      displayDuration: Duration(seconds: 1),
    ),
  );
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byKey(capsuleSurfaceKey)),
  );
  await tester.pump(const Duration(seconds: 3));
  expect(find.byKey(capsuleSurfaceKey), findsOneWidget);

  await gesture.up();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byKey(capsuleSurfaceKey), findsNothing);
});

testWidgets('elapsed hold completes with timedOut', (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.success(
      title: 'Brief',
      displayDuration: Duration(milliseconds: 100),
    ),
  );

  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));

  expect(
    (await harness.handle.closed).reason,
    CapsuleToastDismissReason.timedOut,
  );
});

testWidgets('handle dismiss completes after the exit animation',
    (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.neutral(title: 'Dismiss me'),
  );

  harness.handle.dismiss();
  expect(harness.handle.isClosed, isFalse);
  await tester.pump(const Duration(milliseconds: 400));

  expect(
    (await harness.handle.closed).reason,
    CapsuleToastDismissReason.dismissed,
  );
});

testWidgets('upward swipe dismisses with swiped result', (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.neutral(title: 'Swipe me'),
  );

  await tester.fling(
    find.byKey(capsuleSurfaceKey),
    const Offset(0, -80),
    900,
  );
  await tester.pumpAndSettle();

  expect(
    (await harness.handle.closed).reason,
    CapsuleToastDismissReason.swiped,
  );
});

testWidgets('loading resolves without replacing its handle', (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.loading(title: 'Uploading'),
  );

  harness.handle.resolve(
    const CapsuleToastData.success(title: 'Uploaded'),
  );
  await tester.pump(const Duration(milliseconds: 520));

  expect(find.text('Uploaded'), findsOneWidget);
  expect(harness.handle.isClosed, isFalse);
  expect(find.byKey(capsuleSurfaceKey), findsOneWidget);
});

testWidgets('keyboard activates the focused action', (tester) async {
  bool invoked = false;
  await pumpToast(
    tester,
    CapsuleToastData.neutral(
      title: 'Keyboard ready',
      compactAction: CapsuleToastAction(
        label: 'Open',
        onPressed: () => invoked = true,
        dismissOnInvoke: false,
      ),
    ),
  );

  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();

  expect(invoked, isTrue);
});

testWidgets('dismissing action is isolated and returned in result',
    (tester) async {
  const CapsuleToastAction action = CapsuleToastAction(
    label: 'Undo',
    onPressed: noop,
  );
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.success(
      title: 'Saved',
      compactAction: action,
    ),
  );
  final double heightBefore = capsuleSize(tester).height;

  await tester.tap(find.text('Undo'));
  await tester.pump(const Duration(milliseconds: 400));
  final CapsuleToastResult result = await harness.handle.closed;

  expect(result.reason, CapsuleToastDismissReason.actionSelected);
  expect(result.action, same(action));
  expect(heightBefore, closeTo(44, 1));
});
```

- [ ] **Step 2: Run interaction tests and verify they fail**

Run:

```bash
flutter test test/widgets/capsule_toast_interaction_test.dart
```

Expected: tap, pause, swipe, and resolve assertions fail.

- [ ] **Step 3: Implement pointer and action behavior**

Use one `RawGestureDetector` around the capsule content so the approved
long-press duration is configurable:

```dart
gestures: <Type, GestureRecognizerFactory>{
  TapGestureRecognizer:
      GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
    TapGestureRecognizer.new,
    (TapGestureRecognizer recognizer) {
      recognizer
        ..onTapDown = (_) => motion.setInteractionPaused(true)
        ..onTapCancel = () => motion.setInteractionPaused(false)
        ..onTapUp = (_) {
          motion.setInteractionPaused(false);
          toggleMode();
        };
    },
  ),
  LongPressGestureRecognizer:
      GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
    () => LongPressGestureRecognizer(
      duration: motionTheme.longPressDuration!,
    ),
    (LongPressGestureRecognizer recognizer) {
      recognizer
        ..onLongPressStart = (_) {
          motion.setInteractionPaused(true);
          expand();
        }
        ..onLongPressEnd = (_) => motion.setInteractionPaused(false);
    },
  ),
  VerticalDragGestureRecognizer:
      GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
    VerticalDragGestureRecognizer.new,
    (VerticalDragGestureRecognizer recognizer) {
      recognizer
        ..onStart = startDrag
        ..onUpdate = updateDrag
        ..onEnd = finishDrag
        ..onCancel = cancelDrag;
    },
  ),
},
```

During drag, upward displacement follows the pointer 1:1 and downward
displacement is multiplied by 0.22. Dismiss when upward displacement exceeds
26 logical pixels or upward velocity exceeds 420 logical pixels/second.
Otherwise retarget to rest with the 320 ms interactive spring. Pass ending
velocity to
`coordinator.requestDismiss(record.token, CapsuleToastDismissReason.swiped,
velocity: velocity)`; the layer then passes the record's stored velocity into
the exit spring.

- [ ] **Step 4: Implement actions, hold timing, resolution, and haptics**

Action buttons must win their own gesture arena and must not toggle or drag the
capsule. Complete dismissing actions with `actionSelected` and retain the
specific `CapsuleToastAction` in `CapsuleToastResult.action`.
Map `ActivateIntent` to action invocation so Enter and Space work on desktop
and web. Make the capsule itself focusable; its `ActivateIntent` toggles mode
when focus is on the surface rather than an action.

Reset content reveal and the post-settlement hold clock after expand, collapse,
or resolve. An explicit `displayDuration` wins; otherwise ask the motion theme
for the semantic default. Persistent records never start a hold clock.

Trigger optional haptics only on Android and iOS when policy is
`supportedPlatforms` and reduced motion is inactive. Call
`HapticFeedback.lightImpact()` once after entrance settlement and once after a
resolved loading toast settles; do not trigger it for expand, collapse, drag,
or exit.

- [ ] **Step 5: Run all interaction-related tests**

Run:

```bash
dart format lib/src/widgets lib/src/motion lib/src/manager test/widgets
flutter analyze
flutter test test/widgets/capsule_toast_interaction_test.dart \
  test/widgets/capsule_toast_motion_test.dart
```

Expected: all interaction, timing, action-isolation, and resolve tests pass.

- [ ] **Step 6: Commit interaction behavior**

```bash
git add lib/src/widgets lib/src/motion lib/src/manager test/widgets
git commit -m "feat: add capsule toast interactions"
```

---

### Task 11: Add custom animated slots, accessibility, RTL, and reduced motion

**Files:**

- Create: `lib/src/widgets/capsule_toast_animated_slot.dart`
- Modify: `lib/src/widgets/capsule_toast_content.dart`
- Modify: `lib/src/widgets/capsule_toast_layer.dart`
- Modify: `lib/src/motion/capsule_motion_controller.dart`
- Modify: `lib/capsule_toast.dart`
- Create: `test/widgets/capsule_toast_accessibility_test.dart`

**Interfaces:**

- Consumes: `CapsuleToastContentContext`, slot delays, content progress, ambient
  `Directionality`, and `MediaQuery.disableAnimations`.
- Produces:

```dart
class CapsuleToastAnimatedSlot extends StatelessWidget {
  const CapsuleToastAnimatedSlot({
    super.key,
    required this.slot,
    required this.child,
  });

  final CapsuleToastSlot slot;
  final Widget child;
}

Widget customCompactBuilder(
  BuildContext context,
  CapsuleToastContentContext details,
) {
  return CapsuleToastAnimatedSlot(
    slot: CapsuleToastSlot.title,
    child: const Text('Custom calendar content'),
  );
}
```

- [ ] **Step 1: Write failing semantics and adaptation tests**

```dart
testWidgets('toast is a live region with a composed label', (tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await pumpToast(
    tester,
    const CapsuleToastData.error(
      title: 'Upload failed',
      message: 'Check the connection.',
    ),
  );

  expect(
    tester.getSemantics(find.byKey(capsuleSurfaceKey)),
    matchesSemantics(
      label: 'Error. Upload failed. Check the connection.',
      liveRegion: true,
      textDirection: TextDirection.ltr,
    ),
  );
});

testWidgets('explicit announcement replaces composed semantics',
    (tester) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  addTearDown(handle.dispose);
  await pumpToast(
    tester,
    CapsuleToastData.custom(
      semanticAnnouncement: 'Calendar updated.',
      compactBuilder: customCompactBuilder,
    ),
  );

  expect(find.bySemanticsLabel('Calendar updated.'), findsOneWidget);
});

testWidgets('RTL mirrors structured order and slot travel', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.information(title: 'تم الحفظ'),
    textDirection: TextDirection.rtl,
  );

  expect(
    tester.getTopRight(find.byKey(const ValueKey('capsule.information.glyph')))
        .dx,
    greaterThan(tester.getTopRight(find.text('تم الحفظ')).dx),
  );
});

testWidgets('reduced motion removes overshoot and directional travel',
    (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.success(title: 'Saved'),
    disableAnimations: true,
  );
  await tester.pump(const Duration(milliseconds: 120));

  expect(harness.motion.debugHasOvershoot, isFalse);
  expect(harness.motion.debugContentTravel, Offset.zero);
});

testWidgets('per-toast reduced-motion policy wins over ambient settings',
    (tester) async {
  final ToastTestHarness harness = await pumpToastHarness(
    tester,
    const CapsuleToastData.success(
      title: 'Reduced by override',
      motionTheme: CapsuleToastMotionTheme(
        reducedMotionPolicy: CapsuleToastReducedMotionPolicy.always,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));

  expect(harness.motion.debugHasOvershoot, isFalse);
  expect(harness.motion.debugContentTravel, Offset.zero);
});

testWidgets('large text expands height without overflowing', (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.warning(
      title: 'Attention',
      message: 'Review the information before continuing.',
      initialMode: CapsuleToastMode.expanded,
    ),
    textScaler: const TextScaler.linear(2),
  );

  expect(tester.takeException(), isNull);
  expect(capsuleSize(tester).height, greaterThan(88));
});

testWidgets('live window resize retargets the mounted surface',
    (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.information(
      title: 'Window-aware notification',
    ),
  );
  final Element surfaceBefore =
      tester.element(find.byKey(capsuleSurfaceKey));

  tester.view.physicalSize = const Size(240, 640);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 520));

  expect(tester.getSize(find.byKey(capsuleSurfaceKey)).width, lessThan(208));
  expect(
    tester.element(find.byKey(capsuleSurfaceKey)),
    same(surfaceBefore),
  );
});
```

- [ ] **Step 2: Run accessibility tests and verify they fail**

Run:

```bash
flutter test test/widgets/capsule_toast_accessibility_test.dart
```

Expected: semantics, RTL, custom slot, reduced-motion, or large-text assertions
fail.

- [ ] **Step 3: Implement adaptive content and semantics**

Wrap each active capsule in one `Semantics` node with `liveRegion: true`.
Exclude duplicate title/message semantics inside it, but leave action button
semantics as explicit child controls. Compose default labels as:

```dart
String composeAnnouncement(CapsuleToastData toast) {
  final String prefix = switch (toast.type) {
    CapsuleToastType.success => 'Success.',
    CapsuleToastType.information => 'Information.',
    CapsuleToastType.warning => 'Warning.',
    CapsuleToastType.error => 'Error.',
    CapsuleToastType.loading => 'Loading.',
    CapsuleToastType.neutral => 'Notice.',
    CapsuleToastType.custom => 'Notice.',
  };
  return <String>[
    prefix,
    if (toast.title case final String title) title,
    if (toast.message case final String message) message,
  ].join(' ');
}
```

An explicit `semanticAnnouncement` replaces the composed label. Keep action
buttons in visual order and semantic focus order.

- [ ] **Step 4: Implement RTL, text scaling, resizing, and reduced motion**

Resolve direction from the toast override, then ambient `Directionality`.
Mirror rows and horizontal slot travel in RTL. Keep the capsule centered.
Resolve reduced motion from `CapsuleToastReducedMotionPolicy`: system reads
`MediaQuery.disableAnimations`, always forces it, never disables it. Reduced
motion uses the 240 ms no-bounce size transition, opacity-only content, no
stretch, no directional travel, and no haptics.

- [ ] **Step 5: Implement animated slots and custom-builder envelopes**

`CapsuleToastAnimatedSlot` reads content progress, direction, reduced-motion
state, and motion theme from a private inherited animation scope installed
around structured and custom content. It maps delays by slot, applies the common
220 ms ease-out interval, and clips through the parent surface. The icon starts
at the capsule center, travels to its measured layout center, scales from 0.92
to 1, and reaches full opacity by progress 0.625. Title and action enter from
10 logical pixels in the directional inline axis; message enters from 8.
Title and message enter from 3 logical pixels below, action from 4. Exit delays
are action 0 ms, message 40 ms, title 90 ms, and icon 100 ms with a 130 ms
normal exit interval or 100 ms reduced-motion interval.

Custom builders receive the exact resolved context from Task 3; use custom
compact or expanded content when supplied, falling back to the structured
renderer for a missing mode.

- [ ] **Step 6: Run adaptation, semantics, and full widget suites**

Run:

```bash
dart format lib test/widgets test/support
flutter analyze
flutter test test/widgets
```

Expected: semantics, RTL, large text, custom content, and reduced-motion tests
all pass.

- [ ] **Step 7: Commit accessibility and extension points**

```bash
git add lib test/widgets test/support
git commit -m "feat: support accessible custom toast content"
```

---

### Task 12: Lock visual and motion fidelity with golden and frame tests

**Files:**

- Create: `test/widgets/capsule_toast_golden_test.dart`
- Modify: `test/widgets/capsule_toast_motion_test.dart`
- Create: `test/goldens/capsule_toast_seed.png`
- Create: `test/goldens/capsule_toast_compact_states.png`
- Create: `test/goldens/capsule_toast_expanded_states.png`
- Create: `test/goldens/capsule_toast_loading_resolve.png`
- Create: `test/goldens/capsule_toast_rtl_large_text.png`
- Create: `test/goldens/capsule_toast_reduced_motion.png`
- Create: `doc/capsule_toast_overview.png`

**Interfaces:**

- Consumes: the complete default renderer and deterministic motion controller.
- Produces: reviewed exact-pixel baselines, fixed phase assertions, and:

```dart
const Key goldenBoundaryKey =
    ValueKey<String>('capsule_toast.golden_boundary');

Future<void> pumpGoldenGrid(
  WidgetTester tester,
  List<CapsuleToastData> toasts,
);
```

- [ ] **Step 1: Add failing golden and phase assertions**

```dart
testWidgets('compact semantic states match the reference', (tester) async {
  await pumpGoldenGrid(
    tester,
    <CapsuleToastData>[
      const CapsuleToastData.success(title: 'Saved'),
      const CapsuleToastData.information(title: 'New information'),
      const CapsuleToastData.warning(title: 'Connection unstable'),
      const CapsuleToastData.error(title: 'Upload failed'),
      const CapsuleToastData.loading(title: 'Uploading'),
      const CapsuleToastData.neutral(title: 'Draft available'),
    ],
  );

  await expectLater(
    find.byKey(goldenBoundaryKey),
    matchesGoldenFile('goldens/capsule_toast_compact_states.png'),
  );
});

testWidgets('reference timestamps have deterministic geometry',
    (tester) async {
  await pumpToast(
    tester,
    const CapsuleToastData.information(
      title: 'Backup ready',
      message: 'Two files were added.',
    ),
    settle: false,
  );
  expect(capsuleSize(tester).width, closeTo(84, 0.5));
  expect(capsuleSize(tester).height, closeTo(34, 0.5));

  await tester.pump(const Duration(milliseconds: 140));
  expect(capsuleOpacity(tester), closeTo(1, 0.02));
  expect(capsuleSize(tester).width, greaterThan(84));

  await tester.pump(const Duration(milliseconds: 380));
  expect(capsuleMotion(tester).isSettled, isTrue);
  expect(tester.binding.transientCallbackCount, 0);
});
```

Add separate golden cases for seed, expanded semantic states, loading→resolve,
RTL plus 2× text, and reduced motion. Use an exact comparator: zero differing
pixels. Fix each test surface to 390×844 logical pixels at device pixel ratio
1 with the application font replaced by Flutter's deterministic test font.

- [ ] **Step 2: Run without baselines and verify missing-golden failures**

Run:

```bash
flutter test test/widgets/capsule_toast_golden_test.dart
```

Expected: tests fail with missing golden files.

- [ ] **Step 3: Generate and inspect the visual baselines**

Run:

```bash
flutter test --update-goldens \
  test/widgets/capsule_toast_golden_test.dart
```

Expected: six PNG baselines are created. Open each image and compare it with the
supplied HTML/React reference at the matching state. Correct source tokens or
layout when a discrepancy is visible, regenerate, and repeat until seed,
capsule radius, spacing, glyphs, actions, shadows, and content hierarchy match.
Copy the reviewed expanded overview with:

```bash
cp test/goldens/capsule_toast_expanded_states.png \
  doc/capsule_toast_overview.png
```

- [ ] **Step 4: Run fidelity tests twice without updating**

Run:

```bash
flutter test test/widgets/capsule_toast_golden_test.dart \
  test/widgets/capsule_toast_motion_test.dart
flutter test test/widgets/capsule_toast_golden_test.dart \
  test/widgets/capsule_toast_motion_test.dart
```

Expected: both runs pass exactly and leave
`tester.binding.transientCallbackCount` at zero after settlement and disposal.

- [ ] **Step 5: Commit reviewed fidelity baselines**

```bash
git add lib test/widgets test/goldens doc
git commit -m "test: lock capsule toast visual fidelity"
```

---

### Task 13: Build the cross-platform example lab

**Files:**

- Create: `example/pubspec.yaml`
- Create: `example/lib/main.dart`
- Create: `example/lib/capsule_toast_lab.dart`
- Create: `example/test/capsule_toast_lab_test.dart`
- Create: generated `example/android/`, `example/ios/`, `example/linux/`,
  `example/macos/`, `example/web/`, and `example/windows/` runners.

**Interfaces:**

- Consumes: only the exported API from `package:capsule_toast/capsule_toast.dart`.
- Produces: a brand-neutral interactive lab for every supported platform.

- [ ] **Step 1: Scaffold the example and write its failing smoke test**

Run:

```bash
flutter create example \
  --project-name capsule_toast_example \
  --platforms=android,ios,linux,macos,web,windows
```

Set the generated `example/pubspec.yaml` dependency to:

```yaml
dependencies:
  capsule_toast:
    path: ../
  flutter:
    sdk: flutter
```

Then replace the generated test with:

```dart
testWidgets('lab demonstrates statuses queue and loading resolution',
    (tester) async {
  await tester.pumpWidget(const CapsuleToastExampleApp());

  expect(find.text('Capsule Toast Lab'), findsOneWidget);
  expect(find.text('Success'), findsOneWidget);
  expect(find.text('Loading → Success'), findsOneWidget);
  expect(find.text('Queue three'), findsOneWidget);
  expect(find.text('RTL'), findsOneWidget);
  expect(find.text('Reduced motion'), findsOneWidget);
  expect(find.text('Custom content'), findsOneWidget);
});
```

- [ ] **Step 2: Run the example smoke test and verify it fails**

Run with `example/` as the working directory:

```bash
flutter test test/capsule_toast_lab_test.dart
```

Expected: compilation fails because `CapsuleToastExampleApp` is not defined.

- [ ] **Step 3: Implement the brand-neutral reference lab**

Use `MaterialApp.builder` exactly:

```dart
builder: (BuildContext context, Widget? child) {
  return CapsuleToastHost(child: child!);
},
```

- [ ] **Step 4: Add semantic, mode, queue, and resolution demonstrations**

Add buttons for all seven semantic factories, compact and expanded initial
modes, a three-item FIFO queue, and loading resolution. Store only the loading
handle that must be resolved:

```dart
final CapsuleToastHandle handle = CapsuleToastHost.of(context).show(
  const CapsuleToastData.loading(title: 'Uploading report'),
);
await Future<void>.delayed(const Duration(seconds: 2));
handle.resolve(
  const CapsuleToastData.success(title: 'Report uploaded'),
);
```

- [ ] **Step 5: Add inspection, adaptation, and customization controls**

Add replay, slow-motion inspection, RTL, reduced motion, visual theme
overrides, motion theme overrides, and structured/custom content controls.
Do not create a controller, navigator key, global manager, or context extension.
Use `Directionality`, `MediaQuery.copyWith(disableAnimations: true)`, and
`CapsuleToastTheme` controls so example behavior exercises the actual package
APIs.

- [ ] **Step 6: Test and analyze the example on the host platform**

Run with `example/` as the working directory:

```bash
flutter pub get
flutter test test/capsule_toast_lab_test.dart
flutter analyze
flutter build web --release
```

Expected: smoke test, analysis, and web compilation pass.

- [ ] **Step 7: Commit the example**

```bash
git add example
git commit -m "feat: add capsule toast example lab"
```

---

### Task 14: Finish documentation, API quality, and pub.dev validation

**Files:**

- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `pubspec.yaml`
- Modify: `lib/capsule_toast.dart`
- Modify: `lib/src/host/capsule_toast_host.dart`
- Modify: `lib/src/manager/capsule_toast_manager.dart`
- Modify: `lib/src/model/capsule_toast_action.dart`
- Modify: `lib/src/model/capsule_toast_data.dart`
- Modify: `lib/src/model/capsule_toast_handle.dart`
- Modify: `lib/src/model/capsule_toast_result.dart`
- Modify: `lib/src/model/capsule_toast_types.dart`
- Modify: `lib/src/theme/capsule_toast_theme.dart`
- Modify: `lib/src/theme/capsule_toast_theme_data.dart`
- Modify: `lib/src/theme/capsule_toast_motion_theme.dart`
- Modify: `lib/src/widgets/capsule_toast_animated_slot.dart`

**Interfaces:**

- Consumes: the complete exported API and reviewed overview image.
- Produces: documented `0.1.0` package ready for `dart pub publish`.

- [ ] **Step 1: Add a public API and documentation smoke test**

Create a temporary consumer test in `test/public_api_test.dart`:

```dart
testWidgets('README setup compiles against the public barrel', (tester) async {
  late BuildContext commandContext;
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return CapsuleToastHost(child: child!);
      },
      home: Builder(
        builder: (BuildContext context) {
          commandContext = context;
          return const SizedBox();
        },
      ),
    ),
  );

  final CapsuleToastHandle handle = CapsuleToastHost.of(commandContext).show(
    const CapsuleToastData.success(title: 'Saved'),
  );
  expect(handle.closed, isA<Future<CapsuleToastResult>>());
});
```

Run:

```bash
flutter test test/public_api_test.dart
```

Expected: the README-level API compiles and the test passes.

- [ ] **Step 2: Write complete package documentation**

Replace the generated README stub with these sections: overview image, features,
installation, `MaterialApp.builder` host setup, `show`, queue policy, handle
commands, loading resolution, actions, visual theme, motion theme, custom
builders and `CapsuleToastAnimatedSlot`, nested hosts, accessibility, platform
support, performance behavior, and API reference. Every code sample must import
only `package:capsule_toast/capsule_toast.dart` and use explicit
`CapsuleToastHost.of(context)`.

- [ ] **Step 3: Finalize changelog and pub.dev presentation metadata**

Set `CHANGELOG.md` to:

```markdown
## 0.1.0

- Initial release with structured and custom capsule content.
- Added interruptible spring motion, FIFO queueing, replacement, and loading
  resolution.
- Added touch, mouse, keyboard, RTL, reduced-motion, and accessibility support.
- Added themes, example lab, deterministic motion tests, and golden coverage.
```

Add the reviewed image to `pubspec.yaml`:

```yaml
screenshots:
  - description: Compact and expanded capsule toast states.
    path: doc/capsule_toast_overview.png
```

- [ ] **Step 4: Audit exported dartdoc, diagnostics, and barrel visibility**

Audit every exported class, constructor, method, typedef, enum, and field for
Flutter-style dartdoc. Add `debugFillProperties` to public widgets and
diagnosticable values. Ensure the barrel exports the public types and no
coordinator, record, render object, lifecycle, or integrator implementation.

- [ ] **Step 5: Run the complete quality gate**

Run:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
dart pub publish --dry-run
```

Then run with `example/` as the working directory:

```bash
flutter analyze
flutter test
```

Expected: formatting is unchanged, both analyzers have no diagnostics, every
unit, widget, semantics, motion, example, and golden test passes, and the
publish dry-run reports no warnings.

- [ ] **Step 6: Inspect the final package surface and repository state**

Run:

```bash
dart doc --validate-links
git status --short
git diff --check
git ls-files | sort
```

Expected: dartdoc has no broken public links, `git diff --check` reports no
whitespace errors, generated build output is absent, and only intentional
package, test, documentation, golden, and example files are present.

- [ ] **Step 7: Commit the pub.dev-ready release**

```bash
git add README.md CHANGELOG.md pubspec.yaml lib test/public_api_test.dart
git commit -m "docs: prepare capsule toast for pub.dev"
```

After the commit, rerun:

```bash
flutter analyze
flutter test
dart pub publish --dry-run
git status --short
```

Expected: all checks pass and the worktree is clean. Do not run
`dart pub publish`; publication remains an explicit user action.
