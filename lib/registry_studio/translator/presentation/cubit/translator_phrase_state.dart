import 'package:equatable/equatable.dart';

import '../../translator_phrase_result.dart';

enum TranslatorPhrasePresentationStatus { initial, loading, success, failure }

final class TranslatorPhraseState extends Equatable {
  factory TranslatorPhraseState.failure({required String errorMessage}) {
    return TranslatorPhraseState._(
      status: TranslatorPhrasePresentationStatus.failure,
      result: null,
      errorMessage: _normalizedError(errorMessage),
    );
  }

  const TranslatorPhraseState.initial()
    : status = TranslatorPhrasePresentationStatus.initial,
      result = null,
      errorMessage = '';

  const TranslatorPhraseState.loading()
    : status = TranslatorPhrasePresentationStatus.loading,
      result = null,
      errorMessage = '';

  const TranslatorPhraseState.success({required TranslatorPhraseResult result})
    : status = TranslatorPhrasePresentationStatus.success,
      result = result,
      errorMessage = '';

  const TranslatorPhraseState._({
    required this.status,
    required this.result,
    required this.errorMessage,
  });

  final TranslatorPhrasePresentationStatus status;
  final TranslatorPhraseResult? result;
  final String errorMessage;

  static String _normalizedError(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return 'Translator phrase action failed.';
    }

    return normalized;
  }

  @override
  List<Object?> get props => <Object?>[status, result, errorMessage];
}
