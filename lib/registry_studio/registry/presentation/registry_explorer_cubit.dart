import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_snapshot_comparison.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../../maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_cache.dart';
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
    required this.registryViewFilter,
    this.analysisHistory = const <RegistryAnalysisHistoryEntry>[],
    this.searchQuery = '',
    this.isRefreshing = false,
    this.refreshWarning,
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
  final String registryViewFilter;
  final List<RegistryAnalysisHistoryEntry> analysisHistory;
  final String searchQuery;
  final bool isRefreshing;
  final String? refreshWarning;

  RegistryExplorerLoaded copyWith({
    RegistrySnapshot? snapshot,
    RegistryStructuralIndex? index,
    RegistrySnapshot? previousSnapshot,
    bool clearPreviousSnapshot = false,
    RegistrySnapshotComparison? previousComparison,
    bool clearPreviousComparison = false,
    RegistrySnapshot? cleanBaselineSnapshot,
    bool clearCleanBaselineSnapshot = false,
    RegistrySnapshotComparison? cleanBaselineComparison,
    bool clearCleanBaselineComparison = false,
    RegistryNodeId? openRegistryNodeId,
    bool clearOpenRegistryNodeId = false,
    RegistryPath? openRegistryPath,
    bool clearOpenRegistryPath = false,
    int? selectedProblemIndex,
    bool clearSelectedProblemIndex = false,
    String? registryViewFilter,
    List<RegistryAnalysisHistoryEntry>? analysisHistory,
    String? searchQuery,
    bool? isRefreshing,
    String? refreshWarning,
    bool clearRefreshWarning = false,
  }) {
    return RegistryExplorerLoaded(
      snapshot: snapshot ?? this.snapshot,
      index: index ?? this.index,
      previousSnapshot: clearPreviousSnapshot
          ? null
          : previousSnapshot ?? this.previousSnapshot,
      previousComparison: clearPreviousComparison
          ? null
          : previousComparison ?? this.previousComparison,
      cleanBaselineSnapshot: clearCleanBaselineSnapshot
          ? null
          : cleanBaselineSnapshot ?? this.cleanBaselineSnapshot,
      cleanBaselineComparison: clearCleanBaselineComparison
          ? null
          : cleanBaselineComparison ?? this.cleanBaselineComparison,
      openRegistryNodeId: clearOpenRegistryNodeId
          ? null
          : openRegistryNodeId ?? this.openRegistryNodeId,
      openRegistryPath: clearOpenRegistryPath
          ? null
          : openRegistryPath ?? this.openRegistryPath,
      selectedProblemIndex: clearSelectedProblemIndex
          ? null
          : selectedProblemIndex ?? this.selectedProblemIndex,
      registryViewFilter: registryViewFilter ?? this.registryViewFilter,
      analysisHistory: analysisHistory ?? this.analysisHistory,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshWarning: clearRefreshWarning
          ? null
          : refreshWarning ?? this.refreshWarning,
    );
  }

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
    required this.registryViewFilterBeforeRefresh,
    this.searchQueryBeforeRefresh = '',
    this.analysisHistoryBeforeRefresh = const <RegistryAnalysisHistoryEntry>[],
  });

  final String message;
  final RegistryNode? openRegistryNodeBeforeRefresh;
  final String registryViewFilterBeforeRefresh;
  final String searchQueryBeforeRefresh;
  final List<RegistryAnalysisHistoryEntry> analysisHistoryBeforeRefresh;
}

final class RegistryExplorerCubit extends Cubit<RegistryExplorerState> {
  RegistryExplorerCubit({
    required this.snapshotLoader,
    required this.snapshotRefreshLoader,
    required this.snapshotRevisionLoader,
    this.snapshotCache,
    required this.revisionStateStore,
    required this.analysisHistoryStore,
    required this.snapshotComparator,
  }) : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRefreshLoader snapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistrySnapshotCache? snapshotCache;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistryAnalysisHistoryStore analysisHistoryStore;
  final RegistrySnapshotComparator snapshotComparator;

  bool _isLoading = false;
  bool _retryRefresh = false;

  RegistrySnapshot? _currentSnapshot;
  RegistrySnapshot? _previousSnapshot;
  RegistrySnapshot? _cleanBaselineSnapshot;

  Future<void> _pendingRevisionStateWrite = Future<void>.value();

  Future<void> restore() async {
    if (_isLoading) {
      return;
    }

    _retryRefresh = false;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    String searchQuery = '';
    String registryViewFilter = 'all';
    List<RegistryAnalysisHistoryEntry> analysisHistory =
        const <RegistryAnalysisHistoryEntry>[];

    try {
      final RegistryRevisionState? persistedState = await revisionStateStore
          .loadRevisionState();
      List<RegistryAnalysisHistoryEntry> storedAnalysisHistory =
          const <RegistryAnalysisHistoryEntry>[];

      try {
        storedAnalysisHistory = await analysisHistoryStore.loadHistory();
      } catch (_) {
        // Analysis history is secondary. A damaged history file must not make
        // the locally cached Registry unavailable.
      }

      final RegistrySnapshotCache? localSnapshotCache = snapshotCache;
      late final RegistryRevisionState effectiveState;
      late final RegistrySnapshot snapshot;

      if (persistedState == null) {
        if (localSnapshotCache != null) {
          throw const _RegistrySnapshotUnavailable(
            'Registry ещё не загружен на устройство. '
            'Нажмите кнопку обновления, чтобы загрузить Registry вручную.',
          );
        }

        // Backward-compatible path for tests and custom integrations that do
        // not inject the production file cache. The production Helpy factory
        // always injects JsonFileRegistrySnapshotCache and never enters here.
        snapshot = await snapshotLoader.loadSnapshot();
        effectiveState = RegistryRevisionState(
          projectId: snapshot.projectId,
          projectAdapterId: snapshot.projectAdapterId,
          sourceDocumentPath: snapshot.sourceDocumentPath,
          currentRevision: snapshot.sourceRevision,
          previousRevision: null,
          cleanBaselineRevision: null,
          searchQuery: '',
          registryViewFilter: 'all',
        );
        await revisionStateStore.saveRevisionState(effectiveState);
      } else {
        effectiveState = persistedState;

        if (localSnapshotCache == null) {
          snapshot = await snapshotRevisionLoader.loadSnapshotAtRevision(
            effectiveState.currentRevision,
          );
        } else {
          final RegistrySnapshot? cachedCurrent = await localSnapshotCache
              .loadSnapshot(effectiveState.currentRevision);

          if (cachedCurrent == null) {
            throw const _RegistrySnapshotUnavailable(
              'Локальный snapshot Registry отсутствует. '
              'Нажмите кнопку обновления, чтобы загрузить его вручную.',
            );
          }

          snapshot = cachedCurrent;
        }
      }

      searchQuery = effectiveState.searchQuery;
      registryViewFilter = effectiveState.registryViewFilter;

      if (snapshot.projectId != effectiveState.projectId ||
          snapshot.projectAdapterId != effectiveState.projectAdapterId ||
          snapshot.sourceDocumentPath != effectiveState.sourceDocumentPath ||
          snapshot.sourceRevision != effectiveState.currentRevision) {
        throw const FormatException(
          'Локальный snapshot Registry не соответствует сохранённой revision.',
        );
      }

      RegistrySnapshot? previousSnapshot;
      final String? previousRevision = effectiveState.previousRevision;

      if (previousRevision != null) {
        previousSnapshot = localSnapshotCache == null
            ? await snapshotRevisionLoader.loadSnapshotAtRevision(
                previousRevision,
              )
            : await localSnapshotCache.loadSnapshot(previousRevision);

        if (previousSnapshot != null &&
            (previousSnapshot.projectId != effectiveState.projectId ||
                previousSnapshot.projectAdapterId !=
                    effectiveState.projectAdapterId ||
                previousSnapshot.sourceDocumentPath !=
                    effectiveState.sourceDocumentPath ||
                previousSnapshot.sourceRevision != previousRevision)) {
          throw const FormatException(
            'Локальный previous snapshot Registry повреждён.',
          );
        }
      }

      RegistrySnapshot? cleanBaselineSnapshot;
      final String? cleanBaselineRevision =
          effectiveState.cleanBaselineRevision;

      if (cleanBaselineRevision != null) {
        if (cleanBaselineRevision == snapshot.sourceRevision) {
          cleanBaselineSnapshot = snapshot;
        } else if (previousSnapshot != null &&
            cleanBaselineRevision == previousSnapshot.sourceRevision) {
          cleanBaselineSnapshot = previousSnapshot;
        } else {
          cleanBaselineSnapshot = localSnapshotCache == null
              ? await snapshotRevisionLoader.loadSnapshotAtRevision(
                  cleanBaselineRevision,
                )
              : await localSnapshotCache.loadSnapshot(cleanBaselineRevision);
        }

        if (cleanBaselineSnapshot != null &&
            (cleanBaselineSnapshot.projectId != effectiveState.projectId ||
                cleanBaselineSnapshot.projectAdapterId !=
                    effectiveState.projectAdapterId ||
                cleanBaselineSnapshot.sourceDocumentPath !=
                    effectiveState.sourceDocumentPath ||
                cleanBaselineSnapshot.sourceRevision !=
                    cleanBaselineRevision)) {
          throw const FormatException(
            'Локальный clean baseline Registry повреждён.',
          );
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
          effectiveState.openRegistryNodeId;
      final RegistryPath? openRegistryPath = effectiveState.openRegistryPath;

      int? selectedProblemIndex;

      if (openRegistryNodeId != null &&
          openRegistryPath != null &&
          effectiveState.selectedProblemIndex != null) {
        final int persistedProblemIndex = effectiveState.selectedProblemIndex!;

        if (persistedProblemIndex < problems.length) {
          final RegistryStructuralProblem candidate =
              problems[persistedProblemIndex];

          if (candidate.exactNode.id == openRegistryNodeId &&
              candidate.path == openRegistryPath) {
            selectedProblemIndex = persistedProblemIndex;
          }
        }

        selectedProblemIndex ??= _findProblemIndex(
          problems,
          openRegistryNodeId,
          openRegistryPath,
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

      final RegistryAnalysisHistoryEntry historyEntry = _buildHistoryEntry(
        snapshot: snapshot,
        previousSnapshot: previousSnapshot,
        cleanBaselineSnapshot: cleanBaselineSnapshot,
        previousComparison: previousComparison,
        cleanBaselineComparison: cleanBaselineComparison,
        problems: problems,
      );

      analysisHistory = await _appendHistoryIfChanged(
        analysisHistory,
        historyEntry,
      );

      _currentSnapshot = snapshot;
      _previousSnapshot = previousSnapshot;
      _cleanBaselineSnapshot = cleanBaselineSnapshot;
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
            openRegistryNodeId: openRegistryNodeId,
            openRegistryPath: openRegistryPath,
            selectedProblemIndex: selectedProblemIndex,
            registryViewFilter: registryViewFilter,
            analysisHistory: analysisHistory,
            searchQuery: searchQuery,
          ),
        );
      }
    } on _RegistrySnapshotUnavailable catch (error) {
      _retryRefresh = true;

      if (!isClosed) {
        emit(
          RegistryExplorerFailure(
            error.message,
            openRegistryNodeBeforeRefresh: null,
            registryViewFilterBeforeRefresh: registryViewFilter,
            searchQueryBeforeRefresh: searchQuery,
            analysisHistoryBeforeRefresh: analysisHistory,
          ),
        );
      }
    } catch (error) {
      _retryRefresh = true;

      if (!isClosed) {
        emit(
          RegistryExplorerFailure(
            _registryUserMessage(error, duringRefresh: false),
            openRegistryNodeBeforeRefresh: null,
            registryViewFilterBeforeRefresh: registryViewFilter,
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
    final RegistryExplorerLoaded? loadedBeforeRefresh =
        stateBeforeRefresh is RegistryExplorerLoaded
        ? stateBeforeRefresh
        : null;

    RegistryNode? openRegistryNodeBeforeRefresh =
        loadedBeforeRefresh?.openRegistryNode;
    RegistryStructuralProblem? selectedProblemBeforeRefresh =
        loadedBeforeRefresh?.selectedProblem;
    String registryViewFilterBeforeRefresh =
        loadedBeforeRefresh?.registryViewFilter ??
        (stateBeforeRefresh is RegistryExplorerFailure
            ? stateBeforeRefresh.registryViewFilterBeforeRefresh
            : 'all');
    String searchQueryBeforeRefresh =
        loadedBeforeRefresh?.searchQuery ??
        (stateBeforeRefresh is RegistryExplorerFailure
            ? stateBeforeRefresh.searchQueryBeforeRefresh
            : '');
    List<RegistryAnalysisHistoryEntry> analysisHistoryBeforeRefresh =
        loadedBeforeRefresh?.analysisHistory ??
        (stateBeforeRefresh is RegistryExplorerFailure
            ? stateBeforeRefresh.analysisHistoryBeforeRefresh
            : const <RegistryAnalysisHistoryEntry>[]);

    _retryRefresh = true;
    _isLoading = true;

    if (loadedBeforeRefresh != null) {
      emit(
        loadedBeforeRefresh.copyWith(
          isRefreshing: true,
          clearRefreshWarning: true,
        ),
      );
    } else {
      emit(const RegistryExplorerLoading());
    }

    try {
      await _pendingRevisionStateWrite;

      final RegistrySnapshot? currentSnapshot = _currentSnapshot;

      final RegistrySnapshot snapshot = currentSnapshot == null
          ? await snapshotLoader.loadSnapshot()
          : await snapshotRefreshLoader.loadSnapshotAfterRevision(
              currentSnapshot.sourceRevision,
            );

      if (currentSnapshot != null &&
          (snapshot.projectId != currentSnapshot.projectId ||
              snapshot.projectAdapterId != currentSnapshot.projectAdapterId ||
              snapshot.sourceDocumentPath !=
                  currentSnapshot.sourceDocumentPath)) {
        throw StateError(
          'Refreshed Registry snapshot does not match '
          'the current Registry coordinates.',
        );
      }

      final RegistrySnapshotCache? localSnapshotCache = snapshotCache;

      if (localSnapshotCache != null) {
        if (currentSnapshot != null) {
          await localSnapshotCache.saveSnapshot(currentSnapshot);
        }

        await localSnapshotCache.saveSnapshot(snapshot);
      }

      RegistrySnapshot? previousSnapshot = _previousSnapshot;

      if (currentSnapshot != null &&
          snapshot.sourceRevision != currentSnapshot.sourceRevision) {
        previousSnapshot = currentSnapshot;
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

      final RegistryExplorerState liveStateBeforeApply = state;

      if (liveStateBeforeApply is RegistryExplorerLoaded) {
        openRegistryNodeBeforeRefresh = liveStateBeforeApply.openRegistryNode;
        selectedProblemBeforeRefresh = liveStateBeforeApply.selectedProblem;
        registryViewFilterBeforeRefresh =
            liveStateBeforeApply.registryViewFilter;
        searchQueryBeforeRefresh = liveStateBeforeApply.searchQuery;
        analysisHistoryBeforeRefresh = liveStateBeforeApply.analysisHistory;
      }

      final List<RegistryStructuralProblem> refreshedProblems =
          (cleanBaselineComparison ?? previousComparison)?.problems ??
          const <RegistryStructuralProblem>[];

      int? refreshedSelectedProblemIndex;

      final RegistryStructuralProblem? selectedProblemSnapshot =
          selectedProblemBeforeRefresh;

      if (selectedProblemSnapshot != null) {
        final int identityMatchIndex = refreshedProblems.indexWhere(
          (RegistryStructuralProblem problem) =>
              problem.exactNode.id == selectedProblemSnapshot.exactNode.id,
        );

        if (identityMatchIndex >= 0) {
          refreshedSelectedProblemIndex = identityMatchIndex;
        } else {
          final int pathMatchIndex = refreshedProblems.indexWhere(
            (RegistryStructuralProblem problem) =>
                problem.path == selectedProblemSnapshot.path,
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
          refreshedSelectedProblem == null &&
              openRegistryNodeBeforeRefresh != null
          ? index.nodesById[openRegistryNodeBeforeRefresh.id]
          : null;

      final RegistryNodeId? refreshedOpenRegistryNodeId =
          refreshedSelectedProblem?.exactNode.id ??
          refreshedOpenRegistryNode?.id;

      final RegistryPath? refreshedOpenRegistryPath =
          refreshedSelectedProblem?.path ?? refreshedOpenRegistryNode?.path;

      await _pendingRevisionStateWrite;

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
          registryViewFilter: registryViewFilterBeforeRefresh,
        ),
      );

      final RegistryAnalysisHistoryEntry historyEntry = _buildHistoryEntry(
        snapshot: snapshot,
        previousSnapshot: previousSnapshot,
        cleanBaselineSnapshot: cleanBaselineSnapshot,
        previousComparison: previousComparison,
        cleanBaselineComparison: cleanBaselineComparison,
        problems: refreshedProblems,
      );

      final List<RegistryAnalysisHistoryEntry> analysisHistory =
          await _appendHistoryIfChanged(
            analysisHistoryBeforeRefresh,
            historyEntry,
            forceAppend: true,
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
            registryViewFilter: registryViewFilterBeforeRefresh,
            analysisHistory: analysisHistory,
            searchQuery: searchQueryBeforeRefresh,
          ),
        );
      }
    } catch (error) {
      final String message = _registryUserMessage(error, duringRefresh: true);

      if (!isClosed) {
        final RegistryExplorerState liveStateAfterFailure = state;
        final RegistryExplorerLoaded? fallbackLoaded =
            liveStateAfterFailure is RegistryExplorerLoaded
            ? liveStateAfterFailure
            : loadedBeforeRefresh;

        if (fallbackLoaded != null) {
          _retryRefresh = false;
          emit(
            fallbackLoaded.copyWith(
              isRefreshing: false,
              refreshWarning: message,
            ),
          );
        } else {
          _retryRefresh = true;
          emit(
            RegistryExplorerFailure(
              message,
              openRegistryNodeBeforeRefresh: openRegistryNodeBeforeRefresh,
              registryViewFilterBeforeRefresh: registryViewFilterBeforeRefresh,
              searchQueryBeforeRefresh: searchQueryBeforeRefresh,
              analysisHistoryBeforeRefresh: analysisHistoryBeforeRefresh,
            ),
          );
        }
      }
    } finally {
      _isLoading = false;
    }
  }

  static int? _findProblemIndex(
    List<RegistryStructuralProblem> problems,
    RegistryNodeId nodeId,
    RegistryPath path,
  ) {
    final int index = problems.indexWhere(
      (RegistryStructuralProblem problem) =>
          problem.exactNode.id == nodeId && problem.path == path,
    );

    return index < 0 ? null : index;
  }

  RegistryAnalysisHistoryEntry _buildHistoryEntry({
    required RegistrySnapshot snapshot,
    required RegistrySnapshot? previousSnapshot,
    required RegistrySnapshot? cleanBaselineSnapshot,
    required RegistrySnapshotComparison? previousComparison,
    required RegistrySnapshotComparison? cleanBaselineComparison,
    required List<RegistryStructuralProblem> problems,
  }) {
    return RegistryAnalysisHistoryEntry(
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
  }

  Future<List<RegistryAnalysisHistoryEntry>> _appendHistoryIfChanged(
    List<RegistryAnalysisHistoryEntry> history,
    RegistryAnalysisHistoryEntry candidate, {
    bool forceAppend = false,
  }) async {
    if (!forceAppend &&
        history.isNotEmpty &&
        _sameHistoryEntryIgnoringLoadedAt(history.last, candidate)) {
      return List<RegistryAnalysisHistoryEntry>.unmodifiable(history);
    }

    try {
      await analysisHistoryStore.appendHistoryEntry(candidate);
    } catch (_) {
      // Registry availability is more important than optional analysis
      // history. The next successful restore or refresh can record it.
      return List<RegistryAnalysisHistoryEntry>.unmodifiable(history);
    }

    return List<RegistryAnalysisHistoryEntry>.unmodifiable(
      <RegistryAnalysisHistoryEntry>[...history, candidate],
    );
  }

  static bool _sameHistoryEntryIgnoringLoadedAt(
    RegistryAnalysisHistoryEntry left,
    RegistryAnalysisHistoryEntry right,
  ) {
    return left.projectId == right.projectId &&
        left.projectAdapterId == right.projectAdapterId &&
        left.sourceDocumentPath == right.sourceDocumentPath &&
        left.sourceRevision == right.sourceRevision &&
        left.sourceSnapshotFingerprint == right.sourceSnapshotFingerprint &&
        left.previousRevision == right.previousRevision &&
        left.cleanBaselineRevision == right.cleanBaselineRevision &&
        left.previousAddedCount == right.previousAddedCount &&
        left.previousRemovedCount == right.previousRemovedCount &&
        left.previousChangedCount == right.previousChangedCount &&
        left.cleanBaselineAddedCount == right.cleanBaselineAddedCount &&
        left.cleanBaselineRemovedCount == right.cleanBaselineRemovedCount &&
        left.cleanBaselineChangedCount == right.cleanBaselineChangedCount &&
        left.problemCount == right.problemCount &&
        left.problems.length == right.problems.length &&
        left.problems.asMap().entries.every(
          (MapEntry<int, RegistryAnalysisHistoryProblem> entry) =>
              entry.value == right.problems[entry.key],
        );
  }

  static String _registryUserMessage(
    Object error, {
    required bool duringRefresh,
  }) {
    final String action = duringRefresh ? 'обновить' : 'восстановить';

    if (error is TimeoutException) {
      return 'Не удалось $action Registry: сервер не ответил вовремя. '
          'Проверьте VPN или сеть и повторите вручную.';
    }

    if (error is SocketException || error is HttpException) {
      return 'Не удалось $action Registry через сеть. '
          'Сохранённый snapshot не изменён. '
          'Проверьте VPN или соединение и повторите вручную.';
    }

    if (error is FormatException) {
      return 'Не удалось $action Registry: сохранённые или загруженные '
          'данные имеют неверный формат.';
    }

    if (error is StateError) {
      return 'Не удалось $action Registry: полученная revision '
          'не соответствует текущему проекту.';
    }

    return 'Не удалось $action Registry. '
        'Сохранённый snapshot не изменён.';
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
    final String registryViewFilter = currentState is RegistryExplorerLoaded
        ? currentState.registryViewFilter
        : currentState is RegistryExplorerFailure
        ? currentState.registryViewFilterBeforeRefresh
        : 'all';
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
      await _pendingRevisionStateWrite;

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
          registryViewFilter: registryViewFilter,
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
            registryViewFilter: registryViewFilter,
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
      await _pendingRevisionStateWrite;

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
          registryViewFilter: currentState.registryViewFilter,
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
            registryViewFilter: currentState.registryViewFilter,
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

    final RegistryRevisionState persistedState = RegistryRevisionState(
      projectId: currentState.snapshot.projectId,
      projectAdapterId: currentState.snapshot.projectAdapterId,
      sourceDocumentPath: currentState.snapshot.sourceDocumentPath,
      currentRevision: currentState.snapshot.sourceRevision,
      previousRevision: currentState.previousSnapshot?.sourceRevision,
      cleanBaselineRevision: currentState.cleanBaselineSnapshot?.sourceRevision,
      openRegistryNodeId: openRegistryNode?.id,
      openRegistryPath: openRegistryNode?.path,
      selectedProblemIndex: null,
      searchQuery: currentState.searchQuery,
      registryViewFilter: currentState.registryViewFilter,
    );

    if (_isLoading) {
      if (!currentState.isRefreshing) {
        throw StateError('Контекст Registry уже обновляется.');
      }

      if (!isClosed) {
        emit(
          currentState.copyWith(
            openRegistryNodeId: openRegistryNode?.id,
            clearOpenRegistryNodeId: openRegistryNode == null,
            openRegistryPath: openRegistryNode?.path,
            clearOpenRegistryPath: openRegistryNode == null,
            clearSelectedProblemIndex: true,
          ),
        );
      }

      final Future<void> write = _pendingRevisionStateWrite.then<void>(
        (_) => revisionStateStore.saveRevisionState(persistedState),
      );

      _pendingRevisionStateWrite = write.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      );

      return write;
    }

    _isLoading = true;

    try {
      await _pendingRevisionStateWrite;
      await revisionStateStore.saveRevisionState(persistedState);

      if (!isClosed) {
        emit(
          currentState.copyWith(
            openRegistryNodeId: openRegistryNode?.id,
            clearOpenRegistryNodeId: openRegistryNode == null,
            openRegistryPath: openRegistryNode?.path,
            clearOpenRegistryPath: openRegistryNode == null,
            clearSelectedProblemIndex: true,
          ),
        );
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> resetWorkspaceContext() async {
    if (_isLoading) {
      throw StateError('Контекст Registry уже обновляется.');
    }

    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      throw StateError('Registry недоступен.');
    }

    if (currentState.openRegistryNodeId == null &&
        currentState.selectedProblemIndex == null &&
        currentState.searchQuery.isEmpty &&
        currentState.registryViewFilter == 'all') {
      return;
    }

    _isLoading = true;

    try {
      await _pendingRevisionStateWrite;

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: currentState.snapshot.projectId,
          projectAdapterId: currentState.snapshot.projectAdapterId,
          sourceDocumentPath: currentState.snapshot.sourceDocumentPath,
          currentRevision: currentState.snapshot.sourceRevision,
          previousRevision: currentState.previousSnapshot?.sourceRevision,
          cleanBaselineRevision:
              currentState.cleanBaselineSnapshot?.sourceRevision,
          openRegistryNodeId: null,
          openRegistryPath: null,
          selectedProblemIndex: null,
          searchQuery: '',
          registryViewFilter: 'all',
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
            openRegistryNodeId: null,
            openRegistryPath: null,
            selectedProblemIndex: null,
            registryViewFilter: 'all',
            analysisHistory: currentState.analysisHistory,
            searchQuery: '',
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
      registryViewFilter: currentState.registryViewFilter,
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
        registryViewFilter: currentState.registryViewFilter,
        analysisHistory: currentState.analysisHistory,
        searchQuery: searchQuery,
      ),
    );

    final Future<void> write = _pendingRevisionStateWrite.then<void>(
      (_) => revisionStateStore.saveRevisionState(persistedState),
    );

    _pendingRevisionStateWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );

    return write;
  }

  Future<void> updateRegistryViewFilter(String registryViewFilter) {
    if (_isLoading) {
      return Future<void>.error(
        StateError('Контекст Registry уже обновляется.'),
      );
    }

    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded) {
      return Future<void>.error(StateError('Registry недоступен.'));
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
      searchQuery: currentState.searchQuery,
      registryViewFilter: registryViewFilter,
    );

    if (persistedState.registryViewFilter == currentState.registryViewFilter) {
      return Future<void>.value();
    }

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
        registryViewFilter: persistedState.registryViewFilter,
        analysisHistory: currentState.analysisHistory,
        searchQuery: currentState.searchQuery,
      ),
    );

    final Future<void> write = _pendingRevisionStateWrite.then<void>(
      (_) => revisionStateStore.saveRevisionState(persistedState),
    );

    _pendingRevisionStateWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );

    return write;
  }

  void dismissRefreshWarning() {
    final RegistryExplorerState currentState = state;

    if (currentState is! RegistryExplorerLoaded ||
        currentState.refreshWarning == null) {
      return;
    }

    emit(currentState.copyWith(clearRefreshWarning: true));
  }

  Future<void> retry() {
    if (_retryRefresh) {
      return refresh();
    }

    return restore();
  }

  @override
  Future<void> close() async {
    await _pendingRevisionStateWrite;
    await super.close();
  }
}

final class _RegistrySnapshotUnavailable implements Exception {
  const _RegistrySnapshotUnavailable(this.message);

  final String message;
}
