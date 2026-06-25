import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/background/android_foreground_service_controller.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/translator/data/datasources/registry_remote_datasource.dart';
import 'features/translator/data/datasources/translator_remote_datasource.dart';
import 'features/translator/data/repositories/translator_repository_impl.dart';
import 'features/translator/domain/usecases/audit_canonical_client_rules.dart';
import 'features/translator/domain/usecases/translate_canonical_phrase.dart';
import 'features/translator/presentation/cubit/translator_cubit.dart';
import 'features/translator/presentation/pages/translator_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');

    final AppConfig appConfig = AppConfig.fromEnv();
    final ApiClient apiClient = ApiClient(appConfig);

    final TranslatorRemoteDataSource remoteDataSource =
        TranslatorRemoteDataSourceImpl(
      apiClient: apiClient,
      appConfig: appConfig,
    );

    final RegistryRemoteDataSource registryRemoteDataSource =
        RegistryRemoteDataSourceImpl(appConfig: appConfig);

    final TranslatorRepositoryImpl repository = TranslatorRepositoryImpl(
      remoteDataSource: remoteDataSource,
      registryRemoteDataSource: registryRemoteDataSource,
    );

    final TranslateCanonicalPhrase translateCanonicalPhrase =
        TranslateCanonicalPhrase(repository);

    final AuditCanonicalClientRules auditCanonicalClientRules =
        AuditCanonicalClientRules(repository);

    runApp(
      HelpyTranslatorApp(
        translatorCubit: TranslatorCubit(
          translateCanonicalPhrase: translateCanonicalPhrase,
          auditCanonicalClientRules: auditCanonicalClientRules,
          backgroundExecutionController:
              const AndroidForegroundServiceController(),
        ),
      ),
    );
  } catch (error) {
    runApp(StartupErrorApp(message: error.toString()));
  }
}

class HelpyTranslatorApp extends StatelessWidget {
  const HelpyTranslatorApp({
    required this.translatorCubit,
    super.key,
  });

  final TranslatorCubit translatorCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslatorCubit>.value(
      value: translatorCubit,
      child: MaterialApp(
        title: 'Helpy Translator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const TranslatorPage(),
      ),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Helpy Translator Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SelectableText(
              'Ошибка запуска:\n\n$message',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
