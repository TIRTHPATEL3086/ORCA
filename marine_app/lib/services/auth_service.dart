import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';

import '../models/auth_models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static const String _baseUrl = '${ApiConfig.apiV1}/auth';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<OtpRequestResult> requestFishermanOtp(
    String phoneNumber,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/fisherman/request-otp'),
          headers: _headers,
          body: jsonEncode({'phone_number': phoneNumber.trim()}),
        )
        .timeout(ApiConfig.requestTimeout);

    return OtpRequestResult.fromJson(_decode(response));
  }

  static Future<OtpVerifyResult> verifyFishermanOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/fisherman/verify-otp'),
          headers: _headers,
          body: jsonEncode({
            'phone_number': phoneNumber.trim(),
            'otp': otp.trim(),
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    return OtpVerifyResult.fromJson(_decode(response));
  }

  static Future<AuthResult> completeFishermanRegistration({
    required String onboardingToken,
    required String fullName,
    required String preferredLanguage,
    String? homeLandingCentre,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/fisherman/complete-registration'),
          headers: _headers,
          body: jsonEncode({
            'onboarding_token': onboardingToken,
            'full_name': fullName.trim(),
            'preferred_language': preferredLanguage,
            'home_landing_centre': _nullable(homeLandingCentre),
            'emergency_contact_name': _nullable(emergencyContactName),
            'emergency_contact_phone': _nullable(emergencyContactPhone),
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    return AuthResult.fromJson(_decode(response));
  }

  static Future<AuthenticatedUser> registerResearcher({
    required String fullName,
    required String email,
    required String password,
    required String preferredLanguage,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/register'),
          headers: _headers,
          body: jsonEncode({
            'full_name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'role': 'RESEARCHER',
            'preferred_language': preferredLanguage,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    return AuthenticatedUser.fromJson(_decode(response));
  }

  static Future<AuthResult> loginWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/login'),
          headers: _headers,
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    return AuthResult.fromJson(_decode(response));
  }

  static Map<String, dynamic> _decode(http.Response response) {
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
      return body;
    }

    String message = 'Request failed (${response.statusCode}).';
    final detail = body['detail'];

    if (detail is String) {
      message = detail;
    } else if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) {
        message = first['msg'].toString();
      }
    }

    throw ApiException(statusCode: response.statusCode, message: message);
  }

  static String? _nullable(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
