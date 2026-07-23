import 'package:flutter/material.dart';

import '../../registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_canonical_business_text_candidate_extractor.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_canonical_phrase_applicability_resolver.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_loader.dart';
import '../../registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import '../../registry_studio/canonical/application/deterministic_canonical_business_text_classifier.dart';
import '../../registry_studio/canonical/application/run_canonical_business_text_analysis.dart';
import '../../registry_studio/canonical/application/run_canonical_business_text_analysis_session.dart';
import '../../registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/adapters/helpy/infrastructure/json_file_helpy_registry_node_identity_store.dart';
import '../../registry_studio/technical/storage/json_file_registry_revision_state_store.dart';
import '../../registry_studio/technical/storage/json_lines_registry_analysis_history_store.dart';
import '../shell/registry_studio_shell.dart';

final class RegistryStudioApplication extends StatelessWidget {
  const RegistryStudioApplication({
    this.canonicalDictionaryLoader,
    this.canonicalBusinessTextAnalysisSessionRunner,
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
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

    final HelpyCanonicalDictionaryLoader canonicalDictionaryLoader =
        HelpyCanonicalDictionaryLoader(
          documentSource: GitHubRegistryDocumentSource(
            owner: 'srs2800302-collab',
            repository: 'helpy_translator',
            documentPath:
                'docs/architecture/registry_studio/'
                'Registry_Studio_Engineering_Change_Propagation_'
                'and_Approval_Contract_v1.md',
            ref: 'registry-studio/modular-rebuild',
          ),
        );

    return RegistryStudioApplication(
      key: key,
      canonicalDictionaryLoader: canonicalDictionaryLoader,
      canonicalBusinessTextAnalysisSessionRunner:
          RunCanonicalBusinessTextAnalysisSession(
            canonicalDictionaryLoader: canonicalDictionaryLoader,
            analysis: const RunCanonicalBusinessTextAnalysis(
              candidateExtractor:
                  HelpyCanonicalBusinessTextCandidateExtractor(),
              classifier: DeterministicCanonicalBusinessTextClassifier(
                applicabilityResolver:
                    HelpyCanonicalPhraseApplicabilityResolver(),
              ),
            ),
          ),
      registrySnapshotLoader: registrySnapshotLoader,
      registrySnapshotRefreshLoader: registrySnapshotLoader,
      registrySnapshotRevisionLoader: registrySnapshotLoader,
      registryRevisionStateStore: const JsonFileRegistryRevisionStateStore(),
      registryAnalysisHistoryStore:
          const JsonLinesRegistryAnalysisHistoryStore(),
    );
  }

  final CanonicalDictionaryLoader? canonicalDictionaryLoader;

  final CanonicalBusinessTextAnalysisSessionRunner?
  canonicalBusinessTextAnalysisSessionRunner;
  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registry Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: RegistryStudioShell(
        canonicalDictionaryLoader: canonicalDictionaryLoader,
        canonicalBusinessTextAnalysisSessionRunner:
            canonicalBusinessTextAnalysisSessionRunner,
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        registrySnapshotComparator: const RegistrySnapshotComparator(),
      ),
    );
  }
}
