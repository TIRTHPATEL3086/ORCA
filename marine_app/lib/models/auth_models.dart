class AuthenticatedUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? fisherId;
  final String role;
  final String authMethod;
  final String preferredLanguage;
  final bool isActive;

  const AuthenticatedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.fisherId,
    required this.role,
    required this.authMethod,
    required this.preferredLanguage,
    required this.isActive,
  });

  factory AuthenticatedUser.fromJson(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'].toString(),
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      fisherId: json['fisher_id'] as String?,
      role: json['role'] as String,
      authMethod: json['auth_method'] as String,
      preferredLanguage: json['preferred_language'] as String,
      isActive: json['is_active'] as bool,
    );
  }
}

class OtpRequestResult {
  final String message;
  final int expiresInSeconds;
  final String? devOtp;

  const OtpRequestResult({
    required this.message,
    required this.expiresInSeconds,
    required this.devOtp,
  });

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) {
    return OtpRequestResult(
      message: json['message'] as String,
      expiresInSeconds: json['expires_in_seconds'] as int,
      devOtp: json['dev_otp'] as String?,
    );
  }
}

class OtpVerifyResult {
  final bool isNewUser;
  final String? accessToken;
  final String? refreshToken;
  final String? onboardingToken;
  final AuthenticatedUser? user;

  const OtpVerifyResult({
    required this.isNewUser,
    required this.accessToken,
    required this.refreshToken,
    required this.onboardingToken,
    required this.user,
  });

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return OtpVerifyResult(
      isNewUser: json['is_new_user'] as bool,
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      onboardingToken: json['onboarding_token'] as String?,
      user: rawUser is Map<String, dynamic>
          ? AuthenticatedUser.fromJson(rawUser)
          : null,
    );
  }
}

class AuthResult {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final AuthenticatedUser user;

  const AuthResult({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: AuthenticatedUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
