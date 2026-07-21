import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/registry/presentation/registry_problem_queue_entry.dart';

void main() {
  test('preserves a neutral project-independent queue projection', () {
    final RegistryPath path = RegistryPath(const <String>[
      'Registry',
      'Domain',
    ]);

    final RegistryProblemQueueEntry entry = RegistryProblemQueueEntry(
      identity: 'analysis:entry',
      nodeId: RegistryNodeId('node-domain'),
      path: path,
      typeLabel: 'Analysis finding',
      statusLabel: 'Review',
      reason: 'Requires review',
      severity: RegistryProblemQueueEntrySeverity.reviewRequired,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'git-blob:registry',
          headingPath: path.segments,
          startLine: 2,
          endLine: 4,
        ),
      ],
    );

    expect(entry.identity, 'analysis:entry');
    expect(entry.nodeId, RegistryNodeId('node-domain'));
    expect(entry.path, path);
    expect(entry.requiresAttention, isTrue);

    expect(
      () => entry.sourceEvidence.clear(),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('keeps informational entries non-actionable', () {
    final RegistryPath path = RegistryPath(const <String>[
      'Registry',
      'Neutral',
    ]);

    final RegistryProblemQueueEntry entry = RegistryProblemQueueEntry(
      identity: 'analysis:neutral',
      nodeId: RegistryNodeId('node-neutral'),
      path: path,
      typeLabel: 'Analysis finding',
      statusLabel: 'Informational',
      reason: 'No exact match',
      severity: RegistryProblemQueueEntrySeverity.informational,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'git-blob:registry',
          headingPath: path.segments,
          startLine: 5,
          endLine: 6,
        ),
      ],
    );

    expect(entry.requiresAttention, isFalse);
  });
}
