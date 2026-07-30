import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  group('TranslationAudit', () {
    test('derives exact only when every findings group is empty', () {
      final TranslationAudit audit = TranslationAudit();

      expect(audit.verdict, TranslationVerdict.exact);
      expect(audit.meaningPreserved, isTrue);
      expect(audit.terminologyPreserved, isTrue);
      expect(audit.canonicalStylePreserved, isTrue);
      expect(audit.ambiguousWording, isFalse);
    });

    test('preserves structured evidence and derives verdict from category', () {
      final TranslationFinding finding = TranslationFinding(
        category: TranslationFindingCategory.meaning,
        section: TranslationLanguage.en,
        sourceFragment: 'Исходный текст',
        translationFragment: 'Different text',
        reason: 'Изменён объект.',
        impact: 'Пользователь получает другое указание.',
        correctVariant: 'Сохранить исходный объект.',
        sourceAmbiguity: 'NONE',
      );
      final TranslationAudit audit = TranslationAudit(
        findings: <TranslationFinding>[finding],
      );

      expect(audit.findings, <TranslationFinding>[finding]);
      expect(audit.meaningFindings, <String>['Изменён объект.']);
      expect(audit.verdict, TranslationVerdict.canonicalDrift);
      expect(finding.isLegacy, isFalse);
    });

    test('marks compatibility string findings as legacy evidence', () {
      final TranslationAudit audit = TranslationAudit(
        terminologyFindings: const <String>['Старое строковое доказательство.'],
      );

      expect(audit.findings, hasLength(1));
      expect(audit.findings.single.isLegacy, isTrue);
      expect(
        audit.terminologyFindings,
        <String>['Старое строковое доказательство.'],
      );
      expect(audit.verdict, TranslationVerdict.needsReview);
    });

    test('rejects empty structured evidence fields and duplicate findings', () {
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

      final TranslationFinding finding = TranslationFinding.legacy(
        category: TranslationFindingCategory.ambiguity,
        message: 'Старое доказательство.',
      );

      expect(
        () => TranslationAudit(
          findings: <TranslationFinding>[finding, finding],
        ),
        throwsArgumentError,
      );
    });

    test('derives equivalent from style-only findings', () {
      final TranslationAudit audit = TranslationAudit(
        styleFindings: const <String>['Формулировка менее канонична.'],
      );

      expect(audit.verdict, TranslationVerdict.equivalent);
    });

    test('derives needsReview from terminology findings', () {
      final TranslationAudit audit = TranslationAudit(
        terminologyFindings: const <String>[
          'Термин исполнителя стал слишком узким.',
        ],
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.meaningPreserved, isTrue);
    });

    test('derives canonical drift from meaning and review from ambiguity', () {
      expect(
        TranslationAudit(
          meaningFindings: const <String>['Изменено обязательство.'],
        ).verdict,
        TranslationVerdict.canonicalDrift,
      );
      expect(
        TranslationAudit(
          ambiguityFindings: const <String>[
            'Фраза допускает два материально разных прочтения.',
          ],
        ).verdict,
        TranslationVerdict.needsReview,
      );
    });

    test('meaning risk has priority over terminology findings', () {
      final TranslationAudit audit = TranslationAudit(
        meaningFindings: const <String>['Изменено обязательство.'],
        terminologyFindings: const <String>['Изменён термин.'],
      );

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
    });

    test('meaning risk has priority over ambiguity', () {
      expect(
        TranslationAudit(
          meaningFindings: const <String>['m'],
          ambiguityFindings: const <String>['a'],
        ).verdict,
        TranslationVerdict.canonicalDrift,
      );
    });

    test('terminology blocks equivalent with style findings', () {
      expect(
        TranslationAudit(
          terminologyFindings: const <String>['t'],
          styleFindings: const <String>['s'],
        ).verdict,
        TranslationVerdict.needsReview,
      );
    });

    test('terminology and ambiguity require review', () {
      expect(
        TranslationAudit(
          terminologyFindings: const <String>['t'],
          ambiguityFindings: const <String>['a'],
        ).verdict,
        TranslationVerdict.needsReview,
      );
    });

    test('meaning risk wins when every findings group is non-empty', () {
      expect(
        TranslationAudit(
          meaningFindings: const <String>['m'],
          terminologyFindings: const <String>['t'],
          styleFindings: const <String>['s'],
          ambiguityFindings: const <String>['a'],
        ).verdict,
        TranslationVerdict.canonicalDrift,
      );
    });
  });

  group('TranslationBundle', () {
    test('preserves exact nine-section payload', () {
      final TranslationBundle bundle = _bundle();

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
      expect(bundle.nineSections['SOURCE TEXT'], 'Исходный текст.');
    });

    test('rejects source-language section different from source text', () {
      expect(
        () => TranslationBundle(
          sourceLanguage: TranslationLanguage.ru,
          sourceText: 'Исходный текст.',
          ru: 'Другой текст.',
          en: 'Source text.',
          th: 'ข้อความต้นฉบับ',
          enToRu: 'Исходный текст.',
          thToRu: 'Исходный текст.',
          enToTh: 'ข้อความต้นฉบับ',
          thToEn: 'Source text.',
        ),
        throwsArgumentError,
      );
    });
  });
}

TranslationBundle _bundle() {
  return TranslationBundle(
    sourceLanguage: TranslationLanguage.ru,
    sourceText: 'Исходный текст.',
    ru: 'Исходный текст.',
    en: 'Source text.',
    th: 'ข้อความต้นฉบับ',
    enToRu: 'Исходный текст.',
    thToRu: 'Исходный текст.',
    enToTh: 'ข้อความต้นฉบับ',
    thToEn: 'Source text.',
  );
}
