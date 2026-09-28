import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

import '../models/orca_agent_models.dart';
import 'auth_service.dart';
import 'session_service.dart';
import 'api_client.dart';

class OrcaAgentService {
  OrcaAgentService._();

  static const String _endpoint = '${ApiConfig.apiV1}/orca/query';

  static Future<OrcaAgentResponseData> query({
    required String message,
    required double latitude,
    required double longitude,
    required String preferredLanguage,
    required List<OrcaChatMessageData> history,
    double? destinationLatitude,
    double? destinationLongitude,
    double? cruisingSpeedKnots,
  }) async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active ORCA session.',
      );
    }

    try {
      final recentHistory = history.length > 20
          ? history.sublist(history.length - 20)
          : history;

      final response = await ApiClient.instance
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': message.trim(),
              'latitude': latitude,
              'longitude': longitude,
              'preferred_language': preferredLanguage,
              'history': recentHistory
                  .map((e) => {'role': e.role, 'content': e.content})
                  .toList(),
              'destination_latitude': destinationLatitude,
              'destination_longitude': destinationLongitude,
              'cruising_speed_knots': cruisingSpeedKnots,
            }),
          )
          .timeout(const Duration(seconds: 90));

      dynamic decoded;

      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map<String, dynamic>) {
        return OrcaAgentResponseData.fromJson(decoded);
      }

      String error = 'ORCA query failed (${response.statusCode}).';

      if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
        error = decoded['detail'] as String;
      }

      throw ApiException(statusCode: response.statusCode, message: error);
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
        message: 'ORCA took too long to gather evidence. Retry once.',
      );
    }
  }
}
