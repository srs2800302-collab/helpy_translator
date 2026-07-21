import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/application/run_canonical_business_text_analysis.dart';
import 'package:helpy_translator/registry_studio/canonical/application/run_canonical_business_text_analysis_session.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RunCanonicalBusinessTextAnalysisSession', () {
    test('analyzes the accepted Registry snapshot '
        'without loading Registry again', () async {
      final RegistrySnapshot snapshot = _snapshot();

      final _DictionaryLoader dictionaryLoader = _DictionaryLoader(
        _dictionary(),
      );

      final CanonicalBusinessTextAnalysisResult result =
          await RunCanonicalBusinessTextAnalysisSession(
            canonicalDictionaryLoader: dictionaryLoader,
            analysis: const RunCanonicalBusinessTextAnalysis(
              candidateExtractor: _EmptyCandidateExtractor(),
              classifier: _EmptyClassifier(),
            ),
          ).runAnalysis(snapshot);

      expect(dictionaryLoader.callCount, 1);
      expect(result.registrySourceRevision, snapshot.sourceRevision);
      expect(
        result.registrySourceSnapshotFingerprint,
        snapshot.sourceSnapshotFingerprint,
      );
    });

    test('propagates Canonical Dictionary loading '
        'failure', () {
      final Object error = StateError('Dictionary unavailable');

      expect(
        RunCanonicalBusinessTextAnalysisSession(
          canonicalDictionaryLoader: _FailingDictionaryLoader(error),
          analysis: const RunCanonicalBusinessTextAnalysis(
            candidateExtractor: _EmptyCandidateExtractor(),
            classifier: _EmptyClassifier(),
          ),
        ).runAnalysis(_snapshot()),
        throwsA(same(error)),
      );
    });
  });
}

final class _DictionaryLoader implements CanonicalDictionaryLoader {
  _DictionaryLoader(this.dictionary);

  final CanonicalDictionary dictionary;
  int callCount = 0;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    callCount += 1;
    return dictionary;
  }
}

final class _FailingDictionaryLoader implements CanonicalDictionaryLoader {
  _FailingDictionaryLoader(this.error);

  final Object error;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    throw error;
  }
}

final class _EmptyCandidateExtractor
    implements CanonicalBusinessTextCandidateExtractor {
  const _EmptyCandidateExtractor();

  @override
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  ) {
    return CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: const <Never>[],
    );
  }
}

final class _EmptyClassifier implements CanonicalBusinessTextClassifier {
  const _EmptyClassifier();

  @override
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  }) {
    return CanonicalBusinessTextClassificationIndex(
      projectId: candidates.projectId,
      candidateSourceDocumentPath: candidates.sourceDocumentPath,
      candidateSourceRevision: candidates.sourceRevision,
      candidateSourceSnapshotFingerprint: candidates.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: const <Never>[],
    );
  }
}

RegistrySnapshot _snapshot() {
  const String fingerprint = 'git-blob:registry';

  final RegistryPath path = RegistryPath(const <String>['Registry']);

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: '# Registry',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('node-1'),
        kindId: 'helpy.registry.heading.1',
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: path.segments,
            startLine: 1,
            endLine: 1,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      ),
    ],
  );
}

CanonicalDictionary _dictionary() {
  return CanonicalDictionary(
    dictionaryId:
        'REGISTRY_STUDIO_CANONICAL_'
        'BUSINESS_DICTIONARY_V1',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 20,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'canonical.phrases',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: '- Canonical phrase.',
        startLine: 2,
        endLine: 19,
        entries: <CanonicalPhraseEntry>[
          CanonicalPhraseEntry(
            identity:
                'canonical.phrases::'
                'canonical-phrase',
            collectionId: 'canonical.phrases',
            phrase: 'Canonical phrase.',
            sourceDocumentPath: 'contract.md',
            sourceRevision: 'dictionary-revision',
            sourceSnapshotFingerprint: 'sha256:dictionary',
            sourceStartLine: 5,
            sourceEndLine: 5,
          ),
        ],
      ),
    ],
  );
}
