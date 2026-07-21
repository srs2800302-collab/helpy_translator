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

void main() {
  group('CanonicalBusinessTextAnalysisCubit', () {
    test('emits running and ready while retaining the full result', () async {
      final CanonicalBusinessTextAnalysisResult result = _result();

      final Completer<CanonicalBusinessTextAnalysisResult> completer =
          Completer<CanonicalBusinessTextAnalysisResult>();

      final _SessionRunner runner = _SessionRunner(future: completer.future);

      final CanonicalBusinessTextAnalysisCubit cubit =
          CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

      final Future<void> runFuture = cubit.run();

      expect(cubit.state, const CanonicalBusinessTextAnalysisRunning());

      final Future<void> ignoredRun = cubit.run();

      expect(runner.callCount, 1);

      completer.complete(result);

      await runFuture;
      await ignoredRun;

      expect(cubit.state, CanonicalBusinessTextAnalysisReady(result: result));

      expect(
        (cubit.state as CanonicalBusinessTextAnalysisReady).result,
        same(result),
      );

      await cubit.close();
    });

    test('emits failed with the source error', () async {
      final CanonicalBusinessTextAnalysisCubit cubit =
          CanonicalBusinessTextAnalysisCubit(
            sessionRunner: _SessionRunner(
              future: Future<CanonicalBusinessTextAnalysisResult>.error(
                StateError('Analysis failed'),
              ),
            ),
          );

      await cubit.run();

      expect(cubit.state, isA<CanonicalBusinessTextAnalysisFailed>());

      expect(
        (cubit.state as CanonicalBusinessTextAnalysisFailed).message,
        contains('Analysis failed'),
      );

      await cubit.close();
    });
  });
}

final class _SessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  _SessionRunner({required this.future});

  final Future<CanonicalBusinessTextAnalysisResult> future;
  int callCount = 0;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis() {
    callCount += 1;
    return future;
  }
}

CanonicalBusinessTextAnalysisResult _result() {
  final CanonicalDictionary dictionary = CanonicalDictionary(
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

  return CanonicalBusinessTextAnalysisResult(
    candidates: CanonicalBusinessTextCandidateIndex(
      projectId: 'helpy',
      sourceDocumentPath: 'registry.md',
      sourceRevision: 'registry-revision',
      sourceSnapshotFingerprint: 'git-blob:registry',
      candidates: const <Never>[],
    ),
    classifications: CanonicalBusinessTextClassificationIndex(
      projectId: 'helpy',
      candidateSourceDocumentPath: 'registry.md',
      candidateSourceRevision: 'registry-revision',
      candidateSourceSnapshotFingerprint: 'git-blob:registry',
      dictionaryId: dictionary.dictionaryId,
      dictionaryVersion: dictionary.version,
      dictionarySourceRevision: dictionary.sourceRevision,
      dictionarySourceSnapshotFingerprint: dictionary.sourceSnapshotFingerprint,
      classifications: const <Never>[],
    ),
    dictionary: dictionary,
  );
}
