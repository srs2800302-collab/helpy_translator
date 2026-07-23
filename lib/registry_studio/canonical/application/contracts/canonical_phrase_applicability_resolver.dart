import '../../domain/entities/canonical_business_text_candidate.dart';
import '../../domain/entities/canonical_confirmed_application_evidence.dart';
import '../../domain/entities/canonical_phrase_entry.dart';

enum CanonicalPhraseApplicabilityDecision {
  applicable,
  notApplicable,
  unresolved,
}

final class CanonicalPhraseApplicabilityResolution {
  const CanonicalPhraseApplicabilityResolution.applicable(this.evidence)
    : decision = CanonicalPhraseApplicabilityDecision.applicable;

  const CanonicalPhraseApplicabilityResolution.notApplicable()
    : decision = CanonicalPhraseApplicabilityDecision.notApplicable,
      evidence = null;

  const CanonicalPhraseApplicabilityResolution.unresolved()
    : decision = CanonicalPhraseApplicabilityDecision.unresolved,
      evidence = null;

  final CanonicalPhraseApplicabilityDecision decision;
  final CanonicalConfirmedApplicationEvidence? evidence;
}

abstract interface class CanonicalPhraseApplicabilityResolver {
  CanonicalPhraseApplicabilityResolution resolve({
    required CanonicalBusinessTextCandidate candidate,
    required CanonicalPhraseEntry entry,
    required String registrySourceRevision,
  });
}
