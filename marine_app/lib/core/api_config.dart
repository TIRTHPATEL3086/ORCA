import 'package:http/http.dart' as http;

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

  /// How long to wait for the backend. Hosted servers on free plans sleep
  /// when idle and take up to about a minute to wake on the first request.
  static const Duration requestTimeout = Duration(seconds: 60);

  /// Wakes a sleeping backend as soon as the app opens, so it is usually
  /// ready by the time the user submits their first request.
  static void warmUp() {
    http
        .get(Uri.parse('$apiV1/health'))
        .timeout(const Duration(seconds: 90))
        .then((_) {}, onError: (_) {});
  }
}
