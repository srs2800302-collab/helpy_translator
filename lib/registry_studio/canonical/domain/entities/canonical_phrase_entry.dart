import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'canonical_dictionary_entry.dart';

final class CanonicalPhraseEntry extends CanonicalDictionaryEntry {
  factory CanonicalPhraseEntry({
    required String dictionaryId,
    required String collectionId,
    required String phrase,
    Iterable<String> applicability = const <String>[],
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required int sourceStartLine,
    required int sourceEndLine,
  }) {
    final String normalizedDictionaryId = dictionaryId.trim();
    final String normalizedCollectionId = collectionId.trim();
    final String normalizedPhrase = phrase.trim();
    final String technicallyNormalizedPhrase = normalizedPhrase.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();

    final List<String> normalizedApplicability = applicability
        .map((String value) => value.trim())
        .toList(growable: false);

    if (normalizedDictionaryId.isEmpty) {
      throw ArgumentError.value(
        dictionaryId,
        'dictionaryId',
        'Canonical phrase dictionary identity must not be empty.',
      );
    }

    if (normalizedCollectionId.isEmpty) {
      throw ArgumentError.value(
        collectionId,
        'collectionId',
        'Canonical phrase collection identity must not be empty.',
      );
    }

    if (normalizedPhrase.isEmpty) {
      throw ArgumentError.value(
        phrase,
        'phrase',
        'Canonical phrase must not be empty.',
      );
    }

    if (normalizedApplicability.any((String value) => value.isEmpty)) {
      throw ArgumentError.value(
        applicability,
        'applicability',
        'Canonical phrase applicability values must not be empty.',
      );
    }

    if (normalizedApplicability.toSet().length !=
        normalizedApplicability.length) {
      throw ArgumentError.value(
        applicability,
        'applicability',
        'Canonical phrase applicability values must be unique.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Canonical phrase source document path must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Canonical phrase source revision must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Canonical phrase source fingerprint must not be empty.',
      );
    }

    if (sourceStartLine < 1) {
      throw ArgumentError.value(
        sourceStartLine,
        'sourceStartLine',
        'Canonical phrase source start line must be positive.',
      );
    }

    if (sourceEndLine < sourceStartLine) {
      throw ArgumentError.value(
        sourceEndLine,
        'sourceEndLine',
        'Canonical phrase source end line must not precede '
            'its start line.',
      );
    }

    final String approvedTextHash =
        'sha256:${sha256.convert(utf8.encode(technicallyNormalizedPhrase))}';

    final String identity =
        '$normalizedDictionaryId::'
        '$normalizedCollectionId::'
        '$approvedTextHash';

    return CanonicalPhraseEntry._(
      identity: identity,
      dictionaryId: normalizedDictionaryId,
      collectionId: normalizedCollectionId,
      approvedTextHash: approvedTextHash,
      phrase: normalizedPhrase,
      applicability: List<String>.unmodifiable(normalizedApplicability),
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      sourceStartLine: sourceStartLine,
      sourceEndLine: sourceEndLine,
    );
  }

  const CanonicalPhraseEntry._({
    required super.identity,
    required super.dictionaryId,
    required super.collectionId,
    required super.approvedTextHash,
    required this.phrase,
    required this.applicability,
    required super.sourceDocumentPath,
    required super.sourceRevision,
    required super.sourceSnapshotFingerprint,
    required super.sourceStartLine,
    required super.sourceEndLine,
  });

  final String phrase;
  final List<String> applicability;

  @override
  List<Object?> get props => <Object?>[
    identity,
    dictionaryId,
    collectionId,
    approvedTextHash,
    phrase,
    applicability,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    sourceStartLine,
    sourceEndLine,
  ];
}
