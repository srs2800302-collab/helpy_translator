import 'package:equatable/equatable.dart';

import '../../domain/entities/canonical_audit_result.dart';
import '../../domain/entities/translation_result.dart';

enum TranslatorStatus {
  initial,
  loading,
  success,
  failure,
  auditLoading,
  auditSuccess,
}

final class TranslatorState extends Equatable {
  const TranslatorState({
    required this.status,
    required this.result,
    required this.translationHistory,
    required this.auditResults,
    required this.errorMessage,
    required this.auditTotal,
    required this.auditCompleted,
    required this.currentAuditPhrase,
  });

  const TranslatorState.initial()
      : status = TranslatorStatus.initial,
        result = null,
        translationHistory = const <TranslationResult>[],
        auditResults = const <CanonicalAuditResult>[],
        errorMessage = '',
        auditTotal = 0,
        auditCompleted = 0,
        currentAuditPhrase = '';

  final TranslatorStatus status;
  final TranslationResult? result;
  final List<TranslationResult> translationHistory;
  final List<CanonicalAuditResult> auditResults;
  final String errorMessage;
  final int auditTotal;
  final int auditCompleted;
  final String currentAuditPhrase;

  TranslatorState copyWith({
    TranslatorStatus? status,
    TranslationResult? result,
    bool clearResult = false,
    List<TranslationResult>? translationHistory,
    bool clearTranslationHistory = false,
    List<CanonicalAuditResult>? auditResults,
    String? errorMessage,
    int? auditTotal,
    int? auditCompleted,
    String? currentAuditPhrase,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      result: clearResult ? null : result ?? this.result,
      translationHistory: clearTranslationHistory
          ? const <TranslationResult>[]
          : translationHistory ?? this.translationHistory,
      auditResults: auditResults ?? this.auditResults,
      errorMessage: errorMessage ?? this.errorMessage,
      auditTotal: auditTotal ?? this.auditTotal,
      auditCompleted: auditCompleted ?? this.auditCompleted,
      currentAuditPhrase: currentAuditPhrase ?? this.currentAuditPhrase,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        result,
        translationHistory,
        auditResults,
        errorMessage,
        auditTotal,
        auditCompleted,
        currentAuditPhrase,
      ];
}
