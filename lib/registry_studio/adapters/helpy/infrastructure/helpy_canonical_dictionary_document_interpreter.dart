import '../../../canonical/domain/entities/canonical_dictionary.dart';
import '../../../canonical/domain/entities/canonical_dictionary_collection.dart';
import '../../../canonical/domain/entities/canonical_dictionary_entry.dart';
import '../../../canonical/domain/entities/canonical_phrase_entry.dart';

final class HelpyCanonicalDictionaryDocumentInterpreter {
  const HelpyCanonicalDictionaryDocumentInterpreter();

  static const String beginMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->';

  static const String endMarker =
      '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

  static const String approvedStoredStatus = 'APPROVED / STORED';

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

  static final RegExp _bulletPattern = RegExp(r'^-\s+(.+?)\s*$');

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
    );
  }

  List<CanonicalDictionaryEntry> _interpretCollectionEntries({
    required List<String> lines,
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
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      'phrase' => _interpretPhraseCollection(
        lines: lines,
        collectionId: collectionId,
        collectionStartIndex: collectionStartIndex,
        collectionEndIndex: collectionEndIndex,
        sourceDocumentPath: sourceDocumentPath,
        sourceRevision: sourceRevision,
        sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      ),
      _ => const <CanonicalDictionaryEntry>[],
    };
  }

  List<CanonicalDictionaryEntry> _interpretPhrasesWithApplicability({
    required List<String> lines,
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
          identity: _phraseIdentity(collectionId, phrase),
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
          identity: _phraseIdentity(collectionId, phrase),
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

  String _phraseIdentity(String collectionId, String phrase) {
    final String normalizedPhrase = phrase
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();

    return '$collectionId::phrase::$normalizedPhrase';
  }
}
