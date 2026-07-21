import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import '../../registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import '../../registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import '../../registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import '../../registry_studio/canonical/domain/entities/canonical_business_text_finding.dart';
import '../../registry_studio/canonical/presentation/canonical_business_text_analysis_cubit.dart';
import '../../registry_studio/canonical/presentation/canonical_business_text_analysis_status_action.dart';
import '../../registry_studio/canonical/presentation/canonical_dictionary_cubit.dart';
import '../../registry_studio/canonical/presentation/canonical_dictionary_status_action.dart';
import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/registry/domain/value_objects/registry_node_id.dart';
import '../../registry_studio/registry/presentation/registry_analysis_status_entry.dart';
import '../../registry_studio/registry/presentation/registry_explorer_view.dart';
import '../../registry_studio/registry/presentation/registry_problem_queue_entry.dart';

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
    this.canonicalDictionaryLoader,
    this.canonicalBusinessTextAnalysisSessionRunner,
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
    super.key,
  });

  final CanonicalDictionaryLoader? canonicalDictionaryLoader;

  final CanonicalBusinessTextAnalysisSessionRunner?
  canonicalBusinessTextAnalysisSessionRunner;
  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegistryStudioWorkspaceCubit>(
          create: (_) => RegistryStudioWorkspaceCubit(),
        ),
        if (canonicalDictionaryLoader != null)
          BlocProvider<CanonicalDictionaryCubit>(
            create: (_) =>
                CanonicalDictionaryCubit(loader: canonicalDictionaryLoader!)
                  ..load(),
          ),
        if (canonicalBusinessTextAnalysisSessionRunner != null)
          BlocProvider<CanonicalBusinessTextAnalysisCubit>(
            create: (_) => CanonicalBusinessTextAnalysisCubit(
              sessionRunner: canonicalBusinessTextAnalysisSessionRunner!,
            ),
          ),
      ],
      child: _RegistryStudioShellView(
        showCanonicalDictionaryStatus: canonicalDictionaryLoader != null,
        showCanonicalBusinessTextAnalysisStatus:
            canonicalBusinessTextAnalysisSessionRunner != null,
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

final class _RegistryStudioShellView extends StatefulWidget {
  const _RegistryStudioShellView({
    required this.showCanonicalDictionaryStatus,
    required this.showCanonicalBusinessTextAnalysisStatus,
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
  });

  final bool showCanonicalDictionaryStatus;
  final bool showCanonicalBusinessTextAnalysisStatus;
  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;

  @override
  State<_RegistryStudioShellView> createState() =>
      _RegistryStudioShellViewState();
}

final class _RegistryStudioShellViewState
    extends State<_RegistryStudioShellView> {
  Future<void> Function(RegistryNodeId? nodeId)? _selectRegistryNode;

  void _bindRegistryNodeSelection(
    Future<void> Function(RegistryNodeId? nodeId) selectRegistryNode,
  ) {
    _selectRegistryNode = selectRegistryNode;
  }

  Future<void> _openRegistryCandidate(
    CanonicalBusinessTextCandidate candidate,
  ) {
    final Future<void> Function(RegistryNodeId? nodeId)? selectRegistryNode =
        _selectRegistryNode;

    if (selectRegistryNode == null) {
      return Future<void>.error(StateError('Registry недоступен.'));
    }

    return selectRegistryNode(candidate.nodeId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistryStudioWorkspaceCubit, RegistryStudioWorkspace>(
      builder: (BuildContext context, RegistryStudioWorkspace workspace) {
        final int selectedIndex = RegistryStudioWorkspace.values.indexOf(
          workspace,
        );

        final List<RegistryProblemQueueEntry> canonicalProblemEntries =
            widget.showCanonicalBusinessTextAnalysisStatus
            ? _canonicalProblemEntries(
                context.watch<CanonicalBusinessTextAnalysisCubit>().state,
              )
            : const <RegistryProblemQueueEntry>[];

        final List<RegistryAnalysisStatusEntry> canonicalStatusEntries =
            widget.showCanonicalBusinessTextAnalysisStatus
            ? _canonicalStatusEntries(
                context.watch<CanonicalBusinessTextAnalysisCubit>().state,
              )
            : const <RegistryAnalysisStatusEntry>[];

        return Scaffold(
          appBar: AppBar(
            title: Text(_titleFor(workspace)),
            actions: <Widget>[
              if (workspace == RegistryStudioWorkspace.registryStudio &&
                  widget.showCanonicalDictionaryStatus)
                const CanonicalDictionaryStatusAction(),
              if (workspace == RegistryStudioWorkspace.registryStudio &&
                  widget.showCanonicalBusinessTextAnalysisStatus)
                CanonicalBusinessTextAnalysisStatusAction(
                  onOpenRegistryCandidate: _openRegistryCandidate,
                ),
            ],
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: <Widget>[
              RegistryExplorerView(
                snapshotLoader: widget.registrySnapshotLoader,
                snapshotRefreshLoader: widget.registrySnapshotRefreshLoader,
                snapshotRevisionLoader: widget.registrySnapshotRevisionLoader,
                revisionStateStore: widget.registryRevisionStateStore,
                analysisHistoryStore: widget.registryAnalysisHistoryStore,
                snapshotComparator: widget.registrySnapshotComparator,
                analysisProblemEntries: canonicalProblemEntries,
                analysisStatusEntries: canonicalStatusEntries,
                onRegistryNodeSelectionReady: _bindRegistryNodeSelection,
                onSnapshotAccepted:
                    widget.showCanonicalBusinessTextAnalysisStatus
                    ? (snapshot) {
                        unawaited(
                          context
                              .read<CanonicalBusinessTextAnalysisCubit>()
                              .acceptSnapshot(snapshot),
                        );
                      }
                    : null,
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

  List<RegistryProblemQueueEntry> _canonicalProblemEntries(
    CanonicalBusinessTextAnalysisState state,
  ) {
    if (state is! CanonicalBusinessTextAnalysisReady) {
      return const <RegistryProblemQueueEntry>[];
    }

    return List<RegistryProblemQueueEntry>.unmodifiable(
      state.result.findings.findings.map((
        CanonicalBusinessTextFinding finding,
      ) {
        return RegistryProblemQueueEntry(
          identity: 'canonical:${finding.identity}',
          nodeId: finding.candidate.nodeId,
          path: finding.candidate.path,
          typeLabel: 'Canonical finding',
          statusLabel: _canonicalStatusLabel(finding.status.name),
          reason: _canonicalReasonLabel(finding.reason.name),
          severity: switch (finding.disposition) {
            CanonicalBusinessTextFindingDisposition.informational =>
              RegistryProblemQueueEntrySeverity.informational,
            CanonicalBusinessTextFindingDisposition.reviewRequired =>
              RegistryProblemQueueEntrySeverity.reviewRequired,
            CanonicalBusinessTextFindingDisposition.blocking =>
              RegistryProblemQueueEntrySeverity.blocking,
          },
          sourceEvidence: finding.candidate.sourceEvidence,
        );
      }),
    );
  }

  List<RegistryAnalysisStatusEntry> _canonicalStatusEntries(
    CanonicalBusinessTextAnalysisState state,
  ) {
    if (state is! CanonicalBusinessTextAnalysisReady) {
      return const <RegistryAnalysisStatusEntry>[];
    }

    return List<RegistryAnalysisStatusEntry>.unmodifiable(
      state.result.classifications.classifications.map((
        CanonicalBusinessTextClassification classification,
      ) {
        return RegistryAnalysisStatusEntry(
          identity: 'canonical-status:${classification.candidate.identity}',
          nodeId: classification.candidate.nodeId,
          statusId: classification.status.name,
        );
      }),
    );
  }

  String _canonicalStatusLabel(String status) {
    return switch (status) {
      'unclassifiedNeutral' => 'Без точного канонического совпадения',
      'review' => 'Требуется проверка',
      'drift' => 'Каноническое расхождение',
      'failed' => 'Ошибка анализа',
      'exact' => 'Точное совпадение',
      'equivalent' => 'Эквивалентная формулировка',
      _ => status,
    };
  }

  String _canonicalReasonLabel(String reason) {
    return switch (reason) {
      'noExactCanonicalTextMatch' =>
        'Точное каноническое совпадение не найдено',
      'singleExactUniversalMatch' =>
        'Найдено одно точное универсальное совпадение',
      'exactTextRequiresApplicabilityReview' =>
        'Требуется проверка применимости',
      'ambiguousExactCanonicalTextMatch' =>
        'Найдено несколько точных совпадений',
      _ => reason,
    };
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
