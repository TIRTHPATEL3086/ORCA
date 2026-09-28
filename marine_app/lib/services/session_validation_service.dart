import 'dart:convert';


import '../core/api_config.dart';

import '../models/auth_models.dart';
import 'auth_service.dart';
import 'session_service.dart';
import 'api_client.dart';

class SessionValidationService {
  SessionValidationService._();

  static const String _meUrl = '${ApiConfig.apiV1}/auth/me';

  static Future<AuthenticatedUser> getCurrentUser() async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active ORCA session.',
      );
    }

    final response = await ApiClient.instance
        .get(
          Uri.parse(_meUrl),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 10));

    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {}
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AuthenticatedUser.fromJson(body);
    }

    final detail = body['detail'];

    throw ApiException(
      statusCode: response.statusCode,
      message: detail is String ? detail : 'Session validation failed.',
    );
  }
}
