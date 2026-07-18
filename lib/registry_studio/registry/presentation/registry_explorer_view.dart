import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/contracts/registry_snapshot_loader.dart';
import '../domain/entities/registry_node.dart';
import 'registry_explorer_cubit.dart';

final class RegistryExplorerView extends StatelessWidget {
  const RegistryExplorerView({required this.snapshotLoader, super.key});

  final RegistrySnapshotLoader snapshotLoader;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryExplorerCubit>(
      create: (_) =>
          RegistryExplorerCubit(snapshotLoader: snapshotLoader)..load(),
      child: const _RegistryExplorerView(),
    );
  }
}

final class _RegistryExplorerView extends StatelessWidget {
  const _RegistryExplorerView();

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
                      onPressed: context.read<RegistryExplorerCubit>().load,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
          ),
          RegistryExplorerLoaded(:final snapshot, :final index) => SafeArea(
            child: Column(
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
                                'Проект: ${snapshot.projectId}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text('Узлов: ${index.nodes.length}'),
                              Text(
                                'Revision: '
                                '${snapshot.sourceRevision}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Перезагрузить Registry',
                          onPressed: context.read<RegistryExplorerCubit>().load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: index.nodes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int nodeIndex) {
                      final RegistryNode node = index.nodes[nodeIndex];

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
          ),
        };
      },
    );
  }
}
