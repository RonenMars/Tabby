import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Explicit, content-free keyboard diagnostics only.
/// Never include typed text, remote host IDs, or session contents.
class KeyboardTelemetry {
  static void event(String action, {Map<String, Object>? data}) {
    debugPrint('[TabbyKeyboard] $action ${data ?? const {}}');
    if (!Sentry.isEnabled) return;
    Sentry.captureEvent(
      SentryEvent(
        logger: 'tabby.keyboard',
        level: SentryLevel.info,
        message: SentryMessage('keyboard.$action'),
      ),
    );
  }

  static void error(String action, Object error, StackTrace stackTrace) {
    debugPrint('[TabbyKeyboard] $action error=${error.runtimeType}');
    if (!Sentry.isEnabled) return;
    Sentry.captureEvent(
      SentryEvent(
        logger: 'tabby.keyboard',
        level: SentryLevel.error,
        message: SentryMessage('keyboard.$action failed'),
      ),
    );
  }
}
