// Debug logging helper for Flutter Web
// Sends NDJSON logs to local debug server
import 'dart:convert';
import 'dart:js_interop';

const _endpoint = 'http://127.0.0.1:7245/ingest/74894142-ce94-490e-8342-8da5c541f01a';

@JS('globalThis.fetch')
external JSPromise<JSAny?> _jsFetch(JSString url, JSObject init);

/// Send a debug log to the local debug server
void dlog(String loc, String msg, Map<String, dynamic> data, String hId) {
  try {
    final body = jsonEncode({
      'id': 'log_${DateTime.now().millisecondsSinceEpoch}_${loc.hashCode.abs()}',
      'location': loc,
      'message': msg,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hypothesisId': hId,
    });

    final headers = {'Content-Type': 'application/json'}.jsify();
    final init = {
      'method': 'POST',
      'headers': headers,
      'body': body,
    }.jsify() as JSObject;

    _jsFetch(_endpoint.toJS, init);
  } catch (_) {
    // silently ignore logging failures
  }
}
