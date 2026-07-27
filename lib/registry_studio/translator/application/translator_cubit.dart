import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/translator_models.dart';
import 'translator_draft_store.dart';
import 'translator_history_store.dart';
import 'translator_provider.dart';
import 'translator_state.dart';

export 'translator_state.dart';

final class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({
    required this.provider,
    required this.draftStore,
    required this.historyStore,
  }) : super(TranslatorState.initial());

  final TranslatorProvider provider;
  final TranslatorDraftStore draftStore;
  final TranslatorHistoryStore historyStore;

  TranslatorOperation? _operation;
  StreamSubscription<TranslatorRunStage>? _progressSubscription;
  StreamSubscription<TranslationBundle>? _partialBundleSubscription;
  Timer? _draftSaveTimer;
  int _requestId = 0;
  Future<void> _pendingDraftWrite = Future<void>.value();

  Future<void> restore() async {
    TranslatorDraft? draft;
    List<TranslatorHistoryEntry> history = const <TranslatorHistoryEntry>[];
    String? restoreWarning;
    String? historyWarning;

    try {
      draft = await draftStore.load();
    } on FormatException catch (error) {
      restoreWarning =
          'Сохранённое рабочее состояние Translator повреждено: '
          '${error.message}';
    } catch (_) {
      restoreWarning =
          'Не удалось восстановить рабочее состояние Translator. '
          'Можно продолжить работу с новым текстом.';
    }

    try {
      history = await historyStore.load();
    } on FormatException catch (error) {
      historyWarning =
          'Сохранённая история переводов повреждена: ${error.message}';
    } catch (_) {
      historyWarning =
          'Не удалось восстановить историю переводов. '
          'Новые переводы можно продолжать создавать.';
    }

    final TranslatorRunReport? legacyReport = draft?.report;

    if (legacyReport != null) {
      final bool alreadyStored = history.any(
        (TranslatorHistoryEntry entry) => entry.report == legacyReport,
      );
      bool migrationPersisted = alreadyStored;

      if (!alreadyStored) {
        history = <TranslatorHistoryEntry>[
          _createHistoryEntry(legacyReport, history),
          ...history,
        ];

        try {
          await historyStore.save(history);
          migrationPersisted = true;
        } catch (_) {
          historyWarning =
              'Последний перевод показан в истории, '
              'но не удалось сохранить миграцию на устройстве.';
        }
      }

      if (migrationPersisted) {
        final TranslatorDraft migratedDraft = TranslatorDraft(
          sourceText: draft!.sourceText,
          partialBundle: draft.partialBundle,
        );

        try {
          await draftStore.save(migratedDraft);
          draft = migratedDraft;
        } catch (_) {
          restoreWarning =
              'Последний перевод восстановлен в историю, '
              'но рабочее состояние не удалось обновить.';
        }
      }
    }

    final TranslationBundle? partialBundle = draft?.partialBundle;

    if (isClosed) {
      return;
    }

    emit(
      TranslatorState(
        status: partialBundle == null
            ? TranslatorViewStatus.idle
            : TranslatorViewStatus.failure,
        sourceText: draft?.sourceText ?? '',
        report: null,
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
        restoreWarning: restoreWarning,
        historyWarning: historyWarning,
        history: history,
      ),
    );
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

  Future<void> deleteHistoryEntry(String id) async {
    if (state.isRunning) {
      return;
    }

    final List<TranslatorHistoryEntry> updated = state.history
        .where((TranslatorHistoryEntry entry) => entry.id != id)
        .toList(growable: false);

    if (updated.length == state.history.length) {
      return;
    }

    try {
      await historyStore.save(updated);

      if (isClosed) {
        return;
      }

      emit(state.copyWith(history: updated, clearHistoryWarning: true));
    } catch (_) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          historyWarning: 'Не удалось удалить запись из истории на устройстве.',
        ),
      );
    }
  }

  Future<void> clearHistory() async {
    if (state.isRunning || state.history.isEmpty) {
      return;
    }

    try {
      await historyStore.clear();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          history: const <TranslatorHistoryEntry>[],
          clearHistoryWarning: true,
        ),
      );
    } catch (_) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          historyWarning: 'Не удалось удалить историю переводов на устройстве.',
        ),
      );
    }
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

      final List<TranslatorHistoryEntry> updatedHistory =
          <TranslatorHistoryEntry>[
            _createHistoryEntry(report, state.history),
            ...state.history,
          ];
      bool historyPersisted = true;
      String? historyWarning;

      try {
        await historyStore.save(updatedHistory);
      } catch (_) {
        historyPersisted = false;
        historyWarning =
            'Перевод добавлен в текущую историю, '
            'но не удалось сохранить его на устройстве.';
      }

      if (requestId != _requestId || isClosed) {
        return;
      }

      emit(
        state.copyWith(
          status: TranslatorViewStatus.success,
          report: historyPersisted ? null : report,
          clearReport: historyPersisted,
          history: updatedHistory,
          historyWarning: historyWarning,
          clearHistoryWarning: historyPersisted,
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
      TranslatorState(
        status: TranslatorViewStatus.idle,
        sourceText: '',
        history: state.history,
        historyWarning: state.historyWarning,
      ),
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

  TranslatorHistoryEntry _createHistoryEntry(
    TranslatorRunReport report,
    List<TranslatorHistoryEntry> existing,
  ) {
    final String base =
        'translation-${report.createdAt.toUtc().microsecondsSinceEpoch}';
    final Set<String> existingIds = existing
        .map((TranslatorHistoryEntry entry) => entry.id)
        .toSet();
    String candidate = base;
    int suffix = 2;

    while (existingIds.contains(candidate)) {
      candidate = '$base-$suffix';
      suffix += 1;
    }

    return TranslatorHistoryEntry(id: candidate, report: report);
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
