enum CanonicalBusinessTextClassificationStatus {
  unclassifiedNeutral,
  exact,
  equivalent,
  review,
  drift,
  failed,
}

enum CanonicalBusinessTextClassificationReason {
  noExactCanonicalTextMatch,
  singleExactUniversalMatch,
  singleExactApplicableMatch,
  singleApprovedEquivalentMatch,
  exactTextRequiresApplicabilityReview,
  ambiguousExactCanonicalTextMatch,
}
