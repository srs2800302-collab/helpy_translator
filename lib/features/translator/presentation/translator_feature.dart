import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/run_translation_matrix.dart';
import '../data/network/typhoon_chat_client.dart';
import '../data/network/typhoon_translator_config.dart';
import '../data/network/typhoon_translator_gateway.dart';
import '../domain/repositories/primary_linguist_gateway.dart';
import '../domain/repositories/translator_api_key_store.dart';
import '../domain/repositories/translator_gateway.dart';
import '../domain/services/honesty_assessment_policy.dart';
import '../domain/services/linguist_constraint_policy.dart';
import '../domain/services/source_language_detector.dart';
import '../domain/services/translation_route_planner.dart';
import 'cubit/translator_cubit.dart';
import 'pages/translator_page.dart';

final class TranslatorFeature extends StatefulWidget {
  const TranslatorFeature({
    required this.apiKeyStore,
    this.config = const TyphoonTranslatorConfig(),
    super.key,
  });

  final TranslatorApiKeyStore apiKeyStore;
  final TyphoonTranslatorConfig config;

  @override
  State<TranslatorFeature> createState() => _TranslatorFeatureState();
}

final class _TranslatorFeatureState extends State<TranslatorFeature> {
  late final TranslatorGateway _gateway;
  late final PrimaryLinguistGateway _primaryLinguistGateway;
  late final TranslatorCubit _cubit;

  @override
  void initState() {
    super.initState();

    final TyphoonChatClient chatClient = TyphoonChatClient(
      config: widget.config,
    );

    final TyphoonTranslatorGateway gateway = TyphoonTranslatorGateway(
      chatClient: chatClient,
      config: widget.config,
    );

    _gateway = gateway;
    _primaryLinguistGateway = gateway;

    _cubit = TranslatorCubit(
      runTranslationMatrix: RunTranslationMatrix(
        apiKeyStore: widget.apiKeyStore,
        gateway: _gateway,
        primaryLinguistGateway: _primaryLinguistGateway,
        languageDetector: const ScriptSourceLanguageDetector(),
        routePlanner: const CompleteThreeLanguageRoutePlanner(),
        assessmentPolicy: const ConservativeHonestyAssessmentPolicy(),
        linguistConstraintPolicy: const ConservativeLinguistConstraintPolicy(),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    _gateway.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslatorCubit>.value(
      value: _cubit,
      child: const TranslatorPage(),
    );
  }
}
