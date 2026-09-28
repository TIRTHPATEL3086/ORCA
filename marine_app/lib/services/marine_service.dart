import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

import '../models/marine_conditions.dart';
import 'auth_service.dart';
import 'session_service.dart';

class MarineService {
  MarineService._();

  static const String _baseUrl = '${ApiConfig.apiV1}/marine';

  static Future<MarineConditionsData> getConditions({
    required double latitude,
    required double longitude,
  }) async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active ORCA session.',
      );
    }

    final uri = Uri.parse('$_baseUrl/conditions').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(ApiConfig.requestTimeout);

      Map<String, dynamic> body = {};

      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return MarineConditionsData.fromJson(body);
      }

      final detail = body['detail'];

      throw ApiException(
        statusCode: response.statusCode,
        message: detail is String ? detail : 'Marine data request failed.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message:
            'Could not reach ORCA. Check your internet connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        message: 'Could not reach ORCA through the device connection.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'Marine data request timed out.',
      );
    }
  }
}
