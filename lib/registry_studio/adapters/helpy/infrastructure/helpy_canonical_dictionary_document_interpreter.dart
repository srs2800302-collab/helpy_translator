import '../../../canonical/domain/entities/canonical_approved_equivalent_evidence.dart';
import '../../../canonical/domain/entities/canonical_dictionary.dart';
import '../../../canonical/domain/entities/canonical_dictionary_collection.dart';
import '../../../canonical/domain/entities/canonical_dictionary_entry.dart';
import '../../../canonical/domain/entities/canonical_ordered_block_entry.dart';
import '../../../canonical/domain/entities/canonical_ordered_block_item.dart';
import '../../../canonical/domain/entities/canonical_phrase_entry.dart';
import '../../../core/domain/evidence/source_evidence.dart';

final class HelpyCanonicalDictionaryDocumentInterpreter {
  const HelpyCanonicalDictionaryDocumentInterpreter();

  static const String beginMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->';

  static const String endMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

  static const String approvedStoredStatus = 'APPROVED / STORED';

  static const String approvedEquivalentBeginMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_APPROVED_EQUIVALENTS:BEGIN -->';

  static const String approvedEquivalentEndMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_APPROVED_EQUIVALENTS:END -->';

  static const String generalPreparationCollectionId =
      'helpy.canonical.general_preparation';

  static const String photoLabelsCollectionId = 'helpy.canonical.photo_labels';

  static const String clientLabelsCollectionId =
      'helpy.canonical.client_labels';

  static final RegExp _dictionaryIdPattern = RegExp(
    r'^Dictionary ID:\s*`([^`]+)`\s*$',
  );

  static final RegExp _dictionaryVersionPattern = RegExp(
    r'^(?:Версия словаря|Dictionary version):\s*`([^`]+)`\s*$',
  );

  static final RegExp _approvedStatusPattern = RegExp(
    r'^(?:Статус|Status):\s*\*\*([^*]+)\*\*\s*$',
  );

  static final RegExp _collectionPattern = RegExp(
    r'^### Collection:\s*`([^`]+)`\s*$',
  );

  static final RegExp _entryTypePattern = RegExp(
    r'^(?:Тип записи|Entry type):\s*`([^`]+)`\s*$',
  );

  static final RegExp _headingPattern = RegExp(r'^(#{1,6})\s+(.+?)\s*$');

  static final RegExp _stableBlockHeadingPattern = RegExp(
    r'^(.+?)\s*\(`([^`]+)`\)\s*$',
  );

  static final RegExp _bulletPattern = RegExp(r'^-\s+(.+?)\s*$');

  static final RegExp _approvedEquivalentHeadingPattern = RegExp(
    r'^### Approved equivalent:\s*`([^`]+)`\s*$',
  );

  CanonicalDictionary interpret({
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required String sourceContent,
  }) {
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Canonical Dictionary source document path must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Canonical Dictionary source revision must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Canonical Dictionary source fingerprint must not be empty.',
      );
    }

    if (sourceContent.trim().isEmpty) {
      throw ArgumentError.value(
        sourceContent,
        'sourceContent',
        'Canonical Dictionary source document must not be empty.',
      );
    }

    final List<String> lines = sourceContent
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    final List<int> beginMarkerIndexes = <int>[];
    final List<int> endMarkerIndexes = <int>[];

    for (int index = 0; index < lines.length; index += 1) {
      final String normalizedLine = lines[index].trim();

      if (normalizedLine == beginMarker) {
        beginMarkerIndexes.add(index);
      }

      if (normalizedLine == endMarker) {
        endMarkerIndexes.add(index);
      }
    }

    if (beginMarkerIndexes.length != 1) {
      throw FormatException(
        'Canonical Dictionary source must contain exactly one '
        'begin marker; found ${beginMarkerIndexes.length}.',
      );
    }

    if (endMarkerIndexes.length != 1) {
      throw FormatException(
        'Canonical Dictionary source must contain exactly one '
        'end marker; found ${endMarkerIndexes.length}.',
      );
    }

    final int beginMarkerIndex = beginMarkerIndexes.single;
    final int endMarkerIndex = endMarkerIndexes.single;

    if (endMarkerIndex <= beginMarkerIndex) {
      throw const FormatException(
        'Canonical Dictionary end marker must follow '
        'the begin marker.',
      );
    }

    final List<int> collectionIndexes = <int>[];
    final List<String> collectionIds = <String>[];

    for (int index = beginMarkerIndex + 1; index < endMarkerIndex; index += 1) {
      final RegExpMatch? collectionMatch = _collectionPattern.firstMatch(
        lines[index].trim(),
      );

      if (collectionMatch == null) {
        continue;
      }

      collectionIndexes.add(index);
      collectionIds.add(collectionMatch.group(1)!.trim());
    }

    if (collectionIndexes.isEmpty) {
      throw const FormatException(
        'Canonical Dictionary must contain at least one '
        'Collection identifier.',
      );
    }

    String? dictionaryId;
    String? dictionaryVersion;
    String? dictionaryStatus;

    int dictionaryIdCount = 0;
    int dictionaryVersionCount = 0;
    int dictionaryStatusCount = 0;

    final int dictionaryMetadataEndIndex = collectionIndexes.first;

    for (
      int index = beginMarkerIndex + 1;
      index < dictionaryMetadataEndIndex;
      index += 1
    ) {
      final String normalizedLine = lines[index].trim();

      final RegExpMatch? dictionaryIdMatch = _dictionaryIdPattern.firstMatch(
        normalizedLine,
      );

      if (dictionaryIdMatch != null) {
        dictionaryIdCount += 1;
        dictionaryId = dictionaryIdMatch.group(1)!.trim();
      }

      final RegExpMatch? dictionaryVersionMatch = _dictionaryVersionPattern
          .firstMatch(normalizedLine);

      if (dictionaryVersionMatch != null) {
        dictionaryVersionCount += 1;
        dictionaryVersion = dictionaryVersionMatch.group(1)!.trim();
      }

      final RegExpMatch? dictionaryStatusMatch = _approvedStatusPattern
          .firstMatch(normalizedLine);

      if (dictionaryStatusMatch != null) {
        dictionaryStatusCount += 1;
        dictionaryStatus = dictionaryStatusMatch.group(1)!.trim();
      }
    }

    if (dictionaryIdCount != 1 || dictionaryId == null) {
      throw FormatException(
        'Canonical Dictionary must contain exactly one '
        'Dictionary ID before the first collection; '
        'found $dictionaryIdCount.',
      );
    }

    if (dictionaryVersionCount != 1 || dictionaryVersion == null) {
      throw FormatException(
        'Canonical Dictionary must contain exactly one '
        'version before the first collection; '
        'found $dictionaryVersionCount.',
      );
    }

    if (dictionaryStatusCount != 1 || dictionaryStatus == null) {
      throw FormatException(
        'Canonical Dictionary must contain exactly one '
        'approved status before the first collection; '
        'found $dictionaryStatusCount.',
      );
    }

    if (dictionaryStatus != approvedStoredStatus) {
      throw FormatException(
        'Canonical Dictionary status must be '
        '$approvedStoredStatus, but was $dictionaryStatus.',
      );
    }

    final Set<String> uniqueCollectionIds = <String>{};

    final List<CanonicalDictionaryCollection> collections =
        <CanonicalDictionaryCollection>[];

    for (
      int collectionPosition = 0;
      collectionPosition < collectionIndexes.length;
      collectionPosition += 1
    ) {
      final int collectionStartIndex = collectionIndexes[collectionPosition];

      final int collectionEndIndex =
          collectionPosition + 1 < collectionIndexes.length
          ? collectionIndexes[collectionPosition + 1] - 1
          : endMarkerIndex - 1;

      final String collectionId = collectionIds[collectionPosition];

      if (collectionId.isEmpty) {
        throw FormatException(
          'Canonical Dictionary collection at line '
          '${collectionStartIndex + 1} has an empty identifier.',
        );
      }

      if (!uniqueCollectionIds.add(collectionId)) {
        throw FormatException(
          'Canonical Dictionary contains duplicate '
          'collection identifier $collectionId.',
        );
      }

      String? entryType;
      String? collectionStatus;

      int entryTypeCount = 0;
      int collectionStatusCount = 0;

      for (
        int index = collectionStartIndex + 1;
        index <= collectionEndIndex;
        index += 1
      ) {
        final String normalizedLine = lines[index].trim();

        final RegExpMatch? entryTypeMatch = _entryTypePattern.firstMatch(
          normalizedLine,
        );

        if (entryTypeMatch != null) {
          entryTypeCount += 1;
          entryType = entryTypeMatch.group(1)!.trim();
        }

        final RegExpMatch? collectionStatusMatch = _approvedStatusPattern
            .firstMatch(normalizedLine);

        if (collectionStatusMatch != null) {
          collectionStatusCount += 1;
          collectionStatus = collectionStatusMatch.group(1)!.trim();
        }
      }

      if (entryTypeCount != 1 || entryType == null) {
        throw FormatException(
          'Canonical Dictionary collection $collectionId '
          'must contain exactly one entry type; '
          'found $entryTypeCount.',
        );
      }

      if (collectionStatusCount != 1 || collectionStatus == null) {
        throw FormatException(
          'Canonical Dictionary collection $collectionId '
          'must contain exactly one approved status; '
          'found $collectionStatusCount.',
        );
      }

      if (collectionStatus != approvedStoredStatus) {
        throw FormatException(
          'Canonical Dictionary collection $collectionId '
          'status must be $approvedStoredStatus, '
          'but was $collectionStatus.',
        );
      }

      final String collectionContent = lines
          .sublist(collectionStartIndex + 1, collectionEndIndex + 1)
          .join('\n')
          .trim();

      if (collectionContent.isEmpty) {
        throw FormatException(
          'Canonical Dictionary collection $collectionId '
          'must not be empty.',
        );
      }

      final List<CanonicalDictionaryEntry> entries =
          _interpretCollectionEntries(
            lines: lines,
            dictionaryId: dictionaryId,
            collectionId: collectionId,
            entryType: entryType,
            collectionStartIndex: collectionStartIndex,
            collectionEndIndex: collectionEndIndex,
            sourceDocumentPath: normalizedSourceDocumentPath,
            sourceRevision: normalizedSourceRevision,
            sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
          );

      collections.add(
        CanonicalDictionaryCollection(
          id: collectionId,
          entryType: entryType,
          status: collectionStatus,
          content: collectionContent,
          startLine: collectionStartIndex + 1,
          endLine: collectionEndIndex + 1,
          entries: entries,
        ),
      );
    }

    final List<CanonicalApprovedEquivalentEvidence> approvedEquivalentEvidence =
        _interpretApprovedEquivalentEvidence(
          lines: lines,
          beginMarkerIndex: beginMarkerIndex,
          endMarkerIndex: endMarkerIndex,
          dictionaryMetadataEndIndex: dictionaryMetadataEndIndex,
          sourceDocumentPath: normalizedSourceDocumentPath,
          sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
        );

    return CanonicalDictionary(
      dictionaryId: dictionaryId,
      version: dictionaryVersion,
      status: dictionaryStatus,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceContent: sourceContent,
      beginMarkerLine: beginMarkerIndex + 1,
      endMarkerLine: endMarkerIndex + 1,
      collections: collections,
      approvedEquivalentEvidence: approvedEquivalentEvidence,
    );
  }

  List<CanonicalApprovedEquivalentEvidence>
  _interpretApprovedEquivalentEvidence({
    required List<String> lines,
    required int beginMarkerIndex,
    required int endMarkerIndex,
    required int dictionaryMetadataEndIndex,
    required String sourceDocumentPath,
    required String sourceSnapshotFingerprint,
  }) {
    final List<int> approvedBeginIndexes = <int>[];
    final List<int> approvedEndIndexes = <int>[];

    for (
      int index = beginMarkerIndex + 1;
      index < dictionaryMetadataEndIndex;
      index += 1
    ) {
      final String normalizedLine = lines[index].trim();

      if (normalizedLine == approvedEquivalentBeginMarker) {
        approvedBeginIndexes.add(index);
      }

      if (normalizedLine == approvedEquivalentEndMarker) {
        approvedEndIndexes.add(index);
      }
    }

    if (approvedBeginIndexes.isEmpty && approvedEndIndexes.isEmpty) {
      return const <CanonicalApprovedEquivalentEvidence>[];
    }

    if (approvedBeginIndexes.length != 1 || approvedEndIndexes.length != 1) {
      throw FormatException(
        'Canonical Dictionary approved-equivalent evidence must '
        'contain exactly one begin marker and one end marker.',
      );
    }

    final int approvedBeginIndex = approvedBeginIndexes.single;
    final int approvedEndIndex = approvedEndIndexes.single;

    if (approvedEndIndex <= approvedBeginIndex ||
        approvedEndIndex >= dictionaryMetadataEndIndex ||
        approvedEndIndex >= endMarkerIndex) {
      throw const FormatException(
        'Canonical Dictionary approved-equivalent evidence '
        'marker range is invalid.',
      );
    }

    final List<int> evidenceHeadingIndexes = <int>[];

    for (
      int index = approvedBeginIndex + 1;
      index < approvedEndIndex;
      index += 1
    ) {
      if (_approvedEquivalentHeadingPattern.hasMatch(lines[index].trim())) {
        evidenceHeadingIndexes.add(index);
      }
    }

    if (evidenceHeadingIndexes.isEmpty) {
      throw const FormatException(
        'Canonical Dictionary approved-equivalent evidence '
        'must contain at least one approved record.',
      );
    }

    String readSingleBacktickedValue({
      required String label,
      required int startIndex,
      required int endIndex,
    }) {
      final RegExp pattern = RegExp(
        '^${RegExp.escape(label)}:\\s*`([^`]+)`\\s*\$',
      );

      final List<String> values = <String>[];

      for (int index = startIndex; index <= endIndex; index += 1) {
        final RegExpMatch? match = pattern.firstMatch(lines[index].trim());

        if (match != null) {
          values.add(match.group(1)!.trim());
        }
      }

      if (values.length != 1 || values.single.isEmpty) {
        throw FormatException(
          'Approved-equivalent record must contain exactly one '
          '$label value.',
        );
      }

      return values.single;
    }

    final List<CanonicalApprovedEquivalentEvidence> evidence =
        <CanonicalApprovedEquivalentEvidence>[];

    for (
      int position = 0;
      position < evidenceHeadingIndexes.length;
      position += 1
    ) {
      final int recordStartIndex = evidenceHeadingIndexes[position];
      final int recordEndIndex = position + 1 < evidenceHeadingIndexes.length
          ? evidenceHeadingIndexes[position + 1] - 1
          : approvedEndIndex - 1;

      final RegExpMatch headingMatch = _approvedEquivalentHeadingPattern
          .firstMatch(lines[recordStartIndex].trim())!;

      final String identity = headingMatch.group(1)!.trim();

      final RegExp statusPattern = RegExp(
        r'^Approval status:\s*\*\*([^*]+)\*\*\s*$',
      );

      final List<String> statuses = <String>[];
      final List<String> applicability = <String>[];

      final RegExp applicabilityPattern = RegExp(
        r'^Applicability:\s*`([^`]+)`\s*$',
      );

      int lastEvidenceLineIndex = recordStartIndex;

      for (int index = recordStartIndex; index <= recordEndIndex; index += 1) {
        final String normalizedLine = lines[index].trim();

        if (normalizedLine.isNotEmpty) {
          lastEvidenceLineIndex = index;
        }

        final RegExpMatch? statusMatch = statusPattern.firstMatch(
          normalizedLine,
        );

        if (statusMatch != null) {
          statuses.add(statusMatch.group(1)!.trim());
        }

        final RegExpMatch? applicabilityMatch = applicabilityPattern.firstMatch(
          normalizedLine,
        );

        if (applicabilityMatch != null) {
          applicability.add(applicabilityMatch.group(1)!.trim());
        }
      }

      if (statuses.length != 1 || statuses.single != approvedStoredStatus) {
        throw FormatException(
          'Approved-equivalent record $identity must contain '
          'exactly one $approvedStoredStatus status.',
        );
      }

      if (applicability.isEmpty) {
        throw FormatException(
          'Approved-equivalent record $identity must contain '
          'explicit applicability.',
        );
      }

      evidence.add(
        CanonicalApprovedEquivalentEvidence(
          identity: identity,
          canonicalEntryIdentity: readSingleBacktickedValue(
            label: 'Canonical entry identity',
            startIndex: recordStartIndex,
            endIndex: recordEndIndex,
          ),
          equivalentText: readSingleBacktickedValue(
            label: 'Equivalent text',
            startIndex: recordStartIndex,
            endIndex: recordEndIndex,
          ),
          applicability: applicability,
          approvalEvidenceId: readSingleBacktickedValue(
            label: 'Approval evidence ID',
            startIndex: recordStartIndex,
            endIndex: recordEndIndex,
          ),
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: sourceDocumentPath,
              sourceSnapshotFingerprint: sourceSnapshotFingerprint,
              headingPath: const <String>[
                'Canonical Dictionary',
                'Approved equivalent evidence',
              ],
              startLine: recordStartIndex + 1,
              endLine: lastEvidenceLineIndex + 1,
            ),
          ],
        ),
      );
    }

    return evidence;
  }

  List<CanonicalDictionaryEntry> _interpretCollectionEntries({
    required List<String> lines,
    required String dictionaryId,
    required String collectionId,
    required String entryType,
    required int collectionStartIndex,
    required int collectionEndIndex,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
  }) {
    return switch (entryType) {
      'phrase_with_applicability' => _interpretPhrasesWithApplicability(
        lines: lines,
        dictionaryId: dictionaryId,
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      'phrase' => _interpretPhraseCollection(
        lines: lines,
        dictionaryId: dictionaryId,
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      'ordered_block' => _interpretOrderedBlockCollection(
        lines: lines,
        dictionaryId: dictionaryId,
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      'ordered_rule_block' => _interpretOrderedBlockCollection(
        lines: lines,
        dictionaryId: dictionaryId,
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      _ => throw FormatException(
        'Canonical Dictionary collection $collectionId '
        'has unsupported entry type $entryType.',
      ),
    };
  }

  List<CanonicalDictionaryEntry> _interpretPhrasesWithApplicability({
    required List<String> lines,
    required String dictionaryId,
    required String collectionId,
    required int collectionStartIndex,
    required int collectionEndIndex,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
  }) {
    const String entriesMarker =
        'Правила применения утверждённых формулировок:';

    final List<int> markerIndexes = <int>[];

    for (
      int index = collectionStartIndex + 1;
      index <= collectionEndIndex;
      index += 1
    ) {
      if (lines[index].trim() == entriesMarker) {
        markerIndexes.add(index);
      }
    }

    if (markerIndexes.length != 1) {
      throw FormatException(
        'Canonical phrase-with-applicability collection '
        '$collectionId must contain exactly one entries marker; '
        'found ${markerIndexes.length}.',
      );
    }

    final List<CanonicalDictionaryEntry> entries = <CanonicalDictionaryEntry>[];

    int index = markerIndexes.single + 1;

    while (index <= collectionEndIndex) {
      final String normalizedLine = lines[index].trim();

      if (normalizedLine.isEmpty) {
        index += 1;
        continue;
      }

      if (normalizedLine.startsWith('- ')) {
        throw FormatException(
          'Canonical phrase-with-applicability collection '
          '$collectionId contains applicability without a phrase '
          'at line ${index + 1}.',
        );
      }

      if (normalizedLine.startsWith('#')) {
        throw FormatException(
          'Canonical phrase-with-applicability collection '
          '$collectionId contains an unexpected heading '
          'at line ${index + 1}.',
        );
      }

      final String phrase = normalizedLine;
      final int phraseLineIndex = index;
      final List<String> applicability = <String>[];

      index += 1;

      int sourceEndIndex = phraseLineIndex;

      while (index <= collectionEndIndex) {
        final String candidate = lines[index].trim();

        if (candidate.isEmpty) {
          index += 1;
          continue;
        }

        final RegExpMatch? bulletMatch = _bulletPattern.firstMatch(candidate);

        if (bulletMatch == null) {
          break;
        }

        applicability.add(bulletMatch.group(1)!.trim());

        sourceEndIndex = index;
        index += 1;
      }

      if (applicability.isEmpty) {
        throw FormatException(
          'Canonical phrase $phrase in collection '
          '$collectionId must contain applicability.',
        );
      }

      entries.add(
        CanonicalPhraseEntry(
          dictionaryId: dictionaryId,
          collectionId: collectionId,
          phrase: phrase,
          applicability: applicability,
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: sourceRevision,
          sourceSnapshotFingerprint: sourceSnapshotFingerprint,
          sourceStartLine: phraseLineIndex + 1,
          sourceEndLine: sourceEndIndex + 1,
        ),
      );
    }

    if (entries.isEmpty) {
      throw FormatException(
        'Canonical phrase-with-applicability collection '
        '$collectionId must contain at least one phrase.',
      );
    }

    return entries;
  }

  List<CanonicalDictionaryEntry> _interpretPhraseCollection({
    required List<String> lines,
    required String dictionaryId,
    required String collectionId,
    required int collectionStartIndex,
    required int collectionEndIndex,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
  }) {
    int phraseStartIndex = collectionStartIndex + 1;
    int phraseEndIndex = collectionEndIndex;

    if (collectionId == clientLabelsCollectionId) {
      const String startMarker = 'Утверждённые формулировки:';

      const String endMarker = 'Требования к новым формулировкам:';

      final List<int> startMarkerIndexes = <int>[];
      final List<int> endMarkerIndexes = <int>[];

      for (
        int index = collectionStartIndex + 1;
        index <= collectionEndIndex;
        index += 1
      ) {
        final String normalizedLine = lines[index].trim();

        if (normalizedLine == startMarker) {
          startMarkerIndexes.add(index);
        }

        if (normalizedLine == endMarker) {
          endMarkerIndexes.add(index);
        }
      }

      if (startMarkerIndexes.length != 1) {
        throw FormatException(
          'Canonical client-label collection must contain '
          'exactly one approved-phrases marker; '
          'found ${startMarkerIndexes.length}.',
        );
      }

      if (endMarkerIndexes.length != 1) {
        throw FormatException(
          'Canonical client-label collection must contain '
          'exactly one requirements marker; '
          'found ${endMarkerIndexes.length}.',
        );
      }

      phraseStartIndex = startMarkerIndexes.single + 1;
      phraseEndIndex = endMarkerIndexes.single - 1;

      if (phraseEndIndex < phraseStartIndex) {
        throw const FormatException(
          'Canonical client-label phrase range is invalid.',
        );
      }
    }

    final List<CanonicalDictionaryEntry> entries = <CanonicalDictionaryEntry>[];

    for (int index = phraseStartIndex; index <= phraseEndIndex; index += 1) {
      final RegExpMatch? bulletMatch = _bulletPattern.firstMatch(
        lines[index].trim(),
      );

      if (bulletMatch == null) {
        continue;
      }

      final String phrase = bulletMatch.group(1)!.trim();

      entries.add(
        CanonicalPhraseEntry(
          dictionaryId: dictionaryId,
          collectionId: collectionId,
          phrase: phrase,
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: sourceRevision,
          sourceSnapshotFingerprint: sourceSnapshotFingerprint,
          sourceStartLine: index + 1,
          sourceEndLine: index + 1,
        ),
      );
    }

    if (entries.isEmpty) {
      throw FormatException(
        'Canonical phrase collection $collectionId '
        'must contain at least one approved phrase.',
      );
    }

    return entries;
  }

  List<CanonicalDictionaryEntry> _interpretOrderedBlockCollection({
    required List<String> lines,
    required String dictionaryId,
    required String collectionId,
    required int collectionStartIndex,
    required int collectionEndIndex,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
  }) {
    final List<({int index, int level})> headings =
        <({int index, int level})>[];

    final List<({int index, int level, String text, String stableBlockKey})>
    keyedHeadings =
        <({int index, int level, String text, String stableBlockKey})>[];

    for (
      int index = collectionStartIndex + 1;
      index <= collectionEndIndex;
      index += 1
    ) {
      final RegExpMatch? headingMatch = _headingPattern.firstMatch(
        lines[index].trim(),
      );

      if (headingMatch == null) {
        continue;
      }

      final int headingLevel = headingMatch.group(1)!.length;
      final String headingText = headingMatch.group(2)!.trim();

      headings.add((index: index, level: headingLevel));

      final RegExpMatch? stableBlockHeadingMatch = _stableBlockHeadingPattern
          .firstMatch(headingText);

      if (stableBlockHeadingMatch == null) {
        continue;
      }

      final String approvedHeading = stableBlockHeadingMatch.group(1)!.trim();

      final String stableBlockKey = stableBlockHeadingMatch.group(2)!.trim();

      if (approvedHeading.isEmpty) {
        throw FormatException(
          'Canonical ordered collection $collectionId '
          'contains an empty approved heading '
          'at line ${index + 1}.',
        );
      }

      if (stableBlockKey.isEmpty) {
        throw FormatException(
          'Canonical ordered collection $collectionId '
          'contains an empty stable block key '
          'at line ${index + 1}.',
        );
      }

      keyedHeadings.add((
        index: index,
        level: headingLevel,
        text: approvedHeading,
        stableBlockKey: stableBlockKey,
      ));
    }

    if (keyedHeadings.isEmpty) {
      throw FormatException(
        'Canonical ordered collection $collectionId '
        'must contain stable-key headings.',
      );
    }

    final List<({int index, int level, String text, String stableBlockKey})>
    terminalHeadings =
        <({int index, int level, String text, String stableBlockKey})>[];

    for (final heading in keyedHeadings) {
      int subtreeBoundaryIndex = collectionEndIndex + 1;

      for (final candidate in headings) {
        if (candidate.index <= heading.index) {
          continue;
        }

        if (candidate.level <= heading.level) {
          subtreeBoundaryIndex = candidate.index;
          break;
        }
      }

      final bool hasKeyedDescendant = keyedHeadings.any(
        (candidate) =>
            candidate.index > heading.index &&
            candidate.index < subtreeBoundaryIndex &&
            candidate.level > heading.level,
      );

      if (!hasKeyedDescendant) {
        terminalHeadings.add(heading);
      }
    }

    if (terminalHeadings.isEmpty) {
      throw FormatException(
        'Canonical ordered collection $collectionId '
        'contains no terminal ordered blocks.',
      );
    }

    final Set<String> stableBlockKeys = <String>{};
    final List<CanonicalDictionaryEntry> entries = <CanonicalDictionaryEntry>[];

    for (final heading in terminalHeadings) {
      if (!stableBlockKeys.add(heading.stableBlockKey)) {
        throw FormatException(
          'Canonical ordered collection $collectionId '
          'contains duplicate stable block key '
          '${heading.stableBlockKey}.',
        );
      }

      int terminalBoundaryIndex = collectionEndIndex + 1;

      for (final candidate in headings) {
        if (candidate.index <= heading.index) {
          continue;
        }

        if (candidate.level <= heading.level) {
          terminalBoundaryIndex = candidate.index;
          break;
        }
      }

      final List<CanonicalOrderedBlockItem> items =
          <CanonicalOrderedBlockItem>[];

      for (
        int index = heading.index + 1;
        index < terminalBoundaryIndex;
        index += 1
      ) {
        final String normalizedLine = lines[index].trim();

        if (normalizedLine.isEmpty) {
          continue;
        }

        final RegExpMatch? bulletMatch = _bulletPattern.firstMatch(
          normalizedLine,
        );

        final String itemText = (bulletMatch?.group(1) ?? normalizedLine)
            .trim();

        if (itemText.isEmpty) {
          continue;
        }

        items.add(
          CanonicalOrderedBlockItem(
            approvedOrder: items.length + 1,
            text: itemText,
            sourceStartLine: index + 1,
            sourceEndLine: index + 1,
          ),
        );
      }

      if (items.isEmpty) {
        throw FormatException(
          'Canonical ordered block ${heading.stableBlockKey} '
          'in collection $collectionId '
          'must contain at least one ordered item.',
        );
      }

      final String approvedHeading = heading.text;

      if (approvedHeading.isEmpty) {
        throw FormatException(
          'Canonical ordered block ${heading.stableBlockKey} '
          'in collection $collectionId '
          'must contain an approved heading.',
        );
      }

      entries.add(
        CanonicalOrderedBlockEntry(
          dictionaryId: dictionaryId,
          collectionId: collectionId,
          stableBlockKey: heading.stableBlockKey,
          approvedOrder: entries.length + 1,
          heading: approvedHeading,
          items: items,
          sourceDocumentPath: sourceDocumentPath,
          sourceRevision: sourceRevision,
          sourceSnapshotFingerprint: sourceSnapshotFingerprint,
          sourceStartLine: heading.index + 1,
          sourceEndLine: items.last.sourceEndLine,
        ),
      );
    }

    return entries;
  }
}
