import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextCandidate', () {
    test('preserves node, owner, raw text and source evidence', () {
      final List<SourceEvidence> evidence = <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'git-blob:source',
          headingPath: const <String>['Registry', 'Client Rules'],
          startLine: 10,
          endLine: 20,
        ),
      ];

      final CanonicalBusinessTextCandidate candidate =
          CanonicalBusinessTextCandidate(
            identity: ' candidate-1 ',
            nodeId: RegistryNodeId('node-1'),
            businessScopeOwnerId: RegistryEntityId('owner-1'),
            path: RegistryPath(const <String>['Registry', 'Client Rules']),
            sourceEvidence: evidence,
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: '  - Каноническая фраза.  ',
            text: ' Каноническая фраза. ',
            directContentLine: 3,
          );

      evidence.clear();

      expect(candidate.identity, 'candidate-1');
      expect(candidate.nodeId.value, 'node-1');

      expect(candidate.businessScopeOwnerId.value, 'owner-1');

      expect(candidate.rawText, '  - Каноническая фраза.  ');

      expect(candidate.text, 'Каноническая фраза.');

      expect(candidate.directContentLine, 3);
      expect(candidate.sourceEvidence, hasLength(1));

      expect(() => candidate.sourceEvidence.clear(), throwsUnsupportedError);
    });

    test('requires heading candidates to use line zero', () {
      expect(
        () => CanonicalBusinessTextCandidate(
          identity: 'candidate-1',
          nodeId: RegistryNodeId('node-1'),
          businessScopeOwnerId: RegistryEntityId('owner-1'),
          path: RegistryPath(const <String>['Registry', 'Client Rules']),
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'registry.md',
              sourceSnapshotFingerprint: 'git-blob:source',
              headingPath: const <String>['Registry', 'Client Rules'],
              startLine: 10,
              endLine: 20,
            ),
          ],
          kind: CanonicalBusinessTextCandidateKind.heading,
          rawText: 'Client Rules',
          text: 'Client Rules',
          directContentLine: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
