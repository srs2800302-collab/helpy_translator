import 'dart:convert';
import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';

import '../../maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../maintenance/history/domain/entities/registry_analysis_history_entry.dart';

final class JsonLinesRegistryAnalysisHistoryStore
    implements RegistryAnalysisHistoryStore {
  const JsonLinesRegistryAnalysisHistoryStore({
    this.applicationSupportDirectory,
  });

  static const String directoryName = 'registry_studio';
  static const String fileName = 'registry_analysis_history_v1.jsonl';

  static const String _formatVersion = 'v1';

  final Directory? applicationSupportDirectory;

  @override
  Future<List<RegistryAnalysisHistoryEntry>> loadHistory() async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory '
          'is unavailable.',
        );
      }

      supportDirectory = Directory(applicationSupportPath);
    }

    final File historyFile = File(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    if (!await historyFile.exists()) {
      return const <RegistryAnalysisHistoryEntry>[];
    }

    final List<String> lines = await historyFile.readAsLines();
    final List<RegistryAnalysisHistoryEntry> entries =
        <RegistryAnalysisHistoryEntry>[];

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex += 1) {
      final String line = lines[lineIndex];

      if (line.trim().isEmpty) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} must not be empty.',
        );
      }

      final Object? decodedEntry;

      try {
        decodedEntry = jsonDecode(line);
      } on FormatException catch (error) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} is not valid JSON.',
          error,
        );
      }

      if (decodedEntry is! Map<Object?, Object?>) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} must contain a JSON object.',
        );
      }

      if (decodedEntry.keys.any((Object? key) => key is! String)) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} keys must be strings.',
        );
      }

      final Map<String, Object?> entry = decodedEntry.cast<String, Object?>();

      const Set<String> expectedKeys = <String>{
        'version',
        'loadedAt',
        'projectId',
        'projectAdapterId',
        'sourceDocumentPath',
        'sourceRevision',
        'sourceSnapshotFingerprint',
        'previousRevision',
        'cleanBaselineRevision',
        'previousAddedCount',
        'previousRemovedCount',
        'previousChangedCount',
        'cleanBaselineAddedCount',
        'cleanBaselineRemovedCount',
        'cleanBaselineChangedCount',
        'problemCount',
      };

      final Set<String> actualKeys = entry.keys.toSet();

      if (actualKeys.length != expectedKeys.length ||
          !actualKeys.containsAll(expectedKeys)) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} schema is invalid.',
        );
      }

      final Object? version = entry['version'];
      final Object? loadedAt = entry['loadedAt'];
      final Object? projectId = entry['projectId'];
      final Object? projectAdapterId = entry['projectAdapterId'];
      final Object? sourceDocumentPath = entry['sourceDocumentPath'];
      final Object? sourceRevision = entry['sourceRevision'];
      final Object? sourceSnapshotFingerprint =
          entry['sourceSnapshotFingerprint'];
      final Object? previousRevision = entry['previousRevision'];
      final Object? cleanBaselineRevision = entry['cleanBaselineRevision'];
      final Object? previousAddedCount = entry['previousAddedCount'];
      final Object? previousRemovedCount = entry['previousRemovedCount'];
      final Object? previousChangedCount = entry['previousChangedCount'];
      final Object? cleanBaselineAddedCount = entry['cleanBaselineAddedCount'];
      final Object? cleanBaselineRemovedCount =
          entry['cleanBaselineRemovedCount'];
      final Object? cleanBaselineChangedCount =
          entry['cleanBaselineChangedCount'];
      final Object? problemCount = entry['problemCount'];

      if (version != _formatVersion) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} version is unsupported.',
        );
      }

      if (loadedAt is! String ||
          projectId is! String ||
          projectAdapterId is! String ||
          sourceDocumentPath is! String ||
          sourceRevision is! String ||
          sourceSnapshotFingerprint is! String ||
          (previousRevision != null && previousRevision is! String) ||
          (cleanBaselineRevision != null && cleanBaselineRevision is! String) ||
          previousAddedCount is! int ||
          previousRemovedCount is! int ||
          previousChangedCount is! int ||
          cleanBaselineAddedCount is! int ||
          cleanBaselineRemovedCount is! int ||
          cleanBaselineChangedCount is! int ||
          problemCount is! int) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} field types are invalid.',
        );
      }

      final DateTime parsedLoadedAt;

      try {
        parsedLoadedAt = DateTime.parse(loadedAt);
      } on FormatException catch (error) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} timestamp is invalid.',
          error,
        );
      }

      try {
        entries.add(
          RegistryAnalysisHistoryEntry(
            loadedAt: parsedLoadedAt,
            projectId: projectId,
            projectAdapterId: projectAdapterId,
            sourceDocumentPath: sourceDocumentPath,
            sourceRevision: sourceRevision,
            sourceSnapshotFingerprint: sourceSnapshotFingerprint,
            previousRevision: previousRevision as String?,
            cleanBaselineRevision: cleanBaselineRevision as String?,
            previousAddedCount: previousAddedCount,
            previousRemovedCount: previousRemovedCount,
            previousChangedCount: previousChangedCount,
            cleanBaselineAddedCount: cleanBaselineAddedCount,
            cleanBaselineRemovedCount: cleanBaselineRemovedCount,
            cleanBaselineChangedCount: cleanBaselineChangedCount,
            problemCount: problemCount,
          ),
        );
      } on ArgumentError catch (error) {
        throw FormatException(
          'Registry analysis history line '
          '${lineIndex + 1} values are invalid.',
          error,
        );
      }
    }

    return List<RegistryAnalysisHistoryEntry>.unmodifiable(entries);
  }

  @override
  Future<void> appendHistoryEntry(RegistryAnalysisHistoryEntry entry) async {
    final Directory supportDirectory;

    if (applicationSupportDirectory != null) {
      supportDirectory = applicationSupportDirectory!;
    } else {
      final String? applicationSupportPath = await PathProviderAndroid()
          .getApplicationSupportPath();

      if (applicationSupportPath == null ||
          applicationSupportPath.trim().isEmpty) {
        throw StateError(
          'Android application support directory '
          'is unavailable.',
        );
      }

      supportDirectory = Directory(applicationSupportPath);
    }

    final Directory historyDirectory = Directory(
      '${supportDirectory.path}'
      '${Platform.pathSeparator}'
      '$directoryName',
    );

    await historyDirectory.create(recursive: true);

    final File historyFile = File(
      '${historyDirectory.path}'
      '${Platform.pathSeparator}'
      '$fileName',
    );

    await historyFile.writeAsString(
      '${jsonEncode(<String, Object?>{'version': _formatVersion, 'loadedAt': entry.loadedAt.toUtc().toIso8601String(), 'projectId': entry.projectId, 'projectAdapterId': entry.projectAdapterId, 'sourceDocumentPath': entry.sourceDocumentPath, 'sourceRevision': entry.sourceRevision, 'sourceSnapshotFingerprint': entry.sourceSnapshotFingerprint, 'previousRevision': entry.previousRevision, 'cleanBaselineRevision': entry.cleanBaselineRevision, 'previousAddedCount': entry.previousAddedCount, 'previousRemovedCount': entry.previousRemovedCount, 'previousChangedCount': entry.previousChangedCount, 'cleanBaselineAddedCount': entry.cleanBaselineAddedCount, 'cleanBaselineRemovedCount': entry.cleanBaselineRemovedCount, 'cleanBaselineChangedCount': entry.cleanBaselineChangedCount, 'problemCount': entry.problemCount})}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}
