import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'registry_studio/translator/application/translate_phrase.dart';
import 'registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';
import 'registry_studio/translator/presentation/app/registry_studio_translator_app.dart';

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
    RegistryStudioTranslatorApp(
      translatePhrase: TranslatePhrase(provider: translatorPhraseProvider),
    ),
  );
}
