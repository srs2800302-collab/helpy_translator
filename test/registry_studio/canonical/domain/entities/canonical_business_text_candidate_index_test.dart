import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextCandidateIndex', () {
    test('indexes immutable candidates by node and business owner', () {
      final CanonicalBusinessTextCandidate first = _candidate(
        identity: 'candidate-1',
        nodeId: 'node-1',
        ownerId: 'owner-1',
        path: const <String>['Registry', 'Category'],
        text: 'First phrase.',
      );

      final CanonicalBusinessTextCandidate second = _candidate(
        identity: 'candidate-2',
        nodeId: 'node-2',
        ownerId: 'owner-1',
        path: const <String>['Registry', 'Category', 'Client Rules'],
        text: 'Second phrase.',
      );

      final CanonicalBusinessTextCandidateIndex index =
          CanonicalBusinessTextCandidateIndex(
            projectId: 'helpy',
            sourceDocumentPath: 'registry.md',
            sourceRevision: 'revision-1',
            sourceSnapshotFingerprint: 'git-blob:source',
            candidates: <CanonicalBusinessTextCandidate>[first, second],
          );

      expect(index.candidateCount, 2);

      expect(
        index.candidatesByNodeId[RegistryNodeId('node-1')],
        <CanonicalBusinessTextCandidate>[first],
      );

      expect(
        index.candidatesByOwnerId[RegistryEntityId('owner-1')],
        <CanonicalBusinessTextCandidate>[first, second],
      );

      expect(() => index.candidates.clear(), throwsUnsupportedError);
    });

    test('rejects duplicate candidate identities', () {
      final CanonicalBusinessTextCandidate candidate = _candidate(
        identity: 'candidate-1',
        nodeId: 'node-1',
        ownerId: 'owner-1',
        path: const <String>['Registry', 'Category'],
        text: 'Phrase.',
      );

      expect(
        () => CanonicalBusinessTextCandidateIndex(
          projectId: 'helpy',
          sourceDocumentPath: 'registry.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          candidates: <CanonicalBusinessTextCandidate>[candidate, candidate],
        ),
        throwsArgumentError,
      );
    });
  });
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String nodeId,
  required String ownerId,
  required List<String> path,
  required String text,
}) {
  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId(nodeId),
    businessScopeOwnerId: RegistryEntityId(ownerId),
    path: RegistryPath(path),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:source',
        headingPath: path,
        startLine: 1,
        endLine: 10,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.paragraph,
    rawText: text,
    text: text,
    directContentLine: 1,
  );
}
