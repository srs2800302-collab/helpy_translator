import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/registry/presentation/registry_explorer_view.dart';

enum RegistryStudioWorkspace { registryStudio, translator }

final class RegistryStudioWorkspaceCubit
    extends Cubit<RegistryStudioWorkspace> {
  RegistryStudioWorkspaceCubit()
    : super(RegistryStudioWorkspace.registryStudio);

  void select(RegistryStudioWorkspace workspace) {
    if (state == workspace) {
      return;
    }

    emit(workspace);
  }
}

final class RegistryStudioShell extends StatelessWidget {
  const RegistryStudioShell({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
    super.key,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryStudioWorkspaceCubit>(
      create: (_) => RegistryStudioWorkspaceCubit(),
      child: _RegistryStudioShellView(
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        registrySnapshotComparator: registrySnapshotComparator,
      ),
    );
  }
}

final class _RegistryStudioShellView extends StatelessWidget {
  const _RegistryStudioShellView({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistryStudioWorkspaceCubit, RegistryStudioWorkspace>(
      builder: (BuildContext context, RegistryStudioWorkspace workspace) {
        final int selectedIndex = RegistryStudioWorkspace.values.indexOf(
          workspace,
        );

        return Scaffold(
          appBar: AppBar(title: Text(_titleFor(workspace))),
          body: IndexedStack(
            index: selectedIndex,
            children: <Widget>[
              RegistryExplorerView(
                isActive: workspace == RegistryStudioWorkspace.registryStudio,
                snapshotLoader: registrySnapshotLoader,
                snapshotRefreshLoader: registrySnapshotRefreshLoader,
                snapshotRevisionLoader: registrySnapshotRevisionLoader,
                revisionStateStore: registryRevisionStateStore,
                analysisHistoryStore: registryAnalysisHistoryStore,
                snapshotComparator: registrySnapshotComparator,
              ),
              const _TranslatorWorkspaceView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              context.read<RegistryStudioWorkspaceCubit>().select(
                RegistryStudioWorkspace.values[index],
              );
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree),
                label: 'Registry Studio',
              ),
              NavigationDestination(
                icon: Icon(Icons.translate_outlined),
                selectedIcon: Icon(Icons.translate),
                label: 'Translator',
              ),
            ],
          ),
        );
      },
    );
  }

  String _titleFor(RegistryStudioWorkspace workspace) {
    return switch (workspace) {
      RegistryStudioWorkspace.registryStudio => 'Registry Studio',
      RegistryStudioWorkspace.translator => 'Translator',
    };
  }
}

final class _TranslatorWorkspaceView extends StatelessWidget {
  const _TranslatorWorkspaceView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.translate_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'Translator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Перевод и проверка формулировок RU / EN / TH',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
