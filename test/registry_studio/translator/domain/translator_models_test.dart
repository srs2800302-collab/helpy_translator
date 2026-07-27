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

    test('derives needs review from terminology without a dictionary', () {
      final TranslationAudit audit = TranslationAudit(
        terminologyFindings: const <String>[
          'В EN роль необоснованно стала конкретной профессией.',
        ],
      );

      expect(audit.verdict, TranslationVerdict.needsReview);
      expect(audit.verdict, isNot(TranslationVerdict.canonicalDrift));
    });

    test('derives needs review from meaning or ambiguity findings', () {
      expect(
        TranslationAudit(
          meaningFindings: const <String>['Изменено обязательство.'],
        ).verdict,
        TranslationVerdict.needsReview,
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
    test('preserves exact five-section direct payload', () {
      final TranslationBundle bundle = _bundle();

      expect(bundle.directSections.keys, <String>[
        'SOURCE LANGUAGE',
        'SOURCE TEXT',
        'RU',
        'EN',
        'TH',
      ]);
      expect(bundle.directSections['EN'], 'Provider wording.');
    });

    test('contains no reverse translation fields', () {
      final String keys = _bundle().directSections.keys.join(',');

      expect(keys, isNot(contains('EN_TO_RU')));
      expect(keys, isNot(contains('TH_TO_EN')));
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
  );
}
