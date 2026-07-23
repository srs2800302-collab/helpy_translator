import 'package:equatable/equatable.dart';

import 'canonical_approved_equivalent_evidence.dart';
import 'canonical_business_text_candidate.dart';
import 'canonical_business_text_classification_status.dart';
import 'canonical_phrase_entry.dart';

final class CanonicalBusinessTextClassification extends Equatable {
  factory CanonicalBusinessTextClassification({
    required CanonicalBusinessTextCandidate candidate,
    required CanonicalBusinessTextClassificationStatus status,
    required CanonicalBusinessTextClassificationReason reason,
    Iterable<CanonicalPhraseEntry> matchedCanonicalEntries =
        const <CanonicalPhraseEntry>[],
    Iterable<CanonicalApprovedEquivalentEvidence>
        matchedApprovedEquivalentEvidence =
        const <CanonicalApprovedEquivalentEvidence>[],
  }) {
    final List<CanonicalPhraseEntry> normalizedMatches = matchedCanonicalEntries
        .toList(growable: false);

    final List<CanonicalApprovedEquivalentEvidence>
    normalizedApprovedEquivalentMatches = matchedApprovedEquivalentEvidence
        .toList(growable: false);

    final Set<String> matchedIdentities = <String>{};

    for (final CanonicalPhraseEntry entry in normalizedMatches) {
      if (!matchedIdentities.add(entry.identity)) {
        throw ArgumentError.value(
          entry.identity,
          'matchedCanonicalEntries',
          'Matched canonical entry identities must be unique.',
        );
      }
    }

    final Set<String> approvedEquivalentIdentities = <String>{};

    for (final CanonicalApprovedEquivalentEvidence evidence
        in normalizedApprovedEquivalentMatches) {
      if (!approvedEquivalentIdentities.add(evidence.identity)) {
        throw ArgumentError.value(
          evidence.identity,
          'matchedApprovedEquivalentEvidence',
          'Matched approved-equivalent identities must be unique.',
        );
      }
    }

    switch ((status, reason)) {
      case (
        CanonicalBusinessTextClassificationStatus.exact,
        CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
      ):
        if (normalizedMatches.length != 1) {
          throw ArgumentError.value(
            normalizedMatches,
            'matchedCanonicalEntries',
            'Exact classification requires exactly one canonical entry.',
          );
        }

        if (normalizedMatches.single.applicability.isNotEmpty) {
          throw ArgumentError.value(
            normalizedMatches.single.applicability,
            'matchedCanonicalEntries',
            'Exact classification cannot bypass unresolved '
                'canonical applicability.',
          );
        }

        if (normalizedApprovedEquivalentMatches.isNotEmpty) {
          throw ArgumentError.value(
            normalizedApprovedEquivalentMatches,
            'matchedApprovedEquivalentEvidence',
            'Exact classification must not contain '
                'approved-equivalent evidence.',
          );
        }

      case (
        CanonicalBusinessTextClassificationStatus.equivalent,
        CanonicalBusinessTextClassificationReason.singleApprovedEquivalentMatch,
      ):
        if (normalizedMatches.length != 1 ||
            normalizedApprovedEquivalentMatches.length != 1) {
          throw ArgumentError(
            'Equivalent classification requires exactly one canonical entry '
            'and one approved-equivalent evidence record.',
          );
        }

        final CanonicalApprovedEquivalentEvidence approvedEquivalent =
            normalizedApprovedEquivalentMatches.single;

        if (approvedEquivalent.canonicalEntryIdentity !=
            normalizedMatches.single.identity) {
          throw ArgumentError.value(
            approvedEquivalent,
            'matchedApprovedEquivalentEvidence',
            'Approved-equivalent evidence must reference the matched '
                'canonical entry.',
          );
        }

        if (_technicallyNormalize(candidate.text) !=
            _technicallyNormalize(approvedEquivalent.equivalentText)) {
          throw ArgumentError.value(
            candidate.text,
            'candidate',
            'Equivalent classification candidate text must exactly match '
                'the approved equivalent after technical whitespace '
                'normalization.',
          );
        }

      case (
        CanonicalBusinessTextClassificationStatus.review,
        CanonicalBusinessTextClassificationReason
            .exactTextRequiresApplicabilityReview,
      ):
        if (normalizedMatches.length != 1 ||
            normalizedMatches.single.applicability.isEmpty) {
          throw ArgumentError.value(
            normalizedMatches,
            'matchedCanonicalEntries',
            'Applicability review requires exactly one '
                'applicability-constrained entry.',
          );
        }

        if (normalizedApprovedEquivalentMatches.isNotEmpty) {
          throw ArgumentError.value(
            normalizedApprovedEquivalentMatches,
            'matchedApprovedEquivalentEvidence',
            'Exact-text review must not contain '
                'approved-equivalent evidence.',
          );
        }

      case (
        CanonicalBusinessTextClassificationStatus.review,
        CanonicalBusinessTextClassificationReason
            .ambiguousExactCanonicalTextMatch,
      ):
        if (normalizedMatches.length < 2) {
          throw ArgumentError.value(
            normalizedMatches,
            'matchedCanonicalEntries',
            'Ambiguous exact-text review requires at least '
                'two canonical entries.',
          );
        }

        if (normalizedApprovedEquivalentMatches.isNotEmpty) {
          throw ArgumentError.value(
            normalizedApprovedEquivalentMatches,
            'matchedApprovedEquivalentEvidence',
            'Ambiguous exact-text review must not contain '
                'approved-equivalent evidence.',
          );
        }

      case (
        CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      ):
        if (normalizedMatches.isNotEmpty ||
            normalizedApprovedEquivalentMatches.isNotEmpty) {
          throw ArgumentError(
            'Unclassified or neutral candidate must not contain a proven '
            'canonical or approved-equivalent match.',
          );
        }

      default:
        throw ArgumentError(
          'Unsupported canonical classification status '
          'and reason combination: $status / $reason.',
        );
    }

    return CanonicalBusinessTextClassification._(
      candidate: candidate,
      status: status,
      reason: reason,
      matchedCanonicalEntries: List<CanonicalPhraseEntry>.unmodifiable(
        normalizedMatches,
      ),
      matchedApprovedEquivalentEvidence:
          List<CanonicalApprovedEquivalentEvidence>.unmodifiable(
            normalizedApprovedEquivalentMatches,
          ),
    );
  }

  const CanonicalBusinessTextClassification._({
    required this.candidate,
    required this.status,
    required this.reason,
    required this.matchedCanonicalEntries,
    required this.matchedApprovedEquivalentEvidence,
  });

  final CanonicalBusinessTextCandidate candidate;
  final CanonicalBusinessTextClassificationStatus status;
  final CanonicalBusinessTextClassificationReason reason;
  final List<CanonicalPhraseEntry> matchedCanonicalEntries;

  final List<CanonicalApprovedEquivalentEvidence>
  matchedApprovedEquivalentEvidence;

  static String _technicallyNormalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  List<Object?> get props => <Object?>[
    candidate,
    status,
    reason,
    matchedCanonicalEntries,
    matchedApprovedEquivalentEvidence,
  ];
}
