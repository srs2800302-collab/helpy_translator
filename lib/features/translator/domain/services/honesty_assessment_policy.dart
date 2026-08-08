import '../entities/matrix_assessment.dart';
import '../entities/semantic_audit_report.dart';
import '../entities/semantic_observation.dart';
import '../entities/translation_route.dart';

abstract interface class HonestyAssessmentPolicy {
  MatrixAssessment assess(SemanticAuditReport report);
}

/// Replaceable verdict policy.
///
/// Uncertainty and detected drift are never hidden or converted into a
/// positive claim.
///
/// Confirmed evidence remains supported for historical result compatibility.
/// Grounded single-pass evidence remains explicitly unverified and therefore
/// cannot independently assert UNRELIABLE.
final class ConservativeHonestyAssessmentPolicy
    implements HonestyAssessmentPolicy {
  const ConservativeHonestyAssessmentPolicy();

  static const Set<SemanticRelation> _alwaysCriticalRelations =
      <SemanticRelation>{
        SemanticRelation.addition,
        SemanticRelation.omission,
        SemanticRelation.contradiction,
      };

  static const Set<SemanticDimension> _criticalDimensions = <SemanticDimension>{
    SemanticDimension.proposition,
    SemanticDimension.negation,
    SemanticDimension.modality,
    SemanticDimension.quantity,
    SemanticDimension.time,
    SemanticDimension.condition,
    SemanticDimension.actor,
    SemanticDimension.object,
    SemanticDimension.direction,
    SemanticDimension.cause,
    SemanticDimension.restriction,
    SemanticDimension.ambiguity,
    SemanticDimension.terminology,
    SemanticDimension.specificity,
  };

  @override
  MatrixAssessment assess(SemanticAuditReport report) {
    final List<SemanticObservation> observations =
        List<SemanticObservation>.unmodifiable(report.observations);

    final List<String> limitations = List<String>.unmodifiable(
      report.limitations,
    );

    final List<SemanticObservation> confirmed = observations
        .where(_isUsableConfirmed)
        .toList(growable: false);

    final List<SemanticObservation> singlePass = observations
        .where(_isUsableDirectSinglePass)
        .toList(growable: false);

    // Already confirmed drift must never be erased by uncertainty elsewhere.
    final bool containsConfirmedCriticalPrimaryDrift = confirmed.any(
      (SemanticObservation observation) =>
          observation.routeRole == TranslationRouteRole.primary &&
          observation.preservation == MeaningPreservation.altered &&
          _isCritical(observation),
    );

    if (containsConfirmedCriticalPrimaryDrift) {
      return MatrixAssessment(
        verdict: MatrixVerdict.unreliable,
        observations: observations,
        limitations: limitations,
      );
    }

    final bool containsConfirmedAlteredMeaning = confirmed.any(
      (SemanticObservation observation) =>
          observation.preservation == MeaningPreservation.altered,
    );

    if (containsConfirmedAlteredMeaning) {
      return MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: observations,
        limitations: limitations,
      );
    }

    final int usableObservationCount = confirmed.length + singlePass.length;

    // Empty, malformed, conflicting, technically failed, or otherwise
    // unverifiable evidence can never produce a green result.
    if (observations.isEmpty ||
        limitations.isNotEmpty ||
        usableObservationCount != observations.length) {
      return MatrixAssessment(
        verdict: MatrixVerdict.indeterminate,
        observations: observations,
        limitations: limitations,
      );
    }

    // A single Audit A finding is useful but not independently confirmed.
    // It may block green, but cannot by itself assert UNRELIABLE.
    final bool containsSinglePassDrift = singlePass.any(
      (SemanticObservation observation) =>
          observation.preservation == MeaningPreservation.altered,
    );

    if (containsSinglePassDrift) {
      return MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: observations,
        limitations: limitations,
      );
    }

    if (singlePass.isNotEmpty) {
      return MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: observations,
        limitations: limitations,
      );
    }

    return MatrixAssessment(
      verdict: MatrixVerdict.acceptableVariation,
      observations: observations,
      limitations: limitations,
    );
  }

  static bool _isUsableConfirmed(SemanticObservation observation) {
    return observation.verificationStatus ==
            ObservationVerificationStatus.confirmed &&
        _hasValidSemanticShape(observation);
  }

  static bool _isUsableDirectSinglePass(SemanticObservation observation) {
    return observation.verificationStatus ==
            ObservationVerificationStatus.singlePass &&
        _hasValidSemanticShape(observation);
  }

  static bool _hasValidSemanticShape(SemanticObservation observation) {
    if (observation.relation == SemanticRelation.unknown ||
        observation.dimension == SemanticDimension.unknown ||
        observation.dimension == SemanticDimension.other ||
        observation.preservation == MeaningPreservation.unknown) {
      return false;
    }

    if (observation.sourceExcerpt == null &&
        observation.targetExcerpt == null) {
      return false;
    }

    if (observation.relation == SemanticRelation.addition &&
        observation.targetExcerpt == null) {
      return false;
    }

    if (observation.relation == SemanticRelation.omission &&
        observation.sourceExcerpt == null) {
      return false;
    }

    if (observation.relation != SemanticRelation.addition &&
        observation.relation != SemanticRelation.omission &&
        (observation.sourceExcerpt == null ||
            observation.targetExcerpt == null)) {
      return false;
    }

    if (_alwaysCriticalRelations.contains(observation.relation) &&
        observation.preservation != MeaningPreservation.altered) {
      return false;
    }

    if (observation.relation == SemanticRelation.wordingVariation &&
        observation.preservation != MeaningPreservation.preserved) {
      return false;
    }

    return true;
  }

  static bool _isCritical(SemanticObservation observation) {
    return _alwaysCriticalRelations.contains(observation.relation) ||
        _criticalDimensions.contains(observation.dimension);
  }
}
