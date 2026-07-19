import 'package:flutter/material.dart';

import '../../registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/technical/storage/json_file_registry_revision_state_store.dart';
import '../../registry_studio/technical/storage/json_lines_registry_analysis_history_store.dart';
import '../shell/registry_studio_shell.dart';

final class RegistryStudioApplication extends StatelessWidget {
  const RegistryStudioApplication({
    required this.registrySnapshotLoader,
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
        );

    return RegistryStudioApplication(
      key: key,
      registrySnapshotLoader: registrySnapshotLoader,
      registrySnapshotRevisionLoader: registrySnapshotLoader,
      registryRevisionStateStore: const JsonFileRegistryRevisionStateStore(),
      registryAnalysisHistoryStore: const JsonLinesRegistryAnalysisHistoryStore(),
    );
  }

  final RegistrySnapshotLoader registrySnapshotLoader;
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
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        registrySnapshotComparator: const RegistrySnapshotComparator(),
      ),
    );
  }
}
