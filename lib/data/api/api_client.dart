import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when an authenticated call finds no usable identity — no stored
/// token, or the server rejected it. The UI reacts by showing the login
/// screen; unlike the customer app there is no guest fallback.
class UnauthenticatedException extends ApiException {
  UnauthenticatedException([String message = 'Sign in required'])
      : super(401, message);
}

/// Thin JSON client for the provider API. Holds the vendor's JWT (persisted
/// per install) and never mints guest identities.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient ?? http.Client();

  static const _tokenKey = 'beautyhub_vendor_token';

  /// Ceiling for every request; a hung connection surfaces as a
  /// [TimeoutException] instead of spinning forever.
  final Duration timeout;

  final http.Client _http;
  String? _token;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  /// Whether an identity is stored (it may still be stale server-side).
  Future<bool> hasToken() async => await _loadToken() != null;

  Future<String?> _loadToken() async {
    if (_token case final token?) return token;
    final prefs = await SharedPreferences.getInstance();
    return _token = prefs.getString(_tokenKey);
  }

  /// Replaces the current identity with [token] (after login).
  Future<void> adoptToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Forgets the stored identity; authenticated calls fail with
  /// [UnauthenticatedException] until the next [adoptToken].
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    String message = res.reasonPhrase ?? 'Request failed';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] != null) {
        final m = body['message'];
        message = m is List ? m.join(', ') : m.toString();
      }
    } on FormatException {
      // Non-JSON error body; keep the reason phrase.
    }
    throw ApiException(res.statusCode, message);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool authenticated = true,
  }) =>
      _send('GET', path, query: query, authenticated: authenticated);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) =>
      _send('POST', path, body: body, authenticated: authenticated);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body, authenticated: true);

  Future<dynamic> delete(String path) =>
      _send('DELETE', path, authenticated: true);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = await _loadToken();
      if (token == null) throw UnauthenticatedException();
      headers['Authorization'] = 'Bearer $token';
    }
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final res = await http.Response.fromStream(
      await _http.send(request).timeout(timeout),
    );

    // A stored token can go stale (e.g. dev database reset). Drop it and
    // let the UI route back to login.
    if (authenticated && res.statusCode == 401) {
      await clearToken();
      throw UnauthenticatedException('Session expired — sign in again');
    }
    return _decode(res);
  }
}
