# capsule_toast

Morphing capsule notifications for Flutter, with interruptible spring motion,
explicit queueing, live lifecycle controls, and app-level or per-toast theming.

![Capsule toast morphing between compact and expanded states](https://raw.githubusercontent.com/FadyFayezYounan/capsule_toast/main/doc/preview.gif)

[Package](https://pub.dev/packages/capsule_toast) ·
[API documentation](https://pub.dev/documentation/capsule_toast/latest/) ·
[Example](https://github.com/FadyFayezYounan/capsule_toast/tree/main/example) ·
[Repository](https://github.com/FadyFayezYounan/capsule_toast)

## Why capsule_toast?

- Top-center capsules that morph between compact and expanded layouts
- Success, information, warning, error, loading, neutral, and custom content
- Replace, FIFO enqueue, and clear-and-show queue policies
- Live expand, collapse, resolve, and dismiss commands
- Visual and motion themes that follow the host application's brightness
- Touch, mouse, keyboard, RTL, large-text, safe-area, and reduced-motion support
- Independent nested hosts instead of a global singleton or navigator key

## Quick start

Add the package:

```yaml
dependencies:
  capsule_toast: ^1.1.1
```

```bash
flutter pub get
```

Install one `CapsuleToastHost` through `MaterialApp.builder`:

```dart
import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (BuildContext context, Widget? child) {
        return CapsuleToastHost(child: child!);
      },
      home: const HomePage(),
    );
  }
}
```

Then look up the nearest host and show a toast:

```dart
void onSaved(BuildContext context) {
  CapsuleToastHost.of(context).show(
    CapsuleToastData.success(title: 'Saved'),
  );
}
```

`CapsuleToastHost.of(context)` throws a descriptive `FlutterError` when no host
is installed. Use `CapsuleToastHost.maybeOf(context)` when the host is optional.
There is no global manager, navigator key, or `BuildContext` extension.

## Toast content and layout

`CapsuleToastData` provides these semantic factories:

| Factory | Intended use | Default lifetime |
|---|---|---|
| `success` | Completed successfully | Timed |
| `information` | Informational feedback | Timed |
| `warning` | Cautionary feedback | Timed |
| `error` | Failed operation | Timed |
| `loading` | Work in progress | Persistent |
| `neutral` | Feedback without a semantic accent | Timed |
| `custom` | Caller-defined content | Timed |

Structured factories require a title and can also receive a message, semantic
announcement, glyph or custom icon, actions, visual and motion overrides, and
mode-specific builders.

To start with the full message and expanded actions visible, set
`initialMode`:

```dart
CapsuleToastHost.of(context).show(
  CapsuleToastData.warning(
    title: 'Connection is unstable',
    message: 'Changes will sync when the connection recovers.',
    initialMode: CapsuleToastMode.expanded,
  ),
);
```

Users can tap the capsule or activate it from the keyboard to toggle its mode;
a long press expands it. Code can control the same state through the returned
handle.

Some toasts have nothing meaningful to show in one of the two layouts — a
brief success toast with no message has nothing to reveal when expanded. Set
`expansionPolicy` to lock the toast to one layout for its lifetime:

```dart
CapsuleToastData.success(
  title: 'Saved',
  expansionPolicy: CapsuleToastExpansionPolicy.compactOnly,
);
```

`CapsuleToastExpansionPolicy.compactOnly` and `.expandedOnly` disable tap,
long-press, and `CapsuleToastHandle.expand()`/`collapse()` for as long as
that toast's content is showing. The default, `.adaptive`, is today's
toggle-between-both behavior. A restricted toast's `initialMode` must match
its policy (`compactOnly` requires `CapsuleToastMode.compact`,
`expandedOnly` requires `CapsuleToastMode.expanded`) — a mismatch throws in
debug mode. Resolving a `loading` toast into a different outcome is
unaffected: the resolved toast's own `expansionPolicy` takes over
immediately, regardless of what the loading toast's policy was.

## Duration and persistence

Non-persistent toasts use the default duration for their semantic type. Supply
`displayDuration` to override it:

```dart
CapsuleToastData.information(
  title: 'Copied',
  displayDuration: const Duration(seconds: 2),
);
```

Set `persistent: true` when a toast must remain until it is dismissed or
resolved. A persistent toast cannot also define `displayDuration`. Loading
toasts are persistent by default.

Interaction pauses the visible hold timer while the pointer is down or hovering
over the capsule.

## Queue policies

The default policy is `CapsuleToastQueuePolicy.replace`: showing a new toast
replaces the active one. Choose `enqueue` explicitly when events must wait in
FIFO order.

```dart
final CapsuleToastManager manager = CapsuleToastHost.of(context);

manager.show(
  CapsuleToastData.information(title: 'Queued'),
  queuePolicy: CapsuleToastQueuePolicy.enqueue,
);

manager.show(
  CapsuleToastData.warning(title: 'Replaces active'),
  queuePolicy: CapsuleToastQueuePolicy.replace,
);

manager.show(
  CapsuleToastData.error(title: 'Clears queue first'),
  queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
);

manager.clear();
```

`manager.queueLength` counts records waiting behind the active toast.
`CapsuleToastHost(maximumQueueLength: ...)` limits that waiting queue and
defaults to 20. When a full queue receives another enqueue, its oldest waiting
record completes with `CapsuleToastDismissReason.queueOverflow`; a capacity of
zero rejects every waiting record with the same reason.

`clear()` completes queued records with `cleared` and starts the active toast's
exit.

## Live handles and results

`show` returns a `CapsuleToastHandle` tied to that record:

```dart
final CapsuleToastHandle handle = CapsuleToastHost.of(context).show(
  CapsuleToastData.information(
    id: 'sync-status',
    title: 'Details available',
  ),
);

handle.expand();
handle.collapse();

if (!handle.isClosed) {
  handle.dismiss();
}

final CapsuleToastResult result = await handle.closed;
```

`closed` completes exactly once and reports why the record ended. Reasons
include timeout, explicit dismissal, swipe, action selection, replacement,
queue clearing, queue overflow, and host disposal. When an action dismissed
the toast, `result.action` contains that `CapsuleToastAction`.

Commands issued after a handle closes are ignored.

## Loading resolution

Resolve an in-progress toast into terminal content without creating a second
record or changing its handle. This is the common "show a loading capsule,
then morph it into success or error" flow:

```dart
Future<void> uploadAndNotify(BuildContext context) async {
  final CapsuleToastHandle handle = CapsuleToastHost.of(context).show(
    CapsuleToastData.loading(
      id: 'upload',
      title: 'Uploading',
    ),
  );

  try {
    await uploadFile();
    handle.resolve(CapsuleToastData.success(title: 'Uploaded'));
  } catch (_) {
    handle.resolve(CapsuleToastData.error(title: 'Upload failed'));
  }
}
```

Only an unresolved loading record can be resolved. The same handle keeps
working afterwards — `expand()`, `collapse()`, `dismiss()`, and
`handle.closed` all still apply to the resolved toast. The new toast data
supplies the resolved record's type, content, lifetime, and presentation;
`CapsuleToastData.loading` is persistent by default, so the capsule stays up
exactly until you resolve or dismiss it.

The [interactive example](https://github.com/FadyFayezYounan/capsule_toast/tree/main/example)'s
"Loading" variant demonstrates the same flow end to end, chaining
`CapsuleToastData.loading` into `CapsuleToastData.success` after a simulated
delay.

## Actions

Compact content can show one action. Expanded content can show primary and
secondary actions:

```dart
CapsuleToastHost.of(context).show(
  CapsuleToastData.information(
    title: 'Draft ready',
    compactAction: CapsuleToastAction(
      label: 'Open',
      onPressed: () {
        // Open the draft.
      },
    ),
    primaryAction: CapsuleToastAction(
      label: 'Review',
      onPressed: () async {
        await openReview();
      },
    ),
    secondaryAction: CapsuleToastAction(
      label: 'Keep editing',
      onPressed: () {},
      dismissOnInvoke: false,
    ),
  ),
);
```

Actions dismiss after invocation by default. Set `dismissOnInvoke: false` to
keep the toast open. `onPressed` accepts either synchronous or asynchronous
callbacks; use `semanticLabel` when the visible label is not sufficient for
assistive technology.

## Visual theming

Visual overrides can be applied at three scopes. Later scopes take precedence:

1. `CapsuleToastThemeData` in `ThemeData.extensions`
2. The nearest `CapsuleToastTheme`
3. `CapsuleToastData.theme` on one toast

Use a `ThemeData` extension for an application-wide override:

```dart
ThemeData(
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData(
      surfaceColor: const Color(0xFF1E293B),
      foregroundColor: const Color(0xFFF8FAFC),
    ),
  ],
);
```

Use `CapsuleToastTheme` for one subtree:

```dart
CapsuleToastTheme(
  data: CapsuleToastThemeData(
    surfaceColor: const Color(0xFF1E293B),
    foregroundColor: const Color(0xFFF8FAFC),
  ),
  child: child,
);
```

Or customize a single toast:

```dart
CapsuleToastData.success(
  title: 'Published',
  theme: CapsuleToastThemeData(
    surfaceColor: const Color(0xFF052E16),
  ),
);
```

Partial themes merge over the resolved defaults, so only specify the tokens you
want to change. Fonts inherit from the application; the package does not bundle
typefaces.

## Light and dark appearances

The built-in appearance follows `Theme.of(context).brightness`. An application
with both `theme` and `darkTheme` needs no package-specific switching:

```dart
MaterialApp(
  theme: ThemeData(brightness: Brightness.light),
  darkTheme: ThemeData(brightness: Brightness.dark),
  builder: (BuildContext context, Widget? child) {
    return CapsuleToastHost(child: child!);
  },
  home: const HomePage(),
);
```

The light appearance uses a near-black overlay. The dark appearance lifts the
capsule above dark surfaces with a brighter rim and stronger status tints.
Geometry, typography, timings, and springs are shared.

To pin one built-in appearance regardless of app brightness, register its whole
fallback:

```dart
ThemeData(
  brightness: Brightness.dark,
  extensions: <ThemeExtension<dynamic>>[
    CapsuleToastThemeData.fallback(Brightness.light),
  ],
);
```

## Motion theming

`CapsuleToastMotionTheme` controls springs, durations, reveal delays, gesture
thresholds, haptics, and reduced motion. It follows the same application and
subtree scopes as the visual theme, and can also be supplied per toast.

```dart
CapsuleToastTheme(
  data: CapsuleToastThemeData.fallback(),
  motionTheme: CapsuleToastMotionTheme.fallback().copyWith(
    reducedMotionPolicy: CapsuleToastReducedMotionPolicy.system,
    hapticPolicy: CapsuleToastHapticPolicy.supportedPlatforms,
  ),
  child: child,
);
```

The default reduced-motion policy follows `MediaQuery.disableAnimations`.
Choose `always` or `never` when the application requires an explicit policy.

## Custom builders and animated slots

`CapsuleToastData.custom` accepts mode-specific builders. The builder context
exposes the current toast, mode, resolved themes, manager, handle, and layout
constraints.

```dart
CapsuleToastHost.of(context).show(
  CapsuleToastData.custom(
    title: 'Custom capsule',
    compactBuilder: (BuildContext context, CapsuleToastContentContext details) {
      return CapsuleToastAnimatedSlot(
        slot: CapsuleToastSlot.title,
        child: Text(details.toast.title!),
      );
    },
    expandedBuilder: (BuildContext context, CapsuleToastContentContext details) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CapsuleToastAnimatedSlot(
            slot: CapsuleToastSlot.title,
            child: Text(details.toast.title!),
          ),
          const CapsuleToastAnimatedSlot(
            slot: CapsuleToastSlot.message,
            child: Text('Expanded custom body'),
          ),
        ],
      );
    },
  ),
);
```

`CapsuleToastAnimatedSlot` applies the package's staggered reveal and retract
timing. When only one mode-specific builder is supplied, the other mode falls
back to the structured content generated from the toast data.

For a custom structured glyph, use `icon`, `iconBuilder`, or the exported
`CapsuleToastGlyphIcon`.

## Nested hosts

Each `CapsuleToastHost` owns its queue, handles, lifecycle clock, and ticker.
Use one host near the app root for most applications. Nest another host only
when a subtree needs a separate toast layer and independent queue.

Lookup always resolves to the nearest host.

## Accessibility and input

- Structured content and custom content expose semantic announcements
- The capsule and its actions support keyboard focus and activation
- Travel, layout, and dismissal gestures mirror for RTL
- Reduced-motion policy can follow the platform preference
- Large text scales and safe-area insets are supported
- Hold timing pauses during pointer interaction

Keep titles short, provide `semanticAnnouncement` for custom content when the
visible title is insufficient, and give ambiguous actions a `semanticLabel`.

## Platform support

The package supports Android, iOS, web, Windows, macOS, and Linux. Android and
iOS are the pixel and motion fidelity targets.

## Performance behavior

Each host renders at most one top-center capsule. Geometry uses deterministic,
bounded-step springs that preserve position and velocity when the target
changes. Avoid heavy synchronous work inside custom builders and action
callbacks.

## Public API

Import the package through:

```dart
import 'package:capsule_toast/capsule_toast.dart';
```

| API | Role |
|---|---|
| `CapsuleToastHost` | Owns the layer and resolves the nearest manager |
| `CapsuleToastManager` | Shows, clears, and reports queued records |
| `CapsuleToastData` | Configures structured or custom toast content |
| `CapsuleToastAction` | Describes a synchronous or asynchronous action |
| `CapsuleToastHandle` | Controls one live record and exposes its result |
| `CapsuleToastResult` | Reports the dismissal reason and selected action |
| `CapsuleToastTheme` | Applies visual and motion overrides to a subtree |
| `CapsuleToastThemeData` | Defines visual tokens and glyph builders |
| `CapsuleToastMotionTheme` | Defines timing, springs, gestures, and policies |
| `CapsuleToastSpring` | Defines duration and bounce for one spring |
| `CapsuleToastAnimatedSlot` | Applies staggered motion to custom content |
| `CapsuleToastGlyphIcon` | Renders the package's structured glyphs |
| `CapsuleToastType`, `CapsuleToastMode`, `CapsuleToastQueuePolicy` | Define semantics, layout, and queue behavior |
| `CapsuleToastExpansionPolicy` | Locks a toast to compact-only or expanded-only layout |
| `CapsuleToastGlyph`, `CapsuleToastSlot` | Define glyph selection and animated regions |
| `CapsuleToastDismissReason` | Describes how a record ended |
| `CapsuleToastReducedMotionPolicy`, `CapsuleToastHapticPolicy` | Configure interaction policies |

See the
[generated API documentation](https://pub.dev/documentation/capsule_toast/latest/)
for every constructor and property.

## Project resources

- [Interactive example](https://github.com/FadyFayezYounan/capsule_toast/tree/main/example)
- [Changelog](CHANGELOG.md)
- [Issue tracker](https://github.com/FadyFayezYounan/capsule_toast/issues)
- [Source repository](https://github.com/FadyFayezYounan/capsule_toast)

## License

BSD 3-Clause. See [LICENSE](LICENSE). Copyright 2026 The Capsule Toast Authors.

## Performance

`capsule_toast` performs zero per-frame work when idle — no tickers, no
timers, no rebuild propagation — and its only permanent cost is a single
overlay layer. Regression guards and frame-time benchmarks verify this
continuously. See [doc/performance.md](doc/performance.md) for the full
contract, the per-host object inventory, and how to run the benchmarks.
