# README Enhancement Design

## Goal

Turn the root README into a clearer pub.dev landing page without losing its
value as a practical package guide. A Flutter developer should be able to
understand the package, install the host, and show a first toast within the
opening sections, then progressively discover lifecycle control, queueing,
actions, theming, customization, and accessibility.

## Audience

The primary audience is a Flutter developer evaluating or adopting
`capsule_toast` from pub.dev. Existing users looking up a specific behavior are
the secondary audience.

## Approach

Use a layered README:

1. Establish the package's value and show the animated preview.
2. Lead with key capabilities and a complete quick start.
3. Explain common behavior and configuration in task-oriented sections.
4. Keep advanced theming and builder examples later in the document.
5. End with platform, accessibility, performance, API, project, and license
   references.

This is preferable to a minimal polish pass, which would leave practical gaps,
and to an exhaustive reference manual, which would duplicate generated API
documentation and make first use harder.

## Content Changes

- Sharpen the opening description and add direct pub.dev, API documentation,
  repository, example, changelog, and issue links where they are useful.
- Replace separate installation, setup, and first-show sections with a
  contiguous quick-start path.
- Describe compact and expanded modes, automatic duration, persistent toasts,
  live handle commands, loading resolution, completion results, and queue
  policies with implementation-backed examples.
- Explain the three visual-theme scopes and their precedence: application
  `ThemeData`, nearest `CapsuleToastTheme`, then per-toast overrides.
- Retain dark mode, motion, custom builders, nested hosts, accessibility,
  platform support, and performance guidance while removing repetition.
- Make the public API summary accurate and easy to scan, including
  `CapsuleToastHost.maybeOf` and the exported enum families.

## Accuracy Constraints

- Document only behavior supported by the public entry point
  `package:capsule_toast/capsule_toast.dart`.
- Keep the installation version aligned with `pubspec.yaml`.
- Keep the default queue policy documented as replacement.
- Avoid promising visual parity on every platform; Android and iOS remain the
  stated pixel and motion fidelity targets.
- Avoid generated API detail that is better served by the API documentation.

## Verification

- Re-read every code sample against the public API.
- Check local Markdown links and image paths.
- Run formatting checks against extracted Dart snippets where practical.
- Run `dart pub publish --dry-run` and require zero package warnings.
- Review the final diff for unsupported claims, repetition, placeholders, and
  accidental scope expansion.

## Scope

Only the root `README.md` and this design record are changed. Package source,
public API, examples, metadata, and tests remain unchanged.
