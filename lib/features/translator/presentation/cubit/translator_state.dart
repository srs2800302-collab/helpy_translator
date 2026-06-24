import 'package:equatable/equatable.dart';

import '../../domain/entities/translation_result.dart';

enum TranslatorStatus {
  initial,
  loading,
  success,
  failure,
}

final class TranslatorState extends Equatable {
  const TranslatorState({
    required this.status,
    required this.result,
    required this.errorMessage,
  });

  const TranslatorState.initial()
      : status = TranslatorStatus.initial,
        result = null,
        errorMessage = '';

  final TranslatorStatus status;
  final TranslationResult? result;
  final String errorMessage;

  TranslatorState copyWith({
    TranslatorStatus? status,
    TranslationResult? result,
    String? errorMessage,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        result,
        errorMessage,
      ];
}
