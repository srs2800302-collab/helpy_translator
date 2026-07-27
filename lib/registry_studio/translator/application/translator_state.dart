import 'package:equatable/equatable.dart';

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
  factory TranslatorState({
    required TranslatorViewStatus status,
    required String sourceText,
    TranslatorRunStage? stage,
    TranslatorRunReport? report,
    TranslationBundle? partialBundle,
    TranslatorFailure? failure,
    String? restoreWarning,
    String? historyWarning,
    Iterable<TranslatorHistoryEntry> history = const <TranslatorHistoryEntry>[],
  }) {
    return TranslatorState._(
      status: status,
      sourceText: sourceText,
      stage: stage,
      report: report,
      partialBundle: partialBundle,
      failure: failure,
      restoreWarning: restoreWarning,
      historyWarning: historyWarning,
      history: List<TranslatorHistoryEntry>.unmodifiable(history),
    );
  }

  factory TranslatorState.initial() {
    return TranslatorState(
      status: TranslatorViewStatus.restoring,
      sourceText: '',
    );
  }

  const TranslatorState._({
    required this.status,
    required this.sourceText,
    required this.stage,
    required this.report,
    required this.partialBundle,
    required this.failure,
    required this.restoreWarning,
    required this.historyWarning,
    required this.history,
  });

  final TranslatorViewStatus status;
  final String sourceText;
  final TranslatorRunStage? stage;
  final TranslatorRunReport? report;
  final TranslationBundle? partialBundle;
  final TranslatorFailure? failure;
  final String? restoreWarning;
  final String? historyWarning;
  final List<TranslatorHistoryEntry> history;

  bool get isRunning => status == TranslatorViewStatus.running;

  bool get canRetryAudit =>
      !isRunning && report == null && partialBundle != null;

  TranslatorState copyWith({
    TranslatorViewStatus? status,
    String? sourceText,
    TranslatorRunStage? stage,
    bool clearStage = false,
    TranslatorRunReport? report,
    bool clearReport = false,
    TranslationBundle? partialBundle,
    bool clearPartialBundle = false,
    TranslatorFailure? failure,
    bool clearFailure = false,
    String? restoreWarning,
    bool clearRestoreWarning = false,
    String? historyWarning,
    bool clearHistoryWarning = false,
    Iterable<TranslatorHistoryEntry>? history,
  }) {
    return TranslatorState._(
      status: status ?? this.status,
      sourceText: sourceText ?? this.sourceText,
      stage: clearStage ? null : stage ?? this.stage,
      report: clearReport ? null : report ?? this.report,
      partialBundle: clearPartialBundle
          ? null
          : partialBundle ?? this.partialBundle,
      failure: clearFailure ? null : failure ?? this.failure,
      restoreWarning: clearRestoreWarning
          ? null
          : restoreWarning ?? this.restoreWarning,
      historyWarning: clearHistoryWarning
          ? null
          : historyWarning ?? this.historyWarning,
      history: history == null
          ? this.history
          : List<TranslatorHistoryEntry>.unmodifiable(history),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    sourceText,
    stage,
    report,
    partialBundle,
    failure,
    restoreWarning,
    historyWarning,
    history,
  ];
}
