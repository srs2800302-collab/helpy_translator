import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextCandidate business context', () {
    test('preserves block and optional scenario context', () {
      final RegistryPath path = RegistryPath(const <String>[
        'Registry',
        'Entity',
      ]);

      final CanonicalBusinessTextCandidate candidate =
          CanonicalBusinessTextCandidate(
            identity: 'candidate-context',
            nodeId: RegistryNodeId('node-context'),
            businessScopeOwnerId: RegistryEntityId('owner-context'),
            path: path,
            sourceEvidence: <SourceEvidence>[
              SourceEvidence(
                sourceDocumentPath: 'registry.md',
                sourceSnapshotFingerprint: 'git-blob:source',
                headingPath: path.segments,
                startLine: 20,
                endLine: 20,
              ),
            ],
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: '- Подготовьте доступ.',
            text: 'Подготовьте доступ.',
            directContentLine: 4,
            contentBlockIdentity: 'project.content-block.client-rules',
            contentBlockLabel: 'Правила клиента',
            scenarioIdentity: 'owner-context::scenario::replace',
            scenarioLabel: 'Заменить',
          );

      expect(
        candidate.contentBlockIdentity,
        'project.content-block.client-rules',
      );

      expect(candidate.contentBlockLabel, 'Правила клиента');

      expect(candidate.scenarioIdentity, 'owner-context::scenario::replace');

      expect(candidate.scenarioLabel, 'Заменить');
      expect(candidate.hasContentBlockContext, isTrue);
      expect(candidate.hasScenarioContext, isTrue);
    });

    test('supports a business entity without scenario', () {
      final RegistryPath path = RegistryPath(const <String>[
        'Registry',
        'Entity',
      ]);

      final CanonicalBusinessTextCandidate candidate =
          CanonicalBusinessTextCandidate(
            identity: 'candidate-no-scenario',
            nodeId: RegistryNodeId('node-no-scenario'),
            businessScopeOwnerId: RegistryEntityId('owner-context'),
            path: path,
            sourceEvidence: <SourceEvidence>[
              SourceEvidence(
                sourceDocumentPath: 'registry.md',
                sourceSnapshotFingerprint: 'git-blob:source',
                headingPath: path.segments,
                startLine: 21,
                endLine: 21,
              ),
            ],
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: '- Какой тип уборки?',
            text: 'Какой тип уборки?',
            directContentLine: 5,
            contentBlockIdentity: 'project.content-block.questions',
            contentBlockLabel: 'Вопросы',
          );

      expect(candidate.hasContentBlockContext, isTrue);
      expect(candidate.hasScenarioContext, isFalse);
      expect(candidate.scenarioIdentity, isNull);
      expect(candidate.scenarioLabel, isNull);
    });

    test('rejects incomplete paired context', () {
      final RegistryPath path = RegistryPath(const <String>[
        'Registry',
        'Entity',
      ]);

      expect(
        () => CanonicalBusinessTextCandidate(
          identity: 'candidate-block',
          nodeId: RegistryNodeId('node-block'),
          businessScopeOwnerId: RegistryEntityId('owner-context'),
          path: path,
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'registry.md',
              sourceSnapshotFingerprint: 'git-blob:source',
              headingPath: path.segments,
              startLine: 22,
              endLine: 22,
            ),
          ],
          kind: CanonicalBusinessTextCandidateKind.listItem,
          rawText: '- Подготовьте доступ.',
          text: 'Подготовьте доступ.',
          directContentLine: 6,
          contentBlockIdentity: 'project.content-block.client-rules',
        ),
        throwsArgumentError,
      );

      expect(
        () => CanonicalBusinessTextCandidate(
          identity: 'candidate-scenario',
          nodeId: RegistryNodeId('node-scenario'),
          businessScopeOwnerId: RegistryEntityId('owner-context'),
          path: path,
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'registry.md',
              sourceSnapshotFingerprint: 'git-blob:source',
              headingPath: path.segments,
              startLine: 23,
              endLine: 23,
            ),
          ],
          kind: CanonicalBusinessTextCandidateKind.listItem,
          rawText: '- Подготовьте доступ.',
          text: 'Подготовьте доступ.',
          directContentLine: 7,
          scenarioIdentity: 'owner-context::scenario::replace',
        ),
        throwsArgumentError,
      );
    });
  });
}
