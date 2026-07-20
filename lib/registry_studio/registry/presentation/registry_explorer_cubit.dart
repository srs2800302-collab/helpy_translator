import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_snapshot_comparison.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../../maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
import '../application/contracts/registry_snapshot_refresh_loader.dart';
import '../application/contracts/registry_snapshot_revision_loader.dart';
import '../domain/entities/registry_node.dart';
import '../domain/entities/registry_snapshot.dart';
import '../domain/entities/registry_structural_index.dart';
import '../domain/value_objects/registry_node_id.dart';

sealed class RegistryExplorerState {
  const RegistryExplorerState();
}

final class RegistryExplorerLoading extends RegistryExplorerState {
  const RegistryExplorerLoading();
}

final class RegistryExplorerLoaded extends RegistryExplorerState {
  const RegistryExplorerLoaded({
    required this.snapshot,
    required this.index,
    required this.previousSnapshot,
    required this.previousComparison,
    required this.cleanBaselineSnapshot,
    required this.cleanBaselineComparison,
    required this.openRegistryNodeId,
    required this.openRegistryPath,
    required this.selectedProblemIndex,
    this.analysisHistory = const <RegistryAnalysisHistoryEntry>[],
    this.searchQuery = '',
  });

  final RegistrySnapshot snapshot;
  final RegistryStructuralIndex index;
  final RegistrySnapshot? previousSnapshot;
  final RegistrySnapshotComparison? previousComparison;
  final RegistrySnapshot? cleanBaselineSnapshot;
  final RegistrySnapshotComparison? cleanBaselineComparison;
  final RegistryNodeId? openRegistryNodeId;
  final RegistryPath? openRegistryPath;
  final int? selectedProblemIndex;
  final List<RegistryAnalysisHistoryEntry> analysisHistory;
  final String searchQuery;

  RegistrySnapshotComparison? get problemComparison =>
      cleanBaselineComparison ?? previousComparison;

  List<RegistryStructuralProblem> get problems =>
      problemComparison?.problems ?? const <RegistryStructuralProblem>[];

  List<RegistryNode> get searchResults {
    final String normalizedQuery = searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return index.nodes;
    }

    return index.nodes
        .where((RegistryNode node) {
          final List<String> pathSegments = node.path.segments;

          if (node.id.value.toLowerCase().contains(normalizedQuery) ||
              node.kindId.toLowerCase().contains(normalizedQuery) ||
              node.content.toLowerCase().contains(normalizedQuery) ||
              pathSegments.any(
                (String segment) =>
                    segment.toLowerCase().contains(normalizedQuery),
              ) ||
              pathSegments.join('/').toLowerCase().contains(normalizedQuery) ||
              pathSegments
                  .join(' / ')
                  .toLowerCase()
                  .contains(normalizedQuery) ||
              pathSegments
                  .join(' → ')
                  .toLowerCase()
                  .contains(normalizedQuery)) {
            return true;
          }

          for (final SourceEvidence evidence in node.sourceEvidence) {
            final List<String> headingPath = evidence.headingPath;
            final String lineRange =
                '${evidence.startLine}-${evidence.endLine}';
            final String typographicLineRange =
                '${evidence.startLine}–${evidence.endLine}';

            if (evidence.sourceDocumentPath.toLowerCase().contains(
                  normalizedQuery,
                ) ||
                evidence.sourceSnapshotFingerprint.toLowerCase().contains(
                  normalizedQuery,
                ) ||
                headingPath.any(
                  (String segment) =>
                      segment.toLowerCase().contains(normalizedQuery),
                ) ||
                headingPath.join('/').toLowerCase().contains(normalizedQuery) ||
                headingPath
                    .join(' / ')
                    .toLowerCase()
                    .contains(normalizedQuery) ||
                headingPath
                    .join(' → ')
                    .toLowerCase()
                    .contains(normalizedQuery) ||
                evidence.startLine.toString().contains(normalizedQuery) ||
                evidence.endLine.toString().contains(normalizedQuery) ||
                lineRange.contains(normalizedQuery) ||
                typographicLineRange.contains(normalizedQuery)) {
              return true;
            }
          }

          return false;
        })
        .toList(growable: false);
  }

  RegistryNode? get openRegistryNode {
    final RegistryNodeId? nodeId = openRegistryNodeId;
    final RegistryPath? path = openRegistryPath;

    if (nodeId == null || path == null) {
      return null;
    }

    final RegistryNode? node = index.nodesById[nodeId];

    if (node == null || node.path != path) {
      return null;
    }

    return node;
  }

  RegistryStructuralProblem? get selectedProblem {
    final int? problemIndex = selectedProblemIndex;

    if (problemIndex == null ||
        problemIndex < 0 ||
        problemIndex >= problems.length) {
      return null;
    }

    final RegistryStructuralProblem problem = problems[problemIndex];

    if (problem.exactNode.id != openRegistryNodeId ||
        problem.path != openRegistryPath) {
      return null;
    }

    return problem;
  }
}

final class RegistryExplorerFailure extends RegistryExplorerState {
  const RegistryExplorerFailure(
    this.message, {
    required this.openRegistryNodeBeforeRefresh,
    this.searchQueryBeforeRefresh = '',
    this.analysisHistoryBeforeRefresh = const <RegistryAnalysisHistoryEntry>[],
  });

  final String message;
  final RegistryNode? openRegistryNodeBeforeRefresh;
  final String searchQueryBeforeRefresh;
  final List<RegistryAnalysisHistoryEntry> analysisHistoryBeforeRefresh;
}

final class RegistryExplorerCubit extends Cubit<RegistryExplorerState> {
  RegistryExplorerCubit({
    required this.snapshotLoader,
    required this.snapshotRefreshLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.analysisHistoryStore,
    required this.snapshotComparator,
  }) : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRefreshLoader snapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistryAnalysisHistoryStore analysisHistoryStore;
  final RegistrySnapshotComparator snapshotComparator;

  bool _isLoading = false;
  bool _retryRefresh = false;

  RegistrySnapshot? _currentSnapshot;
  RegistrySnapshot? _previousSnapshot;
  RegistrySnapshot? _cleanBaselineSnapshot;

  Future<void> _pendingSearchQueryWrite = Future<void>.value();

  Future<void> restore() async {
    if (_isLoading) {
      return;
    }

    _retryRefresh = false;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    String searchQuery = '';
    List<RegistryAnalysisHistoryEntry> analysisHistory =
        const <RegistryAnalysisHistoryEntry>[];

    try {
      final RegistryRevisionState? persistedState = await revisionStateStore
          .loadRevisionState();
      final List<RegistryAnalysisHistoryEntry> storedAnalysisHistory =
          await analysisHistoryStore.loadHistory();

      searchQuery = persistedState?.searchQuery ?? '';

      late final RegistrySnapshot snapshot;
      RegistrySnapshot? previousSnapshot;
      RegistrySnapshot? cleanBaselineSnapshot;

      if (persistedState == null) {
        snapshot = await snapshotLoader.loadSnapshot();
      } else {
        snapshot = await snapshotRevisionLoader.loadSnapshotAtRevision(
          persistedState.currentRevision,
        );

        if (snapshot.projectId != persistedState.projectId ||
            snapshot.projectAdapterId != persistedState.projectAdapterId ||
            snapshot.sourceDocumentPath != persistedState.sourceDocumentPath ||
            snapshot.sourceRevision != persistedState.currentRevision) {
          throw StateError(
            'Restored current Registry snapshot does not match '
            'the persisted revision coordinates.',
          );
        }

        final String? previousRevision = persistedState.previousRevision;

        if (previousRevision != null) {
          previousSnapshot = await snapshotRevisionLoader
              .loadSnapshotAtRevision(previousRevision);

          if (previousSnapshot.projectId != persistedState.projectId ||
              previousSnapshot.projectAdapterId !=
                  persistedState.projectAdapterId ||
              previousSnapshot.sourceDocumentPath !=
                  persistedState.sourceDocumentPath ||
              previousSnapshot.sourceRevision != previousRevision) {
            throw StateError(
              'Restored previous Registry snapshot does not match '
              'the persisted revision coordinates.',
            );
          }
        }

        final String? cleanBaselineRevision =
            persistedState.cleanBaselineRevision;

        if (cleanBaselineRevision != null) {
          if (cleanBaselineRevision == snapshot.sourceRevision) {
            cleanBaselineSnapshot = snapshot;
          } else if (previousSnapshot != null &&
              cleanBaselineRevision == previousSnapshot.sourceRevision) {
            cleanBaselineSnapshot = previousSnapshot;
          } else {
            cleanBaselineSnapshot = await snapshotRevisionLoader
                .loadSnapshotAtRevision(cleanBaselineRevision);
          }

          if (cleanBaselineSnapshot.projectId != persistedState.projectId ||
              cleanBaselineSnapshot.projectAdapterId !=
                  persistedState.projectAdapterId ||
              cleanBaselineSnapshot.sourceDocumentPath !=
                  persistedState.sourceDocumentPath ||
              cleanBaselineSnapshot.sourceRevision != cleanBaselineRevision) {
            throw StateError(
              'Restored clean baseline Registry snapshot '
              'does not match the persisted revision coordinates.',
            );
          }
        }
      }

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison? cleanBaselineComparison =
          cleanBaselineSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(cleanBaselineSnapshot),
              currentIndex: index,
            );

      final List<RegistryStructuralProblem> problems =
          (cleanBaselineComparison ?? previousComparison)?.problems ??
          const <RegistryStructuralProblem>[];

      final RegistryNodeId? openRegistryNodeId =
          persistedState?.openRegistryNodeId;

      final RegistryPath? openRegistryPath = persistedState?.openRegistryPath;

      int? selectedProblemIndex;

      if (persistedState != null &&
          openRegistryNodeId != null &&
          openRegistryPath != null &&
          persistedState.selectedProblemIndex != null) {
        final int persistedProblemIndex = persistedState.selectedProblemIndex!;

        if (persistedProblemIndex < problems.length) {
          final RegistryStructuralProblem candidate =
              problems[persistedProblemIndex];

          if (candidate.exactNode.id == openRegistryNodeId &&
              candidate.path == openRegistryPath) {
            selectedProblemIndex = persistedProblemIndex;
          }
        }

        if (selectedProblemIndex == null) {
          final int resolvedProblemIndex = problems.indexWhere(
            (RegistryStructuralProblem problem) =>
                problem.exactNode.id == openRegistryNodeId &&
                problem.path == openRegistryPath,
          );

          if (resolvedProblemIndex >= 0) {
            selectedProblemIndex = resolvedProblemIndex;
          }
        }
      }

      if (persistedState == null) {
        await revisionStateStore.saveRevisionState(
          RegistryRevisionState(
            projectId: snapshot.projectId,
            projectAdapterId: snapshot.projectAdapterId,
            sourceDocumentPath: snapshot.sourceDocumentPath,
            currentRevision: snapshot.sourceRevision,
            previousRevision: null,
            cleanBaselineRevision: null,
            searchQuery: searchQuery,
          ),
        );
      }

      analysisHistory = List<RegistryAnalysisHistoryEntry>.unmodifiable(
        storedAnalysisHistory.where(
          (RegistryAnalysisHistoryEntry entry) =>
              entry.projectId == snapshot.projectId &&
              entry.projectAdapterId == snapshot.projectAdapterId &&
              entry.sourceDocumentPath == snapshot.sourceDocumentPath,
        ),
      );

      final RegistryAnalysisHistoryEntry
      historyEntry = RegistryAnalysisHistoryEntry(
        loadedAt: DateTime.now().toUtc(),
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: snapshot.sourceRevision,
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        previousRevision: previousSnapshot?.sourceRevision,
        cleanBaselineRevision: cleanBaselineSnapshot?.sourceRevision,
        previousAddedCount: previousComparison?.addedCount ?? 0,
        previousRemovedCount: previousComparison?.removedCount ?? 0,
        previousChangedCount: previousComparison?.changedCount ?? 0,
        cleanBaselineAddedCount: cleanBaselineComparison?.addedCount ?? 0,
        cleanBaselineRemovedCount: cleanBaselineComparison?.removedCount ?? 0,
        cleanBaselineChangedCount: cleanBaselineComparison?.changedCount ?? 0,
        problemCount: problems.length,
        problems: problems
            .map(
              (RegistryStructuralProblem problem) =>
                  RegistryAnalysisHistoryProblem(
                    nodeId: problem.exactNode.id.value,
                    pathSegments: problem.path.segments,
                    status: problem.status.name,
                    reason: problem.reason,
                  ),
            )
            .toList(growable: false),
      );

      final bool historyEntryAlreadyRecorded =
          analysisHistory.isNotEmpty &&
          analysisHistory.last.sourceRevision == historyEntry.sourceRevision &&
          analysisHistory.last.sourceSnapshotFingerprint ==
              historyEntry.sourceSnapshotFingerprint &&
          analysisHistory.last.previousRevision ==
              historyEntry.previousRevision &&
          analysisHistory.last.cleanBaselineRevision ==
              historyEntry.cleanBaselineRevision &&
          analysisHistory.last.previousAddedCount ==
              historyEntry.previousAddedCount &&
          analysisHistory.last.previousRemovedCount ==
              historyEntry.previousRemovedCount &&
          analysisHistory.last.previousChangedCount ==
              historyEntry.previousChangedCount &&
          analysisHistory.last.cleanBaselineAddedCount ==
              historyEntry.cleanBaselineAddedCount &&
          analysisHistory.last.cleanBaselineRemovedCount ==
              historyEntry.cleanBaselineRemovedCount &&
          analysisHistory.last.cleanBaselineChangedCount ==
              historyEntry.cleanBaselineChangedCount &&
          analysisHistory.last.problemCount == historyEntry.problemCount &&
          analysisHistory.last.problems.length ==
              historyEntry.problems.length &&
          analysisHistory.last.problems.asMap().entries.every(
            (MapEntry<int, RegistryAnalysisHistoryProblem> problemEntry) =>
                problemEntry.value == historyEntry.problems[problemEntry.key],
          );

      if (!historyEntryAlreadyRecorded) {
        await analysisHistoryStore.appendHistoryEntry(historyEntry);

        analysisHistory = List<RegistryAnalysisHistoryEntry>.unmodifiable(
          <RegistryAnalysisHistoryEntry>[...analysisHistory, historyEntry],
        );
      }

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;
      _cleanBaselineSnapshot = cleanBaselineSnapshot;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: snapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: cleanBaselineSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            openRegistryNodeId: openRegistryNodeId,
            openRegistryPath: openRegistryPath,
            selectedProblemIndex: selectedProblemIndex,
            analysisHistory: analysisHistory,
            searchQuery: searchQuery,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        final String message = error.toString().trim();

        emit(
          RegistryExplorerFailure(
            message.isEmpty ? 'Неизвестная ошибка загрузки Registry.' : message,
            openRegistryNodeBeforeRefresh: null,
            searchQueryBeforeRefresh: searchQuery,
            analysisHistoryBeforeRefresh: analysisHistory,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    if (_isLoading) {
      return;
    }

    final RegistryExplorerState stateBeforeRefresh = state;

    final RegistryNode? openRegistryNodeBeforeRefresh;
    final RegistryStructuralProblem? selectedProblemBeforeRefresh;
    final String searchQueryBeforeRefresh;
    final List<RegistryAnalysisHistoryEntry> analysisHistoryBeforeRefresh =
        stateBeforeRefresh is RegistryExplorerLoaded
        ? stateBeforeRefresh.analysisHistory
        : stateBeforeRefresh is RegistryExplorerFailure
        ? stateBeforeRefresh.analysisHistoryBeforeRefresh
        : const <RegistryAnalysisHistoryEntry>[];

    if (stateBeforeRefresh is RegistryExplorerLoaded) {
      openRegistryNodeBeforeRefresh = stateBeforeRefresh.openRegistryNode;
      selectedProblemBeforeRefresh = stateBeforeRefresh.selectedProblem;
      searchQueryBeforeRefresh = stateBeforeRefresh.searchQuery;
    } else if (stateBeforeRefresh is RegistryExplorerFailure) {
      openRegistryNodeBeforeRefresh =
          stateBeforeRefresh.openRegistryNodeBeforeRefresh;
      selectedProblemBeforeRefresh = null;
      searchQueryBeforeRefresh = stateBeforeRefresh.searchQueryBeforeRefresh;
    } else {
      openRegistryNodeBeforeRefresh = null;
      selectedProblemBeforeRefresh = null;
      searchQueryBeforeRefresh = '';
    }

    final RegistryNodeId? openRegistryNodeId =
        openRegistryNodeBeforeRefresh?.id;

    _retryRefresh = true;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      await _pendingSearchQueryWrite;

      final RegistrySnapshot? currentSnapshot = _currentSnapshot;

      final RegistrySnapshot snapshot = currentSnapshot == null
          ? await snapshotLoader.loadSnapshot()
          : await snapshotRefreshLoader.loadSnapshotAfterRevision(
              currentSnapshot.sourceRevision,
            );

      RegistrySnapshot? previousSnapshot = _previousSnapshot;

      if (currentSnapshot != null) {
        if (snapshot.projectId != currentSnapshot.projectId ||
            snapshot.projectAdapterId != currentSnapshot.projectAdapterId ||
            snapshot.sourceDocumentPath != currentSnapshot.sourceDocumentPath) {
          throw StateError(
            'Refreshed Registry snapshot does not match '
            'the current Registry coordinates.',
          );
        }

        if (snapshot.sourceRevision != currentSnapshot.sourceRevision) {
          previousSnapshot = currentSnapshot;
        }
      }

      final RegistrySnapshot? cleanBaselineSnapshot = _cleanBaselineSnapshot;

      final RegistryStructuralIndex index = RegistryStructuralIndex(snapshot);

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison? cleanBaselineComparison =
          cleanBaselineSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(cleanBaselineSnapshot),
              currentIndex: index,
            );

      final List<RegistryStructuralProblem> refreshedProblems =
          (cleanBaselineComparison ?? previousComparison)?.problems ??
          const <RegistryStructuralProblem>[];

      int? refreshedSelectedProblemIndex;

      if (selectedProblemBeforeRefresh != null) {
        final RegistryStructuralProblem selectedProblem =
            selectedProblemBeforeRefresh;

        final int identityMatchIndex = refreshedProblems.indexWhere(
          (RegistryStructuralProblem problem) =>
              problem.exactNode.id == selectedProblem.exactNode.id,
        );

        if (identityMatchIndex >= 0) {
          refreshedSelectedProblemIndex = identityMatchIndex;
        } else {
          final int pathMatchIndex = refreshedProblems.indexWhere(
            (RegistryStructuralProblem problem) =>
                problem.path == selectedProblem.path,
          );

          if (pathMatchIndex >= 0) {
            refreshedSelectedProblemIndex = pathMatchIndex;
          }
        }
      }

      final RegistryStructuralProblem? refreshedSelectedProblem =
          refreshedSelectedProblemIndex == null
          ? null
          : refreshedProblems[refreshedSelectedProblemIndex];

      final RegistryNode? refreshedOpenRegistryNode =
          refreshedSelectedProblem == null && openRegistryNodeId != null
          ? index.nodesById[openRegistryNodeId]
          : null;

      final RegistryNodeId? refreshedOpenRegistryNodeId =
          refreshedSelectedProblem?.exactNode.id ??
          refreshedOpenRegistryNode?.id;

      final RegistryPath? refreshedOpenRegistryPath =
          refreshedSelectedProblem?.path ?? refreshedOpenRegistryNode?.path;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: snapshot.projectId,
          projectAdapterId: snapshot.projectAdapterId,
          sourceDocumentPath: snapshot.sourceDocumentPath,
          currentRevision: snapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
          cleanBaselineRevision: cleanBaselineSnapshot?.sourceRevision,
          openRegistryNodeId: refreshedOpenRegistryNodeId,
          openRegistryPath: refreshedOpenRegistryPath,
          selectedProblemIndex: refreshedSelectedProblemIndex,
          searchQuery: searchQueryBeforeRefresh,
        ),
      );

      final RegistryAnalysisHistoryEntry
      historyEntry = RegistryAnalysisHistoryEntry(
        loadedAt: DateTime.now().toUtc(),
        projectId: snapshot.projectId,
        projectAdapterId: snapshot.projectAdapterId,
        sourceDocumentPath: snapshot.sourceDocumentPath,
        sourceRevision: snapshot.sourceRevision,
        sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        previousRevision: previousSnapshot?.sourceRevision,
        cleanBaselineRevision: cleanBaselineSnapshot?.sourceRevision,
        previousAddedCount: previousComparison?.addedCount ?? 0,
        previousRemovedCount: previousComparison?.removedCount ?? 0,
        previousChangedCount: previousComparison?.changedCount ?? 0,
        cleanBaselineAddedCount: cleanBaselineComparison?.addedCount ?? 0,
        cleanBaselineRemovedCount: cleanBaselineComparison?.removedCount ?? 0,
        cleanBaselineChangedCount: cleanBaselineComparison?.changedCount ?? 0,
        problemCount: refreshedProblems.length,
        problems: refreshedProblems
            .map(
              (RegistryStructuralProblem problem) =>
                  RegistryAnalysisHistoryProblem(
                    nodeId: problem.exactNode.id.value,
                    pathSegments: problem.path.segments,
                    status: problem.status.name,
                    reason: problem.reason,
                  ),
            )
            .toList(growable: false),
      );

      final bool historyEntryAlreadyRecorded =
          analysisHistoryBeforeRefresh.isNotEmpty &&
          analysisHistoryBeforeRefresh.last.sourceRevision ==
              historyEntry.sourceRevision &&
          analysisHistoryBeforeRefresh.last.sourceSnapshotFingerprint ==
              historyEntry.sourceSnapshotFingerprint &&
          analysisHistoryBeforeRefresh.last.previousRevision ==
              historyEntry.previousRevision &&
          analysisHistoryBeforeRefresh.last.cleanBaselineRevision ==
              historyEntry.cleanBaselineRevision &&
          analysisHistoryBeforeRefresh.last.previousAddedCount ==
              historyEntry.previousAddedCount &&
          analysisHistoryBeforeRefresh.last.previousRemovedCount ==
              historyEntry.previousRemovedCount &&
          analysisHistoryBeforeRefresh.last.previousChangedCount ==
              historyEntry.previousChangedCount &&
          analysisHistoryBeforeRefresh.last.cleanBaselineAddedCount ==
              historyEntry.cleanBaselineAddedCount &&
          analysisHistoryBeforeRefresh.last.cleanBaselineRemovedCount ==
              historyEntry.cleanBaselineRemovedCount &&
          analysisHistoryBeforeRefresh.last.cleanBaselineChangedCount ==
              historyEntry.cleanBaselineChangedCount &&
          analysisHistoryBeforeRefresh.last.problemCount ==
              historyEntry.problemCount &&
          analysisHistoryBeforeRefresh.last.problems.length ==
              historyEntry.problems.length &&
          analysisHistoryBeforeRefresh.last.problems.asMap().entries.every(
            (MapEntry<int, RegistryAnalysisHistoryProblem> problemEntry) =>
                problemEntry.value == historyEntry.problems[problemEntry.key],
          );

      if (!historyEntryAlreadyRecorded) {
        await analysisHistoryStore.appendHistoryEntry(historyEntry);
      }

      final List<RegistryAnalysisHistoryEntry> analysisHistory =
          historyEntryAlreadyRecorded
          ? analysisHistoryBeforeRefresh
          : List<RegistryAnalysisHistoryEntry>.unmodifiable(
              <RegistryAnalysisHistoryEntry>[
                ...analysisHistoryBeforeRefresh,
                historyEntry,
              ],
            );

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;
      _retryRefresh = false;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: snapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: cleanBaselineSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            openRegistryNodeId: refreshedOpenRegistryNodeId,
            openRegistryPath: refreshedOpenRegistryPath,
            selectedProblemIndex: refreshedSelectedProblemIndex,
            analysisHistory: analysisHistory,
            searchQuery: searchQueryBeforeRefresh,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        final String message = error.toString().trim();

        emit(
          RegistryExplorerFailure(
            message.isEmpty ? 'Неизвестная ошибка загрузки Registry.' : message,
            openRegistryNodeBeforeRefresh: openRegistryNodeBeforeRefresh,
            searchQueryBeforeRefresh: searchQueryBeforeRefresh,
            analysisHistoryBeforeRefresh: analysisHistoryBeforeRefresh,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> confirmCurrentAsCleanBaseline() async {
    if (_isLoading) {
      return;
    }

    final RegistrySnapshot? currentSnapshot = _currentSnapshot;

    if (currentSnapshot == null) {
      throw StateError('Current Registry snapshot is unavailable.');
    }

    if (_cleanBaselineSnapshot?.sourceRevision ==
        currentSnapshot.sourceRevision) {
      return;
    }

    final RegistryExplorerState currentState = state;
    final String searchQuery = currentState is RegistryExplorerLoaded
        ? currentState.searchQuery
        : currentState is RegistryExplorerFailure
        ? currentState.searchQueryBeforeRefresh
        : '';
    final List<RegistryAnalysisHistoryEntry> analysisHistory =
        currentState is RegistryExplorerLoaded
        ? currentState.analysisHistory
        : currentState is RegistryExplorerFailure
        ? currentState.analysisHistoryBeforeRefresh
        : const <RegistryAnalysisHistoryEntry>[];

    _isLoading = true;

    try {
      await _pendingSearchQueryWrite;

      final RegistrySnapshot? previousSnapshot = _previousSnapshot;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: currentSnapshot.projectId,
          projectAdapterId: currentSnapshot.projectAdapterId,
          sourceDocumentPath: currentSnapshot.sourceDocumentPath,
          currentRevision: currentSnapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
          cleanBaselineRevision: currentSnapshot.sourceRevision,
          searchQuery: searchQuery,
        ),
      );

      final RegistryStructuralIndex index = RegistryStructuralIndex(
        currentSnapshot,
      );

      final RegistrySnapshotComparison? previousComparison =
          previousSnapshot == null
          ? null
          : snapshotComparator.compare(
              previousIndex: RegistryStructuralIndex(previousSnapshot),
              currentIndex: index,
            );

      final RegistrySnapshotComparison cleanBaselineComparison =
          snapshotComparator.compare(previousIndex: index, currentIndex: index);

      _cleanBaselineSnapshot = currentSnapshot;

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: currentSnapshot,
            index: index,
            previousSnapshot: previousSnapshot,
            previousComparison: previousComparison,
            cleanBaselineSnapshot: currentSnapshot,
            cleanBaselineComparison: cleanBaselineComparison,
            openRegistryNodeId: null,
            openRegistryPath: null,
            selectedProblemIndex: null,
            analysisHistory: analysisHistory,
            searchQuery: searchQuery,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> selectProblem(int? index) async {
    if (_isLoading) {
      throw StateError('Контекст Registry уже обновляется.');
    }

    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      throw StateError('Registry problems are unavailable.');
    }

    if (index != null && (index < 0 || index >= currentState.problems.length)) {
      throw RangeError.index(index, currentState.problems, 'index');
    }

    final RegistryStructuralProblem? selectedProblem = index == null
        ? null
        : currentState.problems[index];

    _isLoading = true;

    try {
      await _pendingSearchQueryWrite;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: currentState.snapshot.projectId,
          projectAdapterId: currentState.snapshot.projectAdapterId,
          sourceDocumentPath: currentState.snapshot.sourceDocumentPath,
          currentRevision: currentState.snapshot.sourceRevision,
          previousRevision: currentState.previousSnapshot?.sourceRevision,
          cleanBaselineRevision:
              currentState.cleanBaselineSnapshot?.sourceRevision,
          openRegistryNodeId: selectedProblem?.exactNode.id,
          openRegistryPath: selectedProblem?.path,
          selectedProblemIndex: index,
          searchQuery: currentState.searchQuery,
        ),
      );

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: currentState.snapshot,
            index: currentState.index,
            previousSnapshot: currentState.previousSnapshot,
            previousComparison: currentState.previousComparison,
            cleanBaselineSnapshot: currentState.cleanBaselineSnapshot,
            cleanBaselineComparison: currentState.cleanBaselineComparison,
            openRegistryNodeId: selectedProblem?.exactNode.id,
            openRegistryPath: selectedProblem?.path,
            selectedProblemIndex: index,
            analysisHistory: currentState.analysisHistory,
            searchQuery: currentState.searchQuery,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> selectRegistryNode(RegistryNodeId? nodeId) async {
    if (_isLoading) {
      throw StateError('Контекст Registry уже обновляется.');
    }

    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      throw StateError('Registry недоступен.');
    }

    final RegistryNode? openRegistryNode = nodeId == null
        ? null
        : currentState.index.nodesById[nodeId];

    if (nodeId != null && openRegistryNode == null) {
      throw StateError('Registry block недоступен.');
    }

    _isLoading = true;

    try {
      await _pendingSearchQueryWrite;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: currentState.snapshot.projectId,
          projectAdapterId: currentState.snapshot.projectAdapterId,
          sourceDocumentPath: currentState.snapshot.sourceDocumentPath,
          currentRevision: currentState.snapshot.sourceRevision,
          previousRevision: currentState.previousSnapshot?.sourceRevision,
          cleanBaselineRevision:
              currentState.cleanBaselineSnapshot?.sourceRevision,
          openRegistryNodeId: openRegistryNode?.id,
          openRegistryPath: openRegistryNode?.path,
          selectedProblemIndex: null,
          searchQuery: currentState.searchQuery,
        ),
      );

      if (!isClosed) {
        emit(
          RegistryExplorerLoaded(
            snapshot: currentState.snapshot,
            index: currentState.index,
            previousSnapshot: currentState.previousSnapshot,
            previousComparison: currentState.previousComparison,
            cleanBaselineSnapshot: currentState.cleanBaselineSnapshot,
            cleanBaselineComparison: currentState.cleanBaselineComparison,
            openRegistryNodeId: openRegistryNode?.id,
            openRegistryPath: openRegistryNode?.path,
            selectedProblemIndex: null,
            analysisHistory: currentState.analysisHistory,
            searchQuery: currentState.searchQuery,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateSearchQuery(String searchQuery) {
    if (_isLoading) {
      return Future<void>.error(
        StateError('Контекст Registry уже обновляется.'),
      );
    }

    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      return Future<void>.error(StateError('Registry недоступен.'));
    }

    if (searchQuery == currentState.searchQuery) {
      return Future<void>.value();
    }

    final RegistryRevisionState persistedState = RegistryRevisionState(
      projectId: currentState.snapshot.projectId,
      projectAdapterId: currentState.snapshot.projectAdapterId,
      sourceDocumentPath: currentState.snapshot.sourceDocumentPath,
      currentRevision: currentState.snapshot.sourceRevision,
      previousRevision: currentState.previousSnapshot?.sourceRevision,
      cleanBaselineRevision: currentState.cleanBaselineSnapshot?.sourceRevision,
      openRegistryNodeId: currentState.openRegistryNodeId,
      openRegistryPath: currentState.openRegistryPath,
      selectedProblemIndex: currentState.selectedProblemIndex,
      searchQuery: searchQuery,
    );

    emit(
      RegistryExplorerLoaded(
        snapshot: currentState.snapshot,
        index: currentState.index,
        previousSnapshot: currentState.previousSnapshot,
        previousComparison: currentState.previousComparison,
        cleanBaselineSnapshot: currentState.cleanBaselineSnapshot,
        cleanBaselineComparison: currentState.cleanBaselineComparison,
        openRegistryNodeId: currentState.openRegistryNodeId,
        openRegistryPath: currentState.openRegistryPath,
        selectedProblemIndex: currentState.selectedProblemIndex,
        analysisHistory: currentState.analysisHistory,
        searchQuery: searchQuery,
      ),
    );

    final Future<void> write = _pendingSearchQueryWrite.then<void>(
      (_) => revisionStateStore.saveRevisionState(persistedState),
    );

    _pendingSearchQueryWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );

    return write;
  }

  Future<void> retry() {
    if (_retryRefresh) {
      return refresh();
    }

    return restore();
  }

  @override
  Future<void> close() async {
    await _pendingSearchQueryWrite;
    await super.close();
  }
}
