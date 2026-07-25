import 'package:equatable/equatable.dart';

import '../../core/domain/evidence/source_evidence.dart';
import '../../core/domain/value_objects/registry_path.dart';

String _requiredText(String value, String fieldName) {
  final String normalized = value.trim();

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      fieldName,
      '$fieldName must not be empty.',
    );
  }

  return normalized;
}

List<T> _uniqueValues<T>(Iterable<T> values, String fieldName) {
  final List<T> result = <T>[];
  final Set<T> seen = <T>{};

  for (final T value in values) {
    if (!seen.add(value)) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName must not contain duplicate values.',
      );
    }

    result.add(value);
  }

  return List<T>.unmodifiable(result);
}

List<String> _normalizedUniqueStrings(
  Iterable<String> values,
  String fieldName,
) {
  final List<String> result = <String>[];
  final Set<String> seen = <String>{};

  for (final String value in values) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName must not contain empty values.',
      );
    }

    if (!seen.add(normalized)) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName must not contain duplicate values.',
      );
    }

    result.add(normalized);
  }

  return List<String>.unmodifiable(result);
}

List<SourceEvidence> _requiredEvidence(
  Iterable<SourceEvidence> evidence,
  String fieldName,
) {
  final List<SourceEvidence> normalized = evidence.toList(growable: false);

  if (normalized.isEmpty) {
    throw ArgumentError.value(
      evidence,
      fieldName,
      '$fieldName must preserve source evidence.',
    );
  }

  return List<SourceEvidence>.unmodifiable(normalized);
}

enum CanonicalContentRole {
  questions,
  photoQuestions,
  clientRules,
  masterRules,
}

final class CanonicalApplicability extends Equatable {
  factory CanonicalApplicability({
    Iterable<RegistryPath> registryPathPrefixes = const <RegistryPath>[],
    Iterable<String> businessScopeIdentities = const <String>[],
    Iterable<String> entityIdentities = const <String>[],
    Iterable<String> scenarioIdentities = const <String>[],
    Iterable<String> contentBlockIdentities = const <String>[],
    Iterable<CanonicalContentRole> contentBlockRoles =
        const <CanonicalContentRole>[],
  }) {
    return CanonicalApplicability._(
      registryPathPrefixes: _uniqueValues<RegistryPath>(
        registryPathPrefixes,
        'registryPathPrefixes',
      ),
      businessScopeIdentities: _normalizedUniqueStrings(
        businessScopeIdentities,
        'businessScopeIdentities',
      ),
      entityIdentities: _normalizedUniqueStrings(
        entityIdentities,
        'entityIdentities',
      ),
      scenarioIdentities: _normalizedUniqueStrings(
        scenarioIdentities,
        'scenarioIdentities',
      ),
      contentBlockIdentities: _normalizedUniqueStrings(
        contentBlockIdentities,
        'contentBlockIdentities',
      ),
      contentBlockRoles: _uniqueValues<CanonicalContentRole>(
        contentBlockRoles,
        'contentBlockRoles',
      ),
    );
  }

  const CanonicalApplicability._({
    required this.registryPathPrefixes,
    required this.businessScopeIdentities,
    required this.entityIdentities,
    required this.scenarioIdentities,
    required this.contentBlockIdentities,
    required this.contentBlockRoles,
  });

  final List<RegistryPath> registryPathPrefixes;
  final List<String> businessScopeIdentities;
  final List<String> entityIdentities;
  final List<String> scenarioIdentities;
  final List<String> contentBlockIdentities;
  final List<CanonicalContentRole> contentBlockRoles;

  bool get isUniversal =>
      registryPathPrefixes.isEmpty &&
      businessScopeIdentities.isEmpty &&
      entityIdentities.isEmpty &&
      scenarioIdentities.isEmpty &&
      contentBlockIdentities.isEmpty &&
      contentBlockRoles.isEmpty;

  @override
  List<Object?> get props => <Object?>[
    registryPathPrefixes,
    businessScopeIdentities,
    entityIdentities,
    scenarioIdentities,
    contentBlockIdentities,
    contentBlockRoles,
  ];
}

final class CanonicalDictionary extends Equatable {
  factory CanonicalDictionary({
    required String dictionaryId,
    required String version,
    required String status,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required int beginMarkerLine,
    required int endMarkerLine,
    required Iterable<CanonicalPhraseEntry> phrases,
    required Iterable<CanonicalApprovedEquivalent> approvedEquivalents,
    required Iterable<CanonicalOrderedBlock> orderedBlocks,
  }) {
    final String normalizedDictionaryId = _requiredText(
      dictionaryId,
      'dictionaryId',
    );
    final String normalizedVersion = _requiredText(version, 'version');
    final String normalizedStatus = _requiredText(status, 'status');
    final String normalizedDocumentPath = _requiredText(
      sourceDocumentPath,
      'sourceDocumentPath',
    );
    final String normalizedRevision = _requiredText(
      sourceRevision,
      'sourceRevision',
    );
    final String normalizedFingerprint = _requiredText(
      sourceSnapshotFingerprint,
      'sourceSnapshotFingerprint',
    );

    if (normalizedStatus != 'APPROVED / STORED') {
      throw ArgumentError.value(
        status,
        'status',
        'Canonical Dictionary must be approved and stored.',
      );
    }

    if (beginMarkerLine <= 0 || endMarkerLine <= beginMarkerLine) {
      throw ArgumentError(
        'Canonical Dictionary marker range must be positive and ordered.',
      );
    }

    final List<CanonicalPhraseEntry> normalizedPhrases = phrases.toList(
      growable: false,
    );
    final List<CanonicalApprovedEquivalent> normalizedEquivalents =
        approvedEquivalents.toList(growable: false);
    final List<CanonicalOrderedBlock> normalizedOrderedBlocks = orderedBlocks
        .toList(growable: false);

    final Set<String> identities = <String>{};
    final Map<String, CanonicalPhraseEntry> phrasesByIdentity =
        <String, CanonicalPhraseEntry>{};

    for (final CanonicalPhraseEntry phrase in normalizedPhrases) {
      _requireUniqueIdentity(identities, phrase.identity, 'phrases');
      phrasesByIdentity[phrase.identity] = phrase;

      _validateDictionaryEvidence(
        phrase.sourceEvidence,
        sourceDocumentPath: normalizedDocumentPath,
        sourceSnapshotFingerprint: normalizedFingerprint,
        beginMarkerLine: beginMarkerLine,
        endMarkerLine: endMarkerLine,
      );
    }

    for (final CanonicalApprovedEquivalent equivalent
        in normalizedEquivalents) {
      _requireUniqueIdentity(
        identities,
        equivalent.identity,
        'approvedEquivalents',
      );

      final CanonicalPhraseEntry? phrase =
          phrasesByIdentity[equivalent.canonicalEntryIdentity];

      if (phrase == null) {
        throw ArgumentError.value(
          equivalent.canonicalEntryIdentity,
          'approvedEquivalents',
          'Approved equivalent must reference an existing canonical phrase.',
        );
      }

      if (_normalizeComparableText(phrase.text) ==
          _normalizeComparableText(equivalent.equivalentText)) {
        throw ArgumentError(
          'Approved equivalent must differ from canonical phrase text.',
        );
      }

      _validateDictionaryEvidence(
        equivalent.sourceEvidence,
        sourceDocumentPath: normalizedDocumentPath,
        sourceSnapshotFingerprint: normalizedFingerprint,
        beginMarkerLine: beginMarkerLine,
        endMarkerLine: endMarkerLine,
      );
    }

    final Map<String, List<int>> blockOrdersByCollection =
        <String, List<int>>{};

    for (final CanonicalOrderedBlock block in normalizedOrderedBlocks) {
      _requireUniqueIdentity(identities, block.identity, 'orderedBlocks');

      blockOrdersByCollection
          .putIfAbsent(block.collectionId, () => <int>[])
          .add(block.approvedOrder);

      _validateDictionaryEvidence(
        block.sourceEvidence,
        sourceDocumentPath: normalizedDocumentPath,
        sourceSnapshotFingerprint: normalizedFingerprint,
        beginMarkerLine: beginMarkerLine,
        endMarkerLine: endMarkerLine,
      );

      for (final CanonicalOrderedBlockItem item in block.items) {
        _requireUniqueIdentity(identities, item.identity, 'orderedBlockItems');

        _validateDictionaryEvidence(
          item.sourceEvidence,
          sourceDocumentPath: normalizedDocumentPath,
          sourceSnapshotFingerprint: normalizedFingerprint,
          beginMarkerLine: beginMarkerLine,
          endMarkerLine: endMarkerLine,
        );
      }
    }

    for (final List<int> orders in blockOrdersByCollection.values) {
      orders.sort();

      for (int index = 0; index < orders.length; index += 1) {
        if (orders[index] != index + 1) {
          throw ArgumentError(
            'Canonical ordered-block order must be contiguous '
            'inside each collection.',
          );
        }
      }
    }

    return CanonicalDictionary._(
      dictionaryId: normalizedDictionaryId,
      version: normalizedVersion,
      status: normalizedStatus,
      sourceDocumentPath: normalizedDocumentPath,
      sourceRevision: normalizedRevision,
      sourceSnapshotFingerprint: normalizedFingerprint,
      beginMarkerLine: beginMarkerLine,
      endMarkerLine: endMarkerLine,
      phrases: List<CanonicalPhraseEntry>.unmodifiable(normalizedPhrases),
      approvedEquivalents: List<CanonicalApprovedEquivalent>.unmodifiable(
        normalizedEquivalents,
      ),
      orderedBlocks: List<CanonicalOrderedBlock>.unmodifiable(
        normalizedOrderedBlocks,
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
    required this.beginMarkerLine,
    required this.endMarkerLine,
    required this.phrases,
    required this.approvedEquivalents,
    required this.orderedBlocks,
  });

  final String dictionaryId;
  final String version;
  final String status;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;
  final int beginMarkerLine;
  final int endMarkerLine;
  final List<CanonicalPhraseEntry> phrases;
  final List<CanonicalApprovedEquivalent> approvedEquivalents;
  final List<CanonicalOrderedBlock> orderedBlocks;

  CanonicalPhraseEntry? phraseByIdentity(String identity) {
    final String normalizedIdentity = _requiredText(identity, 'identity');

    for (final CanonicalPhraseEntry phrase in phrases) {
      if (phrase.identity == normalizedIdentity) {
        return phrase;
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
    beginMarkerLine,
    endMarkerLine,
    phrases,
    approvedEquivalents,
    orderedBlocks,
  ];
}

final class CanonicalPhraseEntry extends Equatable {
  factory CanonicalPhraseEntry({
    required String identity,
    required String collectionId,
    required String text,
    required CanonicalApplicability applicability,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    return CanonicalPhraseEntry._(
      identity: _requiredText(identity, 'identity'),
      collectionId: _requiredText(collectionId, 'collectionId'),
      text: _requiredText(text, 'text'),
      applicability: applicability,
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalPhraseEntry._({
    required this.identity,
    required this.collectionId,
    required this.text,
    required this.applicability,
    required this.sourceEvidence,
  });

  final String identity;
  final String collectionId;
  final String text;
  final CanonicalApplicability applicability;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    collectionId,
    text,
    applicability,
    sourceEvidence,
  ];
}

final class CanonicalApprovedEquivalent extends Equatable {
  factory CanonicalApprovedEquivalent({
    required String identity,
    required String canonicalEntryIdentity,
    required String equivalentText,
    required CanonicalApplicability applicability,
    required String approvalEvidenceId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    return CanonicalApprovedEquivalent._(
      identity: _requiredText(identity, 'identity'),
      canonicalEntryIdentity: _requiredText(
        canonicalEntryIdentity,
        'canonicalEntryIdentity',
      ),
      equivalentText: _requiredText(equivalentText, 'equivalentText'),
      applicability: applicability,
      approvalEvidenceId: _requiredText(
        approvalEvidenceId,
        'approvalEvidenceId',
      ),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalApprovedEquivalent._({
    required this.identity,
    required this.canonicalEntryIdentity,
    required this.equivalentText,
    required this.applicability,
    required this.approvalEvidenceId,
    required this.sourceEvidence,
  });

  final String identity;
  final String canonicalEntryIdentity;
  final String equivalentText;
  final CanonicalApplicability applicability;
  final String approvalEvidenceId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    canonicalEntryIdentity,
    equivalentText,
    applicability,
    approvalEvidenceId,
    sourceEvidence,
  ];
}

final class CanonicalOrderedBlock extends Equatable {
  factory CanonicalOrderedBlock({
    required String identity,
    required String collectionId,
    required String stableBlockKey,
    required int approvedOrder,
    required String heading,
    required Iterable<CanonicalOrderedBlockItem> items,
    required CanonicalApplicability applicability,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    if (approvedOrder <= 0) {
      throw ArgumentError.value(
        approvedOrder,
        'approvedOrder',
        'approvedOrder must be positive.',
      );
    }

    final List<CanonicalOrderedBlockItem> normalizedItems = items.toList(
      growable: false,
    );

    if (normalizedItems.isEmpty) {
      throw ArgumentError.value(
        items,
        'items',
        'Canonical ordered block must contain items.',
      );
    }

    for (int index = 0; index < normalizedItems.length; index += 1) {
      if (normalizedItems[index].approvedOrder != index + 1) {
        throw ArgumentError(
          'Canonical ordered-block item order must be contiguous.',
        );
      }
    }

    return CanonicalOrderedBlock._(
      identity: _requiredText(identity, 'identity'),
      collectionId: _requiredText(collectionId, 'collectionId'),
      stableBlockKey: _requiredText(stableBlockKey, 'stableBlockKey'),
      approvedOrder: approvedOrder,
      heading: _requiredText(heading, 'heading'),
      items: List<CanonicalOrderedBlockItem>.unmodifiable(normalizedItems),
      applicability: applicability,
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalOrderedBlock._({
    required this.identity,
    required this.collectionId,
    required this.stableBlockKey,
    required this.approvedOrder,
    required this.heading,
    required this.items,
    required this.applicability,
    required this.sourceEvidence,
  });

  final String identity;
  final String collectionId;
  final String stableBlockKey;
  final int approvedOrder;
  final String heading;
  final List<CanonicalOrderedBlockItem> items;
  final CanonicalApplicability applicability;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    collectionId,
    stableBlockKey,
    approvedOrder,
    heading,
    items,
    applicability,
    sourceEvidence,
  ];
}

final class CanonicalOrderedBlockItem extends Equatable {
  factory CanonicalOrderedBlockItem({
    required String identity,
    required int approvedOrder,
    required String text,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    if (approvedOrder <= 0) {
      throw ArgumentError.value(
        approvedOrder,
        'approvedOrder',
        'approvedOrder must be positive.',
      );
    }

    return CanonicalOrderedBlockItem._(
      identity: _requiredText(identity, 'identity'),
      approvedOrder: approvedOrder,
      text: _requiredText(text, 'text'),
      sourceEvidence: _requiredEvidence(sourceEvidence, 'sourceEvidence'),
    );
  }

  const CanonicalOrderedBlockItem._({
    required this.identity,
    required this.approvedOrder,
    required this.text,
    required this.sourceEvidence,
  });

  final String identity;
  final int approvedOrder;
  final String text;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object?> get props => <Object?>[
    identity,
    approvedOrder,
    text,
    sourceEvidence,
  ];
}

void _requireUniqueIdentity(
  Set<String> identities,
  String identity,
  String fieldName,
) {
  if (!identities.add(identity)) {
    throw ArgumentError.value(
      identity,
      fieldName,
      'Canonical identity must be unique inside the dictionary.',
    );
  }
}

void _validateDictionaryEvidence(
  Iterable<SourceEvidence> evidence, {
  required String sourceDocumentPath,
  required String sourceSnapshotFingerprint,
  required int beginMarkerLine,
  required int endMarkerLine,
}) {
  final List<SourceEvidence> records = evidence.toList(growable: false);

  if (records.isEmpty) {
    throw ArgumentError('Canonical entry must preserve source evidence.');
  }

  for (final SourceEvidence record in records) {
    if (record.sourceDocumentPath != sourceDocumentPath ||
        record.sourceSnapshotFingerprint != sourceSnapshotFingerprint ||
        record.startLine < beginMarkerLine ||
        record.endLine > endMarkerLine) {
      throw ArgumentError.value(
        record,
        'sourceEvidence',
        'Canonical evidence must belong to the exact dictionary snapshot.',
      );
    }
  }
}

String _normalizeComparableText(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}
