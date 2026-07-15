import 'package:flutter/material.dart';

import '../../core/application/source_indexing/registry_document_node.dart';
import '../language/registry_studio_ui_language.dart';

final class RegistryDocumentExplorerScreen extends StatefulWidget {
  const RegistryDocumentExplorerScreen({
    required this.uiLanguage,
    required this.nodes,
    required this.sourceRevision,
    this.nodeActionsBuilder,
    super.key,
  });

  static const Key loadingKey = Key('registry_document_explorer_loading');
  static const Key errorKey = Key('registry_document_explorer_error');
  static const Key listKey = Key('registry_document_explorer_list');
  static const Key searchKey = Key('registry_document_explorer_search');
  static const Key clearSearchKey = Key(
    'registry_document_explorer_search_clear',
  );

  final RegistryStudioUiLanguage uiLanguage;
  final Future<List<RegistryDocumentNode>> nodes;
  final Future<String> sourceRevision;
  final Widget? Function(BuildContext context, RegistryDocumentNode node)?
  nodeActionsBuilder;

  static String titleFor(RegistryStudioUiLanguage language) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => 'Registry',
      RegistryStudioUiLanguage.en => 'Registry',
      RegistryStudioUiLanguage.th => 'Registry',
    };
  }

  @override
  State<RegistryDocumentExplorerScreen> createState() =>
      _RegistryDocumentExplorerScreenState();
}

final class _RegistryDocumentExplorerScreenState
    extends State<RegistryDocumentExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _RegistryDocumentExplorerLabels labels = _labels(widget.uiLanguage);

    return FutureBuilder<List<RegistryDocumentNode>>(
      future: widget.nodes,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<RegistryDocumentNode>> snapshot,
          ) {
            if (snapshot.hasError) {
              return Center(
                key: RegistryDocumentExplorerScreen.errorKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '${labels.loadFailed}\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final List<RegistryDocumentNode>? roots = snapshot.data;

            if (roots == null) {
              return const Center(
                key: RegistryDocumentExplorerScreen.loadingKey,
                child: CircularProgressIndicator(),
              );
            }

            final String normalizedQuery = _query.trim().toLowerCase();
            final List<RegistryDocumentNode> allNodes = _flattenNodes(roots);
            final List<RegistryDocumentNode> visibleNodes =
                normalizedQuery.isEmpty
                ? const <RegistryDocumentNode>[]
                : allNodes
                      .where(
                        (RegistryDocumentNode node) =>
                            _matches(node, normalizedQuery),
                      )
                      .toList(growable: false);

            return ListView(
              key: RegistryDocumentExplorerScreen.listKey,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(
                    normalizedQuery.isEmpty
                        ? '${labels.rootSections}: ${roots.length}'
                        : '${labels.shownCount}: ${visibleNodes.length} '
                              '${labels.ofCount} ${allNodes.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: FutureBuilder<String>(
                    future: widget.sourceRevision,
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<String> revisionSnapshot,
                        ) {
                          return SelectableText(
                            '${labels.sourceRevision}: '
                            '${revisionSnapshot.data ?? labels.loadingRevision}',
                          );
                        },
                  ),
                ),
                TextField(
                  key: RegistryDocumentExplorerScreen.searchKey,
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: labels.searchLabel,
                    hintText: labels.searchHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            key: RegistryDocumentExplorerScreen.clearSearchKey,
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _query = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                            tooltip: labels.clearSearch,
                          ),
                  ),
                  onChanged: (String value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (normalizedQuery.isEmpty) ...<Widget>[
                  if (roots.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(labels.noSections),
                    )
                  else
                    for (final RegistryDocumentNode node in roots)
                      _RegistryDocumentNodeTile(
                        node: node,
                        labels: labels,
                        nodeActionsBuilder: widget.nodeActionsBuilder,
                      ),
                ] else if (visibleNodes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(labels.noMatches),
                    ),
                  )
                else
                  for (final RegistryDocumentNode node in visibleNodes)
                    _RegistryDocumentNodeTile(
                      node: node,
                      labels: labels,
                      flat: true,
                      nodeActionsBuilder: widget.nodeActionsBuilder,
                    ),
              ],
            );
          },
    );
  }

  List<RegistryDocumentNode> _flattenNodes(
    Iterable<RegistryDocumentNode> nodes,
  ) {
    final List<RegistryDocumentNode> result = <RegistryDocumentNode>[];

    for (final RegistryDocumentNode node in nodes) {
      result.add(node);
      result.addAll(_flattenNodes(node.children));
    }

    return List<RegistryDocumentNode>.unmodifiable(result);
  }

  bool _matches(RegistryDocumentNode node, String normalizedQuery) {
    final String searchableText =
        '${node.title}\n'
        '${node.headingPath.join(' / ')}\n'
        '${_ownSourceText(node)}';

    return searchableText.toLowerCase().contains(normalizedQuery);
  }

  String _ownSourceText(RegistryDocumentNode node) {
    if (node.children.isEmpty) {
      return node.sourceText;
    }

    final List<String> lines = node.sourceText.split('\n');
    final Set<int> excludedIndexes = <int>{};

    for (final RegistryDocumentNode child in node.children) {
      final int firstIndex = child.startLine - node.startLine;
      final int lastIndex = child.endLine - node.startLine;

      for (
        int index = firstIndex;
        index <= lastIndex && index < lines.length;
        index += 1
      ) {
        if (index >= 0) {
          excludedIndexes.add(index);
        }
      }
    }

    return <String>[
      for (int index = 0; index < lines.length; index += 1)
        if (!excludedIndexes.contains(index)) lines[index],
    ].join('\n');
  }
}

final class _RegistryDocumentNodeTile extends StatelessWidget {
  const _RegistryDocumentNodeTile({
    required this.node,
    required this.labels,
    this.flat = false,
    this.nodeActionsBuilder,
  });

  final RegistryDocumentNode node;
  final _RegistryDocumentExplorerLabels labels;
  final bool flat;
  final Widget? Function(BuildContext context, RegistryDocumentNode node)?
  nodeActionsBuilder;

  @override
  Widget build(BuildContext context) {
    final String metadata =
        '${labels.level}: H${node.headingLevel}\n'
        '${labels.path}: ${node.headingPath.join(' / ')}\n'
        '${labels.lines}: ${node.startLine}–${node.endLine}';

    if (flat || node.children.isEmpty) {
      return Card(
        child: ListTile(
          key: ValueKey<String>(
            'registry_document_node_${node.headingPath.join('>')}',
          ),
          title: Text(node.title),
          subtitle: Text(metadata),
          trailing: const Icon(Icons.description_outlined),
          onTap: () => _showSource(context),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        key: ValueKey<String>(
          'registry_document_node_${node.headingPath.join('>')}',
        ),
        title: Text(node.title),
        subtitle: Text(metadata),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showSource(context),
              icon: const Icon(Icons.description_outlined),
              label: Text(labels.openSource),
            ),
          ),
          for (final RegistryDocumentNode child in node.children)
            _RegistryDocumentNodeTile(
              node: child,
              labels: labels,
              nodeActionsBuilder: nodeActionsBuilder,
            ),
        ],
      ),
    );
  }

  Future<void> _showSource(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final Widget? nodeActions = nodeActionsBuilder?.call(context, node);

        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    node.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('${labels.lines}: ${node.startLine}–${node.endLine}'),
                  const SizedBox(height: 12),
                  if (nodeActions != null) ...<Widget>[
                    nodeActions,
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(node.sourceText),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

typedef _RegistryDocumentExplorerLabels = ({
  String rootSections,
  String sourceRevision,
  String loadingRevision,
  String shownCount,
  String ofCount,
  String level,
  String path,
  String lines,
  String openSource,
  String loadFailed,
  String noSections,
  String searchLabel,
  String searchHint,
  String clearSearch,
  String noMatches,
});

_RegistryDocumentExplorerLabels _labels(RegistryStudioUiLanguage language) {
  return switch (language) {
    RegistryStudioUiLanguage.ru => (
      rootSections: 'Корневых разделов',
      sourceRevision: 'Исходная ревизия',
      loadingRevision: 'загрузка',
      shownCount: 'Показано',
      ofCount: 'из',
      level: 'Уровень',
      path: 'Путь',
      lines: 'Строки',
      openSource: 'Открыть исходный текст',
      loadFailed: 'Не удалось загрузить полный Registry',
      noSections: 'Разделы Registry не найдены',
      searchLabel: 'Поиск по Registry',
      searchHint: 'Заголовок, путь или исходный текст',
      clearSearch: 'Очистить поиск',
      noMatches: 'Совпадения не найдены',
    ),
    RegistryStudioUiLanguage.en => (
      rootSections: 'Root sections',
      sourceRevision: 'Source revision',
      loadingRevision: 'loading',
      shownCount: 'Shown',
      ofCount: 'of',
      level: 'Level',
      path: 'Path',
      lines: 'Lines',
      openSource: 'Open source text',
      loadFailed: 'Failed to load the complete Registry',
      noSections: 'No Registry sections found',
      searchLabel: 'Search Registry',
      searchHint: 'Heading, path, or source text',
      clearSearch: 'Clear search',
      noMatches: 'No matches found',
    ),
    RegistryStudioUiLanguage.th => (
      rootSections: 'ส่วนราก',
      sourceRevision: 'รีวิชันต้นทาง',
      loadingRevision: 'กำลังโหลด',
      shownCount: 'แสดง',
      ofCount: 'จาก',
      level: 'ระดับ',
      path: 'เส้นทาง',
      lines: 'บรรทัด',
      openSource: 'เปิดข้อความต้นฉบับ',
      loadFailed: 'ไม่สามารถโหลด Registry ทั้งหมดได้',
      noSections: 'ไม่พบส่วนของ Registry',
      searchLabel: 'ค้นหาใน Registry',
      searchHint: 'หัวข้อ เส้นทาง หรือข้อความต้นฉบับ',
      clearSearch: 'ล้างการค้นหา',
      noMatches: 'ไม่พบรายการที่ตรงกัน',
    ),
  };
}
