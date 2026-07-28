// Copyright 2026 The Capsule Toast Authors. All rights reserved.

import 'package:capsule_toast/capsule_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Brand-neutral interactive lab for capsule toast APIs.
class CapsuleToastExampleApp extends StatelessWidget {
  /// Creates the example application root.
  const CapsuleToastExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capsule Toast Lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      builder: (BuildContext context, Widget? child) {
        return CapsuleToastHost(child: child!);
      },
      home: const CapsuleToastLabPage(),
    );
  }
}

/// Interactive controls that exercise toast semantics, motion, and queueing.
class CapsuleToastLabPage extends StatefulWidget {
  /// Creates the lab page.
  const CapsuleToastLabPage({super.key});

  @override
  State<CapsuleToastLabPage> createState() => _CapsuleToastLabPageState();
}

class _CapsuleToastLabPageState extends State<CapsuleToastLabPage> {
  bool _rtl = false;
  bool _reducedMotion = false;
  bool _slowMotion = false;
  bool _visualThemeOverride = false;
  bool _motionThemeOverride = false;
  CapsuleToastData? _lastToast;

  CapsuleToastManager _manager(BuildContext context) {
    return CapsuleToastHost.of(context);
  }

  void _rememberAndShow(
    BuildContext context,
    CapsuleToastData toast, {
    CapsuleToastQueuePolicy queuePolicy = CapsuleToastQueuePolicy.enqueue,
  }) {
    _lastToast = toast;
    _manager(context).show(toast, queuePolicy: queuePolicy);
  }

  Future<void> _showLoadingResolution(BuildContext context) async {
    final CapsuleToastHandle handle = _manager(
      context,
    ).show(CapsuleToastData.loading(title: 'Uploading report'));
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }
    handle.resolve(CapsuleToastData.success(title: 'Report uploaded'));
    _lastToast = CapsuleToastData.loading(title: 'Uploading report');
  }

  void _queueThree(BuildContext context) {
    _rememberAndShow(
      context,
      CapsuleToastData.information(title: 'First queued toast'),
    );
    _rememberAndShow(
      context,
      CapsuleToastData.information(title: 'Second queued toast'),
    );
    _rememberAndShow(
      context,
      CapsuleToastData.information(title: 'Third queued toast'),
    );
  }

  void _replayLast(BuildContext context) {
    final CapsuleToastData? toast = _lastToast;
    if (toast == null) {
      _rememberAndShow(
        context,
        CapsuleToastData.neutral(title: 'Nothing to replay yet'),
      );
      return;
    }
    _rememberAndShow(context, toast);
  }

  void _toggleSlowMotion(bool value) {
    setState(() {
      _slowMotion = value;
      timeDilation = value ? 4.0 : 1.0;
    });
  }

  CapsuleToastThemeData get _labVisualTheme {
    final CapsuleToastThemeData base = CapsuleToastThemeData.fallback();
    final CapsuleToastAccents accents = base.accents!;
    return base.copyWith(
      surfaceColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      accents: accents.copyWith(
        success: const Color(0xFF4ADE80),
        information: const Color(0xFF38BDF8),
      ),
    );
  }

  CapsuleToastMotionTheme get _labMotionTheme {
    final CapsuleToastMotionTheme base = CapsuleToastMotionTheme.fallback();
    final CapsuleToastSpring width = base.widthSpring!;
    return base.copyWith(
      appearanceDuration: const Duration(milliseconds: 280),
      widthSpring: width.copyWith(
        duration: Duration(milliseconds: width.duration.inMilliseconds * 2),
      ),
      reducedMotionPolicy: CapsuleToastReducedMotionPolicy.never,
    );
  }

  @override
  void dispose() {
    if (_slowMotion) {
      timeDilation = 1.0;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Scaffold(
      appBar: AppBar(title: const Text('Capsule Toast Lab')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _sectionTitle('Semantic statuses'),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Success',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.success(
                    title: 'Changes saved',
                    message: 'Your draft is stored locally.',
                  ),
                ),
              ),
              _labButton(
                label: 'Information',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.information(
                    title: 'Sync scheduled',
                    message: 'Updates run in the background.',
                  ),
                ),
              ),
              _labButton(
                label: 'Warning',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.warning(
                    title: 'Connection unstable',
                    message: 'Retrying automatically.',
                  ),
                ),
              ),
            ]),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Error',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.error(
                    title: 'Upload failed',
                    message: 'Check your network and try again.',
                  ),
                ),
              ),
              _labButton(
                label: 'Loading',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.loading(title: 'Working…'),
                ),
              ),
              _labButton(
                label: 'Neutral',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.neutral(title: 'Reminder set'),
                ),
              ),
            ]),
            _sectionTitle('Layout modes'),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Compact',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.information(
                    title: 'Compact capsule',
                    initialMode: CapsuleToastMode.compact,
                  ),
                ),
              ),
              _labButton(
                label: 'Expanded',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.information(
                    title: 'Expanded capsule',
                    message: 'Additional detail appears in expanded layout.',
                    initialMode: CapsuleToastMode.expanded,
                    primaryAction: const CapsuleToastAction(
                      label: 'Details',
                      onPressed: _noopAction,
                    ),
                  ),
                ),
              ),
            ]),
            _sectionTitle('Queue and resolution'),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Queue three',
                onPressed: () => _queueThree(context),
              ),
              _labButton(
                label: 'Loading → Success',
                onPressed: () => _showLoadingResolution(context),
              ),
              _labButton(
                label: 'Clear queue',
                onPressed: () => _manager(context).clear(),
              ),
            ]),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Replace active',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.warning(title: 'Replaced toast'),
                  queuePolicy: CapsuleToastQueuePolicy.replace,
                ),
              ),
              _labButton(
                label: 'Clear and show',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.neutral(title: 'Fresh toast only'),
                  queuePolicy: CapsuleToastQueuePolicy.clearAndShow,
                ),
              ),
            ]),
            _sectionTitle('Inspection and adaptation'),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Replay last',
                onPressed: () => _replayLast(context),
              ),
              _labButton(
                label: 'Slow motion',
                onPressed: () => _toggleSlowMotion(!_slowMotion),
                selected: _slowMotion,
              ),
            ]),
            SwitchListTile(
              title: const Text('RTL'),
              value: _rtl,
              onChanged: (bool value) => setState(() => _rtl = value),
            ),
            SwitchListTile(
              title: const Text('Reduced motion'),
              value: _reducedMotion,
              onChanged: (bool value) => setState(() => _reducedMotion = value),
            ),
            SwitchListTile(
              title: const Text('Visual theme override'),
              value: _visualThemeOverride,
              onChanged: (bool value) =>
                  setState(() => _visualThemeOverride = value),
            ),
            SwitchListTile(
              title: const Text('Motion theme override'),
              value: _motionThemeOverride,
              onChanged: (bool value) =>
                  setState(() => _motionThemeOverride = value),
            ),
            _sectionTitle('Structured and custom content'),
            _buttonRow(<Widget>[
              _labButton(
                label: 'Structured',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.information(
                    title: 'Structured toast',
                    message: 'Message, glyph, and action regions.',
                    compactAction: const CapsuleToastAction(
                      label: 'Undo',
                      onPressed: _noopAction,
                    ),
                  ),
                ),
              ),
              _labButton(
                label: 'Custom content',
                onPressed: () => _rememberAndShow(
                  context,
                  CapsuleToastData.custom(
                    semanticAnnouncement: 'Custom capsule content',
                    compactBuilder: _customCompactContent,
                    expandedBuilder: _customExpandedContent,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );

    if (_visualThemeOverride || _motionThemeOverride) {
      child = CapsuleToastTheme(
        data: _visualThemeOverride
            ? _labVisualTheme
            : CapsuleToastThemeData.fallback(),
        motionTheme: _motionThemeOverride ? _labMotionTheme : null,
        child: child,
      );
    }

    if (_reducedMotion) {
      child = MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child,
      );
    }

    if (_rtl) {
      child = Directionality(textDirection: TextDirection.rtl, child: child);
    }

    return child;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buttonRow(List<Widget> children) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }

  Widget _labButton({
    required String label,
    required VoidCallback onPressed,
    bool selected = false,
  }) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: selected
          ? FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            )
          : null,
      child: Text(label),
    );
  }

  static Future<void> _noopAction() async {}

  static Widget _customCompactContent(
    BuildContext context,
    CapsuleToastContentContext details,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.auto_awesome, color: details.visualTheme.accents!.custom),
          const SizedBox(width: 12),
          Text(
            'Custom compact builder',
            style: details.visualTheme.titleTextStyle,
          ),
        ],
      ),
    );
  }

  static Widget _customExpandedContent(
    BuildContext context,
    CapsuleToastContentContext details,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Custom expanded builder',
            style: details.visualTheme.titleTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Compose any widget tree inside the morphing capsule.',
            style: details.visualTheme.messageTextStyle,
          ),
        ],
      ),
    );
  }
}
