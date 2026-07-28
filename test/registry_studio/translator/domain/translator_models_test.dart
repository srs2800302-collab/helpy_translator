import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/domain/translator_models.dart';

void main() {
  group('TranslationAudit', () {
    test('derives exact only when every findings group is empty', () {
      final TranslationAudit audit = TranslationAudit();

      expect(audit.verdict, TranslationVerdict.exact);
      expect(audit.meaningPreserved, isTrue);
      expect(audit.terminologyPreserved, isTrue);
      expect(audit.stylePreserved, isTrue);
      expect(audit.ambiguousWording, isFalse);
    });

    test('derives equivalent from style-only findings', () {
      final TranslationAudit audit = TranslationAudit(
        styleFindings: const <String>['Фраза читается неестественно.'],
      );

      expect(audit.verdict, TranslationVerdict.equivalent);
    });

    test('derives drift from concrete terminology findings', () {
      final TranslationAudit audit = TranslationAudit(
        terminologyFindings: const <String>[
          'В EN роль необоснованно стала конкретной профессией.',
        ],
      );

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
      expect(audit.terminologyPreserved, isFalse);
    });

    test('derives drift from concrete meaning findings', () {
      final TranslationAudit audit = TranslationAudit(
        meaningFindings: const <String>['Изменено обязательство.'],
      );

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
      expect(audit.meaningPreserved, isFalse);
    });

    test('derives needs review from unresolved ambiguity', () {
      final TranslationAudit audit = TranslationAudit(
        ambiguityFindings: const <String>[
          'TH допускает значения «варочная панель» и «печь».',
        ],
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.ambiguousWording, isTrue);
    });

    test('concrete drift has precedence over ambiguity and style', () {
      final TranslationAudit audit = TranslationAudit(
        terminologyFindings: const <String>[
          'EN добавляет признак «электрическая».',
        ],
        styleFindings: const <String>['TH читается неестественно.'],
        ambiguityFindings: const <String>['TH допускает два значения.'],
      );

      expect(audit.verdict, TranslationVerdict.canonicalDrift);
    });

    test('rejects duplicate findings', () {
      expect(
        () => TranslationAudit(
          meaningFindings: const <String>['Ошибка.', 'Ошибка.'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('TranslationBundle', () {
    test('preserves direct sections and reverse diagnostics', () {
      final TranslationBundle bundle = _bundle();

      expect(bundle.directSections.keys, <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
      ]);
      expect(bundle.allSections.keys, <String>[
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
      expect(bundle.directSections['EN'], 'Provider wording.');
      expect(bundle.reverseTranslations?.thToEn, 'Provider wording.');
    });

    test('keeps reverse diagnostics optional for legacy drafts', () {
      final TranslationBundle legacy = TranslationBundle(
        sourceLanguage: TranslationLanguage.ru,
        sourceText: 'Исходный текст.',
        ru: 'Исходный текст.',
        en: 'Provider wording.',
        th: 'ข้อความจากผู้ให้บริการ',
      );

      expect(legacy.reverseTranslations, isNull);
      expect(legacy.allSections.keys, legacy.directSections.keys);
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

TranslationBundle _bundle() {
  return TranslationBundle(
    sourceLanguage: TranslationLanguage.ru,
    sourceText: 'Исходный текст.',
    ru: 'Исходный текст.',
    en: 'Provider wording.',
    th: 'ข้อความจากผู้ให้บริการ',
    reverseTranslations: ReverseTranslationBundle(
      enToRu: 'Исходный текст.',
      thToRu: 'Исходный текст.',
      enToTh: 'ข้อความจากผู้ให้บริการ',
      thToEn: 'Provider wording.',
    ),
  );
}
