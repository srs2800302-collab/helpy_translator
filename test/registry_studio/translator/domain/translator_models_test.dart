import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  group('TranslationAudit semantic verdict', () {
    test('legacy empty audit is fail-closed', () {
      final TranslationAudit audit = TranslationAudit();

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.usesSemanticProtocol, isFalse);
    });

    test('EXACT requires three audit CLEAR and one global challenge CLEAR', () {
      final TranslationAudit audit = _semanticAudit(
        challenge: ExactChallenge(result: ExactChallengeResult.clear),
      );

      expect(audit.candidateForExact, isTrue);
      expect(audit.verdict, TranslationVerdict.exact);
    });

    test('three audit CLEAR without challenger requires review', () {
      final TranslationAudit audit = _semanticAudit();

      expect(audit.candidateForExact, isTrue);
      expect(audit.verdict, TranslationVerdict.needsReview);
    });

    test('lexical-gap evidence requires review and preserves explanation', () {
      final TranslationPairIssue issue = TranslationPairIssue(
        atom: TranslationSemanticAtom.equipmentIdentity,
        status: TranslationIssueStatus.unknown,
        left: 'варочная панель',
        right: 'เตาไฟ',
        reason: 'broader Thai equipment term',
      );
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.clear,
          ),
          TranslationPairAudit(
            pair: TranslationPair.ruTh,
            result: TranslationPairAuditResult.unproven,
            issues: <TranslationPairIssue>[issue],
          ),
          TranslationPairAudit(
            pair: TranslationPair.enTh,
            result: TranslationPairAuditResult.unproven,
            issues: <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.equipmentIdentity,
                status: TranslationIssueStatus.unknown,
                left: 'cooktop',
                right: 'เตาไฟ',
                reason: 'identity is not proven',
              ),
            ],
          ),
        ],
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.terminologyPreserved, isFalse);
      expect(issue.reason, 'broader Thai equipment term');
    });

    test('hard mismatch has priority and produces canonical drift', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.polarity,
                status: TranslationIssueStatus.mismatch,
                left: 'не устанавливать',
                right: 'install',
                reason: 'negative action became positive',
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

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
    });

    test('style-only mismatch produces equivalent', () {
      final TranslationAudit audit = TranslationAudit(
        pairAudits: <TranslationPairAudit>[
          TranslationPairAudit(
            pair: TranslationPair.ruEn,
            result: TranslationPairAuditResult.blocked,
            issues: <TranslationPairIssue>[
              TranslationPairIssue(
                atom: TranslationSemanticAtom.canonicalStyle,
                status: TranslationIssueStatus.mismatch,
                left: 'мастер',
                right: 'service professional',
                reason: 'noncanonical service wording',
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

    test('global challenger BLOCKED or UNPROVEN requires review', () {
      for (final ExactChallenge challenge in <ExactChallenge>[
        ExactChallenge(
          result: ExactChallengeResult.blocked,
          disqualifiers: <ExactChallengeDisqualifier>[
            ExactChallengeDisqualifier(
              pair: TranslationPair.enTh,
              atom: TranslationSemanticAtom.equipmentIdentity,
              status: TranslationIssueStatus.mismatch,
              left: 'cooktop',
              right: 'เตาไฟ',
              reason: 'different equipment types',
            ),
          ],
        ),
        ExactChallenge(
          result: ExactChallengeResult.unproven,
          disqualifiers: <ExactChallengeDisqualifier>[
            ExactChallengeDisqualifier(
              pair: TranslationPair.enTh,
              atom: TranslationSemanticAtom.equipmentIdentity,
              status: TranslationIssueStatus.unknown,
              left: 'cooktop',
              right: 'เตาไฟ',
              reason: 'identity is not proven',
            ),
          ],
        ),
      ]) {
        final TranslationAudit audit = _semanticAudit(challenge: challenge);
        expect(audit.verdict, TranslationVerdict.needsReview);
        expect(audit.auditChallengerConflict, isTrue);
      }
    });

    test('challenger protocol failure requires review', () {
      final TranslationAudit audit = _semanticAudit(
        challenge: ExactChallenge(result: ExactChallengeResult.protocolFailure),
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.exactChallengeProtocolFailed, isTrue);
    });

    test('ambiguity X is rejected and ambiguity U requires review', () {
      expect(
        () => TranslationPairIssue(
          atom: TranslationSemanticAtom.ambiguity,
          status: TranslationIssueStatus.mismatch,
          left: 'мастер',
          right: 'master',
          reason: 'ambiguous role',
        ),
        throwsArgumentError,
      );

      final TranslationPairIssue issue = TranslationPairIssue(
        atom: TranslationSemanticAtom.ambiguity,
        status: TranslationIssueStatus.unknown,
        left: 'мастер',
        right: 'master',
        reason: 'role interpretation is unresolved',
      );
      expect(issue.status, TranslationIssueStatus.unknown);
    });

    test('semantic audit rejects mixed or inconsistent evidence', () {
      final List<TranslationPairAudit> clearAudits = _clearAudits();

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
          pairAudits: <TranslationPairAudit>[
            TranslationPairAudit(
              pair: TranslationPair.ruEn,
              result: TranslationPairAuditResult.unproven,
              issues: <TranslationPairIssue>[
                TranslationPairIssue(
                  atom: TranslationSemanticAtom.modality,
                  status: TranslationIssueStatus.unknown,
                  left: 'должен',
                  right: 'should',
                  reason: 'obligation strength is uncertain',
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
          exactChallenge: ExactChallenge(result: ExactChallengeResult.clear),
        ),
        throwsArgumentError,
      );
    });

    test('pair audit enforces issue limit and result consistency', () {
      expect(
        () => TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.clear,
          issues: <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.action,
              status: TranslationIssueStatus.mismatch,
              left: 'установить',
              right: 'remove',
              reason: 'opposite actions',
            ),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => TranslationPairAudit(
          pair: TranslationPair.ruEn,
          result: TranslationPairAuditResult.blocked,
          issues: <TranslationPairIssue>[
            TranslationPairIssue(
              atom: TranslationSemanticAtom.action,
              status: TranslationIssueStatus.mismatch,
              left: 'a',
              right: 'a',
              reason: 'one',
            ),
            TranslationPairIssue(
              atom: TranslationSemanticAtom.objectIdentity,
              status: TranslationIssueStatus.mismatch,
              left: 'b',
              right: 'b',
              reason: 'two',
            ),
            TranslationPairIssue(
              atom: TranslationSemanticAtom.scope,
              status: TranslationIssueStatus.mismatch,
              left: 'c',
              right: 'c',
              reason: 'three',
            ),
          ],
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

TranslationAudit _semanticAudit({ExactChallenge? challenge}) {
  return TranslationAudit(
    pairAudits: _clearAudits(),
    exactChallenge: challenge,
  );
}

List<TranslationPairAudit> _clearAudits() {
  return <TranslationPairAudit>[
    for (final TranslationPair pair in TranslationPair.values)
      TranslationPairAudit(
        pair: pair,
        result: TranslationPairAuditResult.clear,
      ),
  ];
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
