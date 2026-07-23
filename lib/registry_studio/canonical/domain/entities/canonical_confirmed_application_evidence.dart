import 'package:equatable/equatable.dart';

import '../../../core/domain/evidence/source_evidence.dart';

final class CanonicalConfirmedApplicationEvidence extends Equatable {
  factory CanonicalConfirmedApplicationEvidence({
    required String identity,
    required String candidateIdentity,
    required String canonicalEntryIdentity,
    required String registrySourceRevision,
    required String confirmationEvidenceId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedCandidateIdentity = candidateIdentity.trim();
    final String normalizedCanonicalEntryIdentity = canonicalEntryIdentity
        .trim();
    final String normalizedRegistrySourceRevision = registrySourceRevision
        .trim();
    final String normalizedConfirmationEvidenceId = confirmationEvidenceId
        .trim();

    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Confirmed canonical application evidence identity '
            'must not be empty.',
      );
    }

    if (normalizedCandidateIdentity.isEmpty) {
      throw ArgumentError.value(
        candidateIdentity,
        'candidateIdentity',
        'Confirmed canonical application evidence must reference '
            'a candidate.',
      );
    }

    if (normalizedCanonicalEntryIdentity.isEmpty) {
      throw ArgumentError.value(
        canonicalEntryIdentity,
        'canonicalEntryIdentity',
        'Confirmed canonical application evidence must reference '
            'a canonical entry.',
      );
    }

    if (normalizedRegistrySourceRevision.isEmpty) {
      throw ArgumentError.value(
        registrySourceRevision,
        'registrySourceRevision',
        'Confirmed canonical application evidence must preserve '
            'the exact Registry revision.',
      );
    }

    if (normalizedConfirmationEvidenceId.isEmpty) {
      throw ArgumentError.value(
        confirmationEvidenceId,
        'confirmationEvidenceId',
        'Confirmed canonical application evidence must preserve '
            'confirmation evidence.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Confirmed canonical application evidence must preserve '
            'source evidence.',
      );
    }

    return CanonicalConfirmedApplicationEvidence._(
      identity: normalizedIdentity,
      candidateIdentity: normalizedCandidateIdentity,
      canonicalEntryIdentity: normalizedCanonicalEntryIdentity,
      registrySourceRevision: normalizedRegistrySourceRevision,
      confirmationEvidenceId: normalizedConfirmationEvidenceId,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
    );
  }

  const CanonicalConfirmedApplicationEvidence._({
    required this.identity,
    required this.candidateIdentity,
    required this.canonicalEntryIdentity,
    required this.registrySourceRevision,
    required this.confirmationEvidenceId,
    required this.sourceEvidence,
  });

  final String identity;
  final String candidateIdentity;
  final String canonicalEntryIdentity;
  final String registrySourceRevision;
  final String confirmationEvidenceId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object> get props => <Object>[
    identity,
    candidateIdentity,
    canonicalEntryIdentity,
    registrySourceRevision,
    confirmationEvidenceId,
    sourceEvidence,
  ];
}
