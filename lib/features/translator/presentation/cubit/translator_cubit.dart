import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/usecases/translate_canonical_phrase.dart';
import 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit(this.translateCanonicalPhrase)
      : super(const TranslatorState.initial());

  final TranslateCanonicalPhrase translateCanonicalPhrase;

  Future<void> translate(String sentence) async {
    emit(
      state.copyWith(
        status: TranslatorStatus.loading,
        errorMessage: '',
      ),
    );

    try {
      final result = await translateCanonicalPhrase(sentence);

      emit(
        state.copyWith(
          status: TranslatorStatus.success,
          result: result,
          errorMessage: '',
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          errorMessage: 'Неизвестная ошибка перевода.',
        ),
      );
    }
  }
}
