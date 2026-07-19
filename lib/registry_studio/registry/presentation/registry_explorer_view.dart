import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_structural_problem.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
import '../application/contracts/registry_snapshot_revision_loader.dart';
import '../domain/entities/registry_node.dart';
import '../domain/value_objects/registry_node_id.dart';
import 'registry_explorer_cubit.dart';

final class RegistryExplorerView extends StatelessWidget {
  const RegistryExplorerView({
    required this.snapshotLoader,
    required this.snapshotRevisionLoader,
    required this.revisionStateStore,
    required this.snapshotComparator,
    super.key,
  });

  final RegistrySnapshotLoader snapshotLoader;
  final RegistrySnapshotRevisionLoader snapshotRevisionLoader;
  final RegistryRevisionStateStore revisionStateStore;
  final RegistrySnapshotComparator snapshotComparator;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryExplorerCubit>(
      create: (_) => RegistryExplorerCubit(
        snapshotLoader: snapshotLoader,
        snapshotRevisionLoader: snapshotRevisionLoader,
        revisionStateStore: revisionStateStore,
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
  final GlobalKey _selectedProblemKey = GlobalKey();
  final GlobalKey _selectedRegistryBlockKey = GlobalKey();

  bool _showScrollToTop = false;
  bool _showProblemQueue = false;
  bool _showProblemQueueFullScreen = false;

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

  @override
  void dispose() {
    _scrollController
      ..removeListener(_updateScrollToTopVisibility)
      ..dispose();

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
                              tooltip: 'Перезагрузить Registry',
                              onPressed: () async {
                                final RegistryExplorerCubit cubit = context
                                    .read<RegistryExplorerCubit>();

                                final ScaffoldMessengerState scaffoldMessenger =
                                    ScaffoldMessenger.of(context);

                                final RegistryExplorerState stateBeforeRefresh =
                                    cubit.state;

                                final RegistryNode?
                                openRegistryNodeBeforeRefresh =
                                    stateBeforeRefresh is RegistryExplorerLoaded
                                    ? stateBeforeRefresh.openRegistryNode
                                    : null;

                                await cubit.refresh();

                                if (!mounted ||
                                    openRegistryNodeBeforeRefresh == null) {
                                  return;
                                }

                                final RegistryExplorerState stateAfterRefresh =
                                    cubit.state;

                                if (stateAfterRefresh
                                    is! RegistryExplorerLoaded) {
                                  return;
                                }

                                final RegistryNode?
                                openRegistryNodeAfterRefresh =
                                    stateAfterRefresh.openRegistryNode;

                                final bool moved =
                                    openRegistryNodeAfterRefresh != null &&
                                    openRegistryNodeAfterRefresh.id ==
                                        openRegistryNodeBeforeRefresh.id &&
                                    openRegistryNodeAfterRefresh.path !=
                                        openRegistryNodeBeforeRefresh.path;

                                final bool changed =
                                    openRegistryNodeAfterRefresh != null &&
                                    openRegistryNodeAfterRefresh.id ==
                                        openRegistryNodeBeforeRefresh.id &&
                                    (openRegistryNodeAfterRefresh.kindId !=
                                            openRegistryNodeBeforeRefresh
                                                .kindId ||
                                        openRegistryNodeAfterRefresh.content !=
                                            openRegistryNodeBeforeRefresh
                                                .content ||
                                        openRegistryNodeAfterRefresh
                                                .businessScopeOwnerId !=
                                            openRegistryNodeBeforeRefresh
                                                .businessScopeOwnerId);

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
                                  ..showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                              },
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
                        initialValue: loaded.searchQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Поиск по Registry',
                          hintText:
                              'Identity, path, kind, content или source evidence',
                          prefixIcon: const Icon(Icons.search),
                          suffixText:
                              '${loaded.searchResults.length}/'
                              '${loaded.index.nodes.length}',
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
                            ? loaded.problems.length + 1
                            : loaded.searchResults.length +
                                  4 +
                                  (_showProblemQueue
                                      ? loaded.problems.length
                                      : 0) +
                                  (loaded.selectedProblem == null &&
                                          loaded.openRegistryNode == null
                                      ? 0
                                      : 1),
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int itemIndex) {
                          final List<RegistryStructuralProblem> problems =
                              loaded.problems;

                          final RegistryStructuralProblem? selectedProblem =
                              loaded.selectedProblem;

                          final RegistryNode? openRegistryNode =
                              loaded.openRegistryNode;

                          final String baselineLabel =
                              loaded.cleanBaselineComparison != null
                              ? 'clean baseline'
                              : 'предыдущая revision';

                          final bool showProblemRows =
                              _showProblemQueue || _showProblemQueueFullScreen;

                          final int problemRowsStartIndex =
                              _showProblemQueueFullScreen ? 1 : 3;

                          final int problemRowsEndIndex =
                              problemRowsStartIndex +
                              (showProblemRows ? problems.length : 0);

                          final int selectedProblemItemIndex =
                              problemRowsEndIndex;

                          final int fullRegistryHeaderIndex =
                              selectedProblemItemIndex +
                              (selectedProblem == null &&
                                      openRegistryNode == null
                                  ? 0
                                  : 1);

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

                          if (!_showProblemQueueFullScreen && itemIndex == 2) {
                            return ListTile(
                              key: const ValueKey<String>(
                                'registry-problem-queue',
                              ),
                              leading: Icon(
                                problems.isEmpty
                                    ? Icons.inbox_outlined
                                    : Icons.adjust,
                                color: problems.isEmpty
                                    ? null
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                'Очередь проблем: '
                                '${problems.length}',
                              ),
                              subtitle: loaded.problemComparison == null
                                  ? const Text(
                                      'Baseline сравнения '
                                      'отсутствует.',
                                    )
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
                                              'Открыть очередь '
                                              'проблем на весь экран',
                                          onPressed: () {
                                            setState(() {
                                              _showProblemQueue = false;
                                              _showProblemQueueFullScreen =
                                                  true;
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
                                          icon: const Icon(Icons.open_in_full),
                                        ),
                                        Icon(
                                          _showProblemQueue
                                              ? Icons.expand_less
                                              : Icons.expand_more,
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

                          if (!_showProblemQueueFullScreen &&
                              selectedProblem == null &&
                              openRegistryNode != null &&
                              itemIndex == selectedProblemItemIndex) {
                            return KeyedSubtree(
                              key: const ValueKey<String>(
                                'registry-selected-block',
                              ),
                              child: Card(
                                key: _selectedRegistryBlockKey,
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
                                            Icons.description_outlined,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Открытый Registry block',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'RegistryPath: '
                                        '${openRegistryNode.path.segments.join(' → ')}',
                                      ),
                                      Text(
                                        'Тип: '
                                        '${openRegistryNode.kindId}',
                                      ),
                                      for (final evidence
                                          in openRegistryNode.sourceEvidence)
                                        Text(
                                          'Evidence: '
                                          '${evidence.sourceDocumentPath}, '
                                          'строки ${evidence.startLine}–'
                                          '${evidence.endLine}',
                                        ),
                                      const Divider(height: 24),
                                      SelectableText(openRegistryNode.content),
                                      const Divider(height: 24),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () async {
                                            await _selectRegistryNode(null);
                                          },
                                          child: const Text('Закрыть'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          if (itemIndex == fullRegistryHeaderIndex) {
                            return const ListTile(
                              key: ValueKey<String>('full-registry-header'),
                              title: Text('Полный Registry'),
                              dense: true,
                            );
                          }

                          final int nodeIndex =
                              itemIndex - fullRegistryHeaderIndex - 1;

                          final RegistryNode node =
                              loaded.searchResults[nodeIndex];

                          final evidence = node.sourceEvidence.first;

                          return ListTile(
                            key: ValueKey<String>(node.id.value),
                            leading: Icon(
                              node.children.isEmpty
                                  ? Icons.description_outlined
                                  : Icons.account_tree_outlined,
                            ),
                            title: Text(node.path.segments.last),
                            subtitle: Text(
                              '${node.path.segments.join(' → ')}\n'
                              'Строки ${evidence.startLine}–'
                              '${evidence.endLine}',
                            ),
                            isThreeLine: true,
                            selected: loaded.openRegistryNodeId == node.id,
                            onTap: () async {
                              await _selectRegistryNode(node.id);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_showScrollToTop)
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
