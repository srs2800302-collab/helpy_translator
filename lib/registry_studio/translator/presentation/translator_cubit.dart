import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/translator_draft_store.dart';
import '../application/translator_provider.dart';
import '../domain/translator_models.dart';

enum TranslatorViewStatus {
  restoring,
  idle,
  running,
  success,
  failure,
  cancelled,
}

final class TranslatorState extends Equatable {
  const TranslatorState({
    required this.status,
    required this.sourceText,
    required this.sourceLanguageHint,
    this.stage,
    this.report,
    this.failure,
    this.restoreWarning,
  });

  const TranslatorState.initial()
    : this(
        status: TranslatorViewStatus.restoring,
        sourceText: '',
        sourceLanguageHint: null,
      );

  final TranslatorViewStatus status;
  final String sourceText;
  final TranslationLanguage? sourceLanguageHint;
  final TranslatorRunStage? stage;
  final TranslatorRunReport? report;
  final TranslatorFailure? failure;
  final String? restoreWarning;

  bool get isRunning => status == TranslatorViewStatus.running;

  TranslatorState copyWith({
    TranslatorViewStatus? status,
    String? sourceText,
    TranslationLanguage? sourceLanguageHint,
    bool clearSourceLanguageHint = false,
    TranslatorRunStage? stage,
    bool clearStage = false,
    TranslatorRunReport? report,
    bool clearReport = false,
    TranslatorFailure? failure,
    bool clearFailure = false,
    String? restoreWarning,
    bool clearRestoreWarning = false,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      sourceLanguageHint: clearSourceLanguageHint
          ? null
          : sourceLanguageHint ?? this.sourceLanguageHint,
      stage: clearStage ? null : stage ?? this.stage,
      report: clearReport ? null : report ?? this.report,
      failure: clearFailure ? null : failure ?? this.failure,
      restoreWarning: clearRestoreWarning
          ? null
          : restoreWarning ?? this.restoreWarning,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    sourceText,
    sourceLanguageHint,
    stage,
    report,
    failure,
    restoreWarning,
  ];
}

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
          sourceLanguageHint: draft.sourceLanguageHint,
          report: draft.report,
        ),
      );
    } on FormatException catch (error) {
      emit(
        TranslatorState(
          status: TranslatorViewStatus.idle,
          sourceText: '',
          sourceLanguageHint: null,
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

  Future<void> selectSourceLanguage(TranslationLanguage? language) async {
    if (state.isRunning || language == state.sourceLanguageHint) {
      return;
    }

    emit(
      state.copyWith(
        status: TranslatorViewStatus.idle,
        sourceLanguageHint: language,
        clearSourceLanguageHint: language == null,
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
      sourceLanguageHint: state.sourceLanguageHint,
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
      const TranslatorState(
        status: TranslatorViewStatus.idle,
        sourceText: '',
        sourceLanguageHint: null,
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
    return draftStore.save(
      TranslatorDraft(
        sourceText: state.sourceText,
        sourceLanguageHint: state.sourceLanguageHint,
        report: state.report,
      ),
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
