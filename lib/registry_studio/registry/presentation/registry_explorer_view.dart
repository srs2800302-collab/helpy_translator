import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../maintenance/analysis/domain/entities/registry_node_change.dart';
import '../application/contracts/registry_revision_state_store.dart';
import '../application/contracts/registry_snapshot_loader.dart';
import '../application/contracts/registry_snapshot_revision_loader.dart';
import '../domain/entities/registry_node.dart';
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

  bool _showScrollToTop = false;

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
          RegistryExplorerFailure(:final String message) => SafeArea(
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
                      onPressed: context.read<RegistryExplorerCubit>().retry,
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
                              onPressed: context
                                  .read<RegistryExplorerCubit>()
                                  .refresh,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        itemCount:
                            (loaded.previousComparison?.changes.length ?? 0) +
                            (loaded.cleanBaselineComparison?.changes.length ??
                                0) +
                            loaded.index.nodes.length +
                            3,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int itemIndex) {
                          final List<RegistryNodeChange> previousChanges =
                              loaded.previousComparison?.changes ??
                              const <RegistryNodeChange>[];

                          final List<RegistryNodeChange> cleanChanges =
                              loaded.cleanBaselineComparison?.changes ??
                              const <RegistryNodeChange>[];

                          final int cleanSummaryIndex =
                              previousChanges.length + 1;

                          final int registryHeaderIndex =
                              cleanSummaryIndex + cleanChanges.length + 1;

                          if (itemIndex == 0) {
                            return ListTile(
                              key: const ValueKey<String>(
                                'registry-previous-comparison-summary',
                              ),
                              title: Text(
                                loaded.previousComparison == null
                                    ? 'Изменения с предыдущей revision: '
                                          'нет baseline'
                                    : 'Изменения с предыдущей revision: '
                                          '${previousChanges.length}',
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

                          if (itemIndex == cleanSummaryIndex) {
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
                                          '${cleanChanges.length}',
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

                          RegistryNodeChange? change;
                          String? comparisonKey;

                          if (itemIndex > 0 && itemIndex < cleanSummaryIndex) {
                            change = previousChanges[itemIndex - 1];
                            comparisonKey = 'previous';
                          } else if (itemIndex > cleanSummaryIndex &&
                              itemIndex < registryHeaderIndex) {
                            change =
                                cleanChanges[itemIndex - cleanSummaryIndex - 1];
                            comparisonKey = 'clean';
                          }

                          if (change != null) {
                            final RegistryNode node =
                                change.currentNode ?? change.previousNode!;

                            final evidence = node.sourceEvidence.first;

                            final List<String> details = <String>[
                              node.path.segments.join(' → '),
                            ];

                            switch (change.kind) {
                              case RegistryNodeChangeKind.added:
                                details.add('Причина: добавлен новый узел.');
                                break;
                              case RegistryNodeChangeKind.removed:
                                details.add('Причина: узел удалён.');
                                break;
                              case RegistryNodeChangeKind.changed:
                                details.add(
                                  'Изменено: '
                                  '${change.aspects.map((RegistryNodeChangeAspect aspect) {
                                    return switch (aspect) {
                                      RegistryNodeChangeAspect.kind => 'тип',
                                      RegistryNodeChangeAspect.path => 'путь',
                                      RegistryNodeChangeAspect.content => 'содержимое',
                                      RegistryNodeChangeAspect.businessScopeOwner => 'владелец бизнес-области',
                                    };
                                  }).join(', ')}',
                                );

                                if (change.aspects.contains(
                                  RegistryNodeChangeAspect.path,
                                )) {
                                  details
                                    ..add(
                                      'Было: '
                                      '${change.previousNode!.path.segments.join(' → ')}',
                                    )
                                    ..add(
                                      'Стало: '
                                      '${change.currentNode!.path.segments.join(' → ')}',
                                    );
                                }
                                break;
                            }

                            details.add(
                              'Строки ${evidence.startLine}–'
                              '${evidence.endLine}',
                            );

                            final String title = switch (change.kind) {
                              RegistryNodeChangeKind.added =>
                                'Добавлено: '
                                    '${node.path.segments.last}',
                              RegistryNodeChangeKind.removed =>
                                'Удалено: '
                                    '${node.path.segments.last}',
                              RegistryNodeChangeKind.changed =>
                                'Изменено: '
                                    '${node.path.segments.last}',
                            };

                            final IconData icon = switch (change.kind) {
                              RegistryNodeChangeKind.added =>
                                Icons.add_circle_outline,
                              RegistryNodeChangeKind.removed =>
                                Icons.remove_circle_outline,
                              RegistryNodeChangeKind.changed =>
                                Icons.edit_outlined,
                            };

                            return ListTile(
                              key: ValueKey<String>(
                                'registry-change-'
                                '$comparisonKey-'
                                '${change.kind.name}-'
                                '${node.id.value}',
                              ),
                              leading: Icon(icon),
                              title: Text(title),
                              subtitle: Text(details.join('\n')),
                              isThreeLine: true,
                              dense: true,
                            );
                          }

                          if (itemIndex == registryHeaderIndex) {
                            return const ListTile(
                              key: ValueKey<String>('full-registry-header'),
                              title: Text('Полный Registry'),
                              dense: true,
                            );
                          }

                          final int nodeIndex =
                              itemIndex - registryHeaderIndex - 1;

                          final RegistryNode node =
                              loaded.index.nodes[nodeIndex];

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
