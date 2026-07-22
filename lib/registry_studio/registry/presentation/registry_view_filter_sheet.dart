import 'package:flutter/material.dart';

import '../domain/entities/registry_node.dart';
import '../domain/value_objects/registry_node_id.dart';
import 'registry_analysis_status_entry.dart';

final class RegistryViewFilterSheet extends StatefulWidget {
  const RegistryViewFilterSheet({
    required this.nodesById,
    required this.analysisStatusEntries,
    required this.branchScopeNodeId,
    required this.initialRegistryViewFilter,
    required this.initialCanonicalStatusFilter,
    required this.onRegistryViewFilterChanged,
    required this.onCanonicalStatusFilterChanged,
    super.key,
  });

  final Map<RegistryNodeId, RegistryNode> nodesById;
  final List<RegistryAnalysisStatusEntry> analysisStatusEntries;
  final RegistryNodeId? branchScopeNodeId;
  final String initialRegistryViewFilter;
  final String initialCanonicalStatusFilter;
  final Future<void> Function(String filter) onRegistryViewFilterChanged;
  final Future<void> Function(String filter) onCanonicalStatusFilterChanged;

  @override
  State<RegistryViewFilterSheet> createState() =>
      _RegistryViewFilterSheetState();
}

final class _RegistryViewFilterSheetState
    extends State<RegistryViewFilterSheet> {
  static const List<String> _canonicalStatusFilters = <String>[
    'all',
    'unclassifiedNeutral',
    'exact',
    'equivalent',
    'review',
    'drift',
    'failed',
  ];

  late String _selectedRegistryViewFilter;
  late String _selectedCanonicalStatusFilter;

  @override
  void initState() {
    super.initState();

    _selectedRegistryViewFilter = widget.initialRegistryViewFilter;
    _selectedCanonicalStatusFilter = widget.initialCanonicalStatusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final List<RegistryNode> allNodes = widget.nodesById.values.toList(
      growable: false,
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

    final ({
      Map<String, int> formulationCounts,
      Map<String, Set<RegistryNodeId>> nodeIds,
    })
    canonicalCounts = _canonicalCounts(allNodes);

    return SafeArea(
      child: SizedBox(
        key: const ValueKey<String>('registry-view-filter-sheet'),
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Фильтр отображения Registry',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey<String>('registry-view-filter-close'),
                    tooltip: 'Закрыть фильтр',
                    onPressed: () {
                      Navigator.of(context).pop();
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
                  _structuralFilterTile(
                    keyValue: 'registry-view-filter-roots',
                    filter: 'roots',
                    icon: Icons.home_work_outlined,
                    title: 'Корневые узлы',
                    count: rootCount,
                  ),
                  _structuralFilterTile(
                    keyValue: 'registry-view-filter-all',
                    filter: 'all',
                    icon: Icons.account_tree_outlined,
                    title: 'Все узлы',
                    count: allNodes.length,
                  ),
                  _structuralFilterTile(
                    keyValue: 'registry-view-filter-branches',
                    filter: 'branches',
                    icon: Icons.folder_outlined,
                    title: 'Ветки',
                    count: branchCount,
                  ),
                  _structuralFilterTile(
                    keyValue: 'registry-view-filter-leaves',
                    filter: 'leaves',
                    icon: Icons.description_outlined,
                    title: 'Конечные блоки',
                    count: leafCount,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text('Канонический статус'),
                  ),
                  for (final String filter in _canonicalStatusFilters)
                    _canonicalFilterTile(
                      filter: filter,
                      formulationCount:
                          canonicalCounts.formulationCounts[filter] ?? 0,
                      nodeCount: canonicalCounts.nodeIds[filter]?.length ?? 0,
                    ),
                  if (kindIds.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                      child: Text('Фактически обнаруженные типы'),
                    ),
                  for (final String kindId in kindIds)
                    _structuralFilterTile(
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

  ({
    Map<String, int> formulationCounts,
    Map<String, Set<RegistryNodeId>> nodeIds,
  })
  _canonicalCounts(List<RegistryNode> allNodes) {
    final RegistryNode? activeBranchScopeRoot =
        _selectedRegistryViewFilter == 'branches' &&
            widget.branchScopeNodeId != null
        ? widget.nodesById[widget.branchScopeNodeId]
        : null;

    final bool aggregateSubtrees =
        _selectedRegistryViewFilter == 'roots' ||
        _selectedRegistryViewFilter == 'branches';

    final List<RegistryNode> scopeNodes =
        _selectedRegistryViewFilter == 'branches' &&
            activeBranchScopeRoot != null
        ? <RegistryNode>[activeBranchScopeRoot]
        : allNodes
              .where(
                (RegistryNode node) =>
                    _selectedRegistryViewFilter == 'all' ||
                    _matchesRegistryViewFilter(
                      node,
                      _selectedRegistryViewFilter,
                    ),
              )
              .toList(growable: false);

    final Set<RegistryNodeId> scopeNodeIds = scopeNodes
        .map((RegistryNode node) => node.id)
        .toSet();

    final Map<String, int> formulationCounts = <String, int>{
      for (final String filter in _canonicalStatusFilters) filter: 0,
    };

    final Map<String, Set<RegistryNodeId>> nodeIds =
        <String, Set<RegistryNodeId>>{
          for (final String filter in _canonicalStatusFilters)
            filter: <RegistryNodeId>{},
        };

    final Map<String, Set<String>> identities = <String, Set<String>>{
      for (final String filter in _canonicalStatusFilters) filter: <String>{},
    };

    for (final RegistryAnalysisStatusEntry entry
        in widget.analysisStatusEntries) {
      final RegistryNode? entryNode = widget.nodesById[entry.nodeId];

      if (entryNode == null) {
        continue;
      }

      bool insideScope = scopeNodeIds.contains(entry.nodeId);

      if (!insideScope && aggregateSubtrees) {
        for (final RegistryNode scopeNode in scopeNodes) {
          if (_isPathPrefix(scopeNode.path.segments, entryNode.path.segments)) {
            insideScope = true;
            break;
          }
        }
      }

      if (!insideScope) {
        continue;
      }

      if (identities['all']!.add(entry.identity)) {
        formulationCounts['all'] = formulationCounts['all']! + 1;
        nodeIds['all']!.add(entry.nodeId);
      }

      final Set<String> statusIdentities = identities.putIfAbsent(
        entry.statusId,
        () => <String>{},
      );

      if (!statusIdentities.add(entry.identity)) {
        continue;
      }

      formulationCounts.update(
        entry.statusId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );

      nodeIds
          .putIfAbsent(entry.statusId, () => <RegistryNodeId>{})
          .add(entry.nodeId);
    }

    return (formulationCounts: formulationCounts, nodeIds: nodeIds);
  }

  bool _isPathPrefix(List<String> prefix, List<String> path) {
    if (path.length < prefix.length) {
      return false;
    }

    for (int index = 0; index < prefix.length; index += 1) {
      if (path[index] != prefix[index]) {
        return false;
      }
    }

    return true;
  }

  Widget _structuralFilterTile({
    required String keyValue,
    required String filter,
    required IconData icon,
    required String title,
    required int count,
  }) {
    final bool selected = _selectedRegistryViewFilter == filter;

    return ListTile(
      key: ValueKey<String>(keyValue),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text('Узлов: $count'),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () async {
        if (selected) {
          return;
        }

        await widget.onRegistryViewFilterChanged(filter);

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedRegistryViewFilter = filter;
        });
      },
    );
  }

  Widget _canonicalFilterTile({
    required String filter,
    required int formulationCount,
    required int nodeCount,
  }) {
    final bool selected = _selectedCanonicalStatusFilter == filter;

    return ListTile(
      key: ValueKey<String>('registry-canonical-status-filter-$filter'),
      leading: Icon(_canonicalStatusFilterIcon(filter)),
      title: Text(_canonicalStatusFilterLabel(filter)),
      subtitle: Text(
        'Формулировок: $formulationCount · узлов: $nodeCount',
        key: ValueKey<String>('registry-canonical-status-count-$filter'),
      ),
      selected: selected,
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: () async {
        if (selected) {
          return;
        }

        await widget.onCanonicalStatusFilterChanged(filter);

        if (!mounted) {
          return;
        }

        setState(() {
          _selectedCanonicalStatusFilter = filter;
        });
      },
    );
  }

  String _canonicalStatusFilterLabel(String filter) {
    return switch (filter) {
      'unclassifiedNeutral' => 'Unclassified / Neutral',
      'exact' => 'Exact',
      'equivalent' => 'Equivalent',
      'review' => 'Review',
      'drift' => 'Drift',
      'failed' => 'Failed',
      _ => 'All',
    };
  }

  IconData _canonicalStatusFilterIcon(String filter) {
    return switch (filter) {
      'unclassifiedNeutral' => Icons.help_outline,
      'exact' => Icons.check_circle_outline,
      'equivalent' => Icons.done_all,
      'review' => Icons.rate_review_outlined,
      'drift' => Icons.warning_amber_rounded,
      'failed' => Icons.error_outline,
      _ => Icons.select_all,
    };
  }
}
