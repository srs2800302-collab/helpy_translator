import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'registry_studio/presentation/app/registry_studio_app.dart';
import 'registry_studio/translator/application/translate_phrase.dart';
import 'registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final AppConfig appConfig = AppConfig.fromEnv();
  final ApiClient apiClient = ApiClient(appConfig);
  final TyphoonTranslatorPhraseProvider translatorPhraseProvider =
      TyphoonTranslatorPhraseProvider(
        apiClient: apiClient,
        appConfig: appConfig,
      );

  runApp(
    RegistryStudioApp(
      translatePhrase: TranslatePhrase(provider: translatorPhraseProvider),
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
    ),
  );
}
