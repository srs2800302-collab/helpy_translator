import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/domain/entities/language_detection_result.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/services/source_language_detector.dart';

void main() {
  const ScriptSourceLanguageDetector detector = ScriptSourceLanguageDetector();

  test('detects RU, EN, and TH without a preferred base language', () {
    expect(
      detector.detect('Это исходный текст').detectedLanguage,
      TranslationLanguage.russian,
    );
    expect(
      detector.detect('This is the source text').detectedLanguage,
      TranslationLanguage.english,
    );
    expect(
      detector.detect('นี่คือข้อความต้นฉบับ').detectedLanguage,
      TranslationLanguage.thai,
    );
  });

  test('reports mixed supported scripts instead of choosing one', () {
    final LanguageDetectionResult result = detector.detect(
      'Hello, отправь это завтра',
    );

    expect(result.status, LanguageDetectionStatus.mixed);
    expect(result.detectedLanguage, isNull);
    expect(result.englishLetterCount, greaterThan(0));
    expect(result.russianLetterCount, greaterThan(0));
  });

  test('reports unknown when no supported letters exist', () {
    final LanguageDetectionResult result = detector.detect('123 — 456');

    expect(result.status, LanguageDetectionStatus.unknown);
    expect(result.detectedLanguage, isNull);
  });
}
