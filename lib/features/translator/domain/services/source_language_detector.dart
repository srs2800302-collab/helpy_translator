import '../entities/language_detection_result.dart';
import '../entities/translation_language.dart';

abstract interface class SourceLanguageDetector {
  LanguageDetectionResult detect(String sourceText);
}

final class ScriptSourceLanguageDetector implements SourceLanguageDetector {
  const ScriptSourceLanguageDetector();

  @override
  LanguageDetectionResult detect(String sourceText) {
    int russianLetterCount = 0;
    int englishLetterCount = 0;
    int thaiLetterCount = 0;

    for (final int rune in sourceText.runes) {
      if (_isRussianLetter(rune)) {
        russianLetterCount += 1;
      } else if (_isEnglishLetter(rune)) {
        englishLetterCount += 1;
      } else if (_isThaiLetter(rune)) {
        thaiLetterCount += 1;
      }
    }

    final List<TranslationLanguage> detectedScripts = <TranslationLanguage>[
      if (russianLetterCount > 0) TranslationLanguage.russian,
      if (englishLetterCount > 0) TranslationLanguage.english,
      if (thaiLetterCount > 0) TranslationLanguage.thai,
    ];

    if (detectedScripts.isEmpty) {
      return const LanguageDetectionResult.unknown();
    }

    if (detectedScripts.length > 1) {
      return LanguageDetectionResult.mixed(
        russianLetterCount: russianLetterCount,
        englishLetterCount: englishLetterCount,
        thaiLetterCount: thaiLetterCount,
      );
    }

    return LanguageDetectionResult.detected(
      language: detectedScripts.single,
      russianLetterCount: russianLetterCount,
      englishLetterCount: englishLetterCount,
      thaiLetterCount: thaiLetterCount,
    );
  }

  static bool _isEnglishLetter(int rune) {
    return (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);
  }

  static bool _isRussianLetter(int rune) {
    return (rune >= 0x0410 && rune <= 0x044F) ||
        rune == 0x0401 ||
        rune == 0x0451;
  }

  static bool _isThaiLetter(int rune) {
    return (rune >= 0x0E01 && rune <= 0x0E3A) ||
        (rune >= 0x0E40 && rune <= 0x0E4E);
  }
}
