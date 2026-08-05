import 'package:equatable/equatable.dart';

import 'semantic_observation.dart';

final class SemanticAuditReport extends Equatable {
  const SemanticAuditReport({
    required this.observations,
    required this.limitations,
  });

  final List<SemanticObservation> observations;
  final List<String> limitations;

  @override
  List<Object> get props => <Object>[observations, limitations];

  Map<String, Object> toJson() {
    return <String, Object>{
      'observations': observations
          .map((SemanticObservation observation) => observation.toJson())
          .toList(growable: false),
      'limitations': limitations,
    };
  }
}
