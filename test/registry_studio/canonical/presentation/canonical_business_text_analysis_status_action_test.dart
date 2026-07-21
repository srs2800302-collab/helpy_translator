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
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_view.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets('opens the automatically produced result', (
    WidgetTester tester,
  ) async {
    final CanonicalBusinessTextAnalysisResult result = _result();

    final CanonicalBusinessTextAnalysisCubit cubit =
        CanonicalBusinessTextAnalysisCubit(
          sessionRunner: _SessionRunner(result),
        );

    await tester.pumpWidget(_application(cubit));

    final IconButton initialAction = tester.widget<IconButton>(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    expect(initialAction.onPressed, isNull);

    await cubit.acceptSnapshot(_snapshot());
    await tester.pumpAndSettle();

    expect(cubit.state, CanonicalBusinessTextAnalysisReady(result: result));

    await tester.tap(
      find.byKey(CanonicalBusinessTextAnalysisStatusAction.actionKey),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(CanonicalBusinessTextAnalysisView.viewKey),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());

    await cubit.close();
  });

  testWidgets('retries the latest accepted snapshot', (
    WidgetTester tester,
  ) async {
    final _FailingSessionRunner runner = _FailingSessionRunner();

    final CanonicalBusinessTextAnalysisCubit cubit =
        CanonicalBusinessTextAnalysisCubit(sessionRunner: runner);

    await tester.pumpWidget(_application(cubit));

    await cubit.acceptSnapshot(_snapshot());
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

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(runner.callCount, 2);
    expect(runner.snapshots, <RegistrySnapshot>[_snapshot(), _snapshot()]);

    await tester.pumpWidget(const SizedBox.shrink());

    await cubit.close();
  });
}

Widget _application(CanonicalBusinessTextAnalysisCubit cubit) {
  return MaterialApp(
    home: BlocProvider<CanonicalBusinessTextAnalysisCubit>.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          actions: const <Widget>[CanonicalBusinessTextAnalysisStatusAction()],
        ),
      ),
    ),
  );
}

final class _SessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  _SessionRunner(this.result);

  final CanonicalBusinessTextAnalysisResult result;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) async {
    return result;
  }
}

final class _FailingSessionRunner
    implements CanonicalBusinessTextAnalysisSessionRunner {
  int callCount = 0;

  final List<RegistrySnapshot> snapshots = <RegistrySnapshot>[];

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  ) async {
    callCount += 1;
    snapshots.add(snapshot);

    throw StateError('Analysis unavailable');
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
