import 'package:equatable/equatable.dart';

import 'canonical_business_text_classification.dart';
import 'canonical_business_text_classification_status.dart';

final class CanonicalBusinessTextClassificationIndex extends Equatable {
  factory CanonicalBusinessTextClassificationIndex({
    required String projectId,
    required String candidateSourceDocumentPath,
    required String candidateSourceRevision,
    required String candidateSourceSnapshotFingerprint,
    required String dictionaryId,
    required String dictionaryVersion,
    required String dictionarySourceRevision,
    required String dictionarySourceSnapshotFingerprint,
    required Iterable<CanonicalBusinessTextClassification> classifications,
  }) {
    final String normalizedProjectId = projectId.trim();

    final String normalizedCandidateSourceDocumentPath =
        candidateSourceDocumentPath.trim();

    final String normalizedCandidateSourceRevision = candidateSourceRevision
        .trim();

    final String normalizedCandidateSourceSnapshotFingerprint =
        candidateSourceSnapshotFingerprint.trim();

    final String normalizedDictionaryId = dictionaryId.trim();
    final String normalizedDictionaryVersion = dictionaryVersion.trim();

    final String normalizedDictionarySourceRevision = dictionarySourceRevision
        .trim();

    final String normalizedDictionarySourceSnapshotFingerprint =
        dictionarySourceSnapshotFingerprint.trim();

    final List<CanonicalBusinessTextClassification> normalizedClassifications =
        classifications.toList(growable: false);

    final Map<String, CanonicalBusinessTextClassification>
    classificationsByCandidateIdentity =
        <String, CanonicalBusinessTextClassification>{};

    final Map<
      CanonicalBusinessTextClassificationStatus,
      List<CanonicalBusinessTextClassification>
    >
    classificationsByStatus =
        <
          CanonicalBusinessTextClassificationStatus,
          List<CanonicalBusinessTextClassification>
        >{
          for (final CanonicalBusinessTextClassificationStatus status
              in CanonicalBusinessTextClassificationStatus.values)
            status: <CanonicalBusinessTextClassification>[],
        };

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'Canonical classification project identifier '
            'must not be empty.',
      );
    }

    if (normalizedCandidateSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        candidateSourceDocumentPath,
        'candidateSourceDocumentPath',
        'Canonical classification candidate source document '
            'must not be empty.',
      );
    }

    if (normalizedCandidateSourceRevision.isEmpty) {
      throw ArgumentError.value(
        candidateSourceRevision,
        'candidateSourceRevision',
        'Canonical classification candidate source revision '
            'must not be empty.',
      );
    }

    if (normalizedCandidateSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        candidateSourceSnapshotFingerprint,
        'candidateSourceSnapshotFingerprint',
        'Canonical classification candidate source '
            'fingerprint must not be empty.',
      );
    }

    if (normalizedDictionaryId.isEmpty) {
      throw ArgumentError.value(
        dictionaryId,
        'dictionaryId',
        'Canonical classification dictionary identifier '
            'must not be empty.',
      );
    }

    if (normalizedDictionaryVersion.isEmpty) {
      throw ArgumentError.value(
        dictionaryVersion,
        'dictionaryVersion',
        'Canonical classification dictionary version '
            'must not be empty.',
      );
    }

    if (normalizedDictionarySourceRevision.isEmpty) {
      throw ArgumentError.value(
        dictionarySourceRevision,
        'dictionarySourceRevision',
        'Canonical classification dictionary source '
            'revision must not be empty.',
      );
    }

    if (normalizedDictionarySourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        dictionarySourceSnapshotFingerprint,
        'dictionarySourceSnapshotFingerprint',
        'Canonical classification dictionary source '
            'fingerprint must not be empty.',
      );
    }

    for (final CanonicalBusinessTextClassification classification
        in normalizedClassifications) {
      final String candidateIdentity = classification.candidate.identity;

      if (classificationsByCandidateIdentity.containsKey(candidateIdentity)) {
        throw ArgumentError.value(
          candidateIdentity,
          'classifications',
          'Each canonical business-text candidate must '
              'have exactly one classification.',
        );
      }

      classificationsByCandidateIdentity[candidateIdentity] = classification;

      classificationsByStatus[classification.status]!.add(classification);
    }

    return CanonicalBusinessTextClassificationIndex._(
      projectId: normalizedProjectId,
      candidateSourceDocumentPath: normalizedCandidateSourceDocumentPath,
      candidateSourceRevision: normalizedCandidateSourceRevision,
      candidateSourceSnapshotFingerprint:
          normalizedCandidateSourceSnapshotFingerprint,
      dictionaryId: normalizedDictionaryId,
      dictionaryVersion: normalizedDictionaryVersion,
      dictionarySourceRevision: normalizedDictionarySourceRevision,
      dictionarySourceSnapshotFingerprint:
          normalizedDictionarySourceSnapshotFingerprint,
      classifications: List<CanonicalBusinessTextClassification>.unmodifiable(
        normalizedClassifications,
      ),
      classificationsByCandidateIdentity:
          Map<String, CanonicalBusinessTextClassification>.unmodifiable(
            classificationsByCandidateIdentity,
          ),
      classificationsByStatus:
          Map<
            CanonicalBusinessTextClassificationStatus,
            List<CanonicalBusinessTextClassification>
          >.unmodifiable(<
            CanonicalBusinessTextClassificationStatus,
            List<CanonicalBusinessTextClassification>
          >{
            for (final entry in classificationsByStatus.entries)
              entry.key: List<CanonicalBusinessTextClassification>.unmodifiable(
                entry.value,
              ),
          }),
    );
  }

  const CanonicalBusinessTextClassificationIndex._({
    required this.projectId,
    required this.candidateSourceDocumentPath,
    required this.candidateSourceRevision,
    required this.candidateSourceSnapshotFingerprint,
    required this.dictionaryId,
    required this.dictionaryVersion,
    required this.dictionarySourceRevision,
    required this.dictionarySourceSnapshotFingerprint,
    required this.classifications,
    required this.classificationsByCandidateIdentity,
    required this.classificationsByStatus,
  });

  final String projectId;

  final String candidateSourceDocumentPath;
  final String candidateSourceRevision;
  final String candidateSourceSnapshotFingerprint;

  final String dictionaryId;
  final String dictionaryVersion;
  final String dictionarySourceRevision;
  final String dictionarySourceSnapshotFingerprint;

  final List<CanonicalBusinessTextClassification> classifications;

  final Map<String, CanonicalBusinessTextClassification>
  classificationsByCandidateIdentity;

  final Map<
    CanonicalBusinessTextClassificationStatus,
    List<CanonicalBusinessTextClassification>
  >
  classificationsByStatus;

  int countFor(CanonicalBusinessTextClassificationStatus status) {
    return classificationsByStatus[status]!.length;
  }

  @override
  List<Object?> get props => <Object?>[
    projectId,
    candidateSourceDocumentPath,
    candidateSourceRevision,
    candidateSourceSnapshotFingerprint,
    dictionaryId,
    dictionaryVersion,
    dictionarySourceRevision,
    dictionarySourceSnapshotFingerprint,
    classifications,
  ];
}
