import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'features/translator/data/datasources/translator_remote_datasource.dart';
import 'features/translator/data/repositories/translator_repository_impl.dart';
import 'features/translator/domain/usecases/translate_canonical_phrase.dart';
import 'features/translator/presentation/cubit/translator_cubit.dart';
import 'features/translator/presentation/pages/translator_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final AppConfig appConfig = AppConfig.fromEnv();
  final ApiClient apiClient = ApiClient(appConfig);

  final TranslatorRemoteDataSource remoteDataSource =
      TranslatorRemoteDataSourceImpl(
    apiClient: apiClient,
    appConfig: appConfig,
  );

  final TranslatorRepositoryImpl repository =
      TranslatorRepositoryImpl(remoteDataSource);

  final TranslateCanonicalPhrase translateCanonicalPhrase =
      TranslateCanonicalPhrase(repository);

  runApp(
    HelpyTranslatorApp(
      translatorCubit: TranslatorCubit(translateCanonicalPhrase),
    ),
  );
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
