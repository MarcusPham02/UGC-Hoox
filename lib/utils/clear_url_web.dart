import 'package:web/web.dart' as web;

/// Replaces the current browser URL with '/' to remove sensitive query params.
void clearSensitiveUrlParams() {
  web.window.history.replaceState(null, '', '/');
}
