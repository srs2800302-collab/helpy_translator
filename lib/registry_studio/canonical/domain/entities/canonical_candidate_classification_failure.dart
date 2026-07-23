import 'package:equatable/equatable.dart';

import '../../../core/domain/evidence/source_evidence.dart';

enum CanonicalCandidateClassificationFailureKind { parsing, validation }

final class CanonicalCandidateClassificationFailure extends Equatable {
  factory CanonicalCandidateClassificationFailure({
    required String identity,
    required String candidateIdentity,
    required CanonicalCandidateClassificationFailureKind kind,
    required String message,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedCandidateIdentity = candidateIdentity.trim();
    final String normalizedMessage = message.trim();

    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Candidate classification failure identity must not be empty.',
      );
    }

    if (normalizedCandidateIdentity.isEmpty) {
      throw ArgumentError.value(
        candidateIdentity,
        'candidateIdentity',
        'Candidate classification failure must reference a candidate.',
      );
    }

    if (normalizedMessage.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'Candidate classification failure message must not be empty.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Candidate classification failure must preserve source evidence.',
      );
    }

    return CanonicalCandidateClassificationFailure._(
      identity: normalizedIdentity,
      candidateIdentity: normalizedCandidateIdentity,
      kind: kind,
      message: normalizedMessage,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
    );
  }

  const CanonicalCandidateClassificationFailure._({
    required this.identity,
    required this.candidateIdentity,
    required this.kind,
    required this.message,
    required this.sourceEvidence,
  });

  final String identity;
  final String candidateIdentity;
  final CanonicalCandidateClassificationFailureKind kind;
  final String message;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object> get props => <Object>[
    identity,
    candidateIdentity,
    kind,
    message,
    sourceEvidence,
  ];
}
