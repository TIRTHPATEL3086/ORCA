import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

import '../models/fisherman_models.dart';
import 'auth_service.dart';
import 'session_service.dart';
import 'api_client.dart';

class FishermanService {
  FishermanService._();

  static const String _baseUrl = '${ApiConfig.apiV1}/fisherman';

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
        message: 'Could not reach ORCA. Check your internet connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        message: 'Could not reach ORCA. Check your internet connection and try again.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'ORCA took too long to respond. Please try again.',
      );
    }
  }

  static Future<FishermanProfileData> getProfile() {
    return _network(() async {
      final response = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/profile'), headers: await _headers())
          .timeout(ApiConfig.requestTimeout);

      return FishermanProfileData.fromJson(_decode(response));
    });
  }

  static Future<FishermanProfileData> updateProfile({
    required String fullName,
    required String preferredLanguage,
    String? homeLandingCentre,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return _network(() async {
      final response = await ApiClient.instance
          .patch(
            Uri.parse('$_baseUrl/profile'),
            headers: await _headers(),
            body: jsonEncode({
              'full_name': fullName.trim(),
              'preferred_language': preferredLanguage.trim().toLowerCase(),
              'home_landing_centre': _nullable(homeLandingCentre),
              'emergency_contact_name': _nullable(emergencyContactName),
              'emergency_contact_phone': _nullable(emergencyContactPhone),
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final result = FishermanProfileData.fromJson(_decode(response));

      await SessionService.setPreferredLanguage(result.preferredLanguage);

      return result;
    });
  }

  static Future<List<VesselData>> getVessels() {
    return _network(() async {
      final response = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/vessels'), headers: await _headers())
          .timeout(ApiConfig.requestTimeout);

      final decoded = _decodeDynamic(response);

      if (decoded is! List) {
        throw const ApiException(
          statusCode: 500,
          message: 'Invalid vessel response from ORCA.',
        );
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(VesselData.fromJson)
          .toList();
    });
  }

  static Future<VesselData> createVessel({
    required String name,
    String? registrationNumber,
    String? vesselType,
    double? lengthM,
    double? beamM,
    double? cruisingSpeedKnots,
    required int personsOnboardDefault,
  }) {
    return _network(() async {
      final response = await ApiClient.instance
          .post(
            Uri.parse('$_baseUrl/vessels'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name.trim(),
              'registration_number': _nullable(registrationNumber),
              'vessel_type': _nullable(vesselType),
              'length_m': lengthM,
              'beam_m': beamM,
              'cruising_speed_knots': cruisingSpeedKnots,
              'persons_onboard_default': personsOnboardDefault,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      return VesselData.fromJson(_decode(response));
    });
  }

  static Future<VesselData> updateVessel({
    required String vesselId,
    required String name,
    String? registrationNumber,
    String? vesselType,
    double? lengthM,
    double? beamM,
    double? cruisingSpeedKnots,
    required int personsOnboardDefault,
  }) {
    return _network(() async {
      final response = await ApiClient.instance
          .patch(
            Uri.parse('$_baseUrl/vessels/$vesselId'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name.trim(),
              'registration_number': _nullable(registrationNumber),
              'vessel_type': _nullable(vesselType),
              'length_m': lengthM,
              'beam_m': beamM,
              'cruising_speed_knots': cruisingSpeedKnots,
              'persons_onboard_default': personsOnboardDefault,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      return VesselData.fromJson(_decode(response));
    });
  }

  static Future<void> deleteVessel(String vesselId) {
    return _network(() async {
      final response = await ApiClient.instance
          .delete(
            Uri.parse('$_baseUrl/vessels/$vesselId'),
            headers: await _headers(),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode != 204) {
        _throwForResponse(response);
      }
    });
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final decoded = _decodeDynamic(response);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ApiException(
      statusCode: 500,
      message: 'Invalid response from ORCA.',
    );
  }

  static dynamic _decodeDynamic(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwForResponse(response);
    }

    if (response.body.isEmpty) return null;

    return jsonDecode(response.body);
  }

  static Never _throwForResponse(http.Response response) {
    String message = 'Request failed (${response.statusCode}).';

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final detail = decoded['detail'];

          if (detail is String) {
            message = detail;
          }
        }
      } catch (_) {}
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  static String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
