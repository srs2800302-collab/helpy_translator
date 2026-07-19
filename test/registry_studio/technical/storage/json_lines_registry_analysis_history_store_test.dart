import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/maintenance/history/domain/entities/registry_analysis_history_entry.dart';
import 'package:helpy_translator/registry_studio/technical/storage/json_lines_registry_analysis_history_store.dart';

void main() {
  group('JsonLinesRegistryAnalysisHistoryStore', () {
    late Directory directory;
    late JsonLinesRegistryAnalysisHistoryStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'registry-analysis-history-',
      );

      store = JsonLinesRegistryAnalysisHistoryStore(
        applicationSupportDirectory: directory,
      );
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('returns empty history when the append-only file is absent', () async {
      expect(await store.loadHistory(), isEmpty);
    });

    test(
      'appends and restores exact analysis history entries in order',
      () async {
        final RegistryAnalysisHistoryEntry firstEntry =
            RegistryAnalysisHistoryEntry(
              loadedAt: DateTime.utc(2026, 7, 19, 16, 0),
              projectId: 'project',
              projectAdapterId: 'project.adapter',
              sourceDocumentPath: 'registry.md',
              sourceRevision: 'revision-a',
              sourceSnapshotFingerprint: 'git-blob:aaaaaaaa',
            );

        final RegistryAnalysisHistoryEntry secondEntry =
            RegistryAnalysisHistoryEntry(
              loadedAt: DateTime.utc(2026, 7, 19, 17, 30),
              projectId: 'project',
              projectAdapterId: 'project.adapter',
              sourceDocumentPath: 'registry.md',
              sourceRevision: 'revision-b',
              sourceSnapshotFingerprint: 'git-blob:bbbbbbbb',
              previousRevision: 'revision-a',
              cleanBaselineRevision: 'revision-clean',
              previousAddedCount: 2,
              previousRemovedCount: 1,
              previousChangedCount: 3,
              cleanBaselineAddedCount: 4,
              cleanBaselineRemovedCount: 5,
              cleanBaselineChangedCount: 6,
              problemCount: 15,
            );

        await store.appendHistoryEntry(firstEntry);
        await store.appendHistoryEntry(secondEntry);

        final List<RegistryAnalysisHistoryEntry> restored = await store
            .loadHistory();

        expect(restored, <RegistryAnalysisHistoryEntry>[
          firstEntry,
          secondEntry,
        ]);

        expect(restored.first.previousChangeCount, 0);
        expect(restored.last.previousChangeCount, 6);
        expect(restored.last.cleanBaselineChangeCount, 15);

        final File historyFile = File(
          '${directory.path}'
          '${Platform.pathSeparator}'
          '${JsonLinesRegistryAnalysisHistoryStore.directoryName}'
          '${Platform.pathSeparator}'
          '${JsonLinesRegistryAnalysisHistoryStore.fileName}',
        );

        final List<String> lines = await historyFile.readAsLines();

        expect(lines, hasLength(2));

        final Map<String, dynamic> firstEncoded =
            jsonDecode(lines.first) as Map<String, dynamic>;

        final Map<String, dynamic> secondEncoded =
            jsonDecode(lines.last) as Map<String, dynamic>;

        expect(firstEncoded['version'], 'v1');
        expect(firstEncoded['loadedAt'], '2026-07-19T16:00:00.000Z');
        expect(secondEncoded['sourceRevision'], 'revision-b');
        expect(secondEncoded['previousAddedCount'], 2);
        expect(secondEncoded['cleanBaselineChangedCount'], 6);
        expect(secondEncoded['problemCount'], 15);

        for (final Map<String, dynamic> encoded in <Map<String, dynamic>>[
          firstEncoded,
          secondEncoded,
        ]) {
          expect(encoded.containsKey('sourceContent'), isFalse);
          expect(encoded.containsKey('roots'), isFalse);
          expect(encoded.containsKey('changes'), isFalse);
          expect(encoded.containsKey('problems'), isFalse);
        }
      },
    );

    test('rejects an invalid append-only history line', () async {
      final Directory historyDirectory = Directory(
        '${directory.path}'
        '${Platform.pathSeparator}'
        '${JsonLinesRegistryAnalysisHistoryStore.directoryName}',
      );

      await historyDirectory.create(recursive: true);

      final File historyFile = File(
        '${historyDirectory.path}'
        '${Platform.pathSeparator}'
        '${JsonLinesRegistryAnalysisHistoryStore.fileName}',
      );

      await historyFile.writeAsString(
        '${jsonEncode(<String, Object?>{'version': 'v1', 'loadedAt': 'invalid timestamp', 'projectId': 'project', 'projectAdapterId': 'project.adapter', 'sourceDocumentPath': 'registry.md', 'sourceRevision': 'revision-b', 'sourceSnapshotFingerprint': 'git-blob:bbbbbbbb', 'previousRevision': 'revision-a', 'cleanBaselineRevision': null, 'previousAddedCount': 1, 'previousRemovedCount': 0, 'previousChangedCount': 0, 'cleanBaselineAddedCount': 0, 'cleanBaselineRemovedCount': 0, 'cleanBaselineChangedCount': 0, 'problemCount': 1})}\n',
        flush: true,
      );

      await expectLater(store.loadHistory(), throwsA(isA<FormatException>()));
    });
  });
}
