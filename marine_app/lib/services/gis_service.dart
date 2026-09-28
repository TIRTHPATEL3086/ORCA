import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

import '../models/gis_models.dart';
import 'auth_service.dart';
import 'session_service.dart';
import 'api_client.dart';

class GisService {
  GisService._();

  static const String _baseUrl = '${ApiConfig.apiV1}/gis';

  static Future<Map<String, String>> _headers() async {
    final token = await SessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No active ORCA session.',
      );
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<T> _network<T>(Future<T> Function() request) async {
    try {
      return await request();
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
        message: 'GIS request timed out. Retry after checking the backend.',
      );
    }
  }

  static Future<List<BoundaryZoneData>> getZones() {
    return _network(() async {
      final response = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/zones'), headers: await _headers())
          .timeout(ApiConfig.requestTimeout);

      final decoded = _decodeDynamic(response);

      if (decoded is! List) {
        throw const ApiException(
          statusCode: 500,
          message: 'Invalid geofence response from ORCA.',
        );
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(BoundaryZoneData.fromJson)
          .toList();
    });
  }

  static Future<BoundaryCheckData> checkBoundary({
    required double latitude,
    required double longitude,
  }) {
    return _network(() async {
      final uri = Uri.parse('$_baseUrl/boundary/check').replace(
        queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        },
      );

      final response = await ApiClient.instance
          .get(uri, headers: await _headers())
          .timeout(ApiConfig.requestTimeout);

      return BoundaryCheckData.fromJson(_decodeMap(response));
    });
  }

  static Future<RoutePlanData> planRoute({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    required double cruisingSpeedKnots,
  }) {
    return _network(() async {
      final response = await ApiClient.instance
          .post(
            Uri.parse('$_baseUrl/route/plan'),
            headers: await _headers(),
            body: jsonEncode({
              'start_latitude': startLatitude,
              'start_longitude': startLongitude,
              'end_latitude': endLatitude,
              'end_longitude': endLongitude,
              'cruising_speed_knots': cruisingSpeedKnots,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      return RoutePlanData.fromJson(_decodeMap(response));
    });
  }

  static Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = _decodeDynamic(response);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      statusCode: 500,
      message: 'Invalid ORCA GIS response.',
    );
  }

  static dynamic _decodeDynamic(http.Response response) {
    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {}
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed (${response.statusCode}).';

    if (decoded is Map<String, dynamic> && decoded['detail'] is String) {
      message = decoded['detail'] as String;
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }
}
