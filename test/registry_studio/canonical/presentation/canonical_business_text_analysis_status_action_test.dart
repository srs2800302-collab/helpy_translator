import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_business_text_analysis_session_runner.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_cubit.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_status_action.dart';

void main() {
  testWidgets('runs analysis and opens the immutable result panel', (
    WidgetTester tester,
  ) async {
    final CanonicalBusinessTextAnalysisResult result = _result();

    final CanonicalBusinessTextAnalysisCubit cubit =
        CanonicalBusinessTextAnalysisCubit(
          sessionRunner: _SessionRunner(result: result),
        );

    await tester.pumpWidget(_application(cubit));

    expect(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    await tester.pumpAndSettle();

    expect(cubit.state, CanonicalBusinessTextAnalysisReady(result: result));

    await tester.tap(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.resultDialogKey),
      findsOneWidget,
    );

    expect(find.text('Канонический анализ'), findsOneWidget);
    expect(find.text('Кандидаты: 0'), findsOneWidget);
    expect(find.text('Business scopes: 0'), findsOneWidget);
    expect(find.text('Registry revision: registry-revision'), findsOneWidget);
    expect(
      find.text('Dictionary revision: dictionary-revision'),
      findsOneWidget,
    );

    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();

    await cubit.close();
  });

  testWidgets('shows failure and allows a retry', (WidgetTester tester) async {
    final _FailingSessionRunner runner = _FailingSessionRunner();

    final CanonicalBusinessTextAnalysisCubit cubit =
        CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

    await tester.pumpWidget(_application(cubit));

    await tester.tap(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    await tester.pumpAndSettle();

    expect(cubit.state, isA<CanonicalBusinessTextAnalysisFailed>());

    await tester.tap(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.failureDialogKey),
      findsOneWidget,
    );

    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(runner.callCount, 2);

    await cubit.close();
  });
}

Widget _application(CanonicalBusinessTextAnalysisCubit cubit) {
  return MaterialApp(
    home: BlocProvider<CanonicalBusinessTextAnalysisCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[CanonicalBusinessTextAnalysisStatusAction()],
        ),
      ),
    ),
  );
}

final class _SessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  _SessionRunner({required this.result});

  final CanonicalBusinessTextAnalysisResult result;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis() async {
    return result;
  }
}

final class _FailingSessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  int callCount = 0;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis() async {
    callCount += 1;
    throw StateError('Analysis unavailable');
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
