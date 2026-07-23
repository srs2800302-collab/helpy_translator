import 'package:equatable/equatable.dart';

import 'canonical_dictionary_collection.dart';

final class CanonicalDictionary extends Equatable {
  factory CanonicalDictionary({
    required String dictionaryId,
    required String version,
    required String status,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required String sourceContent,
    required int beginMarkerLine,
    required int endMarkerLine,
    required Iterable<CanonicalDictionaryCollection> collections,
  }) {
    final String normalizedDictionaryId = dictionaryId.trim();
    final String normalizedVersion = version.trim();
    final String normalizedStatus = status.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();
    final List<CanonicalDictionaryCollection> normalizedCollections =
        collections.toList(growable: false);

    if (normalizedDictionaryId.isEmpty) {
      throw ArgumentError.value(
        dictionaryId,
        'dictionaryId',
        'Canonical Dictionary identifier must not be empty.',
      );
    }

    if (normalizedVersion.isEmpty) {
      throw ArgumentError.value(
        version,
        'version',
        'Canonical Dictionary version must not be empty.',
      );
    }

    if (normalizedStatus.isEmpty) {
      throw ArgumentError.value(
        status,
        'status',
        'Canonical Dictionary status must not be empty.',
      );
    }

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
        'Canonical Dictionary source content must not be empty.',
      );
    }

    if (beginMarkerLine < 1) {
      throw ArgumentError.value(
        beginMarkerLine,
        'beginMarkerLine',
        'Canonical Dictionary begin marker line must be positive.',
      );
    }

    if (endMarkerLine <= beginMarkerLine) {
      throw ArgumentError.value(
        endMarkerLine,
        'endMarkerLine',
        'Canonical Dictionary end marker must follow the begin marker.',
      );
    }

    if (normalizedCollections.isEmpty) {
      throw ArgumentError.value(
        collections,
        'collections',
        'Canonical Dictionary must contain at least one approved collection.',
      );
    }

    final Set<String> collectionIds = <String>{};

    for (final CanonicalDictionaryCollection collection
        in normalizedCollections) {
      if (!collectionIds.add(collection.id)) {
        throw ArgumentError.value(
          collection.id,
          'collections',
          'Canonical Dictionary collection identifiers must be unique.',
        );
      }

      for (final entry in collection.entries) {
        if (entry.dictionaryId != normalizedDictionaryId) {
          throw ArgumentError.value(
            entry,
            'collections',
            'Canonical Dictionary entry must belong to its dictionary.',
          );
        }
      }

      if (collection.startLine <= beginMarkerLine ||
          collection.endLine >= endMarkerLine) {
        throw ArgumentError.value(
          collection,
          'collections',
          'Canonical Dictionary collections must be located strictly between '
              'the stable markers.',
        );
      }
    }

    return CanonicalDictionary._(
      dictionaryId: normalizedDictionaryId,
      version: normalizedVersion,
      status: normalizedStatus,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceContent: sourceContent,
      beginMarkerLine: beginMarkerLine,
      endMarkerLine: endMarkerLine,
      collections: List<CanonicalDictionaryCollection>.unmodifiable(
        normalizedCollections,
      ),
    );
  }

  const CanonicalDictionary._({
    required this.dictionaryId,
    required this.version,
    required this.status,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required this.sourceContent,
    required this.beginMarkerLine,
    required this.endMarkerLine,
    required this.collections,
  });

  final String dictionaryId;
  final String version;
  final String status;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final String sourceContent;
  final int beginMarkerLine;
  final int endMarkerLine;
  final List<CanonicalDictionaryCollection> collections;

  CanonicalDictionaryCollection? collectionById(String collectionId) {
    final String normalizedCollectionId = collectionId.trim();

    for (final CanonicalDictionaryCollection collection in collections) {
      if (collection.id == normalizedCollectionId) {
        return collection;
      }
    }

    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    dictionaryId,
    version,
    status,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    sourceContent,
    beginMarkerLine,
    endMarkerLine,
    collections,
  ];
}
