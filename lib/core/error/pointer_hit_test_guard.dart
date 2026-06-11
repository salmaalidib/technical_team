import 'package:flutter/foundation.dart';

/// Workaround for a known Flutter framework behavior on Web/Desktop.
///
/// When a mouse-wheel (or hover) pointer event is hit-tested against an
/// `Overlay`/route child *before* that child's first layout pass completes
/// (e.g. during an instant `NoTransitionPage` route swap, or while a dialog /
/// `DropdownButtonFormField` menu is opening/closing), `RenderBox.hitTest`
/// throws:
///
///   RenderBox was not laid out: _RenderColoredBox … hasSize
///
/// This is a **debug-only `assert`** reported by the *gestures library*. It is
/// non-fatal (the next frame paints correctly) and it never fires in
/// `--profile` / `--release` builds. See:
/// https://github.com/flutter/flutter/issues/133545
///
/// This guard swallows ONLY that specific pointer-hit-test race in debug so it
/// stops spamming the console. Every other error — including real layout
/// "not laid out" errors raised during build/layout (rendering/widgets
/// library) — is forwarded to the previous handler untouched.
void installPointerHitTestErrorGuard() {
  if (!kDebugMode) return;

  final previous = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final isPointerHitTestRace = details.library == 'gestures library' &&
        details.exception.toString().contains('was not laid out');

    if (isPointerHitTestRace) return; // known framework race — ignore in debug

    (previous ?? FlutterError.presentError)(details);
  };
}
