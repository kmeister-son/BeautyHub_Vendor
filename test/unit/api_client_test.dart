import 'dart:async';

import 'package:beautyhub_vendor/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a hung request fails with TimeoutException instead of spinning',
      () async {
    final hangingClient = MockClient((request) => Completer<http.Response>()
        .future); // never completes, like a dead server that still accepts
    final api = ApiClient(
      httpClient: hangingClient,
      timeout: const Duration(milliseconds: 50),
    );

    await expectLater(
        api.get('/provider/salon', authenticated: false),
        throwsA(isA<TimeoutException>()));
  });

  test('authenticated calls without a stored token fail fast, no request',
      () async {
    var requests = 0;
    final api = ApiClient(httpClient: MockClient((request) async {
      requests++;
      return http.Response('{}', 200);
    }));

    await expectLater(api.get('/provider/salon'),
        throwsA(isA<UnauthenticatedException>()));
    expect(requests, 0);
  });

  test('adopted token rides along as a bearer header on every method',
      () async {
    final seen = <String>[];
    final api = ApiClient(httpClient: MockClient((request) async {
      seen.add('${request.method} ${request.headers['Authorization']}');
      return http.Response('{}', 200);
    }));
    await api.adoptToken('jwt-123');

    await api.get('/provider/salon');
    await api.patch('/provider/salon', body: {'name': 'New'});
    await api.delete('/provider/services/svc-1');

    expect(seen, [
      'GET Bearer jwt-123',
      'PATCH Bearer jwt-123',
      'DELETE Bearer jwt-123',
    ]);
  });

  test('a stale token is dropped on 401 so the UI can route to login',
      () async {
    final api = ApiClient(
        httpClient:
            MockClient((request) async => http.Response('{"message":"Unauthorized"}', 401)));
    await api.adoptToken('stale-jwt');

    await expectLater(api.get('/provider/salon'),
        throwsA(isA<UnauthenticatedException>()));
    expect(await api.hasToken(), isFalse);
  });

  test('API error bodies surface their message', () async {
    final api = ApiClient(
        httpClient: MockClient((request) async =>
            http.Response('{"message":["name should not be empty"]}', 400)));
    await api.adoptToken('jwt-123');

    await expectLater(
      api.post('/provider/services', body: {}),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', 'name should not be empty')),
    );
  });
}
