// Debug logging helper - conditional export
// Web: uses dart:js_interop
// Non-web: no-op stub
export 'debug_log_stub.dart'
    if (dart.library.js_interop) 'debug_log_web.dart';
