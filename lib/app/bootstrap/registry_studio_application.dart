import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import '../../registry_studio/adapters/helpy/infrastructure/json_file_helpy_registry_node_identity_store.dart';
import '../../registry_studio/adapters/helpy/translator/helpy_translator_policy.dart';
import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_cache.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/technical/storage/json_file_registry_revision_state_store.dart';
import '../../registry_studio/technical/storage/json_file_registry_snapshot_cache.dart';
import '../../registry_studio/technical/storage/json_lines_registry_analysis_history_store.dart';
import '../../registry_studio/translator/infrastructure/flutter_secure_translator_access_key_store.dart';
import '../../registry_studio/translator/infrastructure/json_file_translator_draft_store.dart';
import '../../registry_studio/translator/infrastructure/json_file_translator_history_store.dart';
import '../../registry_studio/translator/infrastructure/typhoon/typhoon_translator_provider.dart';
import '../../registry_studio/translator/presentation/translator_workspace_view.dart';
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
    this.registrySnapshotCache,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    this.translatorWorkspace,
    this.translatorWorkspaceController,
    this.localeStore = const FlutterSecureRegistryStudioLocaleStore(),
    super.key,
  });

  factory RegistryStudioApplication.helpy({Key? key}) {
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

    final TranslatorWorkspaceController translatorWorkspaceController =
        TranslatorWorkspaceController();

    return RegistryStudioApplication(
      key: key,
      registrySnapshotLoader: registrySnapshotLoader,
      registrySnapshotRefreshLoader: registrySnapshotLoader,
      registrySnapshotRevisionLoader: registrySnapshotLoader,
      registrySnapshotCache: const JsonFileRegistrySnapshotCache(),
      registryRevisionStateStore: const JsonFileRegistryRevisionStateStore(),
      registryAnalysisHistoryStore:
          const JsonLinesRegistryAnalysisHistoryStore(),
      translatorWorkspaceController: translatorWorkspaceController,
      translatorWorkspace: TranslatorWorkspaceView(
        provider: const TyphoonTranslatorProvider(
          policy: HelpyTranslatorPolicy(),
        ),
        draftStore: const JsonFileTranslatorDraftStore(),
        historyStore: const JsonFileTranslatorHistoryStore(),
        accessKeyStore: FlutterSecureTranslatorAccessKeyStore(
          storageKey: 'registry_studio.translator.typhoon.api_key.v1',
        ),
        controller: translatorWorkspaceController,
      ),
    );
  }

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistrySnapshotCache? registrySnapshotCache;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final Widget? translatorWorkspace;
  final TranslatorWorkspaceController? translatorWorkspaceController;
  final RegistryStudioLocaleStore localeStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryStudioLocaleCubit>(
      create: (_) => RegistryStudioLocaleCubit(store: localeStore)..restore(),
      child: _RegistryStudioMaterialApplication(
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registrySnapshotCache: registrySnapshotCache,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        translatorWorkspace: translatorWorkspace,
        translatorWorkspaceController: translatorWorkspaceController,
      ),
    );
  }
}

final class _RegistryStudioMaterialApplication extends StatelessWidget {
  const _RegistryStudioMaterialApplication({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    this.registrySnapshotCache,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.translatorWorkspace,
    required this.translatorWorkspaceController,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistrySnapshotCache? registrySnapshotCache;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final Widget? translatorWorkspace;
  final TranslatorWorkspaceController? translatorWorkspaceController;

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
            registrySnapshotCache: registrySnapshotCache,
            registryRevisionStateStore: registryRevisionStateStore,
            registryAnalysisHistoryStore: registryAnalysisHistoryStore,
            registrySnapshotComparator: const RegistrySnapshotComparator(),
            translatorWorkspace: translatorWorkspace,
            translatorWorkspaceController: translatorWorkspaceController,
          ),
        );
      },
    );
  }
}
