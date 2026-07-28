// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:flutter/material.dart';

import 'package:capsule_toast/capsule_toast.dart';

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
