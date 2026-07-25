import '../../../canonical/domain/canonical_analysis_package.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';

final class HelpyCanonicalRegistryProjector {
  const HelpyCanonicalRegistryProjector();

  ({
    List<CanonicalBusinessEntity> businessEntities,
    List<CanonicalOrderedBusinessBlock> orderedBusinessBlocks,
    List<CanonicalAdapterFailure> failures,
  })
  project({required RegistrySnapshot snapshot}) {
    final List<RegistryNode> nodes = _flatten(snapshot.roots);
    final List<CanonicalAdapterFailure> failures = <CanonicalAdapterFailure>[];

    for (final RegistryNode node in nodes) {
      for (final evidence in node.sourceEvidence) {
        if (evidence.sourceDocumentPath != snapshot.sourceDocumentPath ||
            evidence.sourceSnapshotFingerprint !=
                snapshot.sourceSnapshotFingerprint) {
          failures.add(
            CanonicalAdapterFailure(
              identity:
                  'helpy.canonical.registry.failure.'
                  '${node.id.value}.evidence',
              source: CanonicalAdapterFailureSource.registry,
              severity: CanonicalAdapterFailureSeverity.fatal,
              code: 'registry_evidence_mismatch',
              explanation:
                  'Структурный узел Registry содержит evidence другого '
                  'документа или другой revision.',
              relatedIdentity: node.id.value,
              path: node.path,
              sourceEvidence: node.sourceEvidence,
            ),
          );
        }
      }
    }

    failures.add(
      CanonicalAdapterFailure(
        identity:
            'helpy.canonical.registry.failure.'
            'projection-not-implemented',
        source: CanonicalAdapterFailureSource.registry,
        severity: CanonicalAdapterFailureSeverity.fatal,
        code: 'registry_projection_not_implemented',
        explanation:
            'Registry snapshot подтверждён, но project-specific canonical '
            'projection ещё не реализована.',
        relatedIdentity: snapshot.sourceRevision,
        path: null,
        sourceEvidence: nodes.expand(
          (RegistryNode node) => node.sourceEvidence,
        ),
      ),
    );

    return (
      businessEntities: const <CanonicalBusinessEntity>[],
      orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
      failures: List<CanonicalAdapterFailure>.unmodifiable(failures),
    );
  }

  List<RegistryNode> _flatten(Iterable<RegistryNode> roots) {
    final List<RegistryNode> result = <RegistryNode>[];
    final List<RegistryNode> pending = <RegistryNode>[
      ...roots.toList(growable: false).reversed,
    ];

    while (pending.isNotEmpty) {
      final RegistryNode node = pending.removeLast();
      result.add(node);

      for (final RegistryNode child in node.children.reversed) {
        pending.add(child);
      }
    }

    return List<RegistryNode>.unmodifiable(result);
  }
}
