import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_phrase_applicability_resolver.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_phrase_applicability_resolver.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  const resolver = HelpyCanonicalPhraseApplicabilityResolver();

  test('matches structured block, scenario, label, and RegistryPath', () {
    final result = resolver.resolve(
      candidate: _candidate(),
      entry: _entry(const <String>[
        'ContentBlockIdentity: helpy.business-content.client-rules',
        'ScenarioIdentity: owner-1::scenario::replace',
        'Используется только для сценария «Заменить».',
        'RegistryPath: Registry -> Entity',
      ]),
      registrySourceRevision: 'revision-42',
    );

    expect(result.decision, CanonicalPhraseApplicabilityDecision.applicable);
    expect(result.evidence?.registrySourceRevision, 'revision-42');
  });

  test('distinguishes mismatch from unsupported grammar', () {
    final mismatch = resolver.resolve(
      candidate: _candidate(),
      entry: _entry(const <String>[
        'ContentBlockIdentity: helpy.business-content.master-rules',
      ]),
      registrySourceRevision: 'revision-42',
    );
    final unsupported = resolver.resolve(
      candidate: _candidate(),
      entry: _entry(const <String>['Unknown grammar']),
      registrySourceRevision: 'revision-42',
    );

    expect(
      mismatch.decision,
      CanonicalPhraseApplicabilityDecision.notApplicable,
    );
    expect(
      unsupported.decision,
      CanonicalPhraseApplicabilityDecision.unresolved,
    );
  });
}

CanonicalBusinessTextCandidate _candidate() {
  final RegistryPath path = RegistryPath(const <String>['Registry', 'Entity']);
  return CanonicalBusinessTextCandidate(
    identity: 'candidate-1',
    nodeId: RegistryNodeId('node-1'),
    businessScopeOwnerId: RegistryEntityId('owner-1'),
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:registry',
        headingPath: path.segments,
        startLine: 10,
        endLine: 10,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.listItem,
    rawText: '- Подготовьте доступ.',
    text: 'Подготовьте доступ.',
    directContentLine: 1,
    contentBlockIdentity: 'helpy.business-content.client-rules',
    contentBlockLabel: 'Правила клиента',
    scenarioIdentity: 'owner-1::scenario::replace',
    scenarioLabel: 'Заменить',
  );
}

CanonicalPhraseEntry _entry(Iterable<String> applicability) {
  return CanonicalPhraseEntry(
    dictionaryId: 'DICTIONARY',
    collectionId: 'collection',
    phrase: 'Подготовьте доступ.',
    applicability: applicability,
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 5,
    sourceEndLine: 5,
  );
}
