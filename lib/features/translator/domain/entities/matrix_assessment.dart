import 'package:equatable/equatable.dart';

import 'semantic_observation.dart';

enum MatrixVerdict {
  noCriticalDriftDetected,
  acceptableVariation,
  reviewRequired,
  unreliable,
  indeterminate,
}

final class MatrixAssessment extends Equatable {
  const MatrixAssessment({
    required this.verdict,
    required this.observations,
    required this.limitations,
  });

  final MatrixVerdict verdict;
  final List<SemanticObservation> observations;
  final List<String> limitations;

  @override
  List<Object> get props => <Object>[verdict, observations, limitations];

  Map<String, Object> toJson() {
    return <String, Object>{
      'verdict': verdict.name,
      'observations': observations
          .map((SemanticObservation observation) => observation.toJson())
          .toList(growable: false),
      'limitations': limitations,
    };
  }
}
