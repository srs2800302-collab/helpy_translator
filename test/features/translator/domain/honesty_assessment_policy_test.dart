import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_audit_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/services/honesty_assessment_policy.dart';

void main() {
  const ConservativeHonestyAssessmentPolicy policy =
      ConservativeHonestyAssessmentPolicy();

  test('empty report is indeterminate and never green', () {
    final MatrixAssessment result = policy.assess(
      const SemanticAuditReport(
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
  });

  test('confirmed critical primary drift is unreliable', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.object,
            preservation: MeaningPreservation.altered,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.unreliable);
  });

  test('critical cross-check drift is diagnostic, not proof', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.crossCheck,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.object,
            preservation: MeaningPreservation.altered,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.reviewRequired);
  });

  test('confirmed wording variation with preserved meaning is acceptable', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.wordingVariation,
            dimension: SemanticDimension.lexicalChoice,
            preservation: MeaningPreservation.preserved,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.acceptableVariation);
  });

  test('pass disagreement is indeterminate instead of reclassified', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.object,
            preservation: MeaningPreservation.altered,
            verificationStatus: ObservationVerificationStatus.conflict,
            verifierRelation: SemanticRelation.scopeChange,
            verifierDimension: SemanticDimension.specificity,
            verifierPreservation: MeaningPreservation.unknown,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
  });

  test('unverifiable observation is indeterminate', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.unknown,
            dimension: SemanticDimension.unknown,
            preservation: MeaningPreservation.unknown,
            verificationStatus: ObservationVerificationStatus.unverifiable,
            sourceExcerpt: null,
            targetExcerpt: null,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
  });

  test('any limitation is indeterminate', () {
    final MatrixAssessment result = policy.assess(
      const SemanticAuditReport(
        observations: <SemanticObservation>[],
        limitations: <String>['INSUFFICIENT_CONTEXT'],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
  });

  test('confirmed primary drift is not softened by another limitation', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.specificity,
            preservation: MeaningPreservation.altered,
          ),
        ],
        limitations: const <String>['AUDIT_CONFLICT_UNRESOLVED'],
      ),
    );

    expect(result.verdict, MatrixVerdict.unreliable);
  });

  test('confirmed cross-check drift is not hidden by uncertainty', () {
    final MatrixAssessment result = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.crossCheck,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.terminology,
            preservation: MeaningPreservation.altered,
          ),
          _observation(
            routeId: 'TH_TO_EN',
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.unknown,
            dimension: SemanticDimension.unknown,
            preservation: MeaningPreservation.unknown,
            verificationStatus: ObservationVerificationStatus.unverifiable,
            sourceExcerpt: null,
            targetExcerpt: null,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.reviewRequired);
  });

  test('all critical semantic dimensions obey the same primary rule', () {
    const Set<SemanticDimension> criticalDimensions = <SemanticDimension>{
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

    for (final SemanticDimension dimension in criticalDimensions) {
      final MatrixAssessment result = policy.assess(
        SemanticAuditReport(
          observations: <SemanticObservation>[
            _observation(
              role: TranslationRouteRole.primary,
              relation: SemanticRelation.substitution,
              dimension: dimension,
              preservation: MeaningPreservation.altered,
            ),
          ],
          limitations: const <String>[],
        ),
      );

      expect(
        result.verdict,
        MatrixVerdict.unreliable,
        reason: 'dimension=${dimension.name}',
      );
    }
  });

  test('cross-check observations never produce unreliable by themselves', () {
    for (final SemanticRelation relation in SemanticRelation.values) {
      if (relation == SemanticRelation.unknown) {
        continue;
      }

      for (final SemanticDimension dimension in SemanticDimension.values) {
        if (dimension == SemanticDimension.unknown ||
            dimension == SemanticDimension.other) {
          continue;
        }

        final MeaningPreservation preservation =
            relation == SemanticRelation.wordingVariation
            ? MeaningPreservation.preserved
            : MeaningPreservation.altered;

        if ((relation == SemanticRelation.addition ||
                relation == SemanticRelation.omission ||
                relation == SemanticRelation.contradiction) &&
            preservation != MeaningPreservation.altered) {
          continue;
        }

        final MatrixAssessment result = policy.assess(
          SemanticAuditReport(
            observations: <SemanticObservation>[
              _observation(
                role: TranslationRouteRole.crossCheck,
                relation: relation,
                dimension: dimension,
                preservation: preservation,
                sourceExcerpt: relation == SemanticRelation.addition
                    ? null
                    : 'source-token',
                targetExcerpt: relation == SemanticRelation.omission
                    ? null
                    : 'target-token',
              ),
            ],
            limitations: const <String>[],
          ),
        );

        expect(
          result.verdict,
          isNot(MatrixVerdict.unreliable),
          reason: '${relation.name}/${dimension.name}',
        );
      }
    }
  });

  test('route identifiers do not privilege a language', () {
    const List<String> routeIds = <String>[
      'RU_TO_EN',
      'RU_TO_TH',
      'EN_TO_RU',
      'EN_TO_TH',
      'TH_TO_RU',
      'TH_TO_EN',
    ];

    for (final String routeId in routeIds) {
      final MatrixAssessment result = policy.assess(
        SemanticAuditReport(
          observations: <SemanticObservation>[
            _observation(
              routeId: routeId,
              role: TranslationRouteRole.primary,
              relation: SemanticRelation.substitution,
              dimension: SemanticDimension.modality,
              preservation: MeaningPreservation.altered,
            ),
          ],
          limitations: const <String>[],
        ),
      );

      expect(result.verdict, MatrixVerdict.unreliable, reason: routeId);
    }
  });

  test('adding uncertainty cannot erase confirmed drift', () {
    final MatrixAssessment review = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          _observation(
            role: TranslationRouteRole.crossCheck,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.specificity,
            preservation: MeaningPreservation.altered,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    final MatrixAssessment withUncertainty = policy.assess(
      SemanticAuditReport(
        observations: <SemanticObservation>[
          ...review.observations,
          _observation(
            routeId: 'TH_TO_EN',
            role: TranslationRouteRole.primary,
            relation: SemanticRelation.unknown,
            dimension: SemanticDimension.unknown,
            preservation: MeaningPreservation.unknown,
            verificationStatus: ObservationVerificationStatus.unverifiable,
            sourceExcerpt: null,
            targetExcerpt: null,
          ),
        ],
        limitations: const <String>[],
      ),
    );

    expect(review.verdict, MatrixVerdict.reviewRequired);
    expect(withUncertainty.verdict, MatrixVerdict.reviewRequired);
  });
}

SemanticObservation _observation({
  String routeId = 'EN_TO_RU',
  required TranslationRouteRole role,
  required SemanticRelation relation,
  required SemanticDimension dimension,
  required MeaningPreservation preservation,
  ObservationVerificationStatus verificationStatus =
      ObservationVerificationStatus.confirmed,
  String? sourceExcerpt = 'source-token',
  String? targetExcerpt = 'target-token',
  SemanticRelation? verifierRelation,
  SemanticDimension? verifierDimension,
  MeaningPreservation? verifierPreservation,
}) {
  return SemanticObservation(
    routeId: routeId,
    routeRole: role,
    relation: relation,
    dimension: dimension,
    preservation: preservation,
    verificationStatus: verificationStatus,
    sourceExcerpt: sourceExcerpt,
    targetExcerpt: targetExcerpt,
    verifierRelation: verifierRelation,
    verifierDimension: verifierDimension,
    verifierPreservation: verifierPreservation,
  );
}
