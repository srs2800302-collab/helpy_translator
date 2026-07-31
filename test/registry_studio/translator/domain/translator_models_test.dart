import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  group('TranslationAudit semantic verdict', () {
    test('legacy empty audit is fail-closed', () {
      final TranslationAudit audit = TranslationAudit();

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.usesSemanticProtocol, isFalse);
    });

    test('exact requires three clear audits and three clear challengers', () {
      final TranslationAudit audit = _semanticAudit(
        exactResults: <ExactCertificationResult>[
          ExactCertificationResult.clear,
          ExactCertificationResult.clear,
          ExactCertificationResult.clear,
        ],
      );

      expect(audit.candidateForExact, isTrue);
      expect(audit.verdict, TranslationVerdict.exact);
    });

    test('three clear audits without certification require review', () {
      final TranslationAudit audit = _semanticAudit();

      expect(audit.candidateForExact, isTrue);
      expect(audit.verdict, TranslationVerdict.needsReview);
    });

    test('one unknown atom requires review and blocks challengers', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.unproven,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.equipmentIdentity,
                status: TranslationIssueStatus.unknown,
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.unproven,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.equipmentIdentity,
                status: TranslationIssueStatus.unknown,
              ),
            ],
          ),
        ],
      );

      expect(audit.candidateForExact, isFalse);
      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.terminologyPreserved, isFalse);
    });

    test('hard mismatch has priority and produces canonical drift', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.polarity,
                status: TranslationIssueStatus.mismatch,
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.blocked,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.polarity,
                status: TranslationIssueStatus.mismatch,
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.clear,
          ),
        ],
      );

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
      expect(audit.meaningPreserved, isFalse);
    });

    test('ambiguity evidence requires review even when marked X', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.ambiguity,
                status: TranslationIssueStatus.mismatch,
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.clear,
          ),
        ],
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
    });

    test('style-only mismatch produces equivalent', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: const <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.canonicalStyle,
                status: TranslationIssueStatus.mismatch,
              ),
            ],
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.clear,
          ),
        ],
      );

      expect(audit.verdict, TranslationVerdict.equivalent);
    });

    test('not-certified challenger requires review', () {
      final TranslationAudit audit = _semanticAudit(
        exactResults: <ExactCertificationResult>[
          ExactCertificationResult.clear,
          ExactCertificationResult.notCertified,
          ExactCertificationResult.clear,
        ],
        blockedAtom: TranslationSemanticAtom.modality,
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
    });

    test('protocol fallback always requires review', () {
      expect(
        TranslationAudit(protocolFallback: true).verdict,
        TranslationVerdict.needsReview,
      );
    });

    test('pair result invariants reject inconsistent issue sets', () {
      expect(
        () => TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.clear,
          issues: const <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.action,
              status: TranslationIssueStatus.mismatch,
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.unproven,
          issues: const <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.action,
              status: TranslationIssueStatus.mismatch,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('semantic audit requires every pair exactly once', () {
      expect(
        () => TranslationAudit(
          pairAudits: <TranslationPairAudit>[
            TranslationPairAudit(
              pair: TranslationPair.ruEn,
              result: TranslationPairAuditResult.clear,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('pair audit rejects more than two issues', () {
      expect(
        () => TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.blocked,
          issues: const <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.action,
              status: TranslationIssueStatus.mismatch,
            ),
            TranslationPairIssue(
              atom: TranslationSemanticAtom.objectIdentity,
              status: TranslationIssueStatus.mismatch,
            ),
            TranslationPairIssue(
              atom: TranslationSemanticAtom.scope,
              status: TranslationIssueStatus.mismatch,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects mixed and inconsistent semantic evidence', () {
      final List<TranslationPairAudit> clearAudits = <TranslationPairAudit>[
        for (final TranslationPair pair in TranslationPair.values)
          TranslationPairAudit(
            pair: pair,
            result: TranslationPairAuditResult.clear,
          ),
      ];
      final List<TranslationPairAudit> nonExactAudits = <TranslationPairAudit>[
        TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.unproven,
          issues: const <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.modality,
              status: TranslationIssueStatus.unknown,
            ),
          ],
        ),
        TranslationPairAudit(
          pair: TranslationPair.ruTh,
          result: TranslationPairAuditResult.clear,
        ),
        TranslationPairAudit(
          pair: TranslationPair.enTh,
          result: TranslationPairAuditResult.clear,
        ),
      ];
      final List<ExactPairCertification> clearCertifications =
          <ExactPairCertification>[
            for (final TranslationPair pair in TranslationPair.values)
              ExactPairCertification(
                pair: pair,
                result: ExactCertificationResult.clear,
              ),
          ];

      expect(
        () => TranslationAudit(
          findings: <TranslationFinding>[
            TranslationFinding.legacy(
              category: TranslationFindingCategory.style,
              message: 'Legacy style evidence.',
            ),
          ],
          pairAudits: clearAudits,
        ),
        throwsArgumentError,
      );
      expect(
        () => TranslationAudit(protocolFallback: true, pairAudits: clearAudits),
        throwsArgumentError,
      );
      expect(
        () => TranslationAudit(
          pairAudits: nonExactAudits,
          exactCertifications: clearCertifications,
        ),
        throwsArgumentError,
      );
    });
  });

  group('legacy evidence compatibility', () {
    test('meaning legacy evidence remains canonical drift', () {
      expect(
        TranslationAudit(
          meaningFindings: const <String>['Изменено обязательство.'],
        ).verdict,
        TranslationVerdict.canonicalDrift,
      );
    });

    test('style-only legacy evidence remains equivalent', () {
      expect(
        TranslationAudit(
          styleFindings: const <String>['Формулировка менее канонична.'],
        ).verdict,
        TranslationVerdict.equivalent,
      );
    });

    test('terminology legacy evidence remains needs review', () {
      expect(
        TranslationAudit(
          terminologyFindings: const <String>['Термин стал неоднозначным.'],
        ).verdict,
        TranslationVerdict.needsReview,
      );
    });

    test('rejects duplicate legacy evidence', () {
      final TranslationFinding finding = TranslationFinding.legacy(
        category: TranslationFindingCategory.ambiguity,
        message: 'Старое доказательство.',
      );

      expect(
        () =>
            TranslationAudit(findings: <TranslationFinding>[finding, finding]),
        throwsArgumentError,
      );
    });
  });

  group('structured legacy evidence', () {
    test('preserves multilingual evidence in all locales', () {
      final TranslationFinding finding = TranslationFinding.multilingual(
        category: TranslationFindingCategory.meaning,
        section: TranslationLanguage.en,
        sourceFragment: 'Исходный текст',
        translationFragment: 'Different text',
        reason: LocalizedEvidenceText(
          ru: 'Изменён объект.',
          en: 'The object changed.',
          th: 'วัตถุถูกเปลี่ยน',
        ),
        impact: LocalizedEvidenceText(
          ru: 'Изменилось указание.',
          en: 'The instruction changed.',
          th: 'คำสั่งเปลี่ยนไป',
        ),
        correctVariant: 'Original object.',
        sourceAmbiguity: null,
      );

      expect(finding.reasonFor(TranslationLanguage.ru), 'Изменён объект.');
      expect(finding.reasonFor(TranslationLanguage.en), 'The object changed.');
      expect(finding.reasonFor(TranslationLanguage.th), 'วัตถุถูกเปลี่ยน');
      expect(finding.sourceAmbiguityFor(TranslationLanguage.en), isNull);
    });

    test('rejects wording-only and cross-category semantic duplicates', () {
      TranslationFinding finding(TranslationFindingCategory category) {
        return TranslationFinding.multilingual(
          category: category,
          section: TranslationLanguage.en,
          sourceFragment: 'Исходный текст',
          translationFragment: 'Different text',
          reason: LocalizedEvidenceText(
            ru: 'Причина.',
            en: 'Reason.',
            th: 'เหตุผล',
          ),
          impact: LocalizedEvidenceText(
            ru: 'Влияние.',
            en: 'Impact.',
            th: 'ผลกระทบ',
          ),
          correctVariant: 'Original object.',
          sourceAmbiguity: null,
        );
      }

      expect(
        () => TranslationAudit(
          findings: <TranslationFinding>[
            finding(TranslationFindingCategory.meaning),
            finding(TranslationFindingCategory.terminology),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty structured evidence fields', () {
      expect(
        () => TranslationFinding(
          category: TranslationFindingCategory.style,
          section: TranslationLanguage.th,
          sourceFragment: 'Текст',
          translationFragment: 'ข้อความ',
          reason: ' ',
          impact: 'Нет смыслового влияния.',
          correctVariant: 'Каноничная формулировка.',
          sourceAmbiguity: 'NONE',
        ),
        throwsArgumentError,
      );
    });
  });

  group('TranslationBundle', () {
    test('new bundle contains only five primary sections', () {
      final TranslationBundle bundle = _bundle();

      expect(bundle.hasReverseDiagnostics, isFalse);
      expect(bundle.fiveSections.keys, <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
      ]);
      expect(bundle.nineSections.keys, bundle.fiveSections.keys);
    });

    test('legacy bundle preserves all reverse diagnostics', () {
      final TranslationBundle bundle = _bundle(withReverse: true);

      expect(bundle.hasReverseDiagnostics, isTrue);
      expect(bundle.nineSections.keys, <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
        'EN_TO_RU',
        'TH_TO_RU',
        'EN_TO_TH',
        'TH_TO_EN',
      ]);
    });

    test('rejects partial reverse diagnostics', () {
      expect(
        () => TranslationBundle(
          sourceLanguage: TranslationLanguage.ru,
          sourceText: 'Исходный текст.',
          ru: 'Исходный текст.',
          en: 'Source text.',
          th: 'ข้อความต้นฉบับ',
          enToRu: 'Исходный текст.',
        ),
        throwsArgumentError,
      );
    });

    test('rejects source-language section different from source text', () {
      expect(
        () => TranslationBundle(
          sourceLanguage: TranslationLanguage.ru,
          sourceText: 'Исходный текст.',
          ru: 'Другой текст.',
          en: 'Source text.',
          th: 'ข้อความต้นฉบับ',
        ),
        throwsArgumentError,
      );
    });
  });
}

TranslationAudit _semanticAudit({
  List<ExactCertificationResult> exactResults =
      const <ExactCertificationResult>[],
  TranslationSemanticAtom blockedAtom = TranslationSemanticAtom.modality,
}) {
  return TranslationAudit(
    pairAudits: <TranslationPairAudit>[
      for (final TranslationPair pair in TranslationPair.values)
        TranslationPairAudit(
          pair: pair,
          result: TranslationPairAuditResult.clear,
        ),
    ],
    exactCertifications: exactResults.isEmpty
        ? const <ExactPairCertification>[]
        : <ExactPairCertification>[
            for (
              int index = 0;
              index < TranslationPair.values.length;
              index += 1
            )
              ExactPairCertification(
                pair: TranslationPair.values[index],
                result: exactResults[index],
                atom:
                    exactResults[index] == ExactCertificationResult.notCertified
                    ? blockedAtom
                    : null,
              ),
          ],
  );
}

TranslationBundle _bundle({bool withReverse = false}) {
  return TranslationBundle(
    sourceLanguage: TranslationLanguage.ru,
    sourceText: 'Исходный текст.',
    ru: 'Исходный текст.',
    en: 'Source text.',
    th: 'ข้อความต้นฉบับ',
    enToRu: withReverse ? 'Исходный текст.' : null,
    thToRu: withReverse ? 'Исходный текст.' : null,
    enToTh: withReverse ? 'ข้อความต้นฉบับ' : null,
    thToEn: withReverse ? 'Source text.' : null,
  );
}
