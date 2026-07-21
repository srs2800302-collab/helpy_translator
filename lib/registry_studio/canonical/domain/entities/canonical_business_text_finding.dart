import 'package:equatable/equatable.dart';

import 'canonical_business_text_candidate.dart';
import 'canonical_business_text_classification.dart';
import 'canonical_business_text_classification_status.dart';

enum CanonicalBusinessTextFindingDisposition {
  informational,
  reviewRequired,
  blocking,
}

final class CanonicalBusinessTextFinding extends Equatable {
  factory CanonicalBusinessTextFinding({
    required CanonicalBusinessTextClassification classification,
  }) {
    final CanonicalBusinessTextFindingDisposition disposition =
        switch (classification.status) {
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral =>
            CanonicalBusinessTextFindingDisposition.informational,
          CanonicalBusinessTextClassificationStatus.review =>
            CanonicalBusinessTextFindingDisposition.reviewRequired,
          CanonicalBusinessTextClassificationStatus.drift =>
            CanonicalBusinessTextFindingDisposition.blocking,
          CanonicalBusinessTextClassificationStatus.failed =>
            CanonicalBusinessTextFindingDisposition.blocking,
          CanonicalBusinessTextClassificationStatus.exact ||
          CanonicalBusinessTextClassificationStatus.equivalent =>
            throw ArgumentError.value(
              classification,
              'classification',
              'Resolved canonical classification does not create a finding.',
            ),
        };

    return CanonicalBusinessTextFinding._(
      classification: classification,
      disposition: disposition,
    );
  }

  const CanonicalBusinessTextFinding._({
    required this.classification,
    required this.disposition,
  });

  final CanonicalBusinessTextClassification classification;
  final CanonicalBusinessTextFindingDisposition disposition;

  String get identity => classification.candidate.identity;

  CanonicalBusinessTextCandidate get candidate => classification.candidate;

  CanonicalBusinessTextClassificationStatus get status => classification.status;

  CanonicalBusinessTextClassificationReason get reason => classification.reason;

  bool get requiresAttention =>
      disposition != CanonicalBusinessTextFindingDisposition.informational;

  @override
  List<Object?> get props => <Object?>[classification, disposition];
}
