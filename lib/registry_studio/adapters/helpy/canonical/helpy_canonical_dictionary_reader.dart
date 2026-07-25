import 'dart:convert';

import '../../../canonical/domain/canonical_analysis_package.dart';
import '../../../canonical/domain/canonical_dictionary.dart';
import '../../../core/domain/evidence/source_evidence.dart';

final class HelpyCanonicalDictionaryReader {
  const HelpyCanonicalDictionaryReader();

  static const String beginMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->';
  static const String endMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';
  static const String expectedDictionaryId =
      'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1';
  static const String expectedVersion = '1';
  static const String expectedStatus = 'APPROVED / STORED';

  ({CanonicalDictionary? dictionary, List<CanonicalAdapterFailure> failures})
  read({
    required String sourceContent,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
  }) {
    final List<String> lines = const LineSplitter().convert(sourceContent);
    final List<int> beginLines = <int>[];
    final List<int> endLines = <int>[];

    for (int index = 0; index < lines.length; index += 1) {
      final String trimmed = lines[index].trim();

      if (trimmed == beginMarker) {
        beginLines.add(index + 1);
      }

      if (trimmed == endMarker) {
        endLines.add(index + 1);
      }
    }

    if (beginLines.length != 1 || endLines.length != 1) {
      return (
        dictionary: null,
        failures: <CanonicalAdapterFailure>[
          _fatalFailure(
            code: 'dictionary_marker_count_invalid',
            explanation:
                'В контракте должен существовать ровно один BEGIN и один '
                'END-маркер Canonical Dictionary.',
          ),
        ],
      );
    }

    final int beginLine = beginLines.single;
    final int endLine = endLines.single;

    if (endLine <= beginLine) {
      return (
        dictionary: null,
        failures: <CanonicalAdapterFailure>[
          _fatalFailure(
            code: 'dictionary_marker_order_invalid',
            explanation:
                'END-маркер Canonical Dictionary расположен раньше '
                'BEGIN-маркера.',
          ),
        ],
      );
    }

    final List<String> headingPath = _headingPathAtLine(lines, beginLine);
    final SourceEvidence dictionaryEvidence = SourceEvidence(
      sourceDocumentPath: sourceDocumentPath,
      sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      headingPath: headingPath,
      startLine: beginLine,
      endLine: endLine,
    );

    final String? dictionaryId = _metadataValue(
      lines,
      beginLine: beginLine,
      endLine: endLine,
      key: 'Dictionary ID',
    );
    final String? version = _metadataValue(
      lines,
      beginLine: beginLine,
      endLine: endLine,
      key: 'Dictionary version',
    );
    final String? status = _metadataValue(
      lines,
      beginLine: beginLine,
      endLine: endLine,
      key: 'Status',
    );

    final List<CanonicalAdapterFailure> failures = <CanonicalAdapterFailure>[];

    if (dictionaryId != expectedDictionaryId) {
      failures.add(
        _fatalFailure(
          code: 'dictionary_id_invalid',
          explanation:
              'Dictionary ID отсутствует или не соответствует '
              'утверждённой identity.',
          sourceEvidence: <SourceEvidence>[dictionaryEvidence],
        ),
      );
    }

    if (version != expectedVersion) {
      failures.add(
        _fatalFailure(
          code: 'dictionary_version_unsupported',
          explanation:
              'Версия Canonical Dictionary отсутствует или не '
              'поддерживается текущим adapter.',
          sourceEvidence: <SourceEvidence>[dictionaryEvidence],
        ),
      );
    }

    if (status != expectedStatus) {
      failures.add(
        _fatalFailure(
          code: 'dictionary_status_invalid',
          explanation:
              'Canonical Dictionary не имеет обязательный статус '
              'APPROVED / STORED.',
          sourceEvidence: <SourceEvidence>[dictionaryEvidence],
        ),
      );
    }

    if (failures.isNotEmpty) {
      return (
        dictionary: null,
        failures: List<CanonicalAdapterFailure>.unmodifiable(failures),
      );
    }

    return (
      dictionary: CanonicalDictionary(
        dictionaryId: dictionaryId!,
        version: version!,
        status: status!,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
        beginMarkerLine: beginLine,
        endMarkerLine: endLine,
        phrases: const <CanonicalPhraseEntry>[],
        approvedEquivalents: const <CanonicalApprovedEquivalent>[],
        orderedBlocks: const <CanonicalOrderedBlock>[],
      ),
      failures: const <CanonicalAdapterFailure>[],
    );
  }

  CanonicalAdapterFailure _fatalFailure({
    required String code,
    required String explanation,
    Iterable<SourceEvidence> sourceEvidence = const <SourceEvidence>[],
  }) {
    return CanonicalAdapterFailure(
      identity: 'helpy.canonical.dictionary.failure.$code',
      source: CanonicalAdapterFailureSource.dictionary,
      severity: CanonicalAdapterFailureSeverity.fatal,
      code: code,
      explanation: explanation,
      relatedIdentity: null,
      path: null,
      sourceEvidence: sourceEvidence,
    );
  }

  String? _metadataValue(
    List<String> lines, {
    required int beginLine,
    required int endLine,
    required String key,
  }) {
    final String prefix = '$key:';

    for (
      int lineNumber = beginLine + 1;
      lineNumber < endLine;
      lineNumber += 1
    ) {
      final String trimmed = lines[lineNumber - 1].trim();

      if (!trimmed.toLowerCase().startsWith(prefix.toLowerCase())) {
        continue;
      }

      final String value = trimmed
          .substring(prefix.length)
          .replaceAll('`', '')
          .replaceAll('**', '')
          .trim();

      return value.isEmpty ? null : value;
    }

    return null;
  }

  List<String> _headingPathAtLine(List<String> lines, int targetLine) {
    final RegExp headingPattern = RegExp(r'^ {0,3}(#{1,6})\s+(.+?)\s*$');
    final List<({int level, String title})> active =
        <({int level, String title})>[];

    for (int lineNumber = 1; lineNumber <= targetLine; lineNumber += 1) {
      final RegExpMatch? match = headingPattern.firstMatch(
        lines[lineNumber - 1],
      );

      if (match == null) {
        continue;
      }

      final int level = match.group(1)!.length;
      final String title = match.group(2)!.trim();

      while (active.isNotEmpty && active.last.level >= level) {
        active.removeLast();
      }

      active.add((level: level, title: title));
    }

    if (active.isEmpty) {
      return const <String>['Registry Studio Contract'];
    }

    return List<String>.unmodifiable(
      active.map((({int level, String title}) item) => item.title),
    );
  }
}
