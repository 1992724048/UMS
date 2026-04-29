import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class HttpClient {
  static const _defaultHeaders = {'Content-Type': 'application/json'};
  static const _compressibleMethods = {'POST', 'PUT', 'PATCH'};

  static Future<web.XMLHttpRequest> _request(
    String method,
    String url, {
    Map<String, String>? headers,
    String? body,
  }) async {
    final completer = Completer<web.XMLHttpRequest>();
    final req = web.XMLHttpRequest();
    req.open(method, url);
    req.withCredentials = true;

    (_defaultHeaders).forEach((k, v) => req.setRequestHeader(k, v));
    headers?.forEach((k, v) => req.setRequestHeader(k, v));

    req.onLoad.listen((_) => completer.complete(req));
    req.onError.listen((_) => completer.completeError(Exception('Request failed')));

    if (body != null && body.isNotEmpty && _compressibleMethods.contains(method)) {
      req.setRequestHeader('Content-Encoding', 'gzip');
      final compressed = await _gzip(body);
      req.send(compressed);
    } else if (body != null) {
      req.send(body.toJS);
    } else {
      req.send();
    }

    return completer.future;
  }

  static Future<JSAny?> _gzip(String data) async {
    final blob = web.Blob([data.toJS].toJS);
    final cs = web.CompressionStream('gzip');
    final compressed = blob.stream().pipeThrough(
      web.ReadableWritablePair(writable: cs.writable, readable: cs.readable),
    );
    final response = web.Response(compressed);
    return response.arrayBuffer().toDart;
  }

  static Future<web.XMLHttpRequest> get(String url, {Map<String, String>? headers}) =>
      _request('GET', url, headers: headers);

  static Future<web.XMLHttpRequest> post(String url, {Map<String, String>? headers, String? body}) =>
      _request('POST', url, headers: headers, body: body);

  static Future<web.XMLHttpRequest> put(String url, {Map<String, String>? headers, String? body}) =>
      _request('PUT', url, headers: headers, body: body);

  static Future<web.XMLHttpRequest> delete(String url, {Map<String, String>? headers}) =>
      _request('DELETE', url, headers: headers);

  static Future<web.XMLHttpRequest> patch(String url, {Map<String, String>? headers, String? body}) =>
      _request('PATCH', url, headers: headers, body: body);

  static Future<web.XMLHttpRequest> head(String url, {Map<String, String>? headers}) =>
      _request('HEAD', url, headers: headers);
}
