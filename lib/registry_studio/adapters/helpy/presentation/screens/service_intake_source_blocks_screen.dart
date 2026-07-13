import 'package:flutter/material.dart';

import '../../../../presentation/language/registry_studio_ui_language.dart';
import '../../infrastructure/service_intake_source_block_extractor.dart';

final class ServiceIntakeSourceBlocksScreen extends StatefulWidget {
  const ServiceIntakeSourceBlocksScreen({
    required this.uiLanguage,
    required this.sourceBlocks,
    this.onStartOperation,
    super.key,
  });

  static const Key loadingKey = Key('service_intake_source_loading');
  static const Key errorKey = Key('service_intake_source_error');
  static const Key listKey = Key('service_intake_source_list');
  static const Key searchKey = Key('service_intake_source_search');
  static const Key clearSearchKey = Key('service_intake_source_search_clear');

  final RegistryStudioUiLanguage uiLanguage;
  final Future<List<ServiceIntakeSourceBlock>> sourceBlocks;
  final ValueChanged<ServiceIntakeSourceBlock>? onStartOperation;

  static String titleFor(RegistryStudioUiLanguage language) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => 'Источник service intake',
      RegistryStudioUiLanguage.en => 'Service intake source',
      RegistryStudioUiLanguage.th => 'แหล่งข้อมูล service intake',
    };
  }

  @override
  State<ServiceIntakeSourceBlocksScreen> createState() =>
      _ServiceIntakeSourceBlocksScreenState();
}

final class _ServiceIntakeSourceBlocksScreenState
    extends State<ServiceIntakeSourceBlocksScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ServiceIntakeSourceLabels labels = _labels(widget.uiLanguage);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ServiceIntakeSourceBlocksScreen.titleFor(widget.uiLanguage),
        ),
      ),
      body: FutureBuilder<List<ServiceIntakeSourceBlock>>(
        future: widget.sourceBlocks,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<ServiceIntakeSourceBlock>> snapshot,
            ) {
              if (snapshot.hasError) {
                return Center(
                  key: ServiceIntakeSourceBlocksScreen.errorKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '${labels.loadFailed}\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final List<ServiceIntakeSourceBlock>? blocks = snapshot.data;

              if (blocks == null) {
                return const Center(
                  key: ServiceIntakeSourceBlocksScreen.loadingKey,
                  child: CircularProgressIndicator(),
                );
              }

              final String normalizedQuery = _query.trim().toLowerCase();
              final List<ServiceIntakeSourceBlock> visibleBlocks =
                  normalizedQuery.isEmpty
                  ? blocks
                  : blocks
                        .where((ServiceIntakeSourceBlock block) {
                          final String searchableText =
                              '${block.identity.heading}\n'
                              '${block.identity.entityId.value}\n'
                              '${block.identity.path.segments.join(' / ')}\n'
                              '${block.sourceText}';

                          return searchableText.toLowerCase().contains(
                            normalizedQuery,
                          );
                        })
                        .toList(growable: false);

              return ListView(
                key: ServiceIntakeSourceBlocksScreen.listKey,
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        normalizedQuery.isEmpty
                            ? '${labels.loadedCount}: ${blocks.length}'
                            : '${labels.shownCount}: ${visibleBlocks.length} '
                                  '${labels.ofCount} ${blocks.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: ServiceIntakeSourceBlocksScreen.searchKey,
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: labels.searchLabel,
                      hintText: labels.searchHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              key: ServiceIntakeSourceBlocksScreen
                                  .clearSearchKey,
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
                  if (visibleBlocks.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(labels.noMatches),
                      ),
                    ),
                  for (final ServiceIntakeSourceBlock block in visibleBlocks)
                    Card(
                      child: ExpansionTile(
                        key: ValueKey<String>(
                          'service_intake_source_block_'
                          '${block.identity.entityId.value}',
                        ),
                        title: Text(
                          block.identity.heading,
                          style:
                              normalizedQuery.isNotEmpty &&
                                  block.identity.heading.toLowerCase().contains(
                                    normalizedQuery,
                                  )
                              ? const TextStyle(fontWeight: FontWeight.w700)
                              : null,
                        ),
                        subtitle: Text(
                          '${block.identity.entityId.value}\n'
                          '${block.identity.path.segments.join(' / ')}\n'
                          '${labels.lineRange}: '
                          '${block.startLine}–${block.endLine}',
                          style:
                              normalizedQuery.isNotEmpty &&
                                  (block.identity.entityId.value
                                          .toLowerCase()
                                          .contains(normalizedQuery) ||
                                      block.identity.path.segments
                                          .join(' / ')
                                          .toLowerCase()
                                          .contains(normalizedQuery))
                              ? const TextStyle(fontWeight: FontWeight.w700)
                              : null,
                        ),
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SelectableText(
                                    block.sourceText,
                                    style:
                                        normalizedQuery.isNotEmpty &&
                                            block.sourceText
                                                .toLowerCase()
                                                .contains(normalizedQuery)
                                        ? const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          )
                                        : null,
                                  ),
                                  if (widget.onStartOperation !=
                                      null) ...<Widget>[
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      key: ValueKey<String>(
                                        'service_intake_start_operation_'
                                        '${block.identity.entityId.value}',
                                      ),
                                      onPressed: () =>
                                          widget.onStartOperation!(block),
                                      icon: const Icon(Icons.play_arrow),
                                      label: Text(labels.startOperation),
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
              );
            },
      ),
    );
  }
}

typedef _ServiceIntakeSourceLabels = ({
  String loadedCount,
  String shownCount,
  String ofCount,
  String lineRange,
  String loadFailed,
  String startOperation,
  String searchLabel,
  String searchHint,
  String clearSearch,
  String noMatches,
});

_ServiceIntakeSourceLabels _labels(RegistryStudioUiLanguage language) {
  return switch (language) {
    RegistryStudioUiLanguage.ru => (
      loadedCount: 'Загружено записей',
      shownCount: 'Показано',
      ofCount: 'из',
      lineRange: 'Строки',
      loadFailed: 'Не удалось загрузить источник Registry',
      startOperation: 'Открыть инженерную операцию',
      searchLabel: 'Поиск по источнику',
      searchHint: 'Заголовок, ID, путь или текст',
      clearSearch: 'Очистить поиск',
      noMatches: 'Совпадения не найдены',
    ),
    RegistryStudioUiLanguage.en => (
      loadedCount: 'Loaded records',
      shownCount: 'Shown',
      ofCount: 'of',
      lineRange: 'Lines',
      loadFailed: 'Failed to load Registry source',
      startOperation: 'Open engineering operation',
      searchLabel: 'Search source',
      searchHint: 'Heading, ID, path, or text',
      clearSearch: 'Clear search',
      noMatches: 'No matches found',
    ),
    RegistryStudioUiLanguage.th => (
      loadedCount: 'ระเบียนที่โหลด',
      shownCount: 'แสดง',
      ofCount: 'จาก',
      lineRange: 'บรรทัด',
      loadFailed: 'ไม่สามารถโหลดแหล่งข้อมูล Registry ได้',
      startOperation: 'เปิดการดำเนินการทางวิศวกรรม',
      searchLabel: 'ค้นหาในแหล่งข้อมูล',
      searchHint: 'หัวข้อ, ID, เส้นทาง หรือข้อความ',
      clearSearch: 'ล้างการค้นหา',
      noMatches: 'ไม่พบรายการที่ตรงกัน',
    ),
  };
}
