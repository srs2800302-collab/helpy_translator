import 'package:equatable/equatable.dart';

import 'translation_result.dart';

enum CanonicalAuditStatus {
  exact,
  equivalent,
  needsReview,
  drift,
  failed,
}

final class CanonicalAuditResult extends Equatable {
  const CanonicalAuditResult({
    required this.sourceRu,
    required this.translation,
    required this.status,
    required this.errorMessage,
  });

  final String sourceRu;
  final TranslationResult? translation;
  final CanonicalAuditStatus status;
  final String errorMessage;

  @override
  List<Object?> get props => <Object?>[
        sourceRu,
        translation,
        status,
        errorMessage,
      ];
}
