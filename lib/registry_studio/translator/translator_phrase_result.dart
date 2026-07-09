import 'package:equatable/equatable.dart';

import 'translator_phrase_status.dart';

final class TranslatorPhraseResult extends Equatable {
  factory TranslatorPhraseResult({
    required String sourceLanguage,
    required String sourceText,
    required TranslatorPhraseStatus status,
    String? ru,
    String? en,
    String? th,
    String? enToRu,
    String? thToRu,
    String? enToTh,
    String? thToEn,
    String? comment,
    String? candidateCanonicalPhrase,
  }) {
    return TranslatorPhraseResult._(
      sourceLanguage: _requiredText(
        sourceLanguage,
        'sourceLanguage',
        'Translator phrase source language must not be empty.',
      ),
      sourceText: _requiredText(
        sourceText,
        'sourceText',
        'Translator phrase source text must not be empty.',
      ),
      status: status,
      ru: _optionalText(ru),
      en: _optionalText(en),
      th: _optionalText(th),
      enToRu: _optionalText(enToRu),
      thToRu: _optionalText(thToRu),
      enToTh: _optionalText(enToTh),
      thToEn: _optionalText(thToEn),
      comment: _optionalText(comment),
      candidateCanonicalPhrase: _optionalText(candidateCanonicalPhrase),
    );
  }

  const TranslatorPhraseResult._({
    required this.sourceLanguage,
    required this.sourceText,
    required this.status,
    required this.ru,
    required this.en,
    required this.th,
    required this.enToRu,
    required this.thToRu,
    required this.enToTh,
    required this.thToEn,
    required this.comment,
    required this.candidateCanonicalPhrase,
  });

  final String sourceLanguage;
  final String sourceText;
  final TranslatorPhraseStatus status;
  final String? ru;
  final String? en;
  final String? th;
  final String? enToRu;
  final String? thToRu;
  final String? enToTh;
  final String? thToEn;
  final String? comment;
  final String? candidateCanonicalPhrase;

  static String _requiredText(String value, String name, String message) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(value, name, message);
    }

    return normalized;
  }

  static String? _optionalText(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  @override
  List<Object?> get props => <Object?>[
    sourceLanguage,
    sourceText,
    status,
    ru,
    en,
    th,
    enToRu,
    thToRu,
    enToTh,
    thToEn,
    comment,
    candidateCanonicalPhrase,
  ];
}
