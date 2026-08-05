import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/run_translation_matrix.dart';
import '../../application/translator_cancellation_signal.dart';
import '../../application/translator_progress.dart';
import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_matrix_result.dart';
import '../../domain/errors/translator_exception.dart';
import 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({required RunTranslationMatrix runTranslationMatrix})
    : _runTranslationMatrix = runTranslationMatrix,
      super(const TranslatorState());

  final RunTranslationMatrix _runTranslationMatrix;
  TranslatorCancellationSignal? _activeCancellationSignal;

  void selectSourceLanguage(SourceLanguageSelection selection) {
    if (state.isRunning || state.sourceLanguageSelection == selection) {
      return;
    }

    emit(
      state.copyWith(
        sourceLanguageSelection: selection,
        status: TranslatorStatus.idle,
        clearFailureKind: true,
        failureDetail: '',
      ),
    );
  }

  Future<void> translate(String sourceText) async {
    if (state.isRunning) {
      return;
    }

    final TranslatorCancellationSignal cancellationSignal =
        TranslatorCancellationSignal();
    _activeCancellationSignal = cancellationSignal;

    emit(
      state.copyWith(
        status: TranslatorStatus.running,
        clearProgress: true,
        clearFailureKind: true,
        failureDetail: '',
      ),
    );

    try {
      final TranslationMatrixResult result = await _runTranslationMatrix(
        sourceText: sourceText,
        sourceLanguageSelection: state.sourceLanguageSelection,
        cancellationSignal: cancellationSignal,
        onProgress: _onProgress,
      );

      if (isClosed || cancellationSignal.isCancelled) {
        return;
      }

      emit(
        state.copyWith(
          status: TranslatorStatus.success,
          clearProgress: true,
          history: List<TranslationMatrixResult>.unmodifiable(
            <TranslationMatrixResult>[result, ...state.history],
          ),
          clearFailureKind: true,
          failureDetail: '',
        ),
      );
    } on TranslatorException catch (error) {
      if (isClosed) {
        return;
      }

      if (error.kind == TranslatorFailureKind.cancelled) {
        emit(
          state.copyWith(
            status: TranslatorStatus.cancelled,
            clearProgress: true,
            failureKind: error.kind,
            failureDetail: error.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: TranslatorStatus.failure,
            clearProgress: true,
            failureKind: error.kind,
            failureDetail: error.message,
          ),
        );
      }
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: TranslatorStatus.failure,
          clearProgress: true,
          failureKind: TranslatorFailureKind.provider,
          failureDetail: error.toString(),
        ),
      );
    } finally {
      if (identical(_activeCancellationSignal, cancellationSignal)) {
        _activeCancellationSignal = null;
      }
    }
  }

  void cancel() {
    _activeCancellationSignal?.cancel();
  }

  void clearResults() {
    if (state.isRunning) {
      return;
    }

    emit(
      TranslatorState(sourceLanguageSelection: state.sourceLanguageSelection),
    );
  }

  void _onProgress(TranslatorProgress progress) {
    if (isClosed || !state.isRunning) {
      return;
    }

    emit(state.copyWith(progress: progress));
  }

  @override
  Future<void> close() {
    _activeCancellationSignal?.cancel();
    return super.close();
  }
}
