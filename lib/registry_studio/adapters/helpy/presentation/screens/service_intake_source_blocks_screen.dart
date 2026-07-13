import 'package:flutter/material.dart';

import '../../../../presentation/language/registry_studio_ui_language.dart';
import '../../infrastructure/service_intake_source_block_extractor.dart';

final class ServiceIntakeSourceBlocksScreen extends StatelessWidget {
  const ServiceIntakeSourceBlocksScreen({
    required this.uiLanguage,
    required this.sourceBlocks,
    super.key,
  });

  static const Key loadingKey = Key('service_intake_source_loading');
  static const Key errorKey = Key('service_intake_source_error');
  static const Key listKey = Key('service_intake_source_list');

  final RegistryStudioUiLanguage uiLanguage;
  final Future<List<ServiceIntakeSourceBlock>> sourceBlocks;

  static String titleFor(RegistryStudioUiLanguage language) {
    return switch (language) {
      RegistryStudioUiLanguage.ru => 'Источник service intake',
      RegistryStudioUiLanguage.en => 'Service intake source',
      RegistryStudioUiLanguage.th => 'แหล่งข้อมูล service intake',
    };
  }

  @override
  Widget build(BuildContext context) {
    final _ServiceIntakeSourceLabels labels = _labels(uiLanguage);

    return Scaffold(
      appBar: AppBar(title: Text(titleFor(uiLanguage))),
      body: FutureBuilder<List<ServiceIntakeSourceBlock>>(
        future: sourceBlocks,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<ServiceIntakeSourceBlock>> snapshot,
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

              final List<ServiceIntakeSourceBlock>? blocks = snapshot.data;

              if (blocks == null) {
                return const Center(
                  key: loadingKey,
                  child: CircularProgressIndicator(),
                );
              }

              return ListView(
                key: listKey,
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${labels.loadedCount}: ${blocks.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final ServiceIntakeSourceBlock block in blocks)
                    Card(
                      child: ExpansionTile(
                        key: ValueKey<String>(
                          'service_intake_source_block_'
                          '${block.identity.entityId.value}',
                        ),
                        title: Text(block.identity.heading),
                        subtitle: Text(
                          '${block.identity.entityId.value}\n'
                          '${block.identity.path.segments.join(' / ')}\n'
                          '${labels.lineRange}: '
                          '${block.startLine}–${block.endLine}',
                        ),
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: SelectableText(block.sourceText),
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
  String lineRange,
  String loadFailed,
});

_ServiceIntakeSourceLabels _labels(RegistryStudioUiLanguage language) {
  return switch (language) {
    RegistryStudioUiLanguage.ru => (
      loadedCount: 'Загружено записей',
      lineRange: 'Строки',
      loadFailed: 'Не удалось загрузить источник Registry',
    ),
    RegistryStudioUiLanguage.en => (
      loadedCount: 'Loaded records',
      lineRange: 'Lines',
      loadFailed: 'Failed to load Registry source',
    ),
    RegistryStudioUiLanguage.th => (
      loadedCount: 'ระเบียนที่โหลด',
      lineRange: 'บรรทัด',
      loadFailed: 'ไม่สามารถโหลดแหล่งข้อมูล Registry ได้',
    ),
  };
}
