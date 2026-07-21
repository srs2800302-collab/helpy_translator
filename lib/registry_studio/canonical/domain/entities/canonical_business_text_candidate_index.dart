import 'package:equatable/equatable.dart';

import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'canonical_business_text_candidate.dart';

final class CanonicalBusinessTextCandidateIndex extends Equatable {
  factory CanonicalBusinessTextCandidateIndex({
    required String projectId,
    required String sourceDocumentPath,
    required String sourceRevision,
    required String sourceSnapshotFingerprint,
    required Iterable<CanonicalBusinessTextCandidate> candidates,
  }) {
    final String normalizedProjectId = projectId.trim();
    final String normalizedSourceDocumentPath = sourceDocumentPath.trim();
    final String normalizedSourceRevision = sourceRevision.trim();
    final String normalizedSourceSnapshotFingerprint = sourceSnapshotFingerprint
        .trim();

    final List<CanonicalBusinessTextCandidate> normalizedCandidates = candidates
        .toList(growable: false);

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError.value(
        projectId,
        'projectId',
        'Canonical candidate index project identifier '
            'must not be empty.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        sourceDocumentPath,
        'sourceDocumentPath',
        'Canonical candidate index source document '
            'must not be empty.',
      );
    }

    if (normalizedSourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'Canonical candidate index source revision '
            'must not be empty.',
      );
    }

    if (normalizedSourceSnapshotFingerprint.isEmpty) {
      throw ArgumentError.value(
        sourceSnapshotFingerprint,
        'sourceSnapshotFingerprint',
        'Canonical candidate index source fingerprint '
            'must not be empty.',
      );
    }

    final Set<String> identities = <String>{};

    final Map<RegistryNodeId, List<CanonicalBusinessTextCandidate>>
    candidatesByNodeId =
        <RegistryNodeId, List<CanonicalBusinessTextCandidate>>{};

    final Map<RegistryEntityId, List<CanonicalBusinessTextCandidate>>
    candidatesByOwnerId =
        <RegistryEntityId, List<CanonicalBusinessTextCandidate>>{};

    for (final CanonicalBusinessTextCandidate candidate
        in normalizedCandidates) {
      if (!identities.add(candidate.identity)) {
        throw ArgumentError.value(
          candidate.identity,
          'candidates',
          'Canonical business-text candidate identities '
              'must be unique.',
        );
      }

      for (final evidence in candidate.sourceEvidence) {
        if (evidence.sourceDocumentPath != normalizedSourceDocumentPath) {
          throw ArgumentError.value(
            evidence.sourceDocumentPath,
            'candidates',
            'Canonical candidate evidence must belong '
                'to the indexed source document.',
          );
        }

        if (evidence.sourceSnapshotFingerprint !=
            normalizedSourceSnapshotFingerprint) {
          throw ArgumentError.value(
            evidence.sourceSnapshotFingerprint,
            'candidates',
            'Canonical candidate evidence must belong '
                'to the indexed source fingerprint.',
          );
        }

        if (!_samePath(evidence.headingPath, candidate.path.segments)) {
          throw ArgumentError.value(
            evidence.headingPath,
            'candidates',
            'Canonical candidate evidence heading path '
                'must match its Registry path.',
          );
        }
      }

      candidatesByNodeId
          .putIfAbsent(
            candidate.nodeId,
            () => <CanonicalBusinessTextCandidate>[],
          )
          .add(candidate);

      candidatesByOwnerId
          .putIfAbsent(
            candidate.businessScopeOwnerId,
            () => <CanonicalBusinessTextCandidate>[],
          )
          .add(candidate);
    }

    return CanonicalBusinessTextCandidateIndex._(
      projectId: normalizedProjectId,
      sourceDocumentPath: normalizedSourceDocumentPath,
      sourceRevision: normalizedSourceRevision,
      sourceSnapshotFingerprint: normalizedSourceSnapshotFingerprint,
      candidates: List<CanonicalBusinessTextCandidate>.unmodifiable(
        normalizedCandidates,
      ),
      candidatesByNodeId: _immutableCandidateMap(candidatesByNodeId),
      candidatesByOwnerId: _immutableCandidateMap(candidatesByOwnerId),
    );
  }

  const CanonicalBusinessTextCandidateIndex._({
    required this.projectId,
    required this.sourceDocumentPath,
    required this.sourceRevision,
    required this.sourceSnapshotFingerprint,
    required this.candidates,
    required this.candidatesByNodeId,
    required this.candidatesByOwnerId,
  });

  final String projectId;
  final String sourceDocumentPath;
  final String sourceRevision;
  final String sourceSnapshotFingerprint;

  final List<CanonicalBusinessTextCandidate> candidates;

  final Map<RegistryNodeId, List<CanonicalBusinessTextCandidate>>
  candidatesByNodeId;

  final Map<RegistryEntityId, List<CanonicalBusinessTextCandidate>>
  candidatesByOwnerId;

  int get candidateCount => candidates.length;

  @override
  List<Object?> get props => <Object?>[
    projectId,
    sourceDocumentPath,
    sourceRevision,
    sourceSnapshotFingerprint,
    candidates,
  ];

  static bool _samePath(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }

    for (int index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }

  static Map<K, List<CanonicalBusinessTextCandidate>> _immutableCandidateMap<K>(
    Map<K, List<CanonicalBusinessTextCandidate>> source,
  ) {
    return Map<K, List<CanonicalBusinessTextCandidate>>.unmodifiable(
      <K, List<CanonicalBusinessTextCandidate>>{
        for (final entry in source.entries)
          entry.key: List<CanonicalBusinessTextCandidate>.unmodifiable(
            entry.value,
          ),
      },
    );
  }
}
