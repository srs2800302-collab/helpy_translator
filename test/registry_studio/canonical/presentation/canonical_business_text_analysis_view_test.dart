import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_analysis_result.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_analysis_view.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_classification_details.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets('filters classifications and exposes exact source evidence', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CanonicalBusinessTextAnalysisView(result: _result())),
    );

    expect(
      find.byKey(CanonicalBusinessTextAnalysisView.viewKey),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'canonical-business-text-analysis-row-'
          'candidate-exact',
        ),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'canonical-business-text-analysis-row-'
          'candidate-neutral',
        ),
      ),
      findsOneWidget,
    );

    for (final status in CanonicalBusinessTextClassificationStatus.values) {
      expect(
        find.byKey(
          ValueKey<String>(
            'canonical-business-text-analysis-filter-'
            '${status.name}',
          ),
        ),
        findsOneWidget,
      );
    }

    final Finder failedFilter = find.byKey(
      const ValueKey<String>(
        'canonical-business-text-analysis-filter-'
        'failed',
      ),
    );

    await tester.ensureVisible(failedFilter);
    await tester.pumpAndSettle();
    await tester.tap(failedFilter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(CanonicalBusinessTextAnalysisView.emptyKey),
      findsOneWidget,
    );

    final Finder exactFilter = find.byKey(
      const ValueKey<String>(
        'canonical-business-text-analysis-filter-'
        'exact',
      ),
    );

    await tester.ensureVisible(exactFilter);
    await tester.pumpAndSettle();
    await tester.tap(exactFilter);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey<String>(
          'canonical-business-text-analysis-row-'
          'candidate-exact',
        ),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>(
          'canonical-business-text-analysis-row-'
          'candidate-neutral',
        ),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>(
          'canonical-business-text-analysis-row-'
          'candidate-exact',
        ),
      ),
    );

    await tester.pumpAndSettle();

    final Finder details = find.byKey(
      CanonicalBusinessTextClassificationDetails.sheetKey,
    );

    expect(details, findsOneWidget);

    expect(
      find.descendant(
        of: details,
        matching: find.text('Candidate: Canonical phrase.'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: details,
        matching: find.text('Business owner ID: owner-exact'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: details,
        matching: find.text('Registry node ID: node-exact'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: details,
        matching: find.text('Registry path: Registry → Service → Rule'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: details,
        matching: find.text('Документ: registry.md'),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(of: details, matching: find.text('Строки: 10–20')),
      findsOneWidget,
    );

    final Finder canonicalPhrase = find.text(
      'Canonical phrase: Canonical phrase.',
    );

    await tester.scrollUntilVisible(
      canonicalPhrase,
      300,
      scrollable: find
          .descendant(of: details, matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: details, matching: canonicalPhrase),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: details,
        matching: find.text('Применимость: без ограничений'),
      ),
      findsOneWidget,
    );
  });
}

CanonicalBusinessTextAnalysisResult _result() {
  final CanonicalPhraseEntry phrase = CanonicalPhraseEntry(
    identity: 'canonical.phrases::canonical-phrase',
    collectionId: 'canonical.phrases',
    phrase: 'Canonical phrase.',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 50,
    sourceEndLine: 50,
  );

  final CanonicalDictionary dictionary = CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 100,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'canonical.phrases',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: '- Canonical phrase.',
        startLine: 40,
        endLine: 60,
        entries: <CanonicalPhraseEntry>[phrase],
      ),
    ],
  );

  final CanonicalBusinessTextCandidate exactCandidate = _candidate(
    identity: 'candidate-exact',
    nodeId: 'node-exact',
    ownerId: 'owner-exact',
    text: 'Canonical phrase.',
    path: const <String>['Registry', 'Service', 'Rule'],
    startLine: 10,
    endLine: 20,
  );

  final CanonicalBusinessTextCandidate neutralCandidate = _candidate(
    identity: 'candidate-neutral',
    nodeId: 'node-neutral',
    ownerId: 'owner-neutral',
    text: 'Unknown phrase.',
    path: const <String>['Registry', 'Global Rules', 'Unknown'],
    startLine: 30,
    endLine: 35,
  );

  final CanonicalBusinessTextClassification exact =
      CanonicalBusinessTextClassification(
        candidate: exactCandidate,
        status: CanonicalBusinessTextClassificationStatus.exact,
        reason:
            CanonicalBusinessTextClassificationReason.singleExactUniversalMatch,
        matchedCanonicalEntries: <CanonicalPhraseEntry>[phrase],
      );

  final CanonicalBusinessTextClassification neutral =
      CanonicalBusinessTextClassification(
        candidate: neutralCandidate,
        status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        reason:
            CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch,
      );

  return CanonicalBusinessTextAnalysisResult(
    candidates: CanonicalBusinessTextCandidateIndex(
      projectId: 'helpy',
      sourceDocumentPath: 'registry.md',
      sourceRevision: 'registry-revision',
      sourceSnapshotFingerprint: 'git-blob:registry',
      candidates: <CanonicalBusinessTextCandidate>[
        exactCandidate,
        neutralCandidate,
      ],
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
      classifications: <CanonicalBusinessTextClassification>[exact, neutral],
    ),
    dictionary: dictionary,
  );
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String nodeId,
  required String ownerId,
  required String text,
  required List<String> path,
  required int startLine,
  required int endLine,
}) {
  final RegistryPath registryPath = RegistryPath(path);

  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId(nodeId),
    businessScopeOwnerId: RegistryEntityId(ownerId),
    path: registryPath,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:registry',
        headingPath: registryPath.segments,
        startLine: startLine,
        endLine: endLine,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.listItem,
    rawText: '- $text',
    text: text,
    directContentLine: 1,
  );
}
