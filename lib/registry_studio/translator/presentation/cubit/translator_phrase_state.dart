import 'package:equatable/equatable.dart';

import '../../translator_phrase_result.dart';

enum TranslatorPhrasePresentationStatus { initial, loading, success, failure }

final class TranslatorPhraseState extends Equatable {
  const TranslatorPhraseState.initial({
    this.history = const <TranslatorPhraseResult>[],
  }) : status = TranslatorPhrasePresentationStatus.initial,
       errorMessage = '';

  const TranslatorPhraseState.loading({
    this.history = const <TranslatorPhraseResult>[],
  }) : status = TranslatorPhrasePresentationStatus.loading,
       errorMessage = '';

  factory TranslatorPhraseState.success({
    required TranslatorPhraseResult result,
    List<TranslatorPhraseResult>? history,
  }) {
    return TranslatorPhraseState._(
      status: TranslatorPhrasePresentationStatus.success,
      history: List<TranslatorPhraseResult>.unmodifiable(
        history ?? <TranslatorPhraseResult>[result],
      ),
      errorMessage: '',
    );
  }

  factory TranslatorPhraseState.failure({
    required String errorMessage,
    List<TranslatorPhraseResult> history = const <TranslatorPhraseResult>[],
  }) {
    return TranslatorPhraseState._(
      status: TranslatorPhrasePresentationStatus.failure,
      history: List<TranslatorPhraseResult>.unmodifiable(history),
      errorMessage: _normalizedError(errorMessage),
    );
  }

  const TranslatorPhraseState._({
    required this.status,
    required this.history,
    required this.errorMessage,
  });

  final TranslatorPhrasePresentationStatus status;
  final List<TranslatorPhraseResult> history;
  final String errorMessage;

  TranslatorPhraseResult? get result {
    return history.isEmpty ? null : history.first;
  }

  static String _normalizedError(String value) {
    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return 'Translator phrase action failed.';
    }

    return normalized;
  }

  @override
  List<Object?> get props => <Object?>[status, history, errorMessage];
}
