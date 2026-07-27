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
  StreamSubscription<TranslationBundle>? _partialBundleSubscription;
  Timer? _draftSaveTimer;
  int _requestId = 0;
  Future<void> _pendingDraftWrite = Future<void>.value();

  Future<void> restore() async {
    try {
      final TranslatorDraft? draft = await draftStore.load();

      if (draft == null) {
        emit(
          state.copyWith(
            status: TranslatorViewStatus.idle,
            clearStage: true,
            clearReport: true,
            clearPartialBundle: true,
            clearFailure: true,
          ),
        );
        return;
      }

      final TranslationBundle? partialBundle = draft.partialBundle;

      emit(
        TranslatorState(
          status: draft.report != null
              ? TranslatorViewStatus.success
              : partialBundle != null
              ? TranslatorViewStatus.failure
              : TranslatorViewStatus.idle,
          sourceText: draft.sourceText,
          report: draft.report,
          partialBundle: partialBundle,
          failure: partialBundle == null
              ? null
              : TranslatorFailure(
                  stage: TranslatorFailureStage.audit,
                  code: TranslatorFailureCode.networkFailure,
                  message:
                      'Прямой и обратный переводы сохранены. '
                      'Семантический аудит не завершён.',
                  completeness: TranslationCompleteness.complete,
                  partialBundle: partialBundle,
                ),
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
    } catch (_) {
      emit(
        const TranslatorState(
          status: TranslatorViewStatus.idle,
          sourceText: '',
          restoreWarning:
              'Не удалось восстановить Translator draft. '
              'Можно продолжить работу с новым текстом.',
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
        clearPartialBundle: true,
        clearFailure: true,
        clearStage: true,
      ),
    );

    _scheduleDraftSave();
  }

  Future<void> translate({required String accessKey}) async {
    final String sourceText = state.sourceText;

    if (sourceText.trim().isEmpty) {
      emit(
        state.copyWith(
          status: TranslatorViewStatus.failure,
          failure: TranslatorFailure(
            stage: TranslatorFailureStage.validation,
            code: TranslatorFailureCode.sourceTextEmpty,
            message: 'Введите исходную формулировку.',
          ),
          clearReport: true,
          clearPartialBundle: true,
          clearStage: true,
        ),
      );
      await _saveDraft();
      return;
    }

    await _cancelActiveOperation();

    final TranslatorWorkRequest request = TranslatorWorkRequest(
      sourceText: sourceText,
    );
    final TranslatorOperation operation = provider.start(
      request: request,
      accessKey: accessKey,
    );

    await _runOperation(
      operation: operation,
      sourceText: sourceText,
      clearPartialBundleAtStart: true,
    );
  }

  Future<void> retryAudit({required String accessKey}) async {
    final TranslationBundle? partialBundle = state.partialBundle;

    if (partialBundle == null || state.report != null || state.isRunning) {
      return;
    }

    final TranslatorProvider currentProvider = provider;

    if (currentProvider is! TranslatorAuditRetryProvider) {
      emit(
        state.copyWith(
          status: TranslatorViewStatus.failure,
          failure: TranslatorFailure(
            stage: TranslatorFailureStage.audit,
            code: TranslatorFailureCode.invalidAuditResponse,
            message:
                'Этот provider не поддерживает повтор только '
                'семантического аудита.',
            completeness: TranslationCompleteness.complete,
            partialBundle: partialBundle,
          ),
          clearStage: true,
        ),
      );
      return;
    }

    await _cancelActiveOperation();

    final TranslatorWorkRequest request = TranslatorWorkRequest(
      sourceText: state.sourceText,
    );
    final TranslatorAuditRetryProvider auditRetryProvider =
        currentProvider as TranslatorAuditRetryProvider;
    final TranslatorOperation operation = auditRetryProvider.startAudit(
      request: request,
      bundle: partialBundle,
      accessKey: accessKey,
    );

    await _runOperation(
      operation: operation,
      sourceText: state.sourceText,
      clearPartialBundleAtStart: false,
      initialStage: TranslatorRunStage.audit,
    );
  }

  Future<void> _runOperation({
    required TranslatorOperation operation,
    required String sourceText,
    required bool clearPartialBundleAtStart,
    TranslatorRunStage? initialStage,
  }) async {
    final int requestId = ++_requestId;
    _operation = operation;

    emit(
      state.copyWith(
        status: TranslatorViewStatus.running,
        sourceText: sourceText,
        stage: initialStage,
        clearStage: initialStage == null,
        clearReport: true,
        clearPartialBundle: clearPartialBundleAtStart,
        clearFailure: true,
      ),
    );

    _progressSubscription = operation.progress.listen((
      TranslatorRunStage stage,
    ) {
      if (requestId == _requestId && !isClosed) {
        emit(state.copyWith(stage: stage));
      }
    });

    if (operation is TranslatorPartialBundleOperation) {
      final TranslatorPartialBundleOperation partialBundleOperation =
          operation as TranslatorPartialBundleOperation;
      _partialBundleSubscription = partialBundleOperation.partialBundles.listen(
        (TranslationBundle bundle) {
          if (requestId != _requestId || isClosed) {
            return;
          }

          emit(
            state.copyWith(
              partialBundle: bundle,
              clearReport: true,
              clearFailure: true,
            ),
          );
          unawaited(_saveDraft());
        },
      );
    }

    try {
      final TranslatorRunReport report = await operation.result;

      if (requestId != _requestId || isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: TranslatorViewStatus.success,
          report: report,
          clearPartialBundle: true,
          clearFailure: true,
          clearStage: true,
        ),
      );

      await _saveDraft();
    } on TranslatorProviderException catch (error) {
      if (requestId != _requestId || isClosed) {
        return;
      }

      final TranslationBundle? partialBundle =
          error.failure.partialBundle ?? state.partialBundle;

      emit(
        state.copyWith(
          status: error.failure.isCancelled
              ? TranslatorViewStatus.cancelled
              : TranslatorViewStatus.failure,
          failure: error.failure,
          partialBundle: partialBundle,
          clearPartialBundle: partialBundle == null,
          clearReport: true,
          clearStage: true,
        ),
      );

      await _saveDraft();
    } catch (_) {
      if (requestId != _requestId || isClosed) {
        return;
      }

      final TranslationBundle? partialBundle = state.partialBundle;

      emit(
        state.copyWith(
          status: TranslatorViewStatus.failure,
          failure: TranslatorFailure(
            stage: partialBundle == null
                ? TranslatorFailureStage.transport
                : TranslatorFailureStage.audit,
            code: TranslatorFailureCode.unexpectedFailure,
            message: partialBundle == null
                ? 'Translator завершил операцию с непредвиденной '
                      'технической ошибкой.'
                : 'Прямой и обратный переводы сохранены, '
                      'но семантический аудит завершился '
                      'непредвиденной технической ошибкой.',
            completeness: partialBundle == null
                ? TranslationCompleteness.translationIncomplete
                : TranslationCompleteness.complete,
            partialBundle: partialBundle,
          ),
          partialBundle: partialBundle,
          clearPartialBundle: partialBundle == null,
          clearReport: true,
          clearStage: true,
        ),
      );

      await _saveDraft();
    } finally {
      if (requestId == _requestId) {
        await _progressSubscription?.cancel();
        await _partialBundleSubscription?.cancel();
        _progressSubscription = null;
        _partialBundleSubscription = null;
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
    await _partialBundleSubscription?.cancel();
    _progressSubscription = null;
    _partialBundleSubscription = null;
    _operation = null;

    final TranslationBundle? partialBundle = state.partialBundle;

    emit(
      state.copyWith(
        status: TranslatorViewStatus.cancelled,
        failure: TranslatorFailure(
          stage: partialBundle == null
              ? TranslatorFailureStage.transport
              : TranslatorFailureStage.audit,
          code: TranslatorFailureCode.cancelled,
          message: partialBundle == null
              ? 'Перевод отменён.'
              : 'Семантический аудит отменён. '
                    'Прямой и обратный переводы сохранены.',
          completeness: partialBundle == null
              ? null
              : TranslationCompleteness.complete,
          partialBundle: partialBundle,
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
    await _pendingDraftWrite;
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
    final TranslatorState snapshot = state;
    final TranslatorDraft draft = TranslatorDraft(
      sourceText: snapshot.sourceText,
      report: snapshot.report,
      partialBundle: snapshot.report == null ? snapshot.partialBundle : null,
    );

    final Future<void> write = _pendingDraftWrite.then<void>(
      (_) => draftStore.save(draft),
    );

    _pendingDraftWrite = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );

    return write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  Future<void> _cancelActiveOperation() async {
    _operation?.cancel();
    await _progressSubscription?.cancel();
    await _partialBundleSubscription?.cancel();
    _progressSubscription = null;
    _partialBundleSubscription = null;
    _operation = null;
  }

  @override
  Future<void> close() async {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = null;
    await _cancelActiveOperation();
    await _pendingDraftWrite;
    return super.close();
  }
}
