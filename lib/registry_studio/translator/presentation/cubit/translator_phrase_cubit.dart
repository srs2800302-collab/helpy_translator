import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/translate_phrase.dart';
import 'translator_phrase_state.dart';

final class TranslatorPhraseCubit extends Cubit<TranslatorPhraseState> {
  TranslatorPhraseCubit({required TranslatePhrase translatePhrase})
    : _translatePhrase = translatePhrase,
      super(const TranslatorPhraseState.initial());

  final TranslatePhrase _translatePhrase;

  Future<void> translatePhrase({
    required String sourceText,
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    emit(const TranslatorPhraseState.loading());

    try {
      final result = await _translatePhrase(
        sourceText: sourceText,
        sourceLanguageHint: sourceLanguageHint,
        engineerContext: engineerContext,
      );

      emit(TranslatorPhraseState.success(result: result));
    } catch (error) {
      emit(TranslatorPhraseState.failure(errorMessage: _errorMessage(error)));
    }
  }

  void clear() {
    emit(const TranslatorPhraseState.initial());
  }

  static String _errorMessage(Object error) {
    if (error is ArgumentError && error.message != null) {
      return error.message.toString();
    }

    return error.toString();
  }
}
