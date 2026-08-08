import 'package:equatable/equatable.dart';

import 'matrix_assessment.dart';
import 'primary_linguist_report.dart';
import 'translation_language.dart';
import 'translation_route_result.dart';

enum TranslationAuditCoverage {
  base,
  expanded,
  prototype,
  blindConsensus,
}

final class TranslationMatrixResult extends Equatable {
  const TranslationMatrixResult({
    required this.sourceText,
    required this.sourceLanguage,
    required this.routes,
    required this.assessment,
    required this.createdAt,
    this.linguistReport = const PrimaryLinguistReport(
      assessments: <PrimaryLinguistAssessment>[],
      limitations: <String>[],
    ),
    this.auditCoverage =
        TranslationAuditCoverage.expanded,
  });

  final String sourceText;
  final TranslationLanguage sourceLanguage;
  final List<TranslationRouteResult> routes;
  final MatrixAssessment assessment;
  final PrimaryLinguistReport linguistReport;
  final DateTime createdAt;
  final TranslationAuditCoverage auditCoverage;

  @override
  List<Object> get props => <Object>[
    sourceText,
    sourceLanguage,
    routes,
    assessment,
    linguistReport,
    createdAt,
    auditCoverage,
  ];

  Map<String, Object> toJson() {
    return <String, Object>{
      'source_text': sourceText,
      'source_language': sourceLanguage.code,
      'routes': routes
          .map(
            (TranslationRouteResult route) =>
                route.toJson(),
          )
          .toList(),
      'assessment': assessment.toJson(),
      'linguist_report': linguistReport.toJson(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'audit_coverage': auditCoverage.name,
    };
  }
}
