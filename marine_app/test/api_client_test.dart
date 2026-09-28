import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marine_app/services/api_client.dart';
import 'package:marine_app/services/session_service.dart';

/// Fake ORCA backend: /profile needs a valid access token; /auth/refresh
/// rotates tokens according to [refreshStatus].
class FakeBackend {
  String validAccess = 'access-2';
  int refreshStatus = 200;
  bool refreshOffline = false;
  int refreshCalls = 0;
  final List<String?> seenAuth = [];

  late final MockClient client = MockClient((request) async {
    if (request.url.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refreshOffline) throw const SocketException('offline');
      if (refreshStatus != 200) {
        return http.Response('{"detail":"Your session has ended."}', 401);
      }
      final sent = jsonDecode(request.body)['refresh_token'];
      expect(sent, 'refresh-1');
      return http.Response(
        jsonEncode({'access_token': validAccess, 'refresh_token': 'refresh-2'}),
        200,
      );
    }

    seenAuth.add(request.headers['Authorization']);
    if (request.headers['Authorization'] != 'Bearer $validAccess') {
      return http.Response('{"detail":"Invalid or expired token."}', 401);
    }
    return http.Response('{"ok":true,"echo":${jsonEncode(request.body)}}', 200);
  });
}

void main() {
  late FakeBackend backend;
  late ApiClient api;
  late int expiredCalls;
  final profile = Uri.parse('https://orca.test/api/v1/fisherman/profile');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'orca_access_token': 'access-1',
      'orca_refresh_token': 'refresh-1',
      'orca_role': 'FISHERMAN',
    });
    backend = FakeBackend();
    api = ApiClient(inner: backend.client);
    expiredCalls = 0;
    ApiClient.onSessionExpired = () => expiredCalls++;
  });

  test('valid token: request goes straight through with the bearer token',
      () async {
    backend.validAccess = 'access-1';
    final response = await api.get(profile);
    expect(response.statusCode, 200);
    expect(backend.seenAuth, ['Bearer access-1']);
    expect(backend.refreshCalls, 0);
  });

  test('expired token: renews silently, retries, and stores the new pair',
      () async {
    final response = await api.patch(profile, body: '{"name":"Ravi"}');
    expect(response.statusCode, 200);
    expect(jsonDecode(response.body)['echo'], '{"name":"Ravi"}');
    expect(backend.seenAuth, ['Bearer access-1', 'Bearer access-2']);
    expect(await SessionService.getAccessToken(), 'access-2');
    expect(await SessionService.getRefreshToken(), 'refresh-2');
    expect(expiredCalls, 0);
  });

  test('many requests expiring together trigger only one renewal', () async {
    final responses = await Future.wait(
      List.generate(5, (_) => api.get(profile)),
    );
    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(backend.refreshCalls, 1);
  });

  test('session cannot be renewed: signs out once with a clear message',
      () async {
    backend.refreshStatus = 401;
    final response = await api.get(profile);
    expect(response.statusCode, 401);
    expect(jsonDecode(response.body)['detail'], ApiClient.sessionEndedMessage);
    expect(await SessionService.getAccessToken(), isNull);
    expect(await SessionService.getRefreshToken(), isNull);
    expect(expiredCalls, 1);
  });

  test('offline during renewal: keeps the session and reports the error',
      () async {
    backend.refreshOffline = true;
    await expectLater(api.get(profile), throwsA(isA<SocketException>()));
    expect(await SessionService.getRefreshToken(), 'refresh-1');
    expect(expiredCalls, 0);
  });
}
