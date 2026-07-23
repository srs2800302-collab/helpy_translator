import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_business_text_classification_details.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  testWidgets('shows business block optional scenario and exact evidence', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1200));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

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
          directContentLine: 7,
          contentBlockIdentity: 'helpy.business-content.client-rules',
          contentBlockLabel: 'Правила клиента',
          scenarioIdentity: 'owner-1::scenario::replace',
          scenarioLabel: 'Заменить',
        );

    final CanonicalBusinessTextClassification classification =
        CanonicalBusinessTextClassification(
          candidate: candidate,
          status: CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
          reason: CanonicalBusinessTextClassificationReason
              .noExactCanonicalTextMatch,
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

    expect(find.text('Бизнес-блок: Правила клиента'), findsOneWidget);

    expect(
      find.text(
        'Content block identity: '
        'helpy.business-content.client-rules',
      ),
      findsOneWidget,
    );

    expect(find.text('Сценарий: Заменить'), findsOneWidget);

    expect(
      find.text(
        'Scenario identity: '
        'owner-1::scenario::replace',
      ),
      findsOneWidget,
    );

    expect(find.text('Строки: 42–42'), findsOneWidget);
  });
}
