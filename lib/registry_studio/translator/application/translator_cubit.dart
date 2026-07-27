import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/translator_models.dart';
import 'translator_draft_store.dart';
import 'translator_provider.dart';
import 'translator_state.dart';

export 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({required this.provider, required this.draftStore})
    : super(const TranslatorState.initial());

  final TranslatorProvider provider;
  final TranslatorDraftStore draftStore;

  TranslatorOperation? _operation;
  StreamSubscription<TranslatorRunStage>? _progressSubscription;
  Timer? _draftSaveTimer;
  int _requestId = 0;

  Future<void> restore() async {
    try {
      final TranslatorDraft? draft = await draftStore.load();

      if (draft == null) {
        emit(
          state.copyWith(
            status: TranslatorViewStatus.idle,
            clearStage: true,
            clearFailure: true,
          ),
        );
        return;
      }

      emit(
        TranslatorState(
          status: draft.report == null
              ? TranslatorViewStatus.idle
              : TranslatorViewStatus.success,
          sourceText: draft.sourceText,
          report: draft.report,
        ),
      );
    } on FormatException catch (error) {
      emit(
        TranslatorState(
          status: TranslatorViewStatus.idle,
          sourceText: '',
          restoreWarning:
              'Сохранённый Translator draft повреждён: ${error.message}',
        ),
      );
    }
  }

  Future<void> updateSourceText(String value) async {
    if (state.isRunning || value == state.sourceText) {
      return;
    }

    emit(
      state.copyWith(
        status: TranslatorViewStatus.idle,
        sourceText: value,
        clearReport: true,
        clearFailure: true,
        clearStage: true,
      ),
    );

    _scheduleDraftSave();
  }

  Future<void> translate({required String accessKey}) async {
    final String sourceText = state.sourceText.trim();

    if (sourceText.isEmpty) {
      emit(
        state.copyWith(
          status: TranslatorViewStatus.failure,
          failure: TranslatorFailure(
            stage: TranslatorFailureStage.validation,
            code: TranslatorFailureCode.sourceTextEmpty,
            message: 'Введите исходную формулировку.',
          ),
          clearReport: true,
          clearStage: true,
        ),
      );
      return;
    }

    await _cancelActiveOperation();

    final int requestId = ++_requestId;
    final TranslatorWorkRequest request = TranslatorWorkRequest(
      sourceText: sourceText,
    );
    final TranslatorOperation operation = provider.start(
      request: request,
      accessKey: accessKey,
    );

    _operation = operation;

    emit(
      state.copyWith(
        status: TranslatorViewStatus.running,
        sourceText: sourceText,
        clearReport: true,
        clearFailure: true,
        clearStage: true,
      ),
    );

    _progressSubscription = operation.progress.listen((
      TranslatorRunStage stage,
    ) {
      if (requestId == _requestId && !isClosed) {
        emit(state.copyWith(stage: stage));
      }
    });

    try {
      final TranslatorRunReport report = await operation.result;

      if (requestId != _requestId || isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: TranslatorViewStatus.success,
          report: report,
          clearFailure: true,
          clearStage: true,
        ),
      );

      await _saveDraft();
    } on TranslatorProviderException catch (error) {
      if (requestId != _requestId || isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: error.failure.isCancelled
              ? TranslatorViewStatus.cancelled
              : TranslatorViewStatus.failure,
          failure: error.failure,
          clearReport: true,
          clearStage: true,
        ),
      );

      await _saveDraft();
    } finally {
      if (requestId == _requestId) {
        await _progressSubscription?.cancel();
        _progressSubscription = null;
        _operation = null;
      }
    }
  }

  Future<void> cancel() async {
    if (!state.isRunning) {
      return;
    }

    _requestId += 1;
    _operation?.cancel();
    await _progressSubscription?.cancel();
    _progressSubscription = null;
    _operation = null;

    emit(
      state.copyWith(
        status: TranslatorViewStatus.cancelled,
        failure: TranslatorFailure(
          stage: TranslatorFailureStage.transport,
          code: TranslatorFailureCode.cancelled,
          message: 'Перевод отменён.',
        ),
        clearStage: true,
      ),
    );

    await _saveDraft();
  }

  Future<void> clear() async {
    await _cancelActiveOperation();
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    _requestId += 1;
    await draftStore.clear();

    emit(
      const TranslatorState(status: TranslatorViewStatus.idle, sourceText: ''),
    );
  }

  void _scheduleDraftSave() {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      _draftSaveTimer = null;
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() {
    return draftStore.save(
      TranslatorDraft(sourceText: state.sourceText, report: state.report),
    );
  }

  Future<void> _cancelActiveOperation() async {
    _operation?.cancel();
    await _progressSubscription?.cancel();
    _progressSubscription = null;
    _operation = null;
  }

  @override
  Future<void> close() async {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    await _cancelActiveOperation();
    return super.close();
  }
}
