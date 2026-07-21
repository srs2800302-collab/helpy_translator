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
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('RunCanonicalBusinessTextAnalysisSession', () {
    test(
      'loads one exact Registry snapshot and one exact dictionary',
      () async {
        final RegistrySnapshot snapshot = _snapshot();
        final CanonicalDictionary dictionary = _dictionary();

        final _SnapshotLoader snapshotLoader = _SnapshotLoader(snapshot);

        final _DictionaryLoader dictionaryLoader = _DictionaryLoader(
          dictionary,
        );

        final CanonicalBusinessTextAnalysisResult result =
            await RunCanonicalBusinessTextAnalysisSession(
              registrySnapshotLoader: snapshotLoader,
              canonicalDictionaryLoader: dictionaryLoader,
              analysis: const RunCanonicalBusinessTextAnalysis(
                candidateExtractor: _EmptyCandidateExtractor(),
                classifier: _EmptyClassifier(),
              ),
            ).runAnalysis();

        expect(snapshotLoader.callCount, 1);
        expect(dictionaryLoader.callCount, 1);

        expect(result.registrySourceRevision, snapshot.sourceRevision);

        expect(
          result.registrySourceSnapshotFingerprint,
          snapshot.sourceSnapshotFingerprint,
        );

        expect(result.dictionarySourceRevision, dictionary.sourceRevision);

        expect(
          result.dictionarySourceSnapshotFingerprint,
          dictionary.sourceSnapshotFingerprint,
        );
      },
    );

    test('propagates Registry loading failure', () {
      final Object error = StateError('Registry unavailable');

      expect(
        RunCanonicalBusinessTextAnalysisSession(
          registrySnapshotLoader: _FailingSnapshotLoader(error),
          canonicalDictionaryLoader: _DictionaryLoader(_dictionary()),
          analysis: const RunCanonicalBusinessTextAnalysis(
            candidateExtractor: _EmptyCandidateExtractor(),
            classifier: _EmptyClassifier(),
          ),
        ).runAnalysis(),
        throwsA(same(error)),
      );
    });
  });
}

final class _SnapshotLoader implements RegistrySnapshotLoader {
  _SnapshotLoader(this.snapshot);

  final RegistrySnapshot snapshot;
  int callCount = 0;

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
    callCount += 1;
    return snapshot;
  }
}

final class _FailingSnapshotLoader implements RegistrySnapshotLoader {
  _FailingSnapshotLoader(this.error);

  final Object error;

  @override
  Future<RegistrySnapshot> loadSnapshot() async {
    throw error;
  }
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
    dictionaryId: 'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
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
            identity: 'canonical.phrases::canonical-phrase',
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
