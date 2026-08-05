import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../features/translator/data/security/flutter_secure_translator_api_key_store.dart';
import '../../features/translator/presentation/translator_feature.dart';
import '../../features/translator/presentation/widgets/translator_api_key_button.dart';

import '../../registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import '../../registry_studio/adapters/helpy/infrastructure/json_file_helpy_registry_node_identity_store.dart';
import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/technical/storage/json_file_registry_revision_state_store.dart';
import '../../registry_studio/technical/storage/json_lines_registry_analysis_history_store.dart';
import '../localization/flutter_secure_registry_studio_locale_store.dart';
import '../localization/registry_studio_locale_cubit.dart';
import '../localization/registry_studio_locale_store.dart';
import '../localization/registry_studio_localizations.dart';
import '../shell/registry_studio_shell.dart';

final class RegistryStudioApplication extends StatelessWidget {
  const RegistryStudioApplication({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    this.translatorWorkspace,
    this.translatorAppBarLeading,
    this.localeStore = const FlutterSecureRegistryStudioLocaleStore(),
    super.key,
  });

  factory RegistryStudioApplication.helpy({Key? key}) {
    const FlutterSecureTranslatorApiKeyStore translatorApiKeyStore =
        FlutterSecureTranslatorApiKeyStore();
    final HelpyRegistrySnapshotLoader registrySnapshotLoader =
        HelpyRegistrySnapshotLoader(
          documentSource: GitHubRegistryDocumentSource(
            owner: 'srs2800302-collab',
            repository: 'helpy',
            documentPath:
                HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath,
            ref: 'main',
          ),
          identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
            documentSource: GitHubRegistryDocumentSource(
              owner: 'srs2800302-collab',
              repository: 'helpy',
              documentPath:
                  HelpyRegistryNodeIdentityLedgerSource.ledgerDocumentPath,
              ref: 'main',
            ),
          ),
          identityStore: const JsonFileHelpyRegistryNodeIdentityStore(),
        );

    return RegistryStudioApplication(
      key: key,
      registrySnapshotLoader: registrySnapshotLoader,
      registrySnapshotRefreshLoader: registrySnapshotLoader,
      registrySnapshotRevisionLoader: registrySnapshotLoader,
      registryRevisionStateStore: const JsonFileRegistryRevisionStateStore(),
      registryAnalysisHistoryStore:
          const JsonLinesRegistryAnalysisHistoryStore(),
      translatorWorkspace: const TranslatorFeature(
        apiKeyStore: translatorApiKeyStore,
      ),
      translatorAppBarLeading: const TranslatorApiKeyButton(
        apiKeyStore: translatorApiKeyStore,
      ),
    );
  }

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final Widget? translatorWorkspace;
  final Widget? translatorAppBarLeading;
  final RegistryStudioLocaleStore localeStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryStudioLocaleCubit>(
      create: (_) => RegistryStudioLocaleCubit(store: localeStore)..restore(),
      child: _RegistryStudioMaterialApplication(
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        translatorWorkspace: translatorWorkspace,
        translatorAppBarLeading: translatorAppBarLeading,
      ),
    );
  }
}

final class _RegistryStudioMaterialApplication extends StatelessWidget {
  const _RegistryStudioMaterialApplication({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.translatorWorkspace,
    required this.translatorAppBarLeading,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final Widget? translatorWorkspace;
  final Widget? translatorAppBarLeading;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistryStudioLocaleCubit, Locale>(
      builder: (BuildContext context, Locale locale) {
        return MaterialApp(
          title: 'Registry Studio',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: RegistryStudioLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            RegistryStudioLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          theme: ThemeData(useMaterial3: true),
          home: RegistryStudioShell(
            registrySnapshotLoader: registrySnapshotLoader,
            registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
            registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
            registryRevisionStateStore: registryRevisionStateStore,
            registryAnalysisHistoryStore: registryAnalysisHistoryStore,
            registrySnapshotComparator: const RegistrySnapshotComparator(),
            translatorWorkspace: translatorWorkspace,
            translatorAppBarLeading: translatorAppBarLeading,
          ),
        );
      },
    );
  }
}
