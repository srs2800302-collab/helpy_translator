import 'package:equatable/equatable.dart';

import '../../../core/domain/value_objects/registry_entity_id.dart';
import 'canonical_business_text_candidate.dart';
import 'canonical_business_text_candidate_index.dart';
import 'canonical_business_text_classification.dart';
import 'canonical_business_text_classification_index.dart';
import 'canonical_business_text_classification_status.dart';
import 'canonical_dictionary.dart';

final class CanonicalBusinessTextAnalysisResult extends Equatable {
  factory CanonicalBusinessTextAnalysisResult({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalBusinessTextClassificationIndex classifications,
    required CanonicalDictionary dictionary,
  }) {
    if (classifications.projectId != candidates.projectId) {
      throw ArgumentError.value(
        classifications.projectId,
        'classifications',
        'Canonical analysis candidate and classification '
            'project identifiers must match.',
      );
    }

    if (classifications.candidateSourceDocumentPath !=
        candidates.sourceDocumentPath) {
      throw ArgumentError.value(
        classifications.candidateSourceDocumentPath,
        'classifications',
        'Canonical analysis candidate source documents '
            'must match.',
      );
    }

    if (classifications.candidateSourceRevision != candidates.sourceRevision) {
      throw ArgumentError.value(
        classifications.candidateSourceRevision,
        'classifications',
        'Canonical analysis candidate source revisions '
            'must match.',
      );
    }

    if (classifications.candidateSourceSnapshotFingerprint !=
        candidates.sourceSnapshotFingerprint) {
      throw ArgumentError.value(
        classifications.candidateSourceSnapshotFingerprint,
        'classifications',
        'Canonical analysis candidate source fingerprints '
            'must match.',
      );
    }

    if (classifications.dictionaryId != dictionary.dictionaryId) {
      throw ArgumentError.value(
        classifications.dictionaryId,
        'classifications',
        'Canonical analysis dictionary identifiers '
            'must match.',
      );
    }

    if (classifications.dictionaryVersion != dictionary.version) {
      throw ArgumentError.value(
        classifications.dictionaryVersion,
        'classifications',
        'Canonical analysis dictionary versions '
            'must match.',
      );
    }

    if (classifications.dictionarySourceRevision != dictionary.sourceRevision) {
      throw ArgumentError.value(
        classifications.dictionarySourceRevision,
        'classifications',
        'Canonical analysis dictionary source revisions '
            'must match.',
      );
    }

    if (classifications.dictionarySourceSnapshotFingerprint !=
        dictionary.sourceSnapshotFingerprint) {
      throw ArgumentError.value(
        classifications.dictionarySourceSnapshotFingerprint,
        'classifications',
        'Canonical analysis dictionary source '
            'fingerprints must match.',
      );
    }

    if (classifications.classifications.length !=
        candidates.candidates.length) {
      throw ArgumentError.value(
        classifications.classifications.length,
        'classifications',
        'Canonical analysis requires exactly one '
            'classification per candidate.',
      );
    }

    final Map<String, CanonicalBusinessTextCandidate> candidatesByIdentity =
        <String, CanonicalBusinessTextCandidate>{
          for (final CanonicalBusinessTextCandidate candidate
              in candidates.candidates)
            candidate.identity: candidate,
        };

    final Set<String> classifiedCandidateIdentities = <String>{};

    final Map<CanonicalBusinessTextClassificationStatus, int> countsByStatus =
        <CanonicalBusinessTextClassificationStatus, int>{
          for (final CanonicalBusinessTextClassificationStatus status
              in CanonicalBusinessTextClassificationStatus.values)
            status: 0,
        };

    final Map<RegistryEntityId, List<CanonicalBusinessTextClassification>>
    classificationsByBusinessScopeOwnerId =
        <RegistryEntityId, List<CanonicalBusinessTextClassification>>{};

    final Map<RegistryEntityId, int> countsByBusinessScopeOwnerId =
        <RegistryEntityId, int>{};

    final Map<
      RegistryEntityId,
      Map<CanonicalBusinessTextClassificationStatus, int>
    >
    countsByBusinessScopeOwnerAndStatus =
        <
          RegistryEntityId,
          Map<CanonicalBusinessTextClassificationStatus, int>
        >{};

    for (final CanonicalBusinessTextClassification classification
        in classifications.classifications) {
      final String candidateIdentity = classification.candidate.identity;

      final CanonicalBusinessTextCandidate? indexedCandidate =
          candidatesByIdentity[candidateIdentity];

      if (indexedCandidate == null) {
        throw ArgumentError.value(
          candidateIdentity,
          'classifications',
          'Canonical classification references a candidate '
              'outside the candidate index.',
        );
      }

      if (classification.candidate != indexedCandidate) {
        throw ArgumentError.value(
          classification.candidate,
          'classifications',
          'Canonical classification candidate content '
              'must match the indexed candidate.',
        );
      }

      if (!classifiedCandidateIdentities.add(candidateIdentity)) {
        throw ArgumentError.value(
          candidateIdentity,
          'classifications',
          'Canonical candidate must not be classified '
              'more than once.',
        );
      }

      countsByStatus[classification.status] =
          countsByStatus[classification.status]! + 1;

      final RegistryEntityId ownerId =
          classification.candidate.businessScopeOwnerId;

      classificationsByBusinessScopeOwnerId
          .putIfAbsent(ownerId, () => <CanonicalBusinessTextClassification>[])
          .add(classification);

      countsByBusinessScopeOwnerId[ownerId] =
          (countsByBusinessScopeOwnerId[ownerId] ?? 0) + 1;

      final Map<CanonicalBusinessTextClassificationStatus, int>
      ownerStatusCounts = countsByBusinessScopeOwnerAndStatus.putIfAbsent(
        ownerId,
        () => <CanonicalBusinessTextClassificationStatus, int>{
          for (final CanonicalBusinessTextClassificationStatus status
              in CanonicalBusinessTextClassificationStatus.values)
            status: 0,
        },
      );

      ownerStatusCounts[classification.status] =
          ownerStatusCounts[classification.status]! + 1;
    }

    if (classifiedCandidateIdentities.length != candidates.candidates.length) {
      throw ArgumentError.value(
        classifiedCandidateIdentities,
        'classifications',
        'Canonical analysis leaves one or more candidates '
            'without classification.',
      );
    }

    return CanonicalBusinessTextAnalysisResult._(
      candidates: candidates,
      classifications: classifications,
      registrySourceDocumentPath: candidates.sourceDocumentPath,
      registrySourceRevision: candidates.sourceRevision,
      registrySourceSnapshotFingerprint: candidates.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionaryStatus: dictionary.status,
      dictionarySourceDocumentPath: dictionary.sourceDocumentPath,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      countsByStatus:
          Map<CanonicalBusinessTextClassificationStatus, int>.unmodifiable(
            countsByStatus,
          ),
      classificationsByBusinessScopeOwnerId:
          Map<
            RegistryEntityId,
            List<CanonicalBusinessTextClassification>
          >.unmodifiable(<
            RegistryEntityId,
            List<CanonicalBusinessTextClassification>
          >{
            for (final MapEntry<
                  RegistryEntityId,
                  List<CanonicalBusinessTextClassification>
                >
                entry
                in classificationsByBusinessScopeOwnerId.entries)
              entry.key: List<CanonicalBusinessTextClassification>.unmodifiable(
                entry.value,
              ),
          }),
      countsByBusinessScopeOwnerId: Map<RegistryEntityId, int>.unmodifiable(
        countsByBusinessScopeOwnerId,
      ),
      countsByBusinessScopeOwnerAndStatus:
          Map<
            RegistryEntityId,
            Map<CanonicalBusinessTextClassificationStatus, int>
          >.unmodifiable(<
            RegistryEntityId,
            Map<CanonicalBusinessTextClassificationStatus, int>
          >{
            for (final MapEntry<
                  RegistryEntityId,
                  Map<CanonicalBusinessTextClassificationStatus, int>
                >
                entry
                in countsByBusinessScopeOwnerAndStatus.entries)
              entry.key:
                  Map<
                    CanonicalBusinessTextClassificationStatus,
                    int
                  >.unmodifiable(entry.value),
          }),
    );
  }

  const CanonicalBusinessTextAnalysisResult._({
    required this.candidates,
    required this.classifications,
    required this.registrySourceDocumentPath,
    required this.registrySourceRevision,
    required this.registrySourceSnapshotFingerprint,
    required this.dictionaryId,
    required this.dictionaryVersion,
    required this.dictionaryStatus,
    required this.dictionarySourceDocumentPath,
    required this.dictionarySourceRevision,
    required this.dictionarySourceSnapshotFingerprint,
    required this.countsByStatus,
    required this.classificationsByBusinessScopeOwnerId,
    required this.countsByBusinessScopeOwnerId,
    required this.countsByBusinessScopeOwnerAndStatus,
  });

  final CanonicalBusinessTextCandidateIndex candidates;

  final CanonicalBusinessTextClassificationIndex classifications;

  final String registrySourceDocumentPath;
  final String registrySourceRevision;
  final String registrySourceSnapshotFingerprint;

  final String dictionaryId;
  final String dictionaryVersion;
  final String dictionaryStatus;
  final String dictionarySourceDocumentPath;
  final String dictionarySourceRevision;
  final String dictionarySourceSnapshotFingerprint;

  final Map<CanonicalBusinessTextClassificationStatus, int> countsByStatus;

  final Map<RegistryEntityId, List<CanonicalBusinessTextClassification>>
  classificationsByBusinessScopeOwnerId;

  final Map<RegistryEntityId, int> countsByBusinessScopeOwnerId;

  final Map<
    RegistryEntityId,
    Map<CanonicalBusinessTextClassificationStatus, int>
  >
  countsByBusinessScopeOwnerAndStatus;

  int get totalCandidateCount => candidates.candidateCount;

  int countForStatus(CanonicalBusinessTextClassificationStatus status) {
    return countsByStatus[status]!;
  }

  int countForBusinessScopeOwner(RegistryEntityId ownerId) {
    return countsByBusinessScopeOwnerId[ownerId] ?? 0;
  }

  int countForBusinessScopeOwnerAndStatus(
    RegistryEntityId ownerId,
    CanonicalBusinessTextClassificationStatus status,
  ) {
    return countsByBusinessScopeOwnerAndStatus[ownerId]?[status] ?? 0;
  }

  @override
  List<Object?> get props => <Object?>[
    candidates,
    classifications,
    registrySourceDocumentPath,
    registrySourceRevision,
    registrySourceSnapshotFingerprint,
    dictionaryId,
    dictionaryVersion,
    dictionaryStatus,
    dictionarySourceDocumentPath,
    dictionarySourceRevision,
    dictionarySourceSnapshotFingerprint,
  ];
}
