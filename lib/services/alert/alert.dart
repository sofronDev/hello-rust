/// Rest-timer feedback (sound + vibration) on the web; no-op elsewhere.
library;

export 'alert_stub.dart' if (dart.library.js_interop) 'alert_web.dart';
