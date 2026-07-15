import 'package:flutter/material.dart';

import '../../core/application/source_indexing/registry_document_node.dart';
import '../language/registry_studio_ui_language.dart';

final class RegistryDocumentExplorerScreen extends StatelessWidget {
  const RegistryDocumentExplorerScreen({
    required this.uiLanguage,
    required this.nodes,
    super.key,
  });

  static const Key loadingKey = Key('registry_document_explorer_loading');
  static const Key errorKey = Key('registry_document_explorer_error');
  static const Key listKey = Key('registry_document_explorer_list');

  final RegistryStudioUiLanguage uiLanguage;
  final Future<List<RegistryDocumentNode>> nodes;

  static String titleFor(RegistryStudioUiLanguage language) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => 'Registry',
      RegistryStudioUiLanguage.en => 'Registry',
      RegistryStudioUiLanguage.th => 'Registry',
    };
  }

  @override
  Widget build(BuildContext context) {
    final _RegistryDocumentExplorerLabels labels = _labels(uiLanguage);

    return FutureBuilder<List<RegistryDocumentNode>>(
      future: nodes,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<RegistryDocumentNode>> snapshot,
          ) {
            if (snapshot.hasError) {
              return Center(
                key: errorKey,
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
                key: loadingKey,
                child: CircularProgressIndicator(),
              );
            }

            return ListView(
              key: listKey,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                  child: Text(
                    '${labels.rootSections}: ${roots.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (roots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(labels.noSections),
                  )
                else
                  for (final RegistryDocumentNode node in roots)
                    _RegistryDocumentNodeTile(node: node, labels: labels),
              ],
            );
          },
    );
  }
}

final class _RegistryDocumentNodeTile extends StatelessWidget {
  const _RegistryDocumentNodeTile({required this.node, required this.labels});

  final RegistryDocumentNode node;
  final _RegistryDocumentExplorerLabels labels;

  @override
  Widget build(BuildContext context) {
    final String metadata =
        '${labels.level}: H${node.headingLevel}\n'
        '${labels.path}: ${node.headingPath.join(' / ')}\n'
        '${labels.lines}: ${node.startLine}–${node.endLine}';

    if (node.children.isEmpty) {
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
            _RegistryDocumentNodeTile(node: child, labels: labels),
        ],
      ),
    );
  }

  Future<void> _showSource(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
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
  String level,
  String path,
  String lines,
  String openSource,
  String loadFailed,
  String noSections,
});

_RegistryDocumentExplorerLabels _labels(RegistryStudioUiLanguage language) {
  return switch (language) {
    RegistryStudioUiLanguage.ru => (
      rootSections: 'Корневых разделов',
      level: 'Уровень',
      path: 'Путь',
      lines: 'Строки',
      openSource: 'Открыть исходный текст',
      loadFailed: 'Не удалось загрузить полный Registry',
      noSections: 'Разделы Registry не найдены',
    ),
    RegistryStudioUiLanguage.en => (
      rootSections: 'Root sections',
      level: 'Level',
      path: 'Path',
      lines: 'Lines',
      openSource: 'Open source text',
      loadFailed: 'Failed to load the complete Registry',
      noSections: 'No Registry sections found',
    ),
    RegistryStudioUiLanguage.th => (
      rootSections: 'ส่วนราก',
      level: 'ระดับ',
      path: 'เส้นทาง',
      lines: 'บรรทัด',
      openSource: 'เปิดข้อความต้นฉบับ',
      loadFailed: 'ไม่สามารถโหลด Registry ทั้งหมดได้',
      noSections: 'ไม่พบส่วนของ Registry',
    ),
  };
}
