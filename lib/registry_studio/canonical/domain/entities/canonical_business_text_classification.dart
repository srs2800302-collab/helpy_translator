import 'package:equatable/equatable.dart';

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
  }) {
    final List<CanonicalPhraseEntry> normalizedMatches = matchedCanonicalEntries
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

    switch ((status, reason)) {
      case (
        CanonicalBusinessTextClassificationStatus.exact,
        CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
      ):
        if (normalizedMatches.length != 1) {
          throw ArgumentError.value(
            normalizedMatches,
            'matchedCanonicalEntries',
            'Exact classification requires exactly one '
                'canonical entry.',
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

      case (
        CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      ):
        if (normalizedMatches.isNotEmpty) {
          throw ArgumentError.value(
            normalizedMatches,
            'matchedCanonicalEntries',
            'Unclassified or neutral candidate must not '
                'contain a proven exact canonical match.',
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
    );
  }

  const CanonicalBusinessTextClassification._({
    required this.candidate,
    required this.status,
    required this.reason,
    required this.matchedCanonicalEntries,
  });

  final CanonicalBusinessTextCandidate candidate;
  final CanonicalBusinessTextClassificationStatus status;
  final CanonicalBusinessTextClassificationReason reason;

  final List<CanonicalPhraseEntry> matchedCanonicalEntries;

  @override
  List<Object?> get props => <Object?>[
    candidate,
    status,
    reason,
    matchedCanonicalEntries,
  ];
}
