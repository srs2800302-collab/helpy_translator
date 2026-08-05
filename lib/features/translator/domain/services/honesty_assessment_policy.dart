import '../entities/matrix_assessment.dart';
import '../entities/semantic_audit_report.dart';
import '../entities/semantic_observation.dart';
import '../entities/translation_route.dart';

abstract interface class HonestyAssessmentPolicy {
  MatrixAssessment assess(SemanticAuditReport report);
}

/// Replaceable verdict policy.
///
/// The only immutable rule is that uncertainty and detected drift are never
/// hidden or converted into a positive claim.
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
  };

  @override
  MatrixAssessment assess(SemanticAuditReport report) {
    final List<SemanticObservation> observations =
        List<SemanticObservation>.unmodifiable(report.observations);
    final List<String> limitations = List<String>.unmodifiable(
      report.limitations,
    );

    if (limitations.isNotEmpty ||
        observations.any(_isUnverifiableOrInconsistent)) {
      return MatrixAssessment(
        verdict: MatrixVerdict.indeterminate,
        observations: observations,
        limitations: limitations,
      );
    }

    final bool containsCriticalPrimaryDrift = observations.any(
      (SemanticObservation observation) =>
          observation.routeRole == TranslationRouteRole.primary &&
          observation.preservation == MeaningPreservation.altered &&
          _isCritical(observation),
    );

    if (containsCriticalPrimaryDrift) {
      return MatrixAssessment(
        verdict: MatrixVerdict.unreliable,
        observations: observations,
        limitations: limitations,
      );
    }

    if (observations.isEmpty) {
      return MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: observations,
        limitations: limitations,
      );
    }

    final bool containsAlteredMeaning = observations.any(
      (SemanticObservation observation) =>
          observation.preservation == MeaningPreservation.altered,
    );

    if (containsAlteredMeaning) {
      return MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
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

  static bool _isCritical(SemanticObservation observation) {
    return _alwaysCriticalRelations.contains(observation.relation) ||
        _criticalDimensions.contains(observation.dimension);
  }

  static bool _isUnverifiableOrInconsistent(SemanticObservation observation) {
    if (observation.verificationStatus !=
        ObservationVerificationStatus.confirmed) {
      return true;
    }

    if (observation.relation == SemanticRelation.unknown ||
        observation.dimension == SemanticDimension.unknown ||
        observation.dimension == SemanticDimension.other ||
        observation.preservation == MeaningPreservation.unknown) {
      return true;
    }

    if (observation.hasVerifierTuple) {
      return true;
    }

    if (observation.sourceExcerpt == null &&
        observation.targetExcerpt == null) {
      return true;
    }

    if (observation.relation == SemanticRelation.addition &&
        observation.targetExcerpt == null) {
      return true;
    }

    if (observation.relation == SemanticRelation.omission &&
        observation.sourceExcerpt == null) {
      return true;
    }

    if (observation.relation != SemanticRelation.addition &&
        observation.relation != SemanticRelation.omission &&
        (observation.sourceExcerpt == null ||
            observation.targetExcerpt == null)) {
      return true;
    }

    if (_alwaysCriticalRelations.contains(observation.relation) &&
        observation.preservation != MeaningPreservation.altered) {
      return true;
    }

    if (observation.relation == SemanticRelation.wordingVariation &&
        observation.preservation != MeaningPreservation.preserved) {
      return true;
    }

    return false;
  }
}
