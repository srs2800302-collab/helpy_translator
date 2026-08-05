enum TranslationLanguage {
  russian('RU', 'Русский'),
  english('EN', 'English'),
  thai('TH', 'ไทย');

  const TranslationLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  static TranslationLanguage? tryParse(String value) {
    final String normalized = value.trim().toUpperCase();

    for (final TranslationLanguage language in values) {
      if (language.code == normalized) {
        return language;
      }
    }

    return null;
  }
}

enum SourceLanguageSelection {
  automatic,
  russian,
  english,
  thai;

  TranslationLanguage? get explicitLanguage {
    return switch (this) {
      SourceLanguageSelection.automatic => null,
      SourceLanguageSelection.russian => TranslationLanguage.russian,
      SourceLanguageSelection.english => TranslationLanguage.english,
      SourceLanguageSelection.thai => TranslationLanguage.thai,
    };
  }
}
