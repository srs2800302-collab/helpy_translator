import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_business_scope_resolver.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/application/deterministic_canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/application/run_canonical_business_text_analysis.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RunCanonicalBusinessTextAnalysis', () {
    test('passes the exact snapshot and dictionary through '
        'the extraction and classification pipeline', () {
      final RegistrySnapshot snapshot = _minimalSnapshot();

      final CanonicalDictionary dictionary = _minimalDictionary();

      final _RecordingCandidateExtractor extractor =
          _RecordingCandidateExtractor(snapshot);

      final _RecordingClassifier classifier = _RecordingClassifier(dictionary);

      final CanonicalBusinessTextAnalysisResult result =
          RunCanonicalBusinessTextAnalysis(
            candidateExtractor: extractor,
            classifier: classifier,
          ).call(snapshot: snapshot, dictionary: dictionary);

      expect(extractor.lastSnapshot, same(snapshot));
      expect(classifier.lastDictionary, same(dictionary));

      expect(classifier.lastCandidates, same(result.candidates));

      expect(result.totalCandidateCount, 1);

      expect(result.registrySourceRevision, snapshot.sourceRevision);

      expect(result.dictionarySourceRevision, dictionary.sourceRevision);
    });

    test('rejects candidate output from another Registry revision', () {
      final RegistrySnapshot snapshot = _minimalSnapshot();

      expect(
        () => RunCanonicalBusinessTextAnalysis(
          candidateExtractor: _WrongRevisionCandidateExtractor(),
          classifier: _RecordingClassifier(_minimalDictionary()),
        ).call(snapshot: snapshot, dictionary: _minimalDictionary()),
        throwsStateError,
      );
    });

    test('runs the complete read-only pipeline against the '
        'pinned Registry and normative dictionary', () async {
      final File registryFixture = File(
        'test/fixtures/registry_studio/source_indexing/'
        'Helpy_Architecture_Registry_v1.md',
      );

      final File contract = File(
        'docs/architecture/registry_studio/'
        'Registry_Studio_Engineering_Change_Propagation_'
        'and_Approval_Contract_v1.md',
      );

      expect(await registryFixture.exists(), isTrue);
      expect(await contract.exists(), isTrue);

      const String registryRevision =
          '745990455b33eef55a7bfc7805e8212afa089b7b';

      const String registryFingerprint =
          'fixture:helpy-registry-stage3-full-analysis';

      const String dictionaryFingerprint =
          'sha256:'
          '73bb98686befe8885e487427537db32d54be7e3443b5d3b4aa192f9d03c976a6';

      final RegistrySnapshot snapshot = _resolvedFixtureSnapshot(
        sourceDocumentPath: registryFixture.path,
        sourceRevision: registryRevision,
        sourceSnapshotFingerprint: registryFingerprint,
        sourceContent: await registryFixture.readAsString(),
      );

      final CanonicalDictionary dictionary =
          const HelpyCanonicalDictionaryDocumentInterpreter().interpret(
            sourceDocumentPath: contract.path,
            sourceRevision: registryRevision,
            sourceSnapshotFingerprint: dictionaryFingerprint,
            sourceContent: await contract.readAsString(),
          );

      final CanonicalBusinessTextAnalysisResult result =
          const RunCanonicalBusinessTextAnalysis(
            candidateExtractor: HelpyCanonicalBusinessTextCandidateExtractor(),
            classifier: DeterministicCanonicalBusinessTextClassifier(),
          ).call(snapshot: snapshot, dictionary: dictionary);

      expect(result.totalCandidateCount, greaterThan(0));

      expect(
        result.classifications.classifications.length,
        result.totalCandidateCount,
      );

      expect(result.classificationsByBusinessScopeOwnerId, hasLength(7));

      expect(result.registrySourceDocumentPath, registryFixture.path);

      expect(result.registrySourceRevision, registryRevision);

      expect(result.registrySourceSnapshotFingerprint, registryFingerprint);

      expect(result.dictionarySourceDocumentPath, contract.path);

      expect(result.dictionarySourceRevision, registryRevision);

      expect(result.dictionarySourceSnapshotFingerprint, dictionaryFingerprint);

      final int statusTotal = CanonicalBusinessTextClassificationStatus.values
          .map(result.countForStatus)
          .fold<int>(0, (int total, int count) => total + count);

      expect(statusTotal, result.totalCandidateCount);

      final int ownerTotal = result.countsByBusinessScopeOwnerId.values
          .fold<int>(0, (int total, int count) => total + count);

      expect(ownerTotal, result.totalCandidateCount);

      expect(
        result.countForStatus(CanonicalBusinessTextClassificationStatus.exact),
        greaterThan(0),
      );

      expect(
        result.countForStatus(CanonicalBusinessTextClassificationStatus.review),
        greaterThan(0),
      );

      expect(
        result.countForStatus(
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        ),
        greaterThan(0),
      );

      expect(
        result.countForStatus(
          CanonicalBusinessTextClassificationStatus.equivalent,
        ),
        0,
      );

      expect(
        result.countForStatus(CanonicalBusinessTextClassificationStatus.drift),
        0,
      );

      expect(
        result.countForStatus(CanonicalBusinessTextClassificationStatus.failed),
        0,
      );

      expect(
        result.classifications.classifications.every(
          (CanonicalBusinessTextClassification classification) =>
              result.candidates.candidates
                  .where(
                    (CanonicalBusinessTextCandidate candidate) =>
                        candidate.identity == classification.candidate.identity,
                  )
                  .single ==
              classification.candidate,
        ),
        isTrue,
      );

      final RegistryStructuralIndex structuralIndex = RegistryStructuralIndex(
        snapshot,
      );

      expect(
        result.classifications.classifications.every((
          CanonicalBusinessTextClassification classification,
        ) {
          final RegistryNode node =
              structuralIndex.nodesById[classification.candidate.nodeId]!;

          return node.businessScopeOwnerId ==
              classification.candidate.businessScopeOwnerId;
        }),
        isTrue,
      );
    });
  });
}

final class _RecordingCandidateExtractor
    implements CanonicalBusinessTextCandidateExtractor {
  _RecordingCandidateExtractor(this.expectedSnapshot);

  final RegistrySnapshot expectedSnapshot;

  RegistrySnapshot? lastSnapshot;

  @override
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  ) {
    lastSnapshot = snapshot;

    final RegistryNode node = RegistryStructuralIndex(snapshot).nodes.single;

    final RegistryEntityId ownerId = node.businessScopeOwnerId!;

    return CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: <CanonicalBusinessTextCandidate>[
        CanonicalBusinessTextCandidate(
          identity: 'candidate-1',
          nodeId: node.id,
          businessScopeOwnerId: ownerId,
          path: node.path,
          sourceEvidence: node.sourceEvidence,
          kind: CanonicalBusinessTextCandidateKind.heading,
          rawText: node.path.segments.last,
          text: node.path.segments.last,
          directContentLine: 0,
        ),
      ],
    );
  }
}

final class _WrongRevisionCandidateExtractor
    implements CanonicalBusinessTextCandidateExtractor {
  @override
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  ) {
    return CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: 'wrong-revision',
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: const <CanonicalBusinessTextCandidate>[],
    );
  }
}

final class _RecordingClassifier implements CanonicalBusinessTextClassifier {
  _RecordingClassifier(this.expectedDictionary);

  final CanonicalDictionary expectedDictionary;

  CanonicalBusinessTextCandidateIndex? lastCandidates;
  CanonicalDictionary? lastDictionary;

  @override
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  }) {
    lastCandidates = candidates;
    lastDictionary = dictionary;

    return CanonicalBusinessTextClassificationIndex(
      projectId: candidates.projectId,
      candidateSourceDocumentPath: candidates.sourceDocumentPath,
      candidateSourceRevision: candidates.sourceRevision,
      candidateSourceSnapshotFingerprint: candidates.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: <CanonicalBusinessTextClassification>[
        for (final CanonicalBusinessTextCandidate candidate
            in candidates.candidates)
          CanonicalBusinessTextClassification(
            candidate: candidate,
            status:
                CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
            reason: CanonicalBusinessTextClassificationReason
                .noExactCanonicalTextMatch,
          ),
      ],
    );
  }
}

RegistrySnapshot _minimalSnapshot() {
  const String fingerprint = 'git-blob:registry';

  final RegistryPath path = RegistryPath(const <String>[
    'Registry',
    'Business Rules',
  ]);

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent:
        '# Registry\n'
        '## Business Rules\n',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('node-1'),
        kindId: 'helpy.registry.heading.2',
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: path.segments,
            startLine: 1,
            endLine: 2,
          ),
        ],
        content: '',
        businessScopeOwnerId: RegistryEntityId('owner-1'),
        children: const <RegistryNode>[],
      ),
    ],
  );
}

CanonicalDictionary _minimalDictionary() {
  return const HelpyCanonicalDictionaryDocumentInterpreter().interpret(
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent:
        '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
        '\n'
        'Dictionary ID: '
        '`REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`\n'
        '\n'
        'Версия словаря: `1`\n'
        '\n'
        'Статус: **APPROVED / STORED**\n'
        '\n'
        '### Collection: '
        '`helpy.canonical.photo_labels`\n'
        '\n'
        'Тип записи: `phrase`\n'
        '\n'
        'Статус: **APPROVED / STORED**\n'
        '\n'
        '- Фотография места установки.\n'
        '\n'
        '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->',
  );
}

RegistrySnapshot _resolvedFixtureSnapshot({
  required String sourceDocumentPath,
  required String sourceRevision,
  required String sourceSnapshotFingerprint,
  required String sourceContent,
}) {
  final List<HelpyRegistryDocumentNode> interpretedRoots =
      const HelpyRegistryDocumentInterpreter().interpret(sourceContent);

  int nodeSequence = 0;

  RegistryNode materializeNode(HelpyRegistryDocumentNode interpretedNode) {
    nodeSequence += 1;

    return RegistryNode(
      id: RegistryNodeId(
        'fixture.node.'
        '${nodeSequence.toString().padLeft(6, '0')}',
      ),
      kindId:
          'helpy.registry.markdown.heading.'
          '${interpretedNode.headingLevel}',
      path: interpretedNode.path,
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: sourceDocumentPath,
          sourceSnapshotFingerprint: sourceSnapshotFingerprint,
          headingPath: interpretedNode.path.segments,
          startLine: interpretedNode.startLine,
          endLine: interpretedNode.endLine,
        ),
      ],
      content: interpretedNode.content,
      businessScopeOwnerId: null,
      children: <RegistryNode>[
        for (final HelpyRegistryDocumentNode child in interpretedNode.children)
          materializeNode(child),
      ],
    );
  }

  return const HelpyRegistryBusinessScopeResolver().resolveBusinessScope(
    RegistrySnapshot(
      projectId: 'helpy',
      projectAdapterId: 'helpy.registry.adapter.v1',
      sourceDocumentPath: sourceDocumentPath,
      sourceRevision: sourceRevision,
      sourceSnapshotFingerprint: sourceSnapshotFingerprint,
      sourceContent: sourceContent,
      roots: <RegistryNode>[
        for (final HelpyRegistryDocumentNode root in interpretedRoots)
          materializeNode(root),
      ],
    ),
  );
}
