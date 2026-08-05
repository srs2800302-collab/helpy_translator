import 'package:equatable/equatable.dart';

import 'translation_language.dart';

enum LanguageDetectionStatus { detected, mixed, unknown }

final class LanguageDetectionResult extends Equatable {
  const LanguageDetectionResult({
    required this.status,
    required this.detectedLanguage,
    required this.russianLetterCount,
    required this.englishLetterCount,
    required this.thaiLetterCount,
  });

  const LanguageDetectionResult.detected({
    required TranslationLanguage language,
    required int russianLetterCount,
    required int englishLetterCount,
    required int thaiLetterCount,
  }) : this(
         status: LanguageDetectionStatus.detected,
         detectedLanguage: language,
         russianLetterCount: russianLetterCount,
         englishLetterCount: englishLetterCount,
         thaiLetterCount: thaiLetterCount,
       );

  const LanguageDetectionResult.mixed({
    required int russianLetterCount,
    required int englishLetterCount,
    required int thaiLetterCount,
  }) : this(
         status: LanguageDetectionStatus.mixed,
         detectedLanguage: null,
         russianLetterCount: russianLetterCount,
         englishLetterCount: englishLetterCount,
         thaiLetterCount: thaiLetterCount,
       );

  const LanguageDetectionResult.unknown()
    : this(
        status: LanguageDetectionStatus.unknown,
        detectedLanguage: null,
        russianLetterCount: 0,
        englishLetterCount: 0,
        thaiLetterCount: 0,
      );

  final LanguageDetectionStatus status;
  final TranslationLanguage? detectedLanguage;
  final int russianLetterCount;
  final int englishLetterCount;
  final int thaiLetterCount;

  @override
  List<Object?> get props => <Object?>[
    status,
    detectedLanguage,
    russianLetterCount,
    englishLetterCount,
    thaiLetterCount,
  ];
}
