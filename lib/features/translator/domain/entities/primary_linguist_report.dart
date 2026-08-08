import 'package:equatable/equatable.dart';

import 'translation_language.dart';

enum PrimaryLinguistStatus {
  compatible,
  incompatible,
  unresolved;

  String get code {
    return switch (this) {
      PrimaryLinguistStatus.compatible => 'COMPATIBLE',
      PrimaryLinguistStatus.incompatible => 'INCOMPATIBLE',
      PrimaryLinguistStatus.unresolved => 'UNRESOLVED',
    };
  }
}

final class PrimaryLinguistAssessment extends Equatable {
  const PrimaryLinguistAssessment({
    required this.routeId,
    required this.targetLanguage,
    required this.status,
    required this.sourceExcerpt,
    required this.targetExcerpt,
    required this.limitations,
  });

  final String routeId;
  final TranslationLanguage targetLanguage;
  final PrimaryLinguistStatus status;
  final String? sourceExcerpt;
  final String? targetExcerpt;
  final List<String> limitations;

  bool get hasCompleteDifferenceEvidence {
    return sourceExcerpt?.trim().isNotEmpty == true &&
        targetExcerpt?.trim().isNotEmpty == true;
  }

  @override
  List<Object?> get props => <Object?>[
    routeId,
    targetLanguage,
    status,
    sourceExcerpt,
    targetExcerpt,
    limitations,
  ];

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'route': routeId,
      'target_language': targetLanguage.code,
      'status': status.code,
      'source_excerpt': sourceExcerpt,
      'target_excerpt': targetExcerpt,
      'limitations': limitations,
    };
  }
}

final class PrimaryLinguistReport extends Equatable {
  const PrimaryLinguistReport({
    required this.assessments,
    required this.limitations,
  });

  final List<PrimaryLinguistAssessment> assessments;
  final List<String> limitations;

  @override
  List<Object> get props => <Object>[assessments, limitations];

  Map<String, Object> toJson() {
    return <String, Object>{
      'assessments': assessments
          .map((PrimaryLinguistAssessment assessment) => assessment.toJson())
          .toList(growable: false),
      'limitations': limitations,
    };
  }
}
