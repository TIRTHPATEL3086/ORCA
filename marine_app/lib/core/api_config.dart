/// Backend base URL, overridable at build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///   flutter build apk --dart-define=API_BASE_URL=https://api.example.com
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String apiV1 = '$baseUrl/api/v1';
}
