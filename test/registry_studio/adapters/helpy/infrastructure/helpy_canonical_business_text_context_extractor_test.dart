import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  const HelpyCanonicalBusinessTextCandidateExtractor extractor =
      HelpyCanonicalBusinessTextCandidateExtractor();

  test('preserves four business blocks optional scenario and exact lines', () {
    final RegistrySnapshot snapshot = _snapshot();

    final CanonicalBusinessTextCandidateIndex index = extractor
        .extractCandidates(snapshot);

    final CanonicalBusinessTextCandidate question = index.candidates
        .singleWhere(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Какой тип оборудования?',
        );

    final CanonicalBusinessTextCandidate photoQuestion = index.candidates
        .singleWhere(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Фотография места установки.',
        );

    final CanonicalBusinessTextCandidate clientRule = index.candidates
        .singleWhere(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Подготовьте доступ.',
        );

    final CanonicalBusinessTextCandidate masterRule = index.candidates
        .singleWhere(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Проверьте место выполнения работ.',
        );

    final CanonicalBusinessTextCandidate noScenarioQuestion = index.candidates
        .singleWhere(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Какой тип уборки?',
        );

    expect(question.contentBlockIdentity, 'helpy.business-content.questions');

    expect(
      photoQuestion.contentBlockIdentity,
      'helpy.business-content.photo-questions',
    );

    expect(
      clientRule.contentBlockIdentity,
      'helpy.business-content.client-rules',
    );

    expect(
      masterRule.contentBlockIdentity,
      'helpy.business-content.master-rules',
    );

    expect(question.scenarioLabel, 'Заменить');
    expect(photoQuestion.scenarioLabel, 'Заменить');
    expect(clientRule.scenarioLabel, 'Заменить');
    expect(masterRule.scenarioLabel, 'Заменить');

    expect(question.scenarioIdentity, startsWith('owner.context::scenario::'));

    expect(
      noScenarioQuestion.contentBlockIdentity,
      'helpy.business-content.questions',
    );

    expect(noScenarioQuestion.scenarioIdentity, isNull);
    expect(noScenarioQuestion.scenarioLabel, isNull);

    final List<CanonicalBusinessTextCandidate> repeatedRules = index.candidates
        .where(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Одинаковая формулировка.',
        )
        .toList(growable: false);

    expect(repeatedRules, hasLength(2));

    expect(
      repeatedRules
          .map(
            (CanonicalBusinessTextCandidate candidate) =>
                candidate.scenarioLabel,
          )
          .toSet(),
      <String?>{'Заменить', 'Установить и подключить'},
    );

    expect(
      repeatedRules
          .map((CanonicalBusinessTextCandidate candidate) => candidate.identity)
          .toSet(),
      hasLength(2),
    );

    final List<String> sourceLines = snapshot.sourceContent.split('\n');

    for (final CanonicalBusinessTextCandidate candidate
        in <CanonicalBusinessTextCandidate>[
          question,
          photoQuestion,
          clientRule,
          masterRule,
          noScenarioQuestion,
          ...repeatedRules,
        ]) {
      final SourceEvidence evidence = candidate.sourceEvidence.single;

      expect(evidence.startLine, evidence.endLine);

      expect(
        sourceLines[evidence.startLine - 1].trim(),
        candidate.rawText.trim(),
      );
    }
  });
}

RegistrySnapshot _snapshot() {
  const String fingerprint =
      'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  final RegistryEntityId ownerId = RegistryEntityId('owner.context');

  const String content =
      '#### Сценарий «Заменить»\n'
      '##### Вопросы\n'
      '- Какой тип оборудования?\n'
      '##### Фото-вопросы\n'
      '- Фотография места установки.\n'
      '##### Правила для клиента\n'
      '- Подготовьте доступ.\n'
      '- Одинаковая формулировка.\n'
      '##### Правила для мастера\n'
      '- Проверьте место выполнения работ.\n'
      '#### Сценарий «Установить и подключить»\n'
      '##### Правила для клиента\n'
      '- Одинаковая формулировка.\n'
      '---\n'
      '#### Вопросы\n'
      '- Какой тип уборки?';

  final String sourceContent =
      '# Registry\n'
      '## Service Architecture Registry\n'
      '### Entity\n'
      '$content';

  final RegistryPath path = RegistryPath(const <String>[
    'Registry',
    'Service Architecture Registry',
    'Entity',
  ]);

  final RegistryNode node = RegistryNode(
    id: RegistryNodeId('node.context'),
    kindId: 'helpy.registry.markdown.heading.3',
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: path.segments,
        startLine: 3,
        endLine: 19,
      ),
    ],
    content: content,
    businessScopeOwnerId: ownerId,
    children: const <RegistryNode>[],
  );

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'revision-context',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent: sourceContent,
    roots: <RegistryNode>[node],
  );
}
