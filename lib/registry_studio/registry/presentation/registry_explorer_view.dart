import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../../maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
import '../application/contracts/registry_snapshot_refresh_loader.dart';
import '../application/contracts/registry_snapshot_revision_loader.dart';
import '../domain/entities/registry_node.dart';
import '../domain/entities/registry_snapshot.dart';
import '../domain/value_objects/registry_node_id.dart';
import 'registry_explorer_cubit.dart';
import 'registry_analysis_status_entry.dart';
import 'registry_problem_queue_entry.dart';
import 'registry_view_filter_sheet.dart';

final class RegistryExplorerView extends StatelessWidget {
  const RegistryExplorerView({
    required this.snapshotLoader,
    required this.snapshotRefreshLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.analysisHistoryStore,
    required this.snapshotComparator,
    this.onSnapshotAccepted,
    this.onRegistryNodeSelectionReady,
    this.analysisProblemEntries = const <RegistryProblemQueueEntry>[],
    this.analysisStatusEntries = const <RegistryAnalysisStatusEntry>[],
    super.key,
  });

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRefreshLoader snapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistryAnalysisHistoryStore analysisHistoryStore;
  final RegistrySnapshotComparator snapshotComparator;
  final void Function(RegistrySnapshot snapshot)? onSnapshotAccepted;
  final void Function(
    Future<void> Function(RegistryNodeId? nodeId) selectRegistryNode,
  )?
  onRegistryNodeSelectionReady;
  final List<RegistryProblemQueueEntry> analysisProblemEntries;
  final List<RegistryAnalysisStatusEntry> analysisStatusEntries;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryExplorerCubit>(
      create: (_) => RegistryExplorerCubit(
        snapshotLoader: snapshotLoader,
        snapshotRefreshLoader: snapshotRefreshLoader,
        snapshotRevisionLoader: snapshotRevisionLoader,
        revisionStateStore: revisionStateStore,
        analysisHistoryStore: analysisHistoryStore,
        snapshotComparator: snapshotComparator,
        onSnapshotAccepted: onSnapshotAccepted,
      )..restore(),
      child: _RegistryExplorerView(
        onRegistryNodeSelectionReady: onRegistryNodeSelectionReady,
        analysisProblemEntries: analysisProblemEntries,
        analysisStatusEntries: analysisStatusEntries,
      ),
    );
  }
}

final class _RegistryExplorerView extends StatefulWidget {
  const _RegistryExplorerView({
    required this.onRegistryNodeSelectionReady,
    required this.analysisProblemEntries,
    required this.analysisStatusEntries,
  });

  final void Function(
    Future<void> Function(RegistryNodeId? nodeId) selectRegistryNode,
  )?
  onRegistryNodeSelectionReady;
  final List<RegistryProblemQueueEntry> analysisProblemEntries;
  final List<RegistryAnalysisStatusEntry> analysisStatusEntries;

  @override
  State<_RegistryExplorerView> createState() => _RegistryExplorerViewState();
}

final class _RegistryExplorerViewState extends State<_RegistryExplorerView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _selectedRegistryBlockScrollController =
      ScrollController();
  String? _selectedRegistrySearchContextId;
  int _selectedRegistrySearchMatchIndex = 0;
  bool _selectedRegistrySearchScrollPending = false;

  String? _selectedCanonicalContextId;
  int _selectedCanonicalMatchIndex = 0;
  bool _selectedCanonicalScrollPending = false;

  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _selectedProblemKey = GlobalKey();
  final GlobalKey _selectedRegistryBlockKey = GlobalKey();

  bool _showScrollToTop = false;
  bool _searchControllerInitialized = false;
  bool _showProblemQueue = false;
  bool _showProblemQueueFullScreen = false;
  final List<RegistryNodeId> _registryBranchScopeNodeIds = <RegistryNodeId>[];
  final List<double> _registryBranchScopeScrollOffsets = <double>[];

  final Set<RegistryNodeId> _expandedRegistryNodeIds = <RegistryNodeId>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollToTopVisibility);
    widget.onRegistryNodeSelectionReady?.call(_selectRegistryNode);
  }

  @override
  void didUpdateWidget(covariant _RegistryExplorerView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.onRegistryNodeSelectionReady ==
        widget.onRegistryNodeSelectionReady) {
      return;
    }

    widget.onRegistryNodeSelectionReady?.call(_selectRegistryNode);
  }

  void _updateScrollToTopVisibility() {
    if (!_scrollController.hasClients) {
      return;
    }

    final bool shouldShow =
        _scrollController.position.pixels >
        _scrollController.position.viewportDimension;

    if (shouldShow == _showScrollToTop) {
      return;
    }

    setState(() {
      _showScrollToTop = shouldShow;
    });
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  TextEditingController _searchTextController(String searchQuery) {
    if (!_searchControllerInitialized) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );

      _searchControllerInitialized = true;
    }

    return _searchController;
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    await _updateSearchQuery('');
  }

  Future<void> _resetRegistryStudio() async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              key: const ValueKey<String>('registry-studio-reset-dialog'),
              title: const Text('Сбросить Registry Studio?'),
              content: const Text(
                'Будут закрыты открытый block и выбранная проблема, '
                'очищены поиск и раскрытые ветки. '
                'Registry, baseline и история анализа не изменятся.',
              ),
              actions: <Widget>[
                TextButton(
                  key: const ValueKey<String>('registry-studio-reset-cancel'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  key: const ValueKey<String>('registry-studio-reset-confirm'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Сбросить'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await cubit.resetWorkspaceContext();

    if (!mounted) {
      return;
    }

    _searchController.clear();

    setState(() {
      _expandedRegistryNodeIds.clear();
      _registryBranchScopeNodeIds.clear();
      _registryBranchScopeScrollOffsets.clear();
      _showProblemQueue = false;
      _showProblemQueueFullScreen = false;
      _selectedRegistrySearchContextId = null;
      _selectedRegistrySearchMatchIndex = 0;
      _selectedRegistrySearchScrollPending = false;
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _updateSearchQuery(String searchQuery) async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    try {
      await cubit.updateSearchQuery(searchQuery);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Не удалось сохранить поисковый запрос Registry.'
                : message,
          ),
        ),
      );
    }
  }

  Future<void> _updateRegistryViewFilter(String filter) async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    try {
      await cubit.updateRegistryViewFilter(filter);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Не удалось сохранить фильтр Registry.' : message,
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _registryBranchScopeNodeIds.clear();
      _registryBranchScopeScrollOffsets.clear();
      _expandedRegistryNodeIds.clear();
    });

    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _selectProblem(int? index) async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    try {
      await cubit.selectProblem(index);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Не удалось сохранить контекст Registry.'
                : message,
          ),
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    if (index != null && (_showProblemQueue || _showProblemQueueFullScreen)) {
      setState(() {
        _showProblemQueue = false;
        _showProblemQueueFullScreen = false;
      });
    }

    if (index == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final BuildContext? selectedContext = _selectedProblemKey.currentContext;

      if (selectedContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.08,
      );
    });
  }

  Future<void> _selectRegistryNode(RegistryNodeId? nodeId) async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    try {
      await cubit.selectRegistryNode(nodeId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Не удалось сохранить открытый Registry block.'
                : message,
          ),
        ),
      );

      return;
    }

    if (!mounted || nodeId == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final BuildContext? selectedContext =
          _selectedRegistryBlockKey.currentContext;

      if (selectedContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.08,
      );
    });
  }

  Future<void> _selectAnalysisProblemEntry(
    RegistryProblemQueueEntry entry,
  ) async {
    await _selectRegistryNode(entry.nodeId);

    if (!mounted) {
      return;
    }

    final RegistryExplorerState currentState = context
        .read<RegistryExplorerCubit>()
        .state;

    if (currentState is! RegistryExplorerLoaded ||
        currentState.openRegistryNodeId != entry.nodeId ||
        currentState.openRegistryPath != entry.path) {
      return;
    }

    if (_showProblemQueue || _showProblemQueueFullScreen) {
      setState(() {
        _showProblemQueue = false;
        _showProblemQueueFullScreen = false;
      });
    }
  }

  Future<void> _refreshRegistry() async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    final ScaffoldMessengerState scaffoldMessenger = ScaffoldMessenger.of(
      context,
    );

    final RegistryExplorerState stateBeforeRefresh = cubit.state;

    final RegistryNode? openRegistryNodeBeforeRefresh =
        stateBeforeRefresh is RegistryExplorerLoaded
        ? stateBeforeRefresh.openRegistryNode
        : null;

    await cubit.refresh();

    if (!mounted || openRegistryNodeBeforeRefresh == null) {
      return;
    }

    final RegistryExplorerState stateAfterRefresh = cubit.state;

    if (stateAfterRefresh is! RegistryExplorerLoaded) {
      return;
    }

    final RegistryNode? openRegistryNodeAfterRefresh =
        stateAfterRefresh.openRegistryNode;

    final bool moved =
        openRegistryNodeAfterRefresh != null &&
        openRegistryNodeAfterRefresh.id == openRegistryNodeBeforeRefresh.id &&
        openRegistryNodeAfterRefresh.path != openRegistryNodeBeforeRefresh.path;

    final bool changed =
        openRegistryNodeAfterRefresh != null &&
        openRegistryNodeAfterRefresh.id == openRegistryNodeBeforeRefresh.id &&
        (openRegistryNodeAfterRefresh.kindId !=
                openRegistryNodeBeforeRefresh.kindId ||
            openRegistryNodeAfterRefresh.content !=
                openRegistryNodeBeforeRefresh.content ||
            openRegistryNodeAfterRefresh.businessScopeOwnerId !=
                openRegistryNodeBeforeRefresh.businessScopeOwnerId);

    final String? message;

    if (openRegistryNodeAfterRefresh == null) {
      message =
          'Открытый Registry block удалён '
          'в новой revision.';
    } else if (moved && changed) {
      message =
          'Открытый Registry block перемещён '
          'и изменён.\n'
          'Было: '
          '${openRegistryNodeBeforeRefresh.path.segments.join(' → ')}\n'
          'Стало: '
          '${openRegistryNodeAfterRefresh.path.segments.join(' → ')}';
    } else if (moved) {
      message =
          'Открытый Registry block перемещён.\n'
          'Было: '
          '${openRegistryNodeBeforeRefresh.path.segments.join(' → ')}\n'
          'Стало: '
          '${openRegistryNodeAfterRefresh.path.segments.join(' → ')}';
    } else if (changed) {
      message =
          'Открытый Registry block изменён '
          'в новой revision.';
    } else {
      message = null;
    }

    if (message == null) {
      return;
    }

    scaffoldMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _registryAnalysisHistoryEventLabel(
    RegistryAnalysisHistoryEntry entry,
    RegistryAnalysisHistoryEntry? previousEntry,
  ) {
    if (previousEntry == null) {
      return 'Первичная загрузка Registry';
    }

    final bool sameRevision =
        previousEntry.sourceRevision == entry.sourceRevision &&
        previousEntry.sourceSnapshotFingerprint ==
            entry.sourceSnapshotFingerprint;

    if (sameRevision) {
      return 'Refresh без новой revision';
    }

    final bool hasChanges =
        entry.previousAddedCount > 0 ||
        entry.previousRemovedCount > 0 ||
        entry.previousChangedCount > 0 ||
        entry.cleanBaselineAddedCount > 0 ||
        entry.cleanBaselineRemovedCount > 0 ||
        entry.cleanBaselineChangedCount > 0;

    if (hasChanges) {
      return 'Обнаружена новая revision';
    }

    return 'Новая revision без структурных изменений';
  }

  Future<void> _showRegistryAnalysisHistory(
    RegistryExplorerLoaded loaded,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            key: const ValueKey<String>('registry-analysis-history-sheet'),
            height: MediaQuery.sizeOf(sheetContext).height * 0.85,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'История анализа Registry: '
                          '${loaded.analysisHistory.length}',
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'registry-analysis-history-close',
                        ),
                        tooltip: 'Закрыть историю анализа',
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    'Каждая запись фиксирует результат загрузки или '
                    'refresh: revision, baseline, изменения и проблемы. '
                    'История не изменяет Registry.',
                  ),
                ),
                Expanded(
                  child: loaded.analysisHistory.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Успешные загрузки Registry '
                              'ещё не зафиксированы.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.separated(
                          key: const ValueKey<String>(
                            'registry-analysis-history-list',
                          ),
                          itemCount: loaded.analysisHistory.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (BuildContext context, int itemIndex) {
                            final int historyIndex =
                                loaded.analysisHistory.length - itemIndex - 1;

                            final RegistryAnalysisHistoryEntry entry =
                                loaded.analysisHistory[historyIndex];

                            final RegistryAnalysisHistoryEntry? previousEntry =
                                historyIndex == 0
                                ? null
                                : loaded.analysisHistory[historyIndex - 1];

                            return Padding(
                              key: ValueKey<String>(
                                'registry-analysis-history-entry-'
                                '$historyIndex',
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Revision: '
                                    '${entry.sourceRevision}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Событие: '
                                    '${_registryAnalysisHistoryEventLabel(entry, previousEntry)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Время: '
                                    '${entry.loadedAt.toLocal().toIso8601String()}',
                                  ),
                                  Text(
                                    'Предыдущая revision: '
                                    '${entry.previousRevision ?? 'нет baseline'}',
                                  ),
                                  Text(
                                    'Clean baseline: '
                                    '${entry.cleanBaselineRevision ?? 'не подтверждён'}',
                                  ),
                                  Text(
                                    'С предыдущей revision: '
                                    '+${entry.previousAddedCount} · '
                                    '-${entry.previousRemovedCount} · '
                                    '~${entry.previousChangedCount}',
                                  ),
                                  Text(
                                    'С clean baseline: '
                                    '+${entry.cleanBaselineAddedCount} · '
                                    '-${entry.cleanBaselineRemovedCount} · '
                                    '~${entry.cleanBaselineChangedCount}',
                                  ),
                                  Text(
                                    'Проблем: '
                                    '${entry.problemCount}',
                                  ),
                                  if (entry.problems.isEmpty &&
                                      entry.problemCount > 0)
                                    const Text(
                                      'Подробности проблем '
                                      'отсутствуют в legacy history.',
                                    ),
                                  for (
                                    int problemIndex = 0;
                                    problemIndex < entry.problems.length;
                                    problemIndex += 1
                                  )
                                    Padding(
                                      key: ValueKey<String>(
                                        'registry-analysis-history-problem-'
                                        '$historyIndex-'
                                        '$problemIndex-'
                                        '${entry.problems[problemIndex].nodeId}',
                                      ),
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Статус: '
                                            '${entry.problems[problemIndex].status == 'affected' ? 'затронуто' : entry.problems[problemIndex].status} · '
                                            '${entry.problems[problemIndex].pathSegments.last}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Identity: '
                                            '${entry.problems[problemIndex].nodeId}',
                                          ),
                                          Text(
                                            'Путь: '
                                            '${entry.problems[problemIndex].pathSegments.join(' → ')}',
                                          ),
                                          Text(
                                            'Причина: '
                                            '${entry.problems[problemIndex].reason}',
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRegistryStatusCenter(RegistryExplorerLoaded loaded) async {
    final int totalProblemCount =
        loaded.problems.length + widget.analysisProblemEntries.length;
    final bool hasProblems = totalProblemCount > 0;

    final bool isCurrentCleanBaseline =
        loaded.cleanBaselineSnapshot?.sourceRevision ==
        loaded.snapshot.sourceRevision;

    FocusManager.instance.primaryFocus?.unfocus(
      disposition: UnfocusDisposition.scope,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final ColorScheme colorScheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: SizedBox(
            key: const ValueKey<String>('registry-status-center-sheet'),
            height: MediaQuery.sizeOf(sheetContext).height * 0.82,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Состояние Registry',
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'registry-status-center-close',
                        ),
                        tooltip: 'Закрыть состояние Registry',
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: <Widget>[
                      Card(
                        child: ListTile(
                          leading: Icon(
                            hasProblems
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: hasProblems
                                ? colorScheme.error
                                : colorScheme.primary,
                          ),
                          title: Text(
                            'Проблемы Registry: '
                            '$totalProblemCount',
                          ),
                          subtitle: hasProblems
                              ? Text(
                                  'Структурных: '
                                  '${loaded.problems.length} · '
                                  'Аналитических: '
                                  '${widget.analysisProblemEntries.length}. '
                                  'Откройте список для перехода к каждому '
                                  'Registry block.',
                                )
                              : loaded.problemComparison == null
                              ? const Text(
                                  'Baseline сравнения отсутствует. '
                                  'Canonical findings и structural '
                                  'расхождения не обнаружены.',
                                )
                              : const Text(
                                  'Проблемы относительно текущего '
                                  'baseline не обнаружены.',
                                ),
                          trailing: hasProblems
                              ? IconButton(
                                  key: const ValueKey<String>(
                                    'registry-status-center-open-problems',
                                  ),
                                  tooltip: 'Открыть проблемы Registry',
                                  onPressed: () {
                                    Navigator.of(sheetContext).pop();

                                    if (!mounted) {
                                      return;
                                    }

                                    setState(() {
                                      _showProblemQueue = false;
                                      _showProblemQueueFullScreen = true;
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_forward),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.compare_arrows_outlined),
                          title: Text(
                            loaded.previousComparison == null
                                ? 'Сравнение с предыдущей revision: '
                                      'нет baseline'
                                : 'Изменения с предыдущей revision: '
                                      '${loaded.previousComparison!.changes.length}',
                          ),
                          subtitle: loaded.previousComparison == null
                              ? const Text(
                                  'Предыдущая известная revision '
                                  'отсутствует. Сравнение появится '
                                  'после загрузки новой revision.',
                                )
                              : Text(
                                  'Добавлено: '
                                  '${loaded.previousComparison!.addedCount} · '
                                  'Удалено: '
                                  '${loaded.previousComparison!.removedCount} · '
                                  'Изменено: '
                                  '${loaded.previousComparison!.changedCount}',
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        key: const ValueKey<String>(
                          'registry-status-center-clean-baseline-card',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  isCurrentCleanBaseline
                                      ? Icons.verified_outlined
                                      : Icons.verified_user_outlined,
                                ),
                                title: Text(
                                  loaded.cleanBaselineSnapshot == null
                                      ? 'Clean baseline не подтверждён'
                                      : 'Clean baseline подтверждён',
                                  key: const ValueKey<String>(
                                    'registry-status-center-'
                                    'clean-baseline-title',
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (loaded.cleanBaselineSnapshot !=
                                        null) ...<Widget>[
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        loaded
                                            .cleanBaselineSnapshot!
                                            .sourceRevision,
                                        key: const ValueKey<String>(
                                          'registry-status-center-'
                                          'clean-baseline-revision',
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      loaded.cleanBaselineSnapshot == null
                                          ? 'Текущая revision ещё не '
                                                'сохранена как '
                                                'подтверждённая инженером '
                                                'контрольная точка. '
                                                'Clean baseline не '
                                                'изменяется автоматически '
                                                'при refresh.'
                                          : loaded.cleanBaselineComparison ==
                                                null
                                          ? 'Clean baseline используется '
                                                'как подтверждённая '
                                                'инженером контрольная '
                                                'точка и не изменяется '
                                                'автоматически при refresh.'
                                          : 'Расхождения с clean baseline: '
                                                '${loaded.cleanBaselineComparison!.changes.length}\n'
                                                'Добавлено: '
                                                '${loaded.cleanBaselineComparison!.addedCount} · '
                                                'Удалено: '
                                                '${loaded.cleanBaselineComparison!.removedCount} · '
                                                'Изменено: '
                                                '${loaded.cleanBaselineComparison!.changedCount}',
                                      key: const ValueKey<String>(
                                        'registry-status-center-'
                                        'clean-baseline-description',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrentCleanBaseline) ...<Widget>[
                                const SizedBox(height: 12),
                                FilledButton(
                                  key: const ValueKey<String>(
                                    'registry-status-center-'
                                    'confirm-baseline',
                                  ),
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();

                                    await Future<void>.delayed(Duration.zero);

                                    if (!mounted) {
                                      return;
                                    }

                                    await _confirmCurrentAsCleanBaseline();
                                  },
                                  child: Text(
                                    loaded.cleanBaselineSnapshot == null
                                        ? 'Подтвердить текущую revision'
                                        : 'Обновить clean baseline',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            'История анализа: '
                            '${loaded.analysisHistory.length}',
                          ),
                          subtitle: const Text(
                            'Хранит revision context, результаты '
                            'comparison и обнаруженные проблемы для '
                            'предыдущих загрузок Registry.',
                          ),
                          trailing: IconButton(
                            key: const ValueKey<String>(
                              'registry-status-center-open-history',
                            ),
                            tooltip: 'Открыть историю анализа Registry',
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();

                              await Future<void>.delayed(Duration.zero);

                              if (!mounted) {
                                return;
                              }

                              await _showRegistryAnalysisHistory(loaded);
                            },
                            icon: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Текущая revision',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              SelectableText(loaded.snapshot.sourceRevision),
                              if (loaded.previousSnapshot != null) ...<Widget>[
                                const SizedBox(height: 12),
                                Text(
                                  'Предыдущая revision',
                                  style: Theme.of(
                                    sheetContext,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 6),
                                SelectableText(
                                  loaded.previousSnapshot!.sourceRevision,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmCurrentAsCleanBaseline() async {
    final RegistryExplorerCubit cubit = context.read<RegistryExplorerCubit>();

    final RegistryExplorerState currentState = cubit.state;

    if (currentState is! RegistryExplorerLoaded) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Подтвердить clean baseline?'),
          content: Text(
            'Revision ${currentState.snapshot.sourceRevision} '
            'будет сохранена как последнее принятое инженером '
            'чистое состояние Registry. Это действие не является '
            'утверждением change set или publication.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Подтвердить'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await cubit.confirmCurrentAsCleanBaseline();
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty ? 'Не удалось сохранить clean baseline.' : message,
          ),
        ),
      );
    }
  }

  MapEntry<String, String>? _registrySearchMatch(
    RegistryNode node,
    String query,
  ) {
    final String normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return null;
    }

    bool matches(String value) {
      return value.toLowerCase().contains(normalizedQuery);
    }

    if (matches(node.id.value)) {
      return MapEntry<String, String>(
        'структурном идентификаторе',
        node.id.value,
      );
    }

    final String title = node.path.segments.last;

    if (matches(title)) {
      return MapEntry<String, String>('заголовке', title);
    }

    final String registryPath = node.path.segments.join(' → ');

    if (matches(registryPath)) {
      return MapEntry<String, String>('пути', registryPath);
    }

    if (matches(node.kindId)) {
      return MapEntry<String, String>('типе блока', node.kindId);
    }

    if (matches(node.content)) {
      return MapEntry<String, String>(
        'содержимом',
        _registrySearchSnippet(node.content, normalizedQuery),
      );
    }

    for (final evidence in node.sourceEvidence) {
      if (matches(evidence.sourceDocumentPath)) {
        return MapEntry<String, String>(
          'документе-источнике',
          evidence.sourceDocumentPath,
        );
      }

      if (matches(evidence.sourceSnapshotFingerprint)) {
        return MapEntry<String, String>(
          'версии источника',
          evidence.sourceSnapshotFingerprint,
        );
      }

      final String evidencePath = evidence.headingPath.join(' → ');

      if (matches(evidencePath)) {
        return MapEntry<String, String>('пути источника', evidencePath);
      }

      final String evidenceLines = '${evidence.startLine}-${evidence.endLine}';

      if (matches(evidenceLines)) {
        return MapEntry<String, String>('номерах строк', evidenceLines);
      }
    }

    return null;
  }

  String _registrySearchSnippet(String content, String normalizedQuery) {
    final String normalizedContent = content.toLowerCase();

    final int matchIndex = normalizedContent.indexOf(normalizedQuery);

    if (matchIndex < 0 || content.length <= 180) {
      return content;
    }

    final int start = matchIndex > 70 ? matchIndex - 70 : 0;

    final int proposedEnd = matchIndex + normalizedQuery.length + 90;

    final int end = proposedEnd < content.length ? proposedEnd : content.length;

    return '${start > 0 ? '…' : ''}'
        '${content.substring(start, end).trim()}'
        '${end < content.length ? '…' : ''}';
  }

  Widget _highlightRegistrySearchText(
    BuildContext context,
    String text,
    String query, {
    Key? key,
    TextStyle? style,
  }) {
    final String normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return Text(text, key: key, style: style);
    }

    final String normalizedText = text.toLowerCase();
    final List<TextSpan> spans = <TextSpan>[];

    int cursor = 0;

    while (cursor < text.length) {
      final int matchIndex = normalizedText.indexOf(normalizedQuery, cursor);

      if (matchIndex < 0) {
        spans.add(TextSpan(text: text.substring(cursor)));
        break;
      }

      if (matchIndex > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, matchIndex)));
      }

      final int matchEnd = matchIndex + normalizedQuery.length;

      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchEnd),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ),
      );

      cursor = matchEnd;
    }

    return Text.rich(
      TextSpan(children: spans),
      key: key,
      style: style,
    );
  }

  List<RegistryNode> _allRegistryNodes(List<RegistryNode> roots) {
    final List<RegistryNode> nodes = <RegistryNode>[];

    void append(List<RegistryNode> currentNodes) {
      for (final RegistryNode node in currentNodes) {
        nodes.add(node);

        if (node.children.isNotEmpty) {
          append(node.children);
        }
      }
    }

    append(roots);

    return nodes;
  }

  bool _matchesRegistryViewFilter(
    RegistryNode node,
    String registryViewFilter,
  ) {
    switch (registryViewFilter) {
      case 'roots':
        return node.path.segments.length == 1;
      case 'branches':
        return node.children.isNotEmpty;
      case 'leaves':
        return node.children.isEmpty;
      default:
        if (registryViewFilter.startsWith('kind:')) {
          return node.kindId == registryViewFilter.substring('kind:'.length);
        }

        return true;
    }
  }

  String _registryViewFilterLabel(String registryViewFilter) {
    switch (registryViewFilter) {
      case 'roots':
        return 'Корневые узлы';
      case 'branches':
        return 'Ветки';
      case 'leaves':
        return 'Конечные блоки';
      default:
        if (registryViewFilter.startsWith('kind:')) {
          return 'Тип: '
              '${registryViewFilter.substring('kind:'.length)}';
        }

        return 'Все узлы';
    }
  }

  Future<void> _updateCanonicalStatusFilter(
    String canonicalStatusFilter,
  ) async {
    try {
      await context.read<RegistryExplorerCubit>().updateCanonicalStatusFilter(
        canonicalStatusFilter,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final String message = error.toString().trim();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.isEmpty
                ? 'Не удалось сохранить canonical status filter.'
                : message,
          ),
        ),
      );
    }
  }

  String _canonicalStatusFilterLabel(String canonicalStatusFilter) {
    return switch (canonicalStatusFilter) {
      'unclassifiedNeutral' => 'Unclassified / Neutral',
      'exact' => 'Exact',
      'equivalent' => 'Equivalent',
      'review' => 'Review',
      'drift' => 'Drift',
      'failed' => 'Failed',
      _ => 'All',
    };
  }

  bool _matchesCanonicalStatusFilter(
    RegistryExplorerLoaded loaded,
    RegistryNode node,
    String canonicalStatusFilter,
  ) {
    if (canonicalStatusFilter == 'all') {
      return true;
    }

    final List<String> nodePath = node.path.segments;

    for (final RegistryAnalysisStatusEntry entry
        in widget.analysisStatusEntries) {
      if (entry.statusId != canonicalStatusFilter) {
        continue;
      }

      final RegistryNode? entryNode = loaded.index.nodesById[entry.nodeId];

      if (entryNode == null) {
        continue;
      }

      final List<String> entryNodePath = entryNode.path.segments;

      if (entryNodePath.length < nodePath.length) {
        continue;
      }

      bool insideNodeSubtree = true;

      for (int index = 0; index < nodePath.length; index += 1) {
        if (entryNodePath[index] != nodePath[index]) {
          insideNodeSubtree = false;
          break;
        }
      }

      if (insideNodeSubtree) {
        return true;
      }
    }

    return false;
  }

  String? _registryFilterHelperText(RegistryExplorerLoaded loaded) {
    final bool structuralFilterActive = loaded.registryViewFilter != 'all';
    final bool canonicalFilterActive = loaded.canonicalStatusFilter != 'all';

    if (!structuralFilterActive && !canonicalFilterActive) {
      return null;
    }

    final String filterLabel;

    if (structuralFilterActive && canonicalFilterActive) {
      filterLabel =
          'Фильтры: '
          '${_registryViewFilterLabel(loaded.registryViewFilter)} · '
          'Canonical: '
          '${_canonicalStatusFilterLabel(loaded.canonicalStatusFilter)}';
    } else if (structuralFilterActive) {
      filterLabel =
          'Фильтр: '
          '${_registryViewFilterLabel(loaded.registryViewFilter)}';
    } else {
      filterLabel =
          'Canonical: '
          '${_canonicalStatusFilterLabel(loaded.canonicalStatusFilter)}';
    }

    final int visibleCount = _visibleRegistryNodes(loaded).length;
    final int searchResultCount = loaded.searchResults.length;

    if (loaded.searchQuery.trim().isEmpty) {
      return '$filterLabel · показано: $visibleCount';
    }

    return '$filterLabel · '
        'показано: $visibleCount из $searchResultCount';
  }

  Future<void> _showRegistryViewFilter(RegistryExplorerLoaded loaded) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => RegistryViewFilterSheet(
        nodesById: loaded.index.nodesById,
        analysisStatusEntries: widget.analysisStatusEntries,
        branchScopeNodeId: _registryBranchScopeRoot(loaded)?.id,
        initialRegistryViewFilter: loaded.registryViewFilter,
        initialCanonicalStatusFilter: loaded.canonicalStatusFilter,
        onRegistryViewFilterChanged: _updateRegistryViewFilter,
        onCanonicalStatusFilterChanged: _updateCanonicalStatusFilter,
      ),
    );
  }

  RegistryNode? _registryBranchScopeRoot(RegistryExplorerLoaded loaded) {
    if (_registryBranchScopeNodeIds.isEmpty) {
      return null;
    }

    return loaded.index.nodesById[_registryBranchScopeNodeIds.last];
  }

  void _openRegistryBranchScope(RegistryNode node) {
    final double currentOffset = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0;

    setState(() {
      _registryBranchScopeNodeIds.add(node.id);
      _registryBranchScopeScrollOffsets.add(currentOffset);
      _expandedRegistryNodeIds.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(0);
    });
  }

  void _closeRegistryBranchScope() {
    if (_registryBranchScopeNodeIds.isEmpty ||
        _registryBranchScopeScrollOffsets.isEmpty) {
      return;
    }

    final double restoreOffset = _registryBranchScopeScrollOffsets.last;

    setState(() {
      _registryBranchScopeNodeIds.removeLast();
      _registryBranchScopeScrollOffsets.removeLast();
      _expandedRegistryNodeIds.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final double targetOffset = restoreOffset
          .clamp(0.0, _scrollController.position.maxScrollExtent)
          .toDouble();

      _scrollController.jumpTo(targetOffset);
    });
  }

  bool _hasVisibleRegistryChildren(
    RegistryNode node, {
    required String registryViewFilter,
    required String canonicalStatusFilter,
    required bool searchActive,
    required bool branchScopeActive,
  }) {
    if (searchActive) {
      return false;
    }

    if (branchScopeActive) {
      return node.children.isNotEmpty;
    }

    if (canonicalStatusFilter != 'all') {
      return false;
    }

    return registryViewFilter == 'all' && node.children.isNotEmpty;
  }

  List<RegistryNode> _visibleRegistryNodes(RegistryExplorerLoaded loaded) {
    final String registryViewFilter = loaded.registryViewFilter;
    final bool searchActive = loaded.searchQuery.trim().isNotEmpty;

    final RegistryNode? branchScopeRoot = _registryBranchScopeRoot(loaded);

    if (!searchActive && branchScopeRoot != null) {
      final List<RegistryNode> visibleNodes = <RegistryNode>[];

      void appendNodes(RegistryNode node, int depth) {
        visibleNodes.add(node);

        final bool childrenVisible =
            depth == 0 || _expandedRegistryNodeIds.contains(node.id);

        if (!childrenVisible) {
          return;
        }

        for (final RegistryNode child in node.children) {
          appendNodes(child, depth + 1);
        }
      }

      appendNodes(branchScopeRoot, 0);

      return visibleNodes;
    }

    if (loaded.canonicalStatusFilter != 'all') {
      Iterable<RegistryNode> canonicalStatusNodes = searchActive
          ? loaded.searchResults
          : _allRegistryNodes(loaded.snapshot.roots);

      if (registryViewFilter != 'all') {
        canonicalStatusNodes = canonicalStatusNodes.where(
          (RegistryNode node) =>
              _matchesRegistryViewFilter(node, registryViewFilter),
        );
      }

      return canonicalStatusNodes
          .where(
            (RegistryNode node) => _matchesCanonicalStatusFilter(
              loaded,
              node,
              loaded.canonicalStatusFilter,
            ),
          )
          .toList(growable: false);
    }

    if (searchActive) {
      if (registryViewFilter == 'all') {
        return loaded.searchResults;
      }

      return loaded.searchResults
          .where(
            (RegistryNode node) =>
                _matchesRegistryViewFilter(node, registryViewFilter),
          )
          .toList(growable: false);
    }

    if (registryViewFilter == 'branches') {
      return _allRegistryNodes(loaded.snapshot.roots)
          .where(
            (RegistryNode node) =>
                _matchesRegistryViewFilter(node, registryViewFilter),
          )
          .toList(growable: false);
    }

    if (registryViewFilter != 'all') {
      return _allRegistryNodes(loaded.snapshot.roots)
          .where(
            (RegistryNode node) =>
                _matchesRegistryViewFilter(node, registryViewFilter),
          )
          .toList(growable: false);
    }

    final List<RegistryNode> visibleNodes = <RegistryNode>[];

    void appendNodes(List<RegistryNode> nodes, int depth) {
      for (final RegistryNode node in nodes) {
        visibleNodes.add(node);

        final bool childrenVisible =
            depth == 0 || _expandedRegistryNodeIds.contains(node.id);

        if (childrenVisible && node.children.isNotEmpty) {
          appendNodes(node.children, depth + 1);
        }
      }
    }

    appendNodes(loaded.snapshot.roots, 0);

    return visibleNodes;
  }

  Widget _buildSelectedRegistryBlockScreen(
    BuildContext context,
    RegistryExplorerLoaded loaded,
    RegistryNode node,
  ) {
    final List<RegistryAnalysisStatusEntry> selectedAnalysisStatusEntries =
        widget.analysisStatusEntries
            .where(
              (RegistryAnalysisStatusEntry entry) =>
                  entry.nodeId == node.id &&
                  (loaded.canonicalStatusFilter == 'all' ||
                      entry.statusId == loaded.canonicalStatusFilter),
            )
            .toList()
          ..sort((
            RegistryAnalysisStatusEntry first,
            RegistryAnalysisStatusEntry second,
          ) {
            final int lineComparison = first.directContentLine.compareTo(
              second.directContentLine,
            );

            if (lineComparison != 0) {
              return lineComparison;
            }

            return first.identity.compareTo(second.identity);
          });

    final String searchQuery = loaded.searchQuery.trim();

    final MapEntry<String, String>? searchMatch = searchQuery.isEmpty
        ? null
        : _registrySearchMatch(node, searchQuery);

    final String normalizedSearchQuery = searchQuery.toLowerCase();
    final String normalizedContent = node.content.toLowerCase();

    final List<int> contentMatchOffsets = <int>[];

    if (normalizedSearchQuery.isNotEmpty) {
      int searchOffset = 0;

      while (searchOffset < normalizedContent.length) {
        final int matchOffset = normalizedContent.indexOf(
          normalizedSearchQuery,
          searchOffset,
        );

        if (matchOffset < 0) {
          break;
        }

        contentMatchOffsets.add(matchOffset);

        searchOffset = matchOffset + normalizedSearchQuery.length;
      }
    }

    final String selectedSearchContextId =
        '${node.id.value}\n$normalizedSearchQuery';

    if (_selectedRegistrySearchContextId != selectedSearchContextId) {
      _selectedRegistrySearchContextId = selectedSearchContextId;
      _selectedRegistrySearchMatchIndex = 0;
      _selectedRegistrySearchScrollPending = contentMatchOffsets.isNotEmpty;
    }

    if (contentMatchOffsets.isEmpty) {
      _selectedRegistrySearchMatchIndex = 0;
      _selectedRegistrySearchScrollPending = false;
    } else if (_selectedRegistrySearchMatchIndex >=
        contentMatchOffsets.length) {
      _selectedRegistrySearchMatchIndex = contentMatchOffsets.length - 1;
    }

    final List<GlobalKey> contentMatchKeys = List<GlobalKey>.generate(
      contentMatchOffsets.length,
      (int index) =>
          GlobalKey(debugLabel: 'registry-selected-content-match-$index'),
    );

    if (_selectedRegistrySearchScrollPending && contentMatchKeys.isNotEmpty) {
      _selectedRegistrySearchScrollPending = false;

      final int targetMatchIndex = _selectedRegistrySearchMatchIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || targetMatchIndex >= contentMatchKeys.length) {
          return;
        }

        final BuildContext? matchContext =
            contentMatchKeys[targetMatchIndex].currentContext;

        if (matchContext == null) {
          return;
        }

        Scrollable.ensureVisible(
          matchContext,
          alignment: 0.24,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }

    final List<InlineSpan> contentSpans = <InlineSpan>[];
    int contentOffset = 0;

    for (
      int matchIndex = 0;
      matchIndex < contentMatchOffsets.length;
      matchIndex += 1
    ) {
      final int matchOffset = contentMatchOffsets[matchIndex];

      if (matchOffset > contentOffset) {
        contentSpans.add(
          TextSpan(text: node.content.substring(contentOffset, matchOffset)),
        );
      }

      final int matchEnd = matchOffset + normalizedSearchQuery.length;

      contentSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            key: contentMatchKeys[matchIndex],
            decoration: BoxDecoration(
              color: matchIndex == _selectedRegistrySearchMatchIndex
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(3),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              node.content.substring(matchOffset, matchEnd),
              style: TextStyle(
                color: matchIndex == _selectedRegistrySearchMatchIndex
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: matchIndex == _selectedRegistrySearchMatchIndex
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
      );

      contentOffset = matchEnd;
    }

    if (contentOffset < node.content.length) {
      contentSpans.add(TextSpan(text: node.content.substring(contentOffset)));
    }

    final List<String> contentLines = node.content.split('\n');

    final GlobalKey canonicalHeadingKey = GlobalKey(
      debugLabel: 'registry-selected-canonical-heading',
    );

    final bool hasCanonicalHeadingEntries = selectedAnalysisStatusEntries.any(
      (RegistryAnalysisStatusEntry entry) => entry.directContentLine == 0,
    );

    final Map<int, List<RegistryAnalysisStatusEntry>> canonicalEntriesByLine =
        <int, List<RegistryAnalysisStatusEntry>>{};

    for (final RegistryAnalysisStatusEntry entry
        in selectedAnalysisStatusEntries) {
      if (entry.directContentLine < 1 ||
          entry.directContentLine > contentLines.length) {
        continue;
      }

      canonicalEntriesByLine
          .putIfAbsent(
            entry.directContentLine,
            () => <RegistryAnalysisStatusEntry>[],
          )
          .add(entry);
    }

    final List<GlobalKey?> canonicalLineKeys = List<GlobalKey?>.filled(
      contentLines.length,
      null,
    );

    for (final int lineNumber in canonicalEntriesByLine.keys) {
      canonicalLineKeys[lineNumber - 1] = GlobalKey(
        debugLabel: 'registry-selected-canonical-line-$lineNumber',
      );
    }

    final String selectedCanonicalContextId =
        '${node.id.value}\n'
        '${loaded.canonicalStatusFilter}\n'
        '${selectedAnalysisStatusEntries.map((RegistryAnalysisStatusEntry entry) => entry.identity).join('\n')}';

    if (_selectedCanonicalContextId != selectedCanonicalContextId) {
      _selectedCanonicalContextId = selectedCanonicalContextId;
      _selectedCanonicalMatchIndex = 0;
      _selectedCanonicalScrollPending =
          searchQuery.isEmpty && selectedAnalysisStatusEntries.isNotEmpty;
    }

    if (selectedAnalysisStatusEntries.isEmpty) {
      _selectedCanonicalMatchIndex = 0;
      _selectedCanonicalScrollPending = false;
    } else if (_selectedCanonicalMatchIndex >=
        selectedAnalysisStatusEntries.length) {
      _selectedCanonicalMatchIndex = selectedAnalysisStatusEntries.length - 1;
    }

    final RegistryAnalysisStatusEntry? selectedCanonicalEntry =
        selectedAnalysisStatusEntries.isEmpty
        ? null
        : selectedAnalysisStatusEntries[_selectedCanonicalMatchIndex];

    if (_selectedCanonicalScrollPending &&
        searchQuery.isEmpty &&
        selectedCanonicalEntry != null) {
      _selectedCanonicalScrollPending = false;

      final int targetLine = selectedCanonicalEntry.directContentLine;

      final GlobalKey? targetKey = targetLine == 0
          ? canonicalHeadingKey
          : targetLine > 0 && targetLine <= canonicalLineKeys.length
          ? canonicalLineKeys[targetLine - 1]
          : null;

      if (targetKey != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }

          final BuildContext? targetContext = targetKey.currentContext;

          if (targetContext == null) {
            return;
          }

          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.24,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        });
      }
    }

    return Material(
      key: const ValueKey<String>('registry-selected-block-screen'),
      child: SafeArea(
        child: Column(
          key: const ValueKey<String>('registry-selected-block'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    key: const ValueKey<String>('registry-selected-block-back'),
                    tooltip: 'Закрыть Registry block',
                    onPressed: () async {
                      await _selectRegistryNode(null);
                    },
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Открытый Registry block',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Container(
                          key: canonicalHeadingKey,
                          child: Container(
                            key: ValueKey<String>(
                              selectedCanonicalEntry?.directContentLine == 0
                                  ? 'registry-selected-canonical-heading-active'
                                  : 'registry-selected-canonical-heading',
                            ),
                            padding: hasCanonicalHeadingEntries
                                ? const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  )
                                : EdgeInsets.zero,
                            decoration: hasCanonicalHeadingEntries
                                ? BoxDecoration(
                                    color:
                                        selectedCanonicalEntry
                                                ?.directContentLine ==
                                            0
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.tertiaryContainer
                                        : Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer
                                              .withValues(alpha: 0.42),
                                    border: Border(
                                      left: BorderSide(
                                        width:
                                            selectedCanonicalEntry
                                                    ?.directContentLine ==
                                                0
                                            ? 4
                                            : 2,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.tertiary,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  )
                                : null,
                            child: Text(
                              node.path.segments.last,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: !hasCanonicalHeadingEntries
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer,
                                      fontWeight:
                                          selectedCanonicalEntry
                                                  ?.directContentLine ==
                                              0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>(
                      'registry-selected-block-reset',
                    ),
                    tooltip: 'Сбросить контекст Registry Studio',
                    onPressed: _resetRegistryStudio,
                    icon: const Icon(Icons.layers_clear_outlined),
                  ),
                  if (searchQuery.isNotEmpty)
                    IconButton(
                      key: const ValueKey<String>(
                        'registry-selected-block-search-clear',
                      ),
                      tooltip: 'Сбросить поиск Registry',
                      onPressed: () async {
                        await _clearSearch();

                        if (!mounted ||
                            !_selectedRegistryBlockScrollController
                                .hasClients) {
                          return;
                        }

                        _selectedRegistryBlockScrollController.jumpTo(0);
                      },
                      icon: const Icon(Icons.search_off),
                    ),
                  IconButton(
                    tooltip: 'Перезагрузить Registry',
                    onPressed: _refreshRegistry,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Stack(
                children: <Widget>[
                  ListView(
                    controller: _selectedRegistryBlockScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                    children: <Widget>[
                      Container(
                        key: _selectedRegistryBlockKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (searchMatch != null) ...<Widget>[
                              Card(
                                key: const ValueKey<String>(
                                  'registry-selected-block-search-context',
                                ),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Поиск: "$searchQuery"',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text('Область: весь Registry'),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Совпадение в ${searchMatch.key}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _highlightRegistrySearchText(
                                        context,
                                        searchMatch.value,
                                        searchQuery,
                                        key: const ValueKey<String>(
                                          'registry-selected-block-search-highlight',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              'RegistryPath: '
                              '${node.path.segments.join(' → ')}',
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Structural identity: '
                              '${node.id.value}',
                            ),
                            const SizedBox(height: 12),
                            Text('Тип: ${node.kindId}'),
                            const SizedBox(height: 12),
                            Text(
                              'Уровень: '
                              '${node.path.segments.length} · '
                              'Дочерних узлов: '
                              '${node.children.length}',
                            ),
                            const SizedBox(height: 12),
                            for (final evidence in node.sourceEvidence)
                              Text(
                                'Evidence: '
                                '${evidence.sourceDocumentPath}, '
                                'строки '
                                '${evidence.startLine}–'
                                '${evidence.endLine}',
                              ),
                            if (selectedAnalysisStatusEntries
                                .isNotEmpty) ...<Widget>[
                              const Divider(height: 24),
                              Text(
                                'Канонический анализ · '
                                '${selectedAnalysisStatusEntries.length} '
                                'формулировок',
                                key: const ValueKey<String>(
                                  'registry-selected-canonical-analysis',
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              for (final RegistryAnalysisStatusEntry entry
                                  in selectedAnalysisStatusEntries)
                                Card(
                                  key: ValueKey<String>(
                                    'registry-selected-analysis-'
                                    '${entry.identity}',
                                  ),
                                  margin: const EdgeInsets.only(top: 10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          entry.statusLabel,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.directContentLine == 0
                                              ? 'Место: заголовок блока'
                                              : 'Место: строка '
                                                    '${entry.directContentLine} '
                                                    'внутри блока',
                                        ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          entry.text,
                                          key: ValueKey<String>(
                                            'registry-selected-analysis-text-'
                                            '${entry.identity}',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          'Причина: ${entry.reason}',
                                        ),
                                        for (final evidence
                                            in entry.sourceEvidence)
                                          SelectableText(
                                            'Source evidence: '
                                            '${evidence.sourceDocumentPath}, '
                                            'строки '
                                            '${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            key: ValueKey<String>(
                                              'registry-selected-analysis-show-'
                                              '${entry.identity}',
                                            ),
                                            onPressed: () {
                                              final int targetIndex =
                                                  selectedAnalysisStatusEntries
                                                      .indexOf(entry);

                                              if (targetIndex < 0) {
                                                return;
                                              }

                                              setState(() {
                                                _selectedCanonicalMatchIndex =
                                                    targetIndex;
                                                _selectedCanonicalScrollPending =
                                                    true;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.my_location_outlined,
                                            ),
                                            label: const Text(
                                              'Показать в тексте',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                            const Divider(height: 24),
                            if (searchQuery.isNotEmpty)
                              SelectionArea(
                                child: Text.rich(
                                  TextSpan(
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                    children: contentSpans,
                                  ),
                                  key: const ValueKey<String>(
                                    'registry-selected-block-content-highlight',
                                  ),
                                ),
                              )
                            else if (selectedAnalysisStatusEntries.isEmpty)
                              SelectableText(node.content)
                            else
                              SelectionArea(
                                child: Column(
                                  key: const ValueKey<String>(
                                    'registry-selected-canonical-content',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    for (
                                      int lineIndex = 0;
                                      lineIndex < contentLines.length;
                                      lineIndex += 1
                                    )
                                      Container(
                                        key: canonicalLineKeys[lineIndex],
                                        child: Container(
                                          key: ValueKey<String>(
                                            selectedCanonicalEntry
                                                        ?.directContentLine ==
                                                    lineIndex + 1
                                                ? 'registry-selected-'
                                                      'canonical-line-active-'
                                                      '${lineIndex + 1}'
                                                : 'registry-selected-'
                                                      'canonical-line-'
                                                      '${lineIndex + 1}',
                                          ),
                                          margin: EdgeInsets.only(
                                            bottom:
                                                lineIndex ==
                                                    contentLines.length - 1
                                                ? 0
                                                : 2,
                                          ),
                                          padding:
                                              canonicalEntriesByLine
                                                  .containsKey(lineIndex + 1)
                                              ? const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 3,
                                                )
                                              : EdgeInsets.zero,
                                          decoration:
                                              canonicalEntriesByLine
                                                  .containsKey(lineIndex + 1)
                                              ? BoxDecoration(
                                                  color:
                                                      selectedCanonicalEntry
                                                              ?.directContentLine ==
                                                          lineIndex + 1
                                                      ? Theme.of(context)
                                                            .colorScheme
                                                            .tertiaryContainer
                                                      : Theme.of(context)
                                                            .colorScheme
                                                            .tertiaryContainer
                                                            .withValues(
                                                              alpha: 0.42,
                                                            ),
                                                  border: Border(
                                                    left: BorderSide(
                                                      width:
                                                          selectedCanonicalEntry
                                                                  ?.directContentLine ==
                                                              lineIndex + 1
                                                          ? 4
                                                          : 2,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.tertiary,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                )
                                              : null,
                                          child: Text(
                                            contentLines[lineIndex].isEmpty
                                                ? ' '
                                                : contentLines[lineIndex],
                                            style:
                                                canonicalEntriesByLine
                                                    .containsKey(lineIndex + 1)
                                                ? TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                    fontWeight:
                                                        selectedCanonicalEntry
                                                                ?.directContentLine ==
                                                            lineIndex + 1
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                  )
                                                : null,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (searchQuery.isEmpty &&
                      selectedAnalysisStatusEntries.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: Material(
                          key: const ValueKey<String>(
                            'registry-selected-canonical-navigation',
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withAlpha(200),
                          elevation: 2,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                key: const ValueKey<String>(
                                  'registry-selected-canonical-previous',
                                ),
                                tooltip: 'Предыдущая формулировка',
                                onPressed: _selectedCanonicalMatchIndex > 0
                                    ? () {
                                        setState(() {
                                          _selectedCanonicalMatchIndex -= 1;
                                          _selectedCanonicalScrollPending =
                                              true;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '${_selectedCanonicalMatchIndex + 1}/'
                                  '${selectedAnalysisStatusEntries.length}',
                                  key: const ValueKey<String>(
                                    'registry-selected-canonical-position',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey<String>(
                                  'registry-selected-canonical-next',
                                ),
                                tooltip: 'Следующая формулировка',
                                onPressed:
                                    _selectedCanonicalMatchIndex <
                                        selectedAnalysisStatusEntries.length - 1
                                    ? () {
                                        setState(() {
                                          _selectedCanonicalMatchIndex += 1;
                                          _selectedCanonicalScrollPending =
                                              true;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_downward),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (searchQuery.isNotEmpty && contentMatchOffsets.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: Material(
                          key: const ValueKey<String>(
                            'registry-selected-block-match-navigation',
                          ),
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withAlpha(200),
                          elevation: 2,
                          borderRadius: BorderRadius.circular(28),
                          clipBehavior: Clip.antiAlias,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                key: const ValueKey<String>(
                                  'registry-selected-block-match-previous',
                                ),
                                tooltip: 'Предыдущее совпадение',
                                onPressed: _selectedRegistrySearchMatchIndex > 0
                                    ? () {
                                        setState(() {
                                          _selectedRegistrySearchMatchIndex -=
                                              1;
                                          _selectedRegistrySearchScrollPending =
                                              true;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '${_selectedRegistrySearchMatchIndex + 1}/'
                                  '${contentMatchOffsets.length}',
                                  key: const ValueKey<String>(
                                    'registry-selected-block-match-position',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey<String>(
                                  'registry-selected-block-match-next',
                                ),
                                tooltip: 'Следующее совпадение',
                                onPressed:
                                    _selectedRegistrySearchMatchIndex <
                                        contentMatchOffsets.length - 1
                                    ? () {
                                        setState(() {
                                          _selectedRegistrySearchMatchIndex +=
                                              1;
                                          _selectedRegistrySearchScrollPending =
                                              true;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.arrow_downward),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistryExplorerCubit, RegistryExplorerState>(
      builder: (BuildContext context, RegistryExplorerState state) {
        return switch (state) {
          RegistryExplorerLoading() => const SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Загрузка Registry'),
                ],
              ),
            ),
          ),
          RegistryExplorerFailure(
            :final String message,
            :final RegistryNode? openRegistryNodeBeforeRefresh,
          ) =>
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Не удалось загрузить Registry',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      IconButton(
                        tooltip: 'Повторить загрузку Registry',
                        onPressed: () async {
                          final RegistryExplorerCubit cubit = context
                              .read<RegistryExplorerCubit>();

                          final ScaffoldMessengerState scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          await cubit.retry();

                          if (!mounted ||
                              openRegistryNodeBeforeRefresh == null) {
                            return;
                          }

                          final RegistryExplorerState stateAfterRetry =
                              cubit.state;

                          if (stateAfterRetry is! RegistryExplorerLoaded) {
                            return;
                          }

                          final RegistryNode? openRegistryNodeAfterRetry =
                              stateAfterRetry.openRegistryNode;

                          final bool moved =
                              openRegistryNodeAfterRetry != null &&
                              openRegistryNodeAfterRetry.id ==
                                  openRegistryNodeBeforeRefresh.id &&
                              openRegistryNodeAfterRetry.path !=
                                  openRegistryNodeBeforeRefresh.path;

                          final bool changed =
                              openRegistryNodeAfterRetry != null &&
                              openRegistryNodeAfterRetry.id ==
                                  openRegistryNodeBeforeRefresh.id &&
                              (openRegistryNodeAfterRetry.kindId !=
                                      openRegistryNodeBeforeRefresh.kindId ||
                                  openRegistryNodeAfterRetry.content !=
                                      openRegistryNodeBeforeRefresh.content ||
                                  openRegistryNodeAfterRetry
                                          .businessScopeOwnerId !=
                                      openRegistryNodeBeforeRefresh
                                          .businessScopeOwnerId);

                          final String? outcomeMessage;

                          if (openRegistryNodeAfterRetry == null) {
                            outcomeMessage =
                                'Открытый Registry block удалён '
                                'в новой revision.';
                          } else if (moved && changed) {
                            outcomeMessage =
                                'Открытый Registry block перемещён '
                                'и изменён.\n'
                                'Было: '
                                '${openRegistryNodeBeforeRefresh.path.segments.join(' → ')}\n'
                                'Стало: '
                                '${openRegistryNodeAfterRetry.path.segments.join(' → ')}';
                          } else if (moved) {
                            outcomeMessage =
                                'Открытый Registry block перемещён.\n'
                                'Было: '
                                '${openRegistryNodeBeforeRefresh.path.segments.join(' → ')}\n'
                                'Стало: '
                                '${openRegistryNodeAfterRetry.path.segments.join(' → ')}';
                          } else if (changed) {
                            outcomeMessage =
                                'Открытый Registry block изменён '
                                'в новой revision.';
                          } else {
                            outcomeMessage = null;
                          }

                          if (outcomeMessage == null) {
                            return;
                          }

                          scaffoldMessenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(outcomeMessage)),
                            );
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          RegistryExplorerLoaded loaded => SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Material(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Registry Studio',
                                    key: const ValueKey<String>(
                                      'registry-explorer-title',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                Badge(
                                  isLabelVisible:
                                      loaded.problems.isNotEmpty ||
                                      widget.analysisProblemEntries.isNotEmpty,
                                  label: Text(
                                    '${loaded.problems.length + widget.analysisProblemEntries.length}',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  child: IconButton(
                                    key: const ValueKey<String>(
                                      'registry-status-center-button',
                                    ),
                                    tooltip:
                                        'Состояние Registry: '
                                        '${loaded.problems.length + widget.analysisProblemEntries.length} проблем',
                                    onPressed: () async {
                                      await _showRegistryStatusCenter(loaded);
                                    },
                                    color:
                                        loaded.problems.isEmpty &&
                                            widget
                                                .analysisProblemEntries
                                                .isEmpty
                                        ? null
                                        : Theme.of(context).colorScheme.error,
                                    icon: const Icon(Icons.fact_check_outlined),
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey<String>(
                                    'registry-studio-reset',
                                  ),
                                  tooltip: 'Сбросить контекст Registry Studio',
                                  onPressed: _resetRegistryStudio,
                                  icon: const Icon(Icons.layers_clear_outlined),
                                ),
                                IconButton(
                                  key: const ValueKey<String>(
                                    'registry-refresh-button',
                                  ),
                                  tooltip:
                                      loaded.selectedProblem == null &&
                                          loaded.openRegistryNode != null
                                      ? null
                                      : 'Перезагрузить Registry',
                                  onPressed: _refreshRegistry,
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Проект: ${loaded.snapshot.projectId}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text('Узлов: ${loaded.index.nodes.length}'),
                            Text(
                              'Revision: '
                              '${loaded.snapshot.sourceRevision}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: TextFormField(
                        key: const ValueKey<String>('registry-search-field'),
                        controller: _searchTextController(loaded.searchQuery),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Поиск по всему Registry',
                          hintText:
                              'Заголовки, пути, identity, типы, содержимое и source evidence',
                          prefixIcon: const Icon(Icons.search),
                          suffixText: loaded.searchQuery.trim().isEmpty
                              ? null
                              : 'Найдено: '
                                    '${loaded.searchResults.length}',
                          helperText: _registryFilterHelperText(loaded),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Badge(
                                isLabelVisible:
                                    loaded.registryViewFilter != 'all' ||
                                    loaded.canonicalStatusFilter != 'all',
                                child: IconButton(
                                  key: const ValueKey<String>(
                                    'registry-view-filter-button',
                                  ),
                                  tooltip: switch ((
                                    loaded.registryViewFilter == 'all',
                                    loaded.canonicalStatusFilter == 'all',
                                  )) {
                                    (true, true) =>
                                      'Фильтр отображения Registry',
                                    (false, true) =>
                                      'Фильтр: '
                                          '${_registryViewFilterLabel(loaded.registryViewFilter)}',
                                    (true, false) =>
                                      'Canonical: '
                                          '${_canonicalStatusFilterLabel(loaded.canonicalStatusFilter)}',
                                    (false, false) =>
                                      'Фильтры: '
                                          '${_registryViewFilterLabel(loaded.registryViewFilter)} · '
                                          'Canonical: '
                                          '${_canonicalStatusFilterLabel(loaded.canonicalStatusFilter)}',
                                  },
                                  color:
                                      loaded.registryViewFilter == 'all' &&
                                          loaded.canonicalStatusFilter == 'all'
                                      ? null
                                      : Theme.of(context).colorScheme.primary,
                                  onPressed: () async {
                                    await _showRegistryViewFilter(loaded);
                                  },
                                  icon: const Icon(Icons.filter_alt_outlined),
                                ),
                              ),
                              if (loaded.searchQuery.isNotEmpty)
                                IconButton(
                                  key: const ValueKey<String>(
                                    'registry-search-clear',
                                  ),
                                  tooltip: 'Очистить поиск Registry',
                                  onPressed: () async {
                                    await _clearSearch();
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                            ],
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 48,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: _updateSearchQuery,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        key: const ValueKey<String>('registry-node-list'),
                        controller: _scrollController,
                        itemCount: _showProblemQueueFullScreen
                            ? loaded.problems.length +
                                  widget.analysisProblemEntries.length +
                                  1
                            : _visibleRegistryNodes(loaded).length +
                                  1 +
                                  (_showProblemQueue
                                      ? loaded.problems.length +
                                            widget.analysisProblemEntries.length
                                      : 0) +
                                  (loaded.selectedProblem == null ? 0 : 1),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int itemIndex) {
                          final List<RegistryStructuralProblem> problems =
                              loaded.problems;

                          final List<RegistryProblemQueueEntry>
                          analysisProblems = widget.analysisProblemEntries;

                          final int totalProblemCount =
                              problems.length + analysisProblems.length;

                          final RegistryStructuralProblem? selectedProblem =
                              loaded.selectedProblem;

                          final List<RegistryNode> visibleRegistryNodes =
                              _visibleRegistryNodes(loaded);

                          final bool showProblemRows =
                              _showProblemQueue || _showProblemQueueFullScreen;

                          final int problemRowsStartIndex =
                              _showProblemQueueFullScreen ? 1 : 0;

                          final int problemRowsEndIndex =
                              problemRowsStartIndex +
                              (showProblemRows ? totalProblemCount : 0);

                          final int selectedProblemItemIndex =
                              problemRowsEndIndex;
                          final int fullRegistryHeaderIndex =
                              selectedProblemItemIndex +
                              (selectedProblem == null ? 0 : 1);

                          if (_showProblemQueueFullScreen && itemIndex == 0) {
                            return Material(
                              key: const ValueKey<String>(
                                'registry-problem-queue-fullscreen',
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.adjust,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Очередь проблем: '
                                            '$totalProblemCount',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Структурных: '
                                            '${problems.length} · '
                                            'Аналитических: '
                                            '${analysisProblems.length}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: const ValueKey<String>(
                                        'registry-problem-queue-fullscreen-close',
                                      ),
                                      tooltip:
                                          'Закрыть полноэкранную '
                                          'очередь проблем',
                                      onPressed: () {
                                        setState(() {
                                          _showProblemQueueFullScreen = false;
                                        });

                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (!mounted ||
                                                  !_scrollController
                                                      .hasClients) {
                                                return;
                                              }

                                              _scrollController.jumpTo(0);
                                            });
                                      },
                                      icon: const Icon(Icons.close_fullscreen),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (itemIndex >= problemRowsStartIndex &&
                              itemIndex < problemRowsEndIndex) {
                            final int problemIndex =
                                itemIndex - problemRowsStartIndex;

                            if (problemIndex >= problems.length) {
                              final int analysisProblemIndex =
                                  problemIndex - problems.length;

                              final RegistryProblemQueueEntry entry =
                                  analysisProblems[analysisProblemIndex];

                              final evidence = entry.sourceEvidence.first;

                              final Color entryColor = switch (entry.severity) {
                                RegistryProblemQueueEntrySeverity
                                    .informational =>
                                  Theme.of(context).colorScheme.outline,
                                RegistryProblemQueueEntrySeverity
                                    .reviewRequired =>
                                  Theme.of(context).colorScheme.tertiary,
                                RegistryProblemQueueEntrySeverity.blocking =>
                                  Theme.of(context).colorScheme.error,
                              };

                              final IconData entryIcon = switch (entry
                                  .severity) {
                                RegistryProblemQueueEntrySeverity
                                    .informational =>
                                  Icons.info_outline,
                                RegistryProblemQueueEntrySeverity
                                    .reviewRequired =>
                                  Icons.rate_review_outlined,
                                RegistryProblemQueueEntrySeverity.blocking =>
                                  Icons.error_outline,
                              };

                              return InkWell(
                                key: ValueKey<String>(
                                  'registry-analysis-problem-'
                                  '${entry.identity}',
                                ),
                                onTap: () async {
                                  await _selectAnalysisProblemEntry(entry);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Icon(entryIcon, color: entryColor),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              '${entry.typeLabel} · '
                                              '${entry.path.segments.last}',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Статус: '
                                              '${entry.statusLabel}',
                                            ),
                                            Text(
                                              'RegistryPath: '
                                              '${entry.path.segments.join(' → ')}',
                                            ),
                                            Text(
                                              'Причина: '
                                              '${entry.reason}',
                                            ),
                                            Text(
                                              'Evidence: '
                                              '${evidence.sourceDocumentPath}, '
                                              'строки '
                                              '${evidence.startLine}–'
                                              '${evidence.endLine}',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final RegistryStructuralProblem problem =
                                problems[problemIndex];

                            final evidence =
                                problem.exactNode.sourceEvidence.first;

                            return InkWell(
                              key: ValueKey<String>(
                                'registry-problem-'
                                '$problemIndex-'
                                '${problem.exactNode.id.value}',
                              ),
                              onTap: () async {
                                await _selectProblem(problemIndex);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.adjust,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Затронуто · '
                                            '${problem.path.segments.last}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RegistryPath: '
                                            '${problem.path.segments.join(' → ')}',
                                          ),
                                          Text(
                                            'Причина: '
                                            '${problem.reason}',
                                          ),
                                          Text(
                                            'Baseline revision: '
                                            '${problem.baselineRevision}',
                                          ),
                                          Text(
                                            'Current revision: '
                                            '${problem.currentRevision}',
                                          ),
                                          Text(
                                            'Evidence: '
                                            '${evidence.sourceDocumentPath}, '
                                            'строки ${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          if (!_showProblemQueueFullScreen &&
                              selectedProblem != null &&
                              itemIndex == selectedProblemItemIndex) {
                            final int selectedIndex =
                                loaded.selectedProblemIndex!;

                            final String statusLabel =
                                switch (selectedProblem.status) {
                                  RegistryStructuralProblemStatus.affected =>
                                    'Статус: затронуто',
                                };

                            return KeyedSubtree(
                              key: const ValueKey<String>(
                                'registry-selected-problem',
                              ),
                              child: Card(
                                key: _selectedProblemKey,
                                margin: const EdgeInsets.all(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Icon(
                                            Icons.adjust,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              statusLabel,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Проблемное место '
                                        '${selectedIndex + 1} из '
                                        '${problems.length}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'RegistryPath: '
                                        '${selectedProblem.path.segments.join(' → ')}',
                                      ),
                                      Text(
                                        'Причина: '
                                        '${selectedProblem.reason}',
                                      ),
                                      Text(
                                        'Baseline revision: '
                                        '${selectedProblem.baselineRevision}',
                                      ),
                                      Text(
                                        'Current revision: '
                                        '${selectedProblem.currentRevision}',
                                      ),
                                      if (selectedProblem.change.previousNode !=
                                          null) ...<Widget>[
                                        const Divider(height: 24),
                                        const Text('Baseline Registry block'),
                                        Text(
                                          'RegistryPath: '
                                          '${selectedProblem.change.previousNode!.path.segments.join(' → ')}',
                                        ),
                                        for (final evidence
                                            in selectedProblem.baselineEvidence)
                                          Text(
                                            'Evidence: '
                                            '${evidence.sourceDocumentPath}, '
                                            'строки ${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          selectedProblem
                                              .change
                                              .previousNode!
                                              .content,
                                        ),
                                      ],
                                      if (selectedProblem.change.currentNode !=
                                          null) ...<Widget>[
                                        const Divider(height: 24),
                                        const Text('Current Registry block'),
                                        Text(
                                          'RegistryPath: '
                                          '${selectedProblem.change.currentNode!.path.segments.join(' → ')}',
                                        ),
                                        for (final evidence
                                            in selectedProblem.currentEvidence)
                                          Text(
                                            'Evidence: '
                                            '${evidence.sourceDocumentPath}, '
                                            'строки ${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          selectedProblem
                                              .change
                                              .currentNode!
                                              .content,
                                        ),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        children: <Widget>[
                                          IconButton(
                                            tooltip: 'Предыдущая проблема',
                                            onPressed: selectedIndex == 0
                                                ? null
                                                : () async {
                                                    await _selectProblem(
                                                      selectedIndex - 1,
                                                    );
                                                  },
                                            icon: const Icon(
                                              Icons.navigate_before,
                                            ),
                                          ),
                                          Text(
                                            '${selectedIndex + 1}/'
                                            '${problems.length}',
                                          ),
                                          IconButton(
                                            tooltip: 'Следующая проблема',
                                            onPressed:
                                                selectedIndex ==
                                                    problems.length - 1
                                                ? null
                                                : () async {
                                                    await _selectProblem(
                                                      selectedIndex + 1,
                                                    );
                                                  },
                                            icon: const Icon(
                                              Icons.navigate_next,
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () async {
                                              await _selectProblem(null);
                                            },
                                            child: const Text('Закрыть'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          if (itemIndex == fullRegistryHeaderIndex) {
                            final bool searchActive = loaded.searchQuery
                                .trim()
                                .isNotEmpty;

                            final RegistryNode? branchScopeRoot =
                                _registryBranchScopeRoot(loaded);

                            final IconData structuralHeaderIcon =
                                switch (loaded.registryViewFilter) {
                                  'roots' => Icons.home_work_outlined,
                                  'branches' => Icons.folder_outlined,
                                  'leaves' => Icons.description_outlined,
                                  _ => Icons.account_tree_outlined,
                                };

                            final String structuralHeaderTitle =
                                switch (loaded.registryViewFilter) {
                                  'roots' =>
                                    'Корневые узлы Registry · '
                                        '${visibleRegistryNodes.length}',
                                  'branches' =>
                                    'Ветки Registry · '
                                        '${visibleRegistryNodes.length}',
                                  'leaves' =>
                                    'Конечные блоки Registry · '
                                        '${visibleRegistryNodes.length}',
                                  _ =>
                                    'Все узлы Registry · '
                                        '${loaded.index.nodes.length}',
                                };

                            return ListTile(
                              key: const ValueKey<String>(
                                'full-registry-header',
                              ),
                              leading: branchScopeRoot != null && !searchActive
                                  ? IconButton(
                                      key: const ValueKey<String>(
                                        'registry-branch-scope-back',
                                      ),
                                      tooltip: 'Вернуться к предыдущему уровню',
                                      onPressed: _closeRegistryBranchScope,
                                      icon: const Icon(Icons.arrow_back),
                                    )
                                  : Icon(
                                      searchActive
                                          ? Icons.manage_search
                                          : structuralHeaderIcon,
                                    ),
                              title: Text(
                                searchActive
                                    ? 'Результаты поиска · '
                                          '${loaded.searchResults.length} '
                                          'из ${loaded.index.nodes.length}'
                                    : branchScopeRoot != null
                                    ? 'Раздел: '
                                          '${branchScopeRoot.path.segments.last}'
                                    : structuralHeaderTitle,
                              ),
                              subtitle: branchScopeRoot == null || searchActive
                                  ? null
                                  : Text(
                                      branchScopeRoot.path.segments.join(' → '),
                                    ),
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              minVerticalPadding: 0,
                            );
                          }
                          final int nodeIndex =
                              itemIndex - fullRegistryHeaderIndex - 1;

                          final RegistryNode node =
                              visibleRegistryNodes[nodeIndex];

                          final evidence = node.sourceEvidence.first;

                          final bool searchActive = loaded.searchQuery
                              .trim()
                              .isNotEmpty;

                          final MapEntry<String, String>? searchMatch =
                              searchActive
                              ? _registrySearchMatch(node, loaded.searchQuery)
                              : null;

                          final Map<String, RegistryAnalysisStatusEntry>
                          nodeAnalysisStatusEntriesByIdentity =
                              <String, RegistryAnalysisStatusEntry>{};

                          final List<String> nodePath = node.path.segments;

                          for (final RegistryAnalysisStatusEntry entry
                              in widget.analysisStatusEntries) {
                            if (loaded.canonicalStatusFilter != 'all' &&
                                entry.statusId !=
                                    loaded.canonicalStatusFilter) {
                              continue;
                            }

                            final RegistryNode? entryNode =
                                loaded.index.nodesById[entry.nodeId];

                            if (entryNode == null) {
                              continue;
                            }

                            final List<String> entryNodePath =
                                entryNode.path.segments;

                            if (entryNodePath.length < nodePath.length) {
                              continue;
                            }

                            bool insideNodeSubtree = true;

                            for (
                              int index = 0;
                              index < nodePath.length;
                              index += 1
                            ) {
                              if (entryNodePath[index] != nodePath[index]) {
                                insideNodeSubtree = false;
                                break;
                              }
                            }

                            if (!insideNodeSubtree) {
                              continue;
                            }

                            nodeAnalysisStatusEntriesByIdentity.putIfAbsent(
                              entry.identity,
                              () => entry,
                            );
                          }

                          final List<RegistryAnalysisStatusEntry>
                          nodeAnalysisStatusEntries =
                              nodeAnalysisStatusEntriesByIdentity.values
                                  .toList()
                                ..sort((
                                  RegistryAnalysisStatusEntry first,
                                  RegistryAnalysisStatusEntry second,
                                ) {
                                  final int lineComparison = first
                                      .directContentLine
                                      .compareTo(second.directContentLine);

                                  if (lineComparison != 0) {
                                    return lineComparison;
                                  }

                                  return first.identity.compareTo(
                                    second.identity,
                                  );
                                });

                          final Set<String> nodeCanonicalStatusLabels =
                              nodeAnalysisStatusEntries
                                  .map(
                                    (RegistryAnalysisStatusEntry entry) =>
                                        entry.statusLabel,
                                  )
                                  .toSet();

                          final String? nodeCanonicalSummary =
                              nodeAnalysisStatusEntries.isEmpty
                              ? null
                              : 'Canonical: '
                                    '${nodeCanonicalStatusLabels.join(', ')} · '
                                    'формулировок: '
                                    '${nodeAnalysisStatusEntries.length}';

                          final RegistryNode? branchScopeRoot =
                              _registryBranchScopeRoot(loaded);

                          final bool branchEntryList =
                              loaded.registryViewFilter == 'branches' &&
                              branchScopeRoot == null &&
                              !searchActive;

                          final bool containerEntryAvailable =
                              node.children.isNotEmpty &&
                              !searchActive &&
                              node.id != branchScopeRoot?.id;

                          final int absoluteDepth =
                              node.path.segments.length - 1;

                          final int depth = searchActive || branchEntryList
                              ? 0
                              : branchScopeRoot == null
                              ? absoluteDepth
                              : absoluteDepth -
                                    (branchScopeRoot.path.segments.length - 1);

                          final bool rootNode =
                              !searchActive && !branchEntryList && depth == 0;

                          final bool expandable = _hasVisibleRegistryChildren(
                            node,
                            registryViewFilter: loaded.registryViewFilter,
                            canonicalStatusFilter: loaded.canonicalStatusFilter,
                            searchActive: searchActive,
                            branchScopeActive: branchScopeRoot != null,
                          );

                          final bool expanded =
                              rootNode ||
                              _expandedRegistryNodeIds.contains(node.id);

                          final ColorScheme colorScheme = Theme.of(
                            context,
                          ).colorScheme;

                          final int visibleDepth = depth > 6 ? 6 : depth;

                          final Color treeLevelColor = switch (depth % 4) {
                            0 => colorScheme.surfaceContainerLowest,
                            1 => colorScheme.primaryContainer.withValues(
                              alpha: 0.34,
                            ),
                            2 => colorScheme.secondaryContainer.withValues(
                              alpha: 0.36,
                            ),
                            _ => colorScheme.tertiaryContainer.withValues(
                              alpha: 0.36,
                            ),
                          };

                          final Color treeLevelAccent = switch (depth % 4) {
                            0 => colorScheme.outlineVariant,
                            1 => colorScheme.primary,
                            2 => colorScheme.secondary,
                            _ => colorScheme.tertiary,
                          };

                          return Container(
                            key: ValueKey<String>(
                              'registry-tree-row-${node.id.value}',
                            ),
                            decoration: BoxDecoration(
                              color: searchActive
                                  ? colorScheme.surface
                                  : treeLevelColor,
                              border: Border(
                                left: BorderSide(
                                  width: depth == 0 ? 0 : 4,
                                  color: searchActive
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.48,
                                        )
                                      : treeLevelAccent.withValues(alpha: 0.58),
                                ),
                              ),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                key: ValueKey<String>(node.id.value),
                                contentPadding: EdgeInsets.only(
                                  left: 12 + visibleDepth * 24,
                                  right: 8,
                                ),
                                leading: SizedBox(
                                  width: 40,
                                  child:
                                      expandable && !rootNode && !searchActive
                                      ? IconButton(
                                          key: ValueKey<String>(
                                            'registry-tree-toggle-'
                                            '${node.id.value}',
                                          ),
                                          tooltip: expanded
                                              ? 'Свернуть '
                                                    '${node.path.segments.last}'
                                              : 'Раскрыть '
                                                    '${node.path.segments.last}',
                                          onPressed: () {
                                            setState(() {
                                              if (expanded) {
                                                final List<RegistryNode>
                                                remainingNodes = <RegistryNode>[
                                                  node,
                                                ];

                                                while (remainingNodes
                                                    .isNotEmpty) {
                                                  final RegistryNode
                                                  collapsedNode = remainingNodes
                                                      .removeLast();

                                                  _expandedRegistryNodeIds
                                                      .remove(collapsedNode.id);

                                                  remainingNodes.addAll(
                                                    collapsedNode.children,
                                                  );
                                                }

                                                return;
                                              }

                                              final List<RegistryNode>
                                              siblingSubtrees =
                                                  <RegistryNode>[];

                                              for (final RegistryNode candidate
                                                  in loaded.index.nodes) {
                                                if (candidate.id == node.id ||
                                                    candidate
                                                            .path
                                                            .segments
                                                            .length !=
                                                        node
                                                            .path
                                                            .segments
                                                            .length) {
                                                  continue;
                                                }

                                                bool sameParent = true;

                                                for (
                                                  int segmentIndex = 0;
                                                  segmentIndex <
                                                      node
                                                              .path
                                                              .segments
                                                              .length -
                                                          1;
                                                  segmentIndex += 1
                                                ) {
                                                  if (candidate
                                                          .path
                                                          .segments[segmentIndex] !=
                                                      node
                                                          .path
                                                          .segments[segmentIndex]) {
                                                    sameParent = false;
                                                    break;
                                                  }
                                                }

                                                if (sameParent) {
                                                  siblingSubtrees.add(
                                                    candidate,
                                                  );
                                                }
                                              }

                                              final List<RegistryNode>
                                              remainingSiblingNodes =
                                                  <RegistryNode>[
                                                    ...siblingSubtrees,
                                                  ];

                                              while (remainingSiblingNodes
                                                  .isNotEmpty) {
                                                final RegistryNode siblingNode =
                                                    remainingSiblingNodes
                                                        .removeLast();

                                                _expandedRegistryNodeIds.remove(
                                                  siblingNode.id,
                                                );

                                                remainingSiblingNodes.addAll(
                                                  siblingNode.children,
                                                );
                                              }

                                              _expandedRegistryNodeIds.add(
                                                node.id,
                                              );
                                            });
                                          },
                                          icon: Icon(
                                            expanded
                                                ? Icons.folder_open_outlined
                                                : Icons.folder_outlined,
                                          ),
                                        )
                                      : Icon(
                                          rootNode && branchScopeRoot != null
                                              ? Icons.folder_open_outlined
                                              : node.path.segments.length == 1
                                              ? Icons.home_work_outlined
                                              : node.children.isNotEmpty
                                              ? Icons.folder_outlined
                                              : Icons.description_outlined,
                                        ),
                                ),
                                title: searchActive
                                    ? _highlightRegistrySearchText(
                                        context,
                                        node.path.segments.last,
                                        loaded.searchQuery,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      )
                                    : Text(
                                        node.path.segments.last,
                                        style: TextStyle(
                                          fontWeight: expandable
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                subtitle: searchActive
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          _highlightRegistrySearchText(
                                            context,
                                            node.path.segments.join(' → '),
                                            loaded.searchQuery,
                                          ),
                                          if (nodeCanonicalSummary !=
                                              null) ...<Widget>[
                                            const SizedBox(height: 4),
                                            Text(
                                              nodeCanonicalSummary,
                                              key: ValueKey<String>(
                                                'registry-node-canonical-summary-'
                                                '${node.id.value}',
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          if (searchMatch != null) ...<Widget>[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Совпадение в '
                                              '${searchMatch.key}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            _highlightRegistrySearchText(
                                              context,
                                              searchMatch.value,
                                              loaded.searchQuery,
                                              key: ValueKey<String>(
                                                'registry-search-highlight-'
                                                '${node.id.value}',
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            'Уровень: '
                                            '${node.path.segments.length} · '
                                            'Дочерних узлов: '
                                            '${node.children.length}',
                                          ),
                                          Text(
                                            'Строки '
                                            '${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                        ],
                                      )
                                    : nodeCanonicalSummary == null
                                    ? Text(
                                        '${node.path.segments.join(' → ')}\n'
                                        'Уровень: '
                                        '${node.path.segments.length} · '
                                        'Дочерних узлов: '
                                        '${node.children.length}\n'
                                        'Строки '
                                        '${evidence.startLine}–'
                                        '${evidence.endLine}',
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            '${node.path.segments.join(' → ')}\n'
                                            'Уровень: '
                                            '${node.path.segments.length} · '
                                            'Дочерних узлов: '
                                            '${node.children.length}\n'
                                            'Строки '
                                            '${evidence.startLine}–'
                                            '${evidence.endLine}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            nodeCanonicalSummary,
                                            key: ValueKey<String>(
                                              'registry-node-canonical-summary-'
                                              '${node.id.value}',
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                trailing: containerEntryAvailable
                                    ? IconButton(
                                        key: ValueKey<String>(
                                          'registry-branch-open-${node.id.value}',
                                        ),
                                        tooltip:
                                            'Открыть раздел '
                                            '${node.path.segments.last}',
                                        onPressed: () {
                                          _openRegistryBranchScope(node);
                                        },
                                        icon: const Icon(Icons.arrow_forward),
                                      )
                                    : null,
                                isThreeLine: true,
                                selected: loaded.openRegistryNodeId == node.id,
                                onTap: () async {
                                  if (containerEntryAvailable) {
                                    _openRegistryBranchScope(node);
                                    return;
                                  }

                                  await _selectRegistryNode(node.id);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (loaded.selectedProblem == null &&
                    loaded.openRegistryNode != null &&
                    !_showProblemQueueFullScreen)
                  Positioned.fill(
                    child: _buildSelectedRegistryBlockScreen(
                      context,
                      loaded,
                      loaded.openRegistryNode!,
                    ),
                  ),
                if (_showScrollToTop &&
                    (loaded.selectedProblem != null ||
                        loaded.openRegistryNode == null))
                  Positioned(
                    right: 8,
                    bottom: 4,
                    child: IconButton(
                      tooltip: 'Наверх',
                      iconSize: 32,
                      onPressed: _scrollToTop,
                      icon: Icon(
                        Icons.arrow_upward,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        };
      },
    );
  }
}
