import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_path.dart';
import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_snapshot_comparison.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
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
  });

  final String message;
  final RegistryNode? openRegistryNodeBeforeRefresh;
  final String searchQueryBeforeRefresh;
}

final class RegistryExplorerCubit extends Cubit<RegistryExplorerState> {
  RegistryExplorerCubit({
    required this.snapshotLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.snapshotComparator,
  }) : super(const RegistryExplorerLoading());

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
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

    try {
      final RegistryRevisionState? persistedState = await revisionStateStore
          .loadRevisionState();

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
    final String searchQueryBeforeRefresh;

    if (stateBeforeRefresh is RegistryExplorerLoaded) {
      openRegistryNodeBeforeRefresh = stateBeforeRefresh.openRegistryNode;
      searchQueryBeforeRefresh = stateBeforeRefresh.searchQuery;
    } else if (stateBeforeRefresh is RegistryExplorerFailure) {
      openRegistryNodeBeforeRefresh =
          stateBeforeRefresh.openRegistryNodeBeforeRefresh;
      searchQueryBeforeRefresh = stateBeforeRefresh.searchQueryBeforeRefresh;
    } else {
      openRegistryNodeBeforeRefresh = null;
      searchQueryBeforeRefresh = '';
    }

    final RegistryNodeId? openRegistryNodeId =
        openRegistryNodeBeforeRefresh?.id;

    _retryRefresh = true;
    _isLoading = true;
    emit(const RegistryExplorerLoading());

    try {
      await _pendingSearchQueryWrite;

      final RegistrySnapshot snapshot = await snapshotLoader.loadSnapshot();

      final RegistrySnapshot? currentSnapshot = _currentSnapshot;

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

      final RegistryNode? refreshedOpenRegistryNode = openRegistryNodeId == null
          ? null
          : index.nodesById[openRegistryNodeId];

      await revisionStateStore.saveRevisionState(
        RegistryRevisionState(
          projectId: snapshot.projectId,
          projectAdapterId: snapshot.projectAdapterId,
          sourceDocumentPath: snapshot.sourceDocumentPath,
          currentRevision: snapshot.sourceRevision,
          previousRevision: previousSnapshot?.sourceRevision,
          cleanBaselineRevision: cleanBaselineSnapshot?.sourceRevision,
          openRegistryNodeId: refreshedOpenRegistryNode?.id,
          openRegistryPath: refreshedOpenRegistryNode?.path,
          selectedProblemIndex: null,
          searchQuery: searchQueryBeforeRefresh,
        ),
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
            openRegistryNodeId: refreshedOpenRegistryNode?.id,
            openRegistryPath: refreshedOpenRegistryNode?.path,
            selectedProblemIndex: null,
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
