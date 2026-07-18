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
                            (loaded.comparison?.changes.length ?? 0) +
                            loaded.index.nodes.length +
                            2,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int itemIndex) {
                          final List<RegistryNodeChange> changes =
                              loaded.comparison?.changes ??
                              const <RegistryNodeChange>[];

                          final int registryHeaderIndex = changes.length + 1;

                          if (itemIndex == 0) {
                            return ListTile(
                              key: const ValueKey<String>(
                                'registry-comparison-summary',
                              ),
                              title: Text(
                                loaded.comparison == null
                                    ? 'Изменения: нет предыдущей revision'
                                    : 'Изменения: ${changes.length}',
                              ),
                              subtitle: loaded.comparison == null
                                  ? const Text(
                                      'Предыдущая известная revision '
                                      'отсутствует.',
                                    )
                                  : Text(
                                      'Добавлено: '
                                      '${loaded.comparison!.addedCount} · '
                                      'Удалено: '
                                      '${loaded.comparison!.removedCount} · '
                                      'Изменено: '
                                      '${loaded.comparison!.changedCount}',
                                    ),
                            );
                          }

                          if (itemIndex <= changes.length) {
                            final RegistryNodeChange change =
                                changes[itemIndex - 1];

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
