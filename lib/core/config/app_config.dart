import 'package:flutter_dotenv/flutter_dotenv.dart';

final class AppConfig {
  const AppConfig({
    required this.typhoonApiKey,
    required this.typhoonBaseUrl,
    required this.typhoonModel,
    required this.githubToken,
    required this.githubOwner,
    required this.githubRepo,
    required this.githubRegistryPath,
    required this.githubRegistryRef,
  });

  final String typhoonApiKey;
  final String typhoonBaseUrl;
  final String typhoonModel;

  final String githubToken;
  final String githubOwner;
  final String githubRepo;
  final String githubRegistryPath;
  final String githubRegistryRef;

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
      githubToken: dotenv.env['GITHUB_TOKEN'] ?? '',
      githubOwner: dotenv.env['GITHUB_OWNER'] ?? 'srs2800302-collab',
      githubRepo: dotenv.env['GITHUB_REPO'] ?? 'Helpy',
      githubRegistryPath: dotenv.env['GITHUB_REGISTRY_PATH'] ??
          'docs/architecture/Helpy_Architecture_Registry_v1.md',
      githubRegistryRef: dotenv.env['GITHUB_REGISTRY_REF'] ?? 'main',
    );
  }
}
