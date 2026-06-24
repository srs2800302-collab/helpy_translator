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
    required this.auditResults,
    required this.errorMessage,
  });

  const TranslatorState.initial()
      : status = TranslatorStatus.initial,
        result = null,
        auditResults = const <CanonicalAuditResult>[],
        errorMessage = '';

  final TranslatorStatus status;
  final TranslationResult? result;
  final List<CanonicalAuditResult> auditResults;
  final String errorMessage;

  TranslatorState copyWith({
    TranslatorStatus? status,
    TranslationResult? result,
    List<CanonicalAuditResult>? auditResults,
    String? errorMessage,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      result: result ?? this.result,
      auditResults: auditResults ?? this.auditResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        result,
        auditResults,
        errorMessage,
      ];
}
