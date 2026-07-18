import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_node_identity_ledger_source.dart';
import '../../registry_studio/adapters/helpy/infrastructure/helpy_registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../shell/registry_studio_shell.dart';

final class RegistryStudioApplication extends StatelessWidget {
  const RegistryStudioApplication({
    required this.registrySnapshotLoader,
    super.key,
  });

  factory RegistryStudioApplication.helpy({Key? key}) {
    return RegistryStudioApplication(
      key: key,
      registrySnapshotLoader: HelpyRegistrySnapshotLoader(
        documentSource: GitHubRegistryDocumentSource(
          owner: 'srs2800302-collab',
          repository: 'helpy',
          documentPath:
              HelpyRegistryNodeIdentityLedgerSource.registryDocumentPath,
          ref: 'main',
        ),
        identityLedgerSource: HelpyRegistryNodeIdentityLedgerSource(
          assetBundle: rootBundle,
        ),
      ),
    );
  }

  final RegistrySnapshotLoader registrySnapshotLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registry Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: RegistryStudioShell(registrySnapshotLoader: registrySnapshotLoader),
    );
  }
}
