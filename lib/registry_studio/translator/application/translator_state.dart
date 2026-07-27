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
    this.stage,
    this.report,
    this.failure,
    this.restoreWarning,
  });

  const TranslatorState.initial()
    : this(status: TranslatorViewStatus.restoring, sourceText: '');

  final TranslatorViewStatus status;
  final String sourceText;
  final TranslatorRunStage? stage;
  final TranslatorRunReport? report;
  final TranslatorFailure? failure;
  final String? restoreWarning;

  bool get isRunning => status == TranslatorViewStatus.running;

  TranslatorState copyWith({
    TranslatorViewStatus? status,
    String? sourceText,
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
    stage,
    report,
    failure,
    restoreWarning,
  ];
}
