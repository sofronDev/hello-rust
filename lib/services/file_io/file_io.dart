/// Backup file download/upload on the web; unsupported elsewhere.
library;

export 'file_io_stub.dart' if (dart.library.js_interop) 'file_io_web.dart';
