import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';
import 'registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'registry_studio/presentation/app/registry_studio_app.dart';
import 'registry_studio/translator/application/translate_phrase.dart';
import 'registry_studio/translator/infrastructure/shared_preferences_translator_phrase_history_persistence.dart';
import 'registry_studio/translator/infrastructure/typhoon_translator_phrase_provider.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';

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

  final Future<List<ServiceIntakeSourceBlock>> serviceIntakeSourceBlocks =
      _loadServiceIntakeSourceBlocks();

  runApp(
    RegistryStudioApp(
      serviceIntakeSourceBlocks: serviceIntakeSourceBlocks,
      workSessionPersistence: const RegistryWorkSessionPersistence(),
      translatorPhraseHistoryPersistence:
          const SharedPreferencesTranslatorPhraseHistoryPersistence(),
      translatePhrase: TranslatePhrase(provider: translatorPhraseProvider),
      createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
      transitionRegistryEngineeringOperationStatus:
          TransitionRegistryEngineeringOperationStatus(),
    ),
  );
}

Future<List<ServiceIntakeSourceBlock>> _loadServiceIntakeSourceBlocks() async {
  final List<ServiceIntakeIdentityManifestEntry> identities =
      await ServiceIntakeIdentityManifestSource(assetBundle: rootBundle).load();

  final GitHubRegistryDocumentSourceResult sourceResult =
      await GitHubRegistryDocumentSource(
        dio: Dio(),
        owner: 'srs2800302-collab',
        repository: 'helpy',
        documentPath: 'docs/architecture/Helpy_Architecture_Registry_v1.md',
        ref: 'main',
      ).load();

  return const ServiceIntakeSourceBlockExtractor().extract(
    source: sourceResult.content,
    identities: identities,
  );
}
