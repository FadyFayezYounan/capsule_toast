// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capsule_toast/capsule_toast.dart';

import '../support/test_app.dart';

/// Renders the settled capsule to pixels.
///
/// Once geometry and the content reveal have come to rest, the spinner is the
/// only thing left that can change, so two captures differing is proof it is
/// turning.
Future<Uint8List> _captureCapsule(WidgetTester tester) async {
  final RenderRepaintBoundary boundary = tester
      .renderObject<RenderRepaintBoundary>(
        find
            .descendant(
              of: find.byKey(capsuleSurfaceKey),
              matching: find.byType(RepaintBoundary),
            )
            .first,
      );
  late Uint8List bytes;
  // Rasterising is genuinely asynchronous, so it has to escape the fake clock.
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}

void main() {
  testWidgets('loading spinner keeps turning after the capsule settles', (
    WidgetTester tester,
  ) async {
    await pumpToast(tester, CapsuleToastData.loading(title: 'Uploading'));
    // Well past the 520ms settle, so springs and slot reveals are done.
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey<String>('capsule.loading.glyph')),
      findsOneWidget,
    );

    final Uint8List first = await _captureCapsule(tester);
    // A quarter of the 850ms rotation — far enough that the arc has visibly
    // moved regardless of where in the cycle the first capture landed.
    await tester.pump(const Duration(milliseconds: 210));
    final Uint8List second = await _captureCapsule(tester);

    expect(first, isNot(equals(second)));
  });

  testWidgets('non-loading glyphs are static', (WidgetTester tester) async {
    await pumpToast(tester, CapsuleToastData.success(title: 'Saved'));
    await tester.pump(const Duration(milliseconds: 600));

    final Uint8List first = await _captureCapsule(tester);
    await tester.pump(const Duration(milliseconds: 210));
    final Uint8List second = await _captureCapsule(tester);

    expect(first, equals(second));
  });

  testWidgets('custom loading spinner does not start the built-in ticker', (
    WidgetTester tester,
  ) async {
    await pumpToast(
      tester,
      CapsuleToastData.loading(
        title: 'Custom loading',
        theme: CapsuleToastThemeData(
          spinnerBuilder: (BuildContext context, Color color, double size) {
            return SizedBox(
              key: const ValueKey<String>('custom-spinner'),
              width: size,
              height: size,
            );
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey<String>('custom-spinner')),
      findsOneWidget,
    );
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('a null size falls back to the glyph optical default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.warning,
          color: const Color(0xFF101010),
          theme: CapsuleToastThemeData.fallback(),
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('capsule.warning.glyph')),
      ),
      const Size(17, 17),
    );
  });

  testWidgets('an explicit size overrides the optical default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Center(
        child: CapsuleToastGlyphIcon(
          glyph: CapsuleToastGlyph.warning,
          color: const Color(0xFF101010),
          size: 24,
          theme: CapsuleToastThemeData.fallback(),
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('capsule.warning.glyph')),
      ),
      const Size(24, 24),
    );
  });
}
