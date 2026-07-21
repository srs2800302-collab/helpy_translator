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
import '../domain/value_objects/registry_node_id.dart';
import 'registry_explorer_cubit.dart';

final class RegistryExplorerView extends StatelessWidget {
  const RegistryExplorerView({
    required this.snapshotLoader,
    required this.snapshotRefreshLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.analysisHistoryStore,
    required this.snapshotComparator,
    super.key,
  });

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRefreshLoader snapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistryAnalysisHistoryStore analysisHistoryStore;
  final RegistrySnapshotComparator snapshotComparator;

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
      )..restore(),
      child: const _RegistryExplorerView(),
    );
  }
}

final class _RegistryExplorerView extends StatefulWidget {
  const _RegistryExplorerView();

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
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _selectedProblemKey = GlobalKey();
  final GlobalKey _selectedRegistryBlockKey = GlobalKey();

  bool _showScrollToTop = false;
  bool _searchControllerInitialized = false;
  bool _showProblemQueue = false;
  bool _showProblemQueueFullScreen = false;
  String _registryViewFilter = 'all';

  final Set<RegistryNodeId> _expandedRegistryNodeIds = <RegistryNodeId>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollToTopVisibility);
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
      _registryViewFilter = 'all';
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
  ) {
    final bool hasChanges =
        entry.previousAddedCount > 0 ||
        entry.previousRemovedCount > 0 ||
        entry.previousChangedCount > 0 ||
        entry.cleanBaselineAddedCount > 0 ||
        entry.cleanBaselineRemovedCount > 0 ||
        entry.cleanBaselineChangedCount > 0;

    if (hasChanges) {
      return 'Обнаружены изменения Registry';
    }

    if (entry.previousRevision == null && entry.cleanBaselineRevision == null) {
      return 'Первичная загрузка Registry';
    }

    if (entry.previousRevision == null && entry.cleanBaselineRevision != null) {
      return 'Проверка относительно clean baseline';
    }

    return 'Refresh без изменений';
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
                                    '${_registryAnalysisHistoryEventLabel(entry)}',
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
    final bool hasProblems = loaded.problems.isNotEmpty;

    final bool isCurrentCleanBaseline =
        loaded.cleanBaselineSnapshot?.sourceRevision ==
        loaded.snapshot.sourceRevision;

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
                            '${loaded.problems.length}',
                          ),
                          subtitle: loaded.problemComparison == null
                              ? const Text(
                                  'Baseline сравнения отсутствует. '
                                  'После появления baseline здесь будут '
                                  'показаны структурные расхождения.',
                                )
                              : hasProblems
                              ? const Text(
                                  'Обнаружены места, требующие проверки. '
                                  'Откройте список для перехода к каждому '
                                  'затронутому Registry block.',
                                )
                              : const Text(
                                  'Структурные проблемы относительно '
                                  'текущего baseline не обнаружены.',
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
                                      _showProblemQueue = true;
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
                          leading: Icon(
                            isCurrentCleanBaseline
                                ? Icons.verified_outlined
                                : Icons.verified_user_outlined,
                          ),
                          title: Text(
                            loaded.cleanBaselineSnapshot == null
                                ? 'Clean baseline: не подтверждён'
                                : 'Clean baseline: '
                                      '${loaded.cleanBaselineSnapshot!.sourceRevision}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: isCurrentCleanBaseline
                              ? const Text(
                                  'Текущая revision подтверждена инженером '
                                  'как чистое контрольное состояние.',
                                )
                              : const Text(
                                  'Clean baseline используется как '
                                  'подтверждённая контрольная точка и '
                                  'не меняется автоматически при refresh.',
                                ),
                          trailing: isCurrentCleanBaseline
                              ? null
                              : TextButton(
                                  key: const ValueKey<String>(
                                    'registry-status-center-confirm-baseline',
                                  ),
                                  onPressed: () async {
                                    Navigator.of(sheetContext).pop();

                                    await Future<void>.delayed(Duration.zero);

                                    if (!mounted) {
                                      return;
                                    }

                                    await _confirmCurrentAsCleanBaseline();
                                  },
                                  child: const Text('Подтвердить'),
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

  bool _matchesRegistryViewFilter(RegistryNode node) {
    switch (_registryViewFilter) {
      case 'roots':
        return node.path.segments.length == 1;
      case 'branches':
        return node.children.isNotEmpty;
      case 'leaves':
        return node.children.isEmpty;
      default:
        if (_registryViewFilter.startsWith('kind:')) {
          return node.kindId == _registryViewFilter.substring('kind:'.length);
        }

        return true;
    }
  }

  String _registryViewFilterLabel() {
    switch (_registryViewFilter) {
      case 'roots':
        return 'Корневые узлы';
      case 'branches':
        return 'Ветки';
      case 'leaves':
        return 'Конечные блоки';
      default:
        if (_registryViewFilter.startsWith('kind:')) {
          return 'Тип: '
              '${_registryViewFilter.substring('kind:'.length)}';
        }

        return 'Все узлы';
    }
  }

  Future<void> _showRegistryViewFilter(RegistryExplorerLoaded loaded) async {
    final List<RegistryNode> allNodes = _allRegistryNodes(
      loaded.snapshot.roots,
    );

    final Map<String, int> kindCounts = <String, int>{};

    for (final RegistryNode node in allNodes) {
      kindCounts.update(
        node.kindId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final List<String> kindIds = kindCounts.keys.toList()..sort();

    final int rootCount = allNodes
        .where((RegistryNode node) => node.path.segments.length == 1)
        .length;

    final int branchCount = allNodes
        .where((RegistryNode node) => node.children.isNotEmpty)
        .length;

    final int leafCount = allNodes
        .where((RegistryNode node) => node.children.isEmpty)
        .length;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        Widget option({
          required String keyValue,
          required String filter,
          required IconData icon,
          required String title,
          required int count,
        }) {
          final bool selected = _registryViewFilter == filter;

          return ListTile(
            key: ValueKey<String>(keyValue),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text('Узлов: $count'),
            selected: selected,
            trailing: selected ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(sheetContext).pop();

              if (!mounted) {
                return;
              }

              setState(() {
                _registryViewFilter = filter;
                _expandedRegistryNodeIds.clear();
              });

              if (_scrollController.hasClients) {
                _scrollController.jumpTo(0);
              }
            },
          );
        }

        return SafeArea(
          child: SizedBox(
            key: const ValueKey<String>('registry-view-filter-sheet'),
            height: MediaQuery.sizeOf(sheetContext).height * 0.72,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Фильтр отображения Registry',
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>(
                          'registry-view-filter-close',
                        ),
                        tooltip: 'Закрыть фильтр',
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
                    children: <Widget>[
                      option(
                        keyValue: 'registry-view-filter-all',
                        filter: 'all',
                        icon: Icons.view_list_outlined,
                        title: 'Все узлы',
                        count: allNodes.length,
                      ),
                      option(
                        keyValue: 'registry-view-filter-roots',
                        filter: 'roots',
                        icon: Icons.account_tree_outlined,
                        title: 'Корневые узлы',
                        count: rootCount,
                      ),
                      option(
                        keyValue: 'registry-view-filter-branches',
                        filter: 'branches',
                        icon: Icons.folder_outlined,
                        title: 'Ветки',
                        count: branchCount,
                      ),
                      option(
                        keyValue: 'registry-view-filter-leaves',
                        filter: 'leaves',
                        icon: Icons.description_outlined,
                        title: 'Конечные блоки',
                        count: leafCount,
                      ),
                      if (kindIds.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                          child: Text('Фактически обнаруженные типы'),
                        ),
                      for (final String kindId in kindIds)
                        option(
                          keyValue: 'registry-view-filter-kind-$kindId',
                          filter: 'kind:$kindId',
                          icon: Icons.category_outlined,
                          title: kindId,
                          count: kindCounts[kindId]!,
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

  List<RegistryNode> _visibleRegistryNodes(RegistryExplorerLoaded loaded) {
    final bool searchActive = loaded.searchQuery.trim().isNotEmpty;

    if (_registryViewFilter != 'all') {
      final List<RegistryNode> candidates = searchActive
          ? loaded.searchResults
          : _allRegistryNodes(loaded.snapshot.roots);

      return candidates
          .where(_matchesRegistryViewFilter)
          .toList(growable: false);
    }

    if (searchActive) {
      return loaded.searchResults;
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
                        Text(
                          node.path.segments.last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge,
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
                    icon: const Icon(Icons.restart_alt),
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
                            const Divider(height: 24),
                            if (searchQuery.isEmpty)
                              SelectableText(node.content)
                            else
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
                              ),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildCompactProblemQueue(
    BuildContext context,
    RegistryExplorerLoaded loaded,
  ) {
    final List<RegistryStructuralProblem> problems = loaded.problems;

    final String baselineLabel = loaded.cleanBaselineComparison != null
        ? 'clean baseline'
        : 'предыдущая revision';

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        key: const ValueKey<String>('registry-problem-queue'),
        leading: Icon(
          problems.isEmpty ? Icons.inbox_outlined : Icons.adjust,
          color: problems.isEmpty
              ? null
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text('Очередь проблем: ${problems.length}'),
        subtitle: loaded.problemComparison == null
            ? const Text('Baseline сравнения отсутствует.')
            : problems.isEmpty
            ? Text(
                'Затронутых мест относительно '
                '$baselineLabel не обнаружено.',
              )
            : Text(
                'Источник: $baselineLabel. '
                'Статус: затронуто.',
              ),
        trailing: problems.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    key: const ValueKey<String>(
                      'registry-problem-queue-fullscreen-button',
                    ),
                    tooltip:
                        'Открыть очередь проблем '
                        'на весь экран',
                    onPressed: () {
                      setState(() {
                        _showProblemQueue = false;
                        _showProblemQueueFullScreen = true;
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted || !_scrollController.hasClients) {
                          return;
                        }

                        _scrollController.jumpTo(0);
                      });
                    },
                    icon: const Icon(Icons.open_in_full),
                  ),
                  Icon(
                    _showProblemQueue ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
        onTap: problems.isEmpty
            ? null
            : () {
                setState(() {
                  _showProblemQueue = !_showProblemQueue;
                });
              },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollToTopVisibility)
      ..dispose();

    _searchController.dispose();

    _selectedRegistryBlockScrollController.dispose();

    super.dispose();
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
                        child: Row(
                          children: <Widget>[
                            Badge(
                              isLabelVisible: loaded.problems.isNotEmpty,
                              label: Text('${loaded.problems.length}'),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              child: IconButton(
                                key: const ValueKey<String>(
                                  'registry-status-center-button',
                                ),
                                tooltip:
                                    'Состояние Registry: '
                                    '${loaded.problems.length} проблем',
                                onPressed: () async {
                                  await _showRegistryStatusCenter(loaded);
                                },
                                color: loaded.problems.isEmpty
                                    ? null
                                    : Theme.of(context).colorScheme.error,
                                icon: const Icon(Icons.fact_check_outlined),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Проект: ${loaded.snapshot.projectId}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Узлов: ${loaded.index.nodes.length}'),
                                  Text(
                                    'Revision: '
                                    '${loaded.snapshot.sourceRevision}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (loaded.previousSnapshot != null)
                                    Text(
                                      'Предыдущая revision: '
                                      '${loaded.previousSnapshot!.sourceRevision}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (loaded.cleanBaselineSnapshot != null)
                                    Text(
                                      'Clean baseline: '
                                      '${loaded.cleanBaselineSnapshot!.sourceRevision}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),

                            IconButton(
                              key: const ValueKey<String>(
                                'registry-analysis-history-button',
                              ),
                              tooltip:
                                  'История анализа: '
                                  '${loaded.analysisHistory.length}',
                              onPressed: () async {
                                await _showRegistryAnalysisHistory(loaded);
                              },
                              icon: const Icon(Icons.history),
                            ),
                            IconButton(
                              key: const ValueKey<String>(
                                'registry-studio-reset',
                              ),
                              tooltip: 'Сбросить контекст Registry Studio',
                              onPressed: _resetRegistryStudio,
                              icon: const Icon(Icons.restart_alt),
                            ),
                            IconButton(
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
                          helperText: _registryViewFilter == 'all'
                              ? null
                              : loaded.searchQuery.trim().isEmpty
                              ? 'Фильтр: '
                                    '${_registryViewFilterLabel()} · '
                                    'показано: '
                                    '${_visibleRegistryNodes(loaded).length}'
                              : 'Фильтр: '
                                    '${_registryViewFilterLabel()} · '
                                    'показано: '
                                    '${_visibleRegistryNodes(loaded).length} '
                                    'из ${loaded.searchResults.length}',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Badge(
                                isLabelVisible: _registryViewFilter != 'all',
                                child: IconButton(
                                  key: const ValueKey<String>(
                                    'registry-view-filter-button',
                                  ),
                                  tooltip: _registryViewFilter == 'all'
                                      ? 'Фильтр отображения Registry'
                                      : 'Фильтр: '
                                            '${_registryViewFilterLabel()}',
                                  color: _registryViewFilter == 'all'
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
                    if (!_showProblemQueueFullScreen)
                      _buildCompactProblemQueue(context, loaded),
                    Expanded(
                      child: ListView.separated(
                        key: const ValueKey<String>('registry-node-list'),
                        controller: _scrollController,
                        itemCount: _showProblemQueueFullScreen
                            ? loaded.problems.length + 1
                            : _visibleRegistryNodes(loaded).length +
                                  3 +
                                  (_showProblemQueue
                                      ? loaded.problems.length
                                      : 0) +
                                  (loaded.selectedProblem == null ? 0 : 1),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int itemIndex) {
                          final List<RegistryStructuralProblem> problems =
                              loaded.problems;

                          final RegistryStructuralProblem? selectedProblem =
                              loaded.selectedProblem;

                          final List<RegistryNode> visibleRegistryNodes =
                              _visibleRegistryNodes(loaded);

                          final String baselineLabel =
                              loaded.cleanBaselineComparison != null
                              ? 'clean baseline'
                              : 'предыдущая revision';

                          final bool showProblemRows =
                              _showProblemQueue || _showProblemQueueFullScreen;

                          final int problemRowsStartIndex =
                              _showProblemQueueFullScreen ? 1 : 2;

                          final int problemRowsEndIndex =
                              problemRowsStartIndex +
                              (showProblemRows ? problems.length : 0);

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
                                            '${problems.length}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Источник: '
                                            '$baselineLabel. '
                                            'Статус: затронуто.',
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

                          if (!_showProblemQueueFullScreen && itemIndex == 0) {
                            return ListTile(
                              key: const ValueKey<String>(
                                'registry-previous-comparison-summary',
                              ),
                              title: Text(
                                loaded.previousComparison == null
                                    ? 'Изменения с предыдущей revision: '
                                          'нет baseline'
                                    : 'Изменения с предыдущей revision: '
                                          '${loaded.previousComparison!.changes.length}',
                              ),
                              subtitle: loaded.previousComparison == null
                                  ? const Text(
                                      'Предыдущая известная revision '
                                      'отсутствует.',
                                    )
                                  : Text(
                                      'Добавлено: '
                                      '${loaded.previousComparison!.addedCount} · '
                                      'Удалено: '
                                      '${loaded.previousComparison!.removedCount} · '
                                      'Изменено: '
                                      '${loaded.previousComparison!.changedCount}',
                                    ),
                            );
                          }

                          if (!_showProblemQueueFullScreen && itemIndex == 1) {
                            final bool isCurrentCleanBaseline =
                                loaded.cleanBaselineSnapshot?.sourceRevision ==
                                loaded.snapshot.sourceRevision;

                            return ListTile(
                              key: const ValueKey<String>(
                                'registry-clean-baseline-summary',
                              ),
                              title: Text(
                                loaded.cleanBaselineComparison == null
                                    ? 'Clean baseline: не подтверждён'
                                    : 'Расхождения с clean baseline: '
                                          '${loaded.cleanBaselineComparison!.changes.length}',
                              ),
                              subtitle: loaded.cleanBaselineComparison == null
                                  ? const Text(
                                      'Новая revision не принимается '
                                      'как clean baseline автоматически.',
                                    )
                                  : Text(
                                      'Baseline: '
                                      '${loaded.cleanBaselineSnapshot!.sourceRevision}\n'
                                      'Добавлено: '
                                      '${loaded.cleanBaselineComparison!.addedCount} · '
                                      'Удалено: '
                                      '${loaded.cleanBaselineComparison!.removedCount} · '
                                      'Изменено: '
                                      '${loaded.cleanBaselineComparison!.changedCount}',
                                    ),
                              trailing: IconButton(
                                tooltip: isCurrentCleanBaseline
                                    ? 'Текущая revision уже является '
                                          'clean baseline'
                                    : 'Подтвердить текущую revision '
                                          'как clean baseline',
                                onPressed: isCurrentCleanBaseline
                                    ? null
                                    : _confirmCurrentAsCleanBaseline,
                                icon: Icon(
                                  isCurrentCleanBaseline
                                      ? Icons.verified_outlined
                                      : Icons.verified_user_outlined,
                                ),
                              ),
                            );
                          }

                          if (itemIndex >= problemRowsStartIndex &&
                              itemIndex < problemRowsEndIndex) {
                            final int problemIndex =
                                itemIndex - problemRowsStartIndex;

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

                            return ListTile(
                              key: const ValueKey<String>(
                                'full-registry-header',
                              ),
                              leading: Icon(
                                searchActive
                                    ? Icons.manage_search
                                    : Icons.account_tree_outlined,
                              ),
                              title: Text(
                                searchActive
                                    ? 'Результаты поиска · '
                                          '${loaded.searchResults.length} '
                                          'из ${loaded.index.nodes.length}'
                                    : 'Дерево Registry',
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

                          final int depth = node.path.segments.length - 1;

                          final bool rootNode = depth == 0;

                          final bool expandable = node.children.isNotEmpty;

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
                                          expandable
                                              ? Icons.account_tree_outlined
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
                                    : Text(
                                        '${node.path.segments.join(' → ')}\n'
                                        'Уровень: '
                                        '${node.path.segments.length} · '
                                        'Дочерних узлов: '
                                        '${node.children.length}\n'
                                        'Строки '
                                        '${evidence.startLine}–'
                                        '${evidence.endLine}',
                                      ),
                                isThreeLine: true,
                                selected: loaded.openRegistryNodeId == node.id,
                                onTap: () async {
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
