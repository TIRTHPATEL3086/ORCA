import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'session_service.dart';

/// HTTP client for signed-in requests.
///
/// Attaches the current access token and, when the server answers 401
/// (the short-lived access token expired), silently renews the session with
/// the stored refresh token and retries once. If the session can no longer
/// be renewed, the stored session is cleared and [onSessionExpired] runs.
class ApiClient extends http.BaseClient {
  ApiClient({http.Client? inner}) : _inner = inner ?? http.Client();

  static final ApiClient instance = ApiClient();

  /// Called once when the session has ended and the user must sign in again.
  static void Function()? onSessionExpired;

  static const String sessionEndedMessage =
      'Your session has ended. Please sign in again.';

  final http.Client _inner;
  Future<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(
      _copy(request, await SessionService.getAccessToken()),
    );
    if (response.statusCode != 401) return response;

    await response.stream.drain<void>();

    if (!await _refreshSession()) {
      await _endSession();
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode({'detail': sessionEndedMessage}))),
        401,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    }

    return _inner.send(_copy(request, await SessionService.getAccessToken()));
  }

  /// Rebuilds the request (a sent request cannot be re-sent) with a token.
  http.BaseRequest _copy(http.BaseRequest original, String? token) {
    if (original is! http.Request) {
      throw ArgumentError('ApiClient only supports simple requests.');
    }

    final copy = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..bodyBytes = original.bodyBytes;

    if (token != null && token.isNotEmpty) {
      copy.headers['Authorization'] = 'Bearer $token';
    }
    return copy;
  }

  /// Renews the session once, even if several requests hit 401 together.
  Future<bool> _refreshSession() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await SessionService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    // Network failures propagate so the caller shows a connection error
    // instead of signing the user out.
    final response = await _inner
        .post(
          Uri.parse('${ApiConfig.apiV1}/auth/refresh'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200) return false;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    await SessionService.saveTokens(
      accessToken: body['access_token'] as String,
      refreshToken: body['refresh_token'] as String?,
    );
    return true;
  }

  Future<void> _endSession() async {
    final hadSession = await SessionService.getAccessToken() != null;
    await SessionService.clear();
    if (hadSession) onSessionExpired?.call();
  }
}
