import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/translate_phrase.dart';
import '../../application/translator_phrase_history_persistence.dart';
import '../../translator_phrase_result.dart';
import 'translator_phrase_state.dart';

final class TranslatorPhraseCubit extends Cubit<TranslatorPhraseState> {
  TranslatorPhraseCubit({
    required TranslatePhrase translatePhrase,
    TranslatorPhraseHistoryPersistence? historyPersistence,
  }) : _translatePhrase = translatePhrase,
       _historyPersistence = historyPersistence,
       super(const TranslatorPhraseState.initial());

  final TranslatePhrase _translatePhrase;
  final TranslatorPhraseHistoryPersistence? _historyPersistence;

  Future<void>? _restoreFuture;

  Future<void> restore() {
    final TranslatorPhraseHistoryPersistence? persistence = _historyPersistence;

    if (persistence == null) {
      return Future<void>.value();
    }

    return _restoreFuture ??= _restore(persistence);
  }

  Future<void> _restore(TranslatorPhraseHistoryPersistence persistence) async {
    try {
      final List<TranslatorPhraseResult> history =
          List<TranslatorPhraseResult>.unmodifiable(await persistence.load());

      emit(TranslatorPhraseState.initial(history: history));
    } catch (error) {
      emit(
        TranslatorPhraseState.failure(
          history: state.history,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> translatePhrase({required String sourceText}) async {
    final TranslatorPhraseHistoryPersistence? persistence = _historyPersistence;

    if (persistence != null) {
      await restore();
    }

    final List<TranslatorPhraseResult> currentHistory = state.history;

    emit(TranslatorPhraseState.loading(history: currentHistory));

    try {
      final TranslatorPhraseResult result = await _translatePhrase(
        sourceText: sourceText,
      );

      final List<TranslatorPhraseResult> updatedHistory =
          List<TranslatorPhraseResult>.unmodifiable(<TranslatorPhraseResult>[
            result,
            ...currentHistory,
          ]);

      if (persistence != null) {
        try {
          await persistence.save(updatedHistory);
        } catch (error) {
          emit(
            TranslatorPhraseState.failure(
              history: updatedHistory,
              errorMessage: _errorMessage(error),
            ),
          );
          return;
        }
      }

      emit(
        TranslatorPhraseState.success(result: result, history: updatedHistory),
      );
    } catch (error) {
      emit(
        TranslatorPhraseState.failure(
          history: currentHistory,
          errorMessage: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> clear() async {
    final TranslatorPhraseHistoryPersistence? persistence = _historyPersistence;

    if (persistence != null) {
      await restore();

      try {
        await persistence.clear();
      } catch (error) {
        emit(
          TranslatorPhraseState.failure(
            history: state.history,
            errorMessage: _errorMessage(error),
          ),
        );
        return;
      }
    }

    emit(const TranslatorPhraseState.initial());
  }

  static String _errorMessage(Object error) {
    if (error is ArgumentError && error.message != null) {
      return error.message.toString();
    }

    return error.toString();
  }
}
