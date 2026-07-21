import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_cubit.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextAnalysisCubit', () {
    test('automatically analyzes an accepted snapshot', () async {
      final RegistrySnapshot snapshot = _snapshot('revision-1');

      final Completer<CanonicalBusinessTextAnalysisResult> completer =
          Completer<CanonicalBusinessTextAnalysisResult>();

      final _ControlledRunner runner = _ControlledRunner(
        futures: <String, Future<CanonicalBusinessTextAnalysisResult>>{
          snapshot.sourceRevision: completer.future,
        },
      );

      final CanonicalBusinessTextAnalysisCubit cubit =
          CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

      final Future<void> accepted = cubit.acceptSnapshot(snapshot);

      expect(cubit.state, const CanonicalBusinessTextAnalysisRunning());

      expect(runner.snapshots, <RegistrySnapshot>[snapshot]);

      final CanonicalBusinessTextAnalysisResult result = _result(snapshot);

      completer.complete(result);
      await accepted;

      expect(cubit.state, CanonicalBusinessTextAnalysisReady(result: result));

      await cubit.close();
    });

    test('retains only the latest accepted snapshot '
        'result', () async {
      final RegistrySnapshot first = _snapshot('revision-1');

      final RegistrySnapshot second = _snapshot('revision-2');

      final Completer<CanonicalBusinessTextAnalysisResult> firstCompleter =
          Completer<CanonicalBusinessTextAnalysisResult>();

      final Completer<CanonicalBusinessTextAnalysisResult> secondCompleter =
          Completer<CanonicalBusinessTextAnalysisResult>();

      final _ControlledRunner runner = _ControlledRunner(
        futures: <String, Future<CanonicalBusinessTextAnalysisResult>>{
          first.sourceRevision: firstCompleter.future,
          second.sourceRevision: secondCompleter.future,
        },
      );

      final CanonicalBusinessTextAnalysisCubit cubit =
          CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

      final Future<void> firstRun = cubit.acceptSnapshot(first);

      final Future<void> secondRun = cubit.acceptSnapshot(second);

      firstCompleter.complete(_result(first));

      await firstRun;

      expect(cubit.state, const CanonicalBusinessTextAnalysisRunning());

      final CanonicalBusinessTextAnalysisResult secondResult = _result(second);

      secondCompleter.complete(secondResult);
      await secondRun;

      expect(
        cubit.state,
        CanonicalBusinessTextAnalysisReady(result: secondResult),
      );

      await cubit.close();
    });

    test('retries the latest accepted snapshot', () async {
      final RegistrySnapshot snapshot = _snapshot('revision-1');

      final CanonicalBusinessTextAnalysisResult result = _result(snapshot);

      final _RetryRunner runner = _RetryRunner(result);

      final CanonicalBusinessTextAnalysisCubit cubit =
          CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

      await cubit.acceptSnapshot(snapshot);

      expect(cubit.state, isA<CanonicalBusinessTextAnalysisFailed>());

      await cubit.retry();

      expect(runner.callCount, 2);
      expect(runner.snapshots, <RegistrySnapshot>[snapshot, snapshot]);
      expect(cubit.state, CanonicalBusinessTextAnalysisReady(result: result));

      await cubit.close();
    });
  });
}

final class _ControlledRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  _ControlledRunner({required this.futures});

  final Map<String, Future<CanonicalBusinessTextAnalysisResult>> futures;

  final List<RegistrySnapshot> snapshots = <RegistrySnapshot>[];

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) {
    snapshots.add(snapshot);
    return futures[snapshot.sourceRevision]!;
  }
}

final class _RetryRunner implements CanonicalBusinessTextAnalysisSessionRunner {
  _RetryRunner(this.result);

  final CanonicalBusinessTextAnalysisResult result;

  final List<RegistrySnapshot> snapshots = <RegistrySnapshot>[];

  int callCount = 0;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) async {
    snapshots.add(snapshot);
    callCount += 1;

    if (callCount == 1) {
      throw StateError('Analysis failed');
    }

    return result;
  }
}

CanonicalBusinessTextAnalysisResult _result(RegistrySnapshot snapshot) {
  final CanonicalDictionary dictionary = _dictionary();

  return CanonicalBusinessTextAnalysisResult(
    candidates: CanonicalBusinessTextCandidateIndex(
      projectId: snapshot.projectId,
      sourceDocumentPath: snapshot.sourceDocumentPath,
      sourceRevision: snapshot.sourceRevision,
      sourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      candidates: const <Never>[],
    ),
    classifications: CanonicalBusinessTextClassificationIndex(
      projectId: snapshot.projectId,
      candidateSourceDocumentPath: snapshot.sourceDocumentPath,
      candidateSourceRevision: snapshot.sourceRevision,
      candidateSourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: const <Never>[],
    ),
    dictionary: dictionary,
  );
}

RegistrySnapshot _snapshot(String revision) {
  final String fingerprint = 'git-blob:$revision';

  final RegistryPath path = RegistryPath(const <String>['Registry']);

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: revision,
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: '# Registry',
    roots: <RegistryNode>[
      RegistryNode(
        id: RegistryNodeId('node-$revision'),
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
    dictionaryId: 'DICTIONARY',
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
