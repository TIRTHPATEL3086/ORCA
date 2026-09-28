import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/orca_agent_models.dart';
import 'auth_service.dart';
import 'session_service.dart';

class OrcaAgentService {
  OrcaAgentService._();

  static const String _endpoint = 'http://127.0.0.1:8000/api/v1/orca/query';

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

      final response = await http
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
          .timeout(const Duration(seconds: 45));

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
            'ORCA backend is not reachable. Check FastAPI and ADB reverse.',
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
