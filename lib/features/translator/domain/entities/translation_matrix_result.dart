import 'package:equatable/equatable.dart';

import 'matrix_assessment.dart';
import 'translation_language.dart';
import 'translation_route_result.dart';

enum TranslationAuditCoverage { base, expanded, prototype }

final class TranslationMatrixResult extends Equatable {
  const TranslationMatrixResult({
    required this.sourceText,
    required this.sourceLanguage,
    required this.routes,
    required this.assessment,
    required this.createdAt,
    this.auditCoverage = TranslationAuditCoverage.expanded,
  });

  final String sourceText;
  final TranslationLanguage sourceLanguage;
  final List<TranslationRouteResult> routes;
  final MatrixAssessment assessment;
  final DateTime createdAt;
  final TranslationAuditCoverage auditCoverage;

  @override
  List<Object> get props => <Object>[
    sourceText,
    sourceLanguage,
    routes,
    assessment,
    createdAt,
    auditCoverage,
  ];

  Map<String, Object> toJson() {
    return <String, Object>{
      'source_text': sourceText,
      'source_language': sourceLanguage.code,
      'routes': routes
          .map((TranslationRouteResult route) => route.toJson())
          .toList(),
      'assessment': assessment.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'audit_coverage': auditCoverage.name,
    };
  }
}
