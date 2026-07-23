import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_confirmed_application_evidence.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_classification_details.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets(
    'shows confirmed applicability evidence after scrolling details',
    (WidgetTester tester) async {
      final RegistryPath path = RegistryPath(const <String>[
        'Registry',
        'Entity',
      ]);

      final CanonicalBusinessTextCandidate candidate =
          CanonicalBusinessTextCandidate(
            identity: 'candidate-1',
            nodeId: RegistryNodeId('node-1'),
            businessScopeOwnerId: RegistryEntityId('owner-1'),
            path: path,
            sourceEvidence: <SourceEvidence>[
              SourceEvidence(
                sourceDocumentPath: 'registry.md',
                sourceSnapshotFingerprint: 'git-blob:registry',
                headingPath: path.segments,
                startLine: 42,
                endLine: 42,
              ),
            ],
            kind: CanonicalBusinessTextCandidateKind.listItem,
            rawText: '- Подготовьте доступ.',
            text: 'Подготовьте доступ.',
            directContentLine: 4,
            contentBlockIdentity: 'helpy.business-content.client-rules',
            contentBlockLabel: 'Правила клиента',
            scenarioIdentity: 'owner-1::scenario::replace',
            scenarioLabel: 'Заменить',
          );

      final CanonicalPhraseEntry entry = CanonicalPhraseEntry(
        dictionaryId: 'DICTIONARY',
        collectionId: 'client-rules',
        phrase: candidate.text,
        applicability: const <String>[
          'Используется только для сценария «Заменить».',
        ],
        sourceDocumentPath: 'contract.md',
        sourceRevision: 'dictionary-revision',
        sourceSnapshotFingerprint: 'sha256:dictionary',
        sourceStartLine: 10,
        sourceEndLine: 11,
      );

      final CanonicalConfirmedApplicationEvidence evidence =
          CanonicalConfirmedApplicationEvidence(
            identity: 'confirmed-application-1',
            candidateIdentity: candidate.identity,
            canonicalEntryIdentity: entry.identity,
            registrySourceRevision: 'registry-revision-42',
            confirmationEvidenceId:
                'helpy.canonical.structured-applicability.v1',
            sourceEvidence: candidate.sourceEvidence,
          );

      final CanonicalBusinessTextClassification classification =
          CanonicalBusinessTextClassification(
            candidate: candidate,
            status: CanonicalBusinessTextClassificationStatus.exact,
            reason: CanonicalBusinessTextClassificationReason
                .singleExactApplicableMatch,
            matchedCanonicalEntries: <CanonicalPhraseEntry>[entry],
            matchedConfirmedApplicationEvidence:
                <CanonicalConfirmedApplicationEvidence>[evidence],
          );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanonicalBusinessTextClassificationDetails(
              classification: classification,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Finder scrollable = find.byType(Scrollable).first;

      Future<void> expectVisible(String text) async {
        final Finder finder = find.text(text);

        await tester.scrollUntilVisible(
          finder,
          250,
          scrollable: scrollable,
          maxScrolls: 30,
        );

        await tester.pumpAndSettle();

        expect(finder, findsOneWidget);
      }

      await expectVisible('Подтверждённая применимость');

      await expectVisible(
        'Confirmation evidence ID: '
        'helpy.canonical.structured-applicability.v1',
      );

      await expectVisible('Candidate identity: candidate-1');

      await expectVisible('Canonical entry identity: ${entry.identity}');

      await expectVisible('Registry revision: registry-revision-42');

      await expectVisible(
        'Confirmation source evidence: '
        'registry.md, строки 42–42',
      );
    },
  );
}
