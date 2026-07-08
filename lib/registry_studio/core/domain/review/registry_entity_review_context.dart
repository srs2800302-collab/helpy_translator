import 'package:equatable/equatable.dart';

import '../entities/registry_entity.dart';
import '../evidence/source_evidence.dart';

final class RegistryEntityReviewContext extends Equatable {
  factory RegistryEntityReviewContext({
    required RegistryEntity entity,
    required Iterable<SourceEvidence> evidence,
  }) {
    final List<SourceEvidence> normalizedEvidence =
        List<SourceEvidence>.unmodifiable(evidence);

    if (normalizedEvidence.isEmpty) {
      throw ArgumentError.value(
        evidence,
        'evidence',
        'Registry entity review context must contain source evidence.',
      );
    }

    return RegistryEntityReviewContext._(
      entity: entity,
      evidence: normalizedEvidence,
    );
  }

  const RegistryEntityReviewContext._({
    required this.entity,
    required this.evidence,
  });

  final RegistryEntity entity;
  final List<SourceEvidence> evidence;

  @override
  List<Object?> get props => <Object?>[
    entity.id,
    entity.path,
    entity.kind,
    entity.payload,
    evidence,
  ];
}
