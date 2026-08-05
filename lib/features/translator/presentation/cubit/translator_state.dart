import 'package:equatable/equatable.dart';

import '../../application/translator_progress.dart';
import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_matrix_result.dart';
import '../../domain/errors/translator_exception.dart';

enum TranslatorStatus { idle, running, success, failure, cancelled }

final class TranslatorState extends Equatable {
  const TranslatorState({
    this.status = TranslatorStatus.idle,
    this.sourceLanguageSelection = SourceLanguageSelection.automatic,
    this.progress,
    this.history = const <TranslationMatrixResult>[],
    this.failureKind,
    this.failureDetail = '',
  });

  final TranslatorStatus status;
  final SourceLanguageSelection sourceLanguageSelection;
  final TranslatorProgress? progress;
  final List<TranslationMatrixResult> history;
  final TranslatorFailureKind? failureKind;
  final String failureDetail;

  bool get isRunning => status == TranslatorStatus.running;

  TranslationMatrixResult? get latestResult {
    return history.isEmpty ? null : history.first;
  }

  TranslatorState copyWith({
    TranslatorStatus? status,
    SourceLanguageSelection? sourceLanguageSelection,
    TranslatorProgress? progress,
    bool clearProgress = false,
    List<TranslationMatrixResult>? history,
    TranslatorFailureKind? failureKind,
    bool clearFailureKind = false,
    String? failureDetail,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceLanguageSelection:
          sourceLanguageSelection ?? this.sourceLanguageSelection,
      progress: clearProgress ? null : progress ?? this.progress,
      history: history ?? this.history,
      failureKind: clearFailureKind ? null : failureKind ?? this.failureKind,
      failureDetail: failureDetail ?? this.failureDetail,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    sourceLanguageSelection,
    progress,
    history,
    failureKind,
    failureDetail,
  ];
}
