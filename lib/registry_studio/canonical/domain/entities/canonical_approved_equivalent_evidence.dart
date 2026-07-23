import 'package:equatable/equatable.dart';

import '../../../core/domain/evidence/source_evidence.dart';

final class CanonicalApprovedEquivalentEvidence extends Equatable {
  factory CanonicalApprovedEquivalentEvidence({
    required String identity,
    required String canonicalEntryIdentity,
    required String equivalentText,
    Iterable<String> applicability = const <String>[],
    required String approvalEvidenceId,
    required Iterable<SourceEvidence> sourceEvidence,
  }) {
    final String normalizedIdentity = identity.trim();
    final String normalizedCanonicalEntryIdentity = canonicalEntryIdentity
        .trim();
    final String normalizedEquivalentText = equivalentText.trim();
    final String normalizedApprovalEvidenceId = approvalEvidenceId.trim();

    final List<String> normalizedApplicability = applicability
        .map((String value) => value.trim())
        .toList(growable: false);

    final List<SourceEvidence> normalizedSourceEvidence = sourceEvidence.toList(
      growable: false,
    );

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError.value(
        identity,
        'identity',
        'Approved equivalent evidence identity must not be empty.',
      );
    }

    if (normalizedCanonicalEntryIdentity.isEmpty) {
      throw ArgumentError.value(
        canonicalEntryIdentity,
        'canonicalEntryIdentity',
        'Approved equivalent evidence must reference a canonical entry.',
      );
    }

    if (normalizedEquivalentText.isEmpty) {
      throw ArgumentError.value(
        equivalentText,
        'equivalentText',
        'Approved equivalent text must not be empty.',
      );
    }

    if (normalizedApplicability.any((String value) => value.isEmpty)) {
      throw ArgumentError.value(
        applicability,
        'applicability',
        'Approved equivalent applicability values must not be empty.',
      );
    }

    if (normalizedApplicability.toSet().length !=
        normalizedApplicability.length) {
      throw ArgumentError.value(
        applicability,
        'applicability',
        'Approved equivalent applicability values must be unique.',
      );
    }

    if (normalizedApprovalEvidenceId.isEmpty) {
      throw ArgumentError.value(
        approvalEvidenceId,
        'approvalEvidenceId',
        'Approved equivalent evidence must preserve approval evidence.',
      );
    }

    if (normalizedSourceEvidence.isEmpty) {
      throw ArgumentError.value(
        sourceEvidence,
        'sourceEvidence',
        'Approved equivalent evidence must preserve source evidence.',
      );
    }

    return CanonicalApprovedEquivalentEvidence._(
      identity: normalizedIdentity,
      canonicalEntryIdentity: normalizedCanonicalEntryIdentity,
      equivalentText: normalizedEquivalentText,
      applicability: List<String>.unmodifiable(normalizedApplicability),
      approvalEvidenceId: normalizedApprovalEvidenceId,
      sourceEvidence: List<SourceEvidence>.unmodifiable(
        normalizedSourceEvidence,
      ),
    );
  }

  const CanonicalApprovedEquivalentEvidence._({
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
  final List<String> applicability;
  final String approvalEvidenceId;
  final List<SourceEvidence> sourceEvidence;

  @override
  List<Object> get props => <Object>[
    identity,
    canonicalEntryIdentity,
    equivalentText,
    applicability,
    approvalEvidenceId,
    sourceEvidence,
  ];
}
