import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  group('TranslatorPhraseResult', () {
    test('normalizes read-only phrase result text fields', () {
      final TranslatorPhraseResult result = TranslatorPhraseResult(
        sourceLanguage: ' ru ',
        sourceText: ' Проверить формулировку. ',
        status: TranslatorPhraseStatus.canonicalDrift,
        ru: ' Проверить формулировку. ',
        en: ' Check the wording. ',
        th: ' ตรวจสอบข้อความ ',
        enToRu: ' Проверить формулировку. ',
        thToRu: ' Проверить текст. ',
        enToTh: ' ตรวจสอบข้อความ ',
        thToEn: ' Check the text. ',
        comment: ' Needs canonical review. ',
        candidateCanonicalPhrase: ' Проверить каноническую формулировку. ',
      );

      expect(result.sourceLanguage, 'ru');
      expect(result.sourceText, 'Проверить формулировку.');
      expect(result.status, TranslatorPhraseStatus.canonicalDrift);
      expect(result.ru, 'Проверить формулировку.');
      expect(result.en, 'Check the wording.');
      expect(result.th, 'ตรวจสอบข้อความ');
      expect(result.enToRu, 'Проверить формулировку.');
      expect(result.thToRu, 'Проверить текст.');
      expect(result.enToTh, 'ตรวจสอบข้อความ');
      expect(result.thToEn, 'Check the text.');
      expect(result.comment, 'Needs canonical review.');
      expect(
        result.candidateCanonicalPhrase,
        'Проверить каноническую формулировку.',
      );
    });

    test('rejects empty required text fields', () {
      expect(
        () => TranslatorPhraseResult(
          sourceLanguage: '',
          sourceText: 'Text.',
          status: TranslatorPhraseStatus.exact,
        ),
        throwsArgumentError,
      );

      expect(
        () => TranslatorPhraseResult(
          sourceLanguage: '   ',
          sourceText: 'Text.',
          status: TranslatorPhraseStatus.exact,
        ),
        throwsArgumentError,
      );

      expect(
        () => TranslatorPhraseResult(
          sourceLanguage: 'en',
          sourceText: '',
          status: TranslatorPhraseStatus.exact,
        ),
        throwsArgumentError,
      );

      expect(
        () => TranslatorPhraseResult(
          sourceLanguage: 'en',
          sourceText: '   ',
          status: TranslatorPhraseStatus.exact,
        ),
        throwsArgumentError,
      );
    });

    test('normalizes blank optional text fields to null', () {
      final TranslatorPhraseResult result = TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'Check wording.',
        status: TranslatorPhraseStatus.needsReview,
        ru: '   ',
        en: '',
        th: null,
        comment: '   ',
        candidateCanonicalPhrase: '',
      );

      expect(result.ru, isNull);
      expect(result.en, isNull);
      expect(result.th, isNull);
      expect(result.comment, isNull);
      expect(result.candidateCanonicalPhrase, isNull);
    });

    test(
      'can represent failed language-quality output without registry action',
      () {
        final TranslatorPhraseResult result = TranslatorPhraseResult(
          sourceLanguage: 'en',
          sourceText: 'Check wording.',
          status: TranslatorPhraseStatus.failed,
          comment: 'Provider failed.',
        );

        expect(result.status, TranslatorPhraseStatus.failed);
        expect(result.comment, 'Provider failed.');
        expect(result.candidateCanonicalPhrase, isNull);
      },
    );

    test('uses value equality for read-only result comparison', () {
      final TranslatorPhraseResult first = TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'Check wording.',
        status: TranslatorPhraseStatus.equivalent,
        ru: 'Проверить формулировку.',
      );
      final TranslatorPhraseResult second = TranslatorPhraseResult(
        sourceLanguage: ' en ',
        sourceText: ' Check wording. ',
        status: TranslatorPhraseStatus.equivalent,
        ru: ' Проверить формулировку. ',
      );

      expect(first, second);
    });
  });
}
