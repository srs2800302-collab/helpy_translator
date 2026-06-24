import 'package:flutter_dotenv/flutter_dotenv.dart';

final class AppConfig {
  const AppConfig({
    required this.typhoonApiKey,
    required this.typhoonBaseUrl,
    required this.typhoonModel,
  });

  final String typhoonApiKey;
  final String typhoonBaseUrl;
  final String typhoonModel;

  static AppConfig fromEnv() {
    final String apiKey = dotenv.env['TYPHOON_API_KEY'] ?? '';
    final String baseUrl = dotenv.env['TYPHOON_BASE_URL'] ?? '';
    final String model = dotenv.env['TYPHOON_MODEL'] ?? '';

    if (apiKey.isEmpty) {
      throw StateError('TYPHOON_API_KEY is missing');
    }

    if (baseUrl.isEmpty) {
      throw StateError('TYPHOON_BASE_URL is missing');
    }

    if (model.isEmpty) {
      throw StateError('TYPHOON_MODEL is missing');
    }

    return AppConfig(
      typhoonApiKey: apiKey,
      typhoonBaseUrl: baseUrl,
      typhoonModel: model,
    );
  }
}
