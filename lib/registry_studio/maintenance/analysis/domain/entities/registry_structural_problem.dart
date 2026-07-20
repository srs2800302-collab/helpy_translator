import 'package:equatable/equatable.dart';

import '../../../../core/domain/evidence/source_evidence.dart';
import '../../../../core/domain/value_objects/registry_path.dart';
import '../../../../registry/domain/entities/registry_node.dart';
import 'registry_node_change.dart';

enum RegistryStructuralProblemStatus { affected }

final class RegistryStructuralProblem extends Equatable {
  factory RegistryStructuralProblem.fromChange({
    required RegistryNodeChange change,
    required String baselineRevision,
    required String currentRevision,
  }) {
    final String normalizedBaselineRevision = baselineRevision.trim();
    final String normalizedCurrentRevision = currentRevision.trim();

    if (normalizedBaselineRevision.isEmpty) {
      throw ArgumentError.value(
        baselineRevision,
        'baselineRevision',
        'Structural problem baseline revision must not be empty.',
      );
    }

    if (normalizedCurrentRevision.isEmpty) {
      throw ArgumentError.value(
        currentRevision,
        'currentRevision',
        'Structural problem current revision must not be empty.',
      );
    }

    final String reason = switch (change.kind) {
      RegistryNodeChangeKind.added => 'Добавлен новый Registry-узел.',
      RegistryNodeChangeKind.removed =>
        'Registry-узел удалён из текущей revision.',
      RegistryNodeChangeKind.changed =>
        'Изменены: '
            '${change.aspects.map((RegistryNodeChangeAspect aspect) {
              return switch (aspect) {
                RegistryNodeChangeAspect.kind => 'тип',
                RegistryNodeChangeAspect.path => 'путь',
                RegistryNodeChangeAspect.order => 'порядок',
                RegistryNodeChangeAspect.content => 'содержимое',
                RegistryNodeChangeAspect.businessScopeOwner => 'владелец бизнес-области',
              };
            }).join(', ')}.',
    };

    return RegistryStructuralProblem._(
      status: RegistryStructuralProblemStatus.affected,
      reason: reason,
      change: change,
      baselineRevision: normalizedBaselineRevision,
      currentRevision: normalizedCurrentRevision,
    );
  }

  const RegistryStructuralProblem._({
    required this.status,
    required this.reason,
    required this.change,
    required this.baselineRevision,
    required this.currentRevision,
  });

  final RegistryStructuralProblemStatus status;
  final String reason;
  final RegistryNodeChange change;
  final String baselineRevision;
  final String currentRevision;

  RegistryNode get exactNode => change.currentNode ?? change.previousNode!;

  RegistryPath get path => exactNode.path;

  List<SourceEvidence> get baselineEvidence =>
      change.previousNode?.sourceEvidence ?? const <SourceEvidence>[];

  List<SourceEvidence> get currentEvidence =>
      change.currentNode?.sourceEvidence ?? const <SourceEvidence>[];

  @override
  List<Object> get props => <Object>[
    status,
    reason,
    change,
    baselineRevision,
    currentRevision,
  ];
}
