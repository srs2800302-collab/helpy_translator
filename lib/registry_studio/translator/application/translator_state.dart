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
