import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/primary_linguist_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/services/linguist_constraint_policy.dart';

void main() {
  const ConservativeLinguistConstraintPolicy policy =
      ConservativeLinguistConstraintPolicy();

  test('compatible evidence never upgrades or changes matrix verdict', () {
    final MatrixAssessment positive = _matrix(
      MatrixVerdict.acceptableVariation,
    );
    final MatrixAssessment negative = _matrix(MatrixVerdict.reviewRequired);

    final PrimaryLinguistReport report =
        _report(const <PrimaryLinguistAssessment>[
          PrimaryLinguistAssessment(
            routeId: 'RU_TO_EN',
            targetLanguage: TranslationLanguage.english,
            status: PrimaryLinguistStatus.compatible,
            sourceExcerpt: null,
            targetExcerpt: null,
            limitations: <String>[],
          ),
        ]);

    expect(
      policy.apply(matrixAssessment: positive, linguistReport: report).verdict,
      MatrixVerdict.acceptableVariation,
    );

    expect(
      policy.apply(matrixAssessment: negative, linguistReport: report).verdict,
      MatrixVerdict.reviewRequired,
    );
  });

  test(
    'complete incompatible evidence lowers positive verdict to review required',
    () {
      final MatrixAssessment result = policy.apply(
        matrixAssessment: _matrix(MatrixVerdict.acceptableVariation),
        linguistReport: _report(const <PrimaryLinguistAssessment>[
          PrimaryLinguistAssessment(
            routeId: 'RU_TO_TH',
            targetLanguage: TranslationLanguage.thai,
            status: PrimaryLinguistStatus.incompatible,
            sourceExcerpt: 'мастер',
            targetExcerpt: 'ครู',
            limitations: <String>[],
          ),
        ]),
      );

      expect(result.verdict, MatrixVerdict.reviewRequired);
      expect(result.limitations, isEmpty);
    },
  );

  test('incompatible evidence preserves existing review-required verdict', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.reviewRequired),
      linguistReport: _report(const <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'EN_TO_TH',
          targetLanguage: TranslationLanguage.thai,
          status: PrimaryLinguistStatus.incompatible,
          sourceExcerpt: 'technician',
          targetExcerpt: 'ครู',
          limitations: <String>[],
        ),
      ]),
    );

    expect(result.verdict, MatrixVerdict.reviewRequired);
  });

  test(
    'grounded incompatibility converts indeterminate matrix to review required',
    () {
      final MatrixAssessment result = policy.apply(
        matrixAssessment: MatrixAssessment(
          verdict: MatrixVerdict.indeterminate,
          observations: const [],
          limitations: const <String>['AUDIT_EVIDENCE_NOT_GROUNDED'],
        ),
        linguistReport: _report(const <PrimaryLinguistAssessment>[
          PrimaryLinguistAssessment(
            routeId: 'RU_TO_TH',
            targetLanguage: TranslationLanguage.thai,
            status: PrimaryLinguistStatus.incompatible,
            sourceExcerpt: 'source object',
            targetExcerpt: 'target object',
            limitations: <String>[],
          ),
        ]),
      );

      expect(result.verdict, MatrixVerdict.reviewRequired);
      expect(result.limitations, contains('AUDIT_EVIDENCE_NOT_GROUNDED'));
    },
  );

  test('grounded incompatibility cannot replace unreliable matrix verdict', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: MatrixAssessment(
        verdict: MatrixVerdict.unreliable,
        observations: const [],
        limitations: const <String>['AUDIT_PASS_A_RESPONSE_INVALID'],
      ),
      linguistReport: _report(const <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'RU_TO_TH',
          targetLanguage: TranslationLanguage.thai,
          status: PrimaryLinguistStatus.incompatible,
          sourceExcerpt: 'source object',
          targetExcerpt: 'target object',
          limitations: <String>[],
        ),
      ]),
    );

    expect(result.verdict, MatrixVerdict.unreliable);
    expect(result.limitations, contains('AUDIT_PASS_A_RESPONSE_INVALID'));
  });

  test('report-level limitation makes positive verdict indeterminate', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.acceptableVariation),
      linguistReport: const PrimaryLinguistReport(
        assessments: <PrimaryLinguistAssessment>[
          PrimaryLinguistAssessment(
            routeId: 'RU_TO_EN',
            targetLanguage: TranslationLanguage.english,
            status: PrimaryLinguistStatus.compatible,
            sourceExcerpt: null,
            targetExcerpt: null,
            limitations: <String>[],
          ),
        ],
        limitations: <String>['LINGUIST_PROVIDER_FAILURE'],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
    expect(result.limitations, contains('LINGUIST_PROVIDER_FAILURE'));
  });

  test('unresolved evidence makes a positive verdict indeterminate', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.acceptableVariation),
      linguistReport: _report(const <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'EN_TO_RU',
          targetLanguage: TranslationLanguage.russian,
          status: PrimaryLinguistStatus.unresolved,
          sourceExcerpt: null,
          targetExcerpt: null,
          limitations: <String>[],
        ),
      ]),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
    expect(
      result.limitations,
      contains(ConservativeLinguistConstraintPolicy.unresolvedLimitation),
    );
  });

  test('unresolved evidence cannot replace an unreliable verdict', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.unreliable),
      linguistReport: _report(const <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'TH_TO_EN',
          targetLanguage: TranslationLanguage.english,
          status: PrimaryLinguistStatus.unresolved,
          sourceExcerpt: null,
          targetExcerpt: null,
          limitations: <String>[],
        ),
      ]),
    );

    expect(result.verdict, MatrixVerdict.unreliable);
    expect(
      result.limitations,
      contains(ConservativeLinguistConstraintPolicy.unresolvedLimitation),
    );
  });

  test('incomplete incompatible evidence cannot assert unreliable', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.acceptableVariation),
      linguistReport: _report(const <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'RU_TO_EN',
          targetLanguage: TranslationLanguage.english,
          status: PrimaryLinguistStatus.incompatible,
          sourceExcerpt: 'панель',
          targetExcerpt: null,
          limitations: <String>[],
        ),
      ]),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
    expect(
      result.limitations,
      contains(ConservativeLinguistConstraintPolicy.invalidEvidenceLimitation),
    );
  });

  test('empty linguist report makes a positive verdict indeterminate', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: _matrix(MatrixVerdict.acceptableVariation),
      linguistReport: const PrimaryLinguistReport(
        assessments: <PrimaryLinguistAssessment>[],
        limitations: <String>[],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
    expect(
      result.limitations,
      contains(ConservativeLinguistConstraintPolicy.emptyReportLimitation),
    );
  });

  test('provider limitation is preserved without duplicate codes', () {
    final MatrixAssessment result = policy.apply(
      matrixAssessment: MatrixAssessment(
        verdict: MatrixVerdict.acceptableVariation,
        observations: const [],
        limitations: const <String>['LINGUIST_PROVIDER_FAILURE'],
      ),
      linguistReport: const PrimaryLinguistReport(
        assessments: <PrimaryLinguistAssessment>[],
        limitations: <String>['LINGUIST_PROVIDER_FAILURE'],
      ),
    );

    expect(result.verdict, MatrixVerdict.indeterminate);
    expect(
      result.limitations
          .where((String code) => code == 'LINGUIST_PROVIDER_FAILURE')
          .length,
      1,
    );
  });

  test('typed report serializes without free-text reasoning fields', () {
    const PrimaryLinguistReport report = PrimaryLinguistReport(
      assessments: <PrimaryLinguistAssessment>[
        PrimaryLinguistAssessment(
          routeId: 'RU_TO_TH',
          targetLanguage: TranslationLanguage.thai,
          status: PrimaryLinguistStatus.incompatible,
          sourceExcerpt: 'мастер',
          targetExcerpt: 'ครู',
          limitations: <String>[],
        ),
      ],
      limitations: <String>[],
    );

    final Map<String, Object> json = report.toJson();

    expect(json.keys, <String>{'assessments', 'limitations'});
    expect(json.toString(), isNot(contains('source_meaning')));
    expect(json.toString(), isNot(contains('note')));
    expect(json.toString(), isNot(contains('reasoning')));
  });
}

MatrixAssessment _matrix(MatrixVerdict verdict) {
  return MatrixAssessment(
    verdict: verdict,
    observations: const [],
    limitations: const <String>[],
  );
}

PrimaryLinguistReport _report(List<PrimaryLinguistAssessment> assessments) {
  return PrimaryLinguistReport(
    assessments: assessments,
    limitations: const <String>[],
  );
}
