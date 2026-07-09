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

  factory AppConfig.fromEnv() {
    final String typhoonApiKey = dotenv.env['TYPHOON_API_KEY'] ?? '';

    if (typhoonApiKey.isEmpty) {
      throw StateError('TYPHOON_API_KEY is missing');
    }

    return AppConfig(
      typhoonApiKey: typhoonApiKey,
      typhoonBaseUrl:
          dotenv.env['TYPHOON_BASE_URL'] ?? 'https://api.opentyphoon.ai/v1',
      typhoonModel:
          dotenv.env['TYPHOON_MODEL'] ?? 'typhoon-v2.5-30b-a3b-instruct',
    );
  }
}
