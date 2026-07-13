import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/service_intake_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_payload_decoder.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_semantic_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  const ServiceIntakePayloadDecoder decoder = ServiceIntakePayloadDecoder();

  group('ServiceIntakePayloadDecoder', () {
    test('decodes exact Registry text into the existing typed payload', () {
      final ServiceIntakePayload payload = decoder.decode(
        sourceBlock: _sourceBlock(),
        manifestEntry: _manifestEntry(),
      );

      expect(payload.displayName, 'Plumbing → Кран');
      expect(payload.scenarios, hasLength(1));

      final IntakeScenario scenario = payload.scenarios.single;

      expect(
        scenario.displayName,
        'Если выбрано «Установить и подключить кран»:',
      );
      expect(
        scenario.entryEvidence.mode,
        ScenarioEntryEvidenceMode.selectorAnswer,
      );
      expect(scenario.entryEvidence.sourceSelectorQuestionKey, 'what_to_do');
      expect(
        scenario.entryEvidence.sourceSelectedAnswerOptionKey,
        'install_connect',
      );

      final IntakeQuestion question = scenario.questions.single;

      expect(question.prompt, 'Где будет установлен и подключён кран?');
      expect(question.inputMode, IntakeQuestionInputMode.singleChoice);
      expect(question.isRequired, isTrue);
      expect(question.answerOptions.single.displayName, 'Раковина.');
      expect(question.qualifiers.single.expression, 'location=sink');

      final PhotoQuestion photoQuestion = scenario.photoQuestions.single;

      expect(photoQuestion.prompt, 'Фотография установленной раковины.');
      expect(photoQuestion.applicabilityQualifierKeys, <String>[
        'location_sink',
      ]);
      expect(photoQuestion.photoLimitKey, 'install_sink_limit');
      expect(photoQuestion.source.mode, PhotoSourceMode.direct);

      final PhotoLimit photoLimit = scenario.photoLimits.single;

      expect(photoLimit.requiredCount, 1);
      expect(photoLimit.optionalCount, 1);
      expect(photoLimit.totalMaximum, 2);

      expect(
        scenario.clientGuidance.map((ScenarioGuidanceItem item) => item.text),
        <String>[
          'Подготовьте доступ к месту выполнения работ.',
          'Освободите пространство рядом с раковиной.',
        ],
      );
      expect(
        scenario.masterGuidance.single.text,
        'Перед распаковкой мастер обязан проверить совместимость.',
      );
    });

    test('rejects a source block with a different identity', () {
      final ServiceIntakeSourceBlock sourceBlock = _sourceBlock(
        entityId: 'helpy.service_intake.plumbing.toilet',
      );

      expect(
        () => decoder.decode(
          sourceBlock: sourceBlock,
          manifestEntry: _manifestEntry(),
        ),
        throwsFormatException,
      );
    });

    test('rejects a non-exact contextual item match', () {
      expect(
        () => decoder.decode(
          sourceBlock: _sourceBlock(),
          manifestEntry: _manifestEntry(
            questionExpectedText: '2. Где должен быть установлен кран?',
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects a missing exact context occurrence', () {
      expect(
        () => decoder.decode(
          sourceBlock: _sourceBlock(),
          manifestEntry: _manifestEntry(questionContextOccurrence: 2),
        ),
        throwsFormatException,
      );
    });
  });
}

ServiceIntakeSourceBlock _sourceBlock({String entityId = _faucetId}) {
  return (
    identity: _identity(entityId),
    startLine: 100,
    endLine: 130,
    sourceText:
        '### Plumbing → Кран\n'
        'Если выбрано «Установить и подключить кран»:\n'
        'Вопросы:\n'
        '1. Что требуется сделать?\n'
        '- Установить и подключить кран.\n'
        '- Заменить кран.\n'
        '2. Где будет установлен и подключён кран?\n'
        '- Раковина.\n'
        'Обязательные фотографии — '
        'Установить и подключить кран — Раковина:\n'
        '1. Фотография установленной раковины.\n'
        'Лимит фотографий — '
        'Установить и подключить кран — Раковина:\n'
        '- Обязательные: 1 фотография.\n'
        '- Дополнительные: до 1 фотографии.\n'
        '- Всего: до 2 из 10 фотографий.\n'
        'Правила для клиента — Установить и подключить:\n'
        '- Подготовьте доступ к месту выполнения работ.\n'
        '- Освободите пространство рядом с раковиной.\n'
        '1. Проверка совместимости до начала работ:\n'
        '- Перед распаковкой мастер обязан проверить совместимость.\n',
  );
}

ServiceIntakeIdentityManifestEntry _identity(String entityId) {
  return (
    entityId: RegistryEntityId(entityId),
    path: RegistryPath(const <String>[
      'helpy',
      'service_intake',
      'plumbing',
      'faucet',
    ]),
    ownerHeadingLevel: 2,
    ownerHeading: 'Plumbing',
    headingLevel: 3,
    heading: 'Plumbing → Кран',
  );
}

ServiceIntakeSemanticManifestEntry _manifestEntry({
  String questionExpectedText = '2. Где будет установлен и подключён кран?',
  int questionContextOccurrence = 1,
}) {
  const String photoSection =
      'Обязательные фотографии — '
      'Установить и подключить кран — Раковина:';
  const String limitSection =
      'Лимит фотографий — '
      'Установить и подключить кран — Раковина:';

  return (
    entityId: RegistryEntityId(_faucetId),
    displayNameLocator: _line('### Plumbing → Кран'),
    entrySelectors: <ServiceIntakeSemanticEntrySelector>[
      (
        key: 'what_to_do',
        answerOptionKeys: <String>['install_connect', 'replace'],
      ),
    ],
    scenarios: <ServiceIntakeSemanticScenario>[
      (
        key: 'install_connect',
        displayNameLocator: _line(
          'Если выбрано «Установить и подключить кран»:',
        ),
        entryEvidence: (
          mode: ScenarioEntryEvidenceMode.selectorAnswer,
          sourceSelectorQuestionKey: 'what_to_do',
          sourceSelectedAnswerOptionKey: 'install_connect',
        ),
        questions: <ServiceIntakeSemanticQuestion>[
          (
            key: 'location',
            promptLocator: _item(
              context: 'Вопросы:',
              contextOccurrence: questionContextOccurrence,
              kind: ServiceIntakeSemanticItemKind.numberedItem,
              ordinal: 2,
              expectedText: questionExpectedText,
            ),
            inputMode: IntakeQuestionInputMode.singleChoice,
            isRequired: true,
            answerOptions: <ServiceIntakeSemanticAnswerOption>[
              (
                key: 'sink',
                displayNameLocator: _item(
                  context: '2. Где будет установлен и подключён кран?',
                  kind: ServiceIntakeSemanticItemKind.bullet,
                  ordinal: 1,
                  expectedText: '- Раковина.',
                ),
              ),
            ],
            qualifiers: <ServiceIntakeSemanticQuestionQualifier>[
              (
                key: 'location_sink',
                kind: QuestionQualifierKind.answerContext,
                sourceQuestionKey: 'location',
                sourceAnswerOptionKey: 'sink',
              ),
            ],
          ),
        ],
        photoQuestions: <ServiceIntakeSemanticPhotoQuestion>[
          (
            key: 'installed_sink',
            promptLocator: _item(
              context: photoSection,
              kind: ServiceIntakeSemanticItemKind.numberedItem,
              ordinal: 1,
              expectedText: '1. Фотография установленной раковины.',
            ),
            isRequired: true,
            applicabilityQualifierKeys: <String>['location_sink'],
            photoLimitKey: 'install_sink_limit',
            source: (
              mode: PhotoSourceMode.direct,
              sourceScenarioKey: null,
              sourcePhotoQuestionKey: null,
            ),
          ),
        ],
        photoLimits: <ServiceIntakeSemanticPhotoLimit>[
          (
            key: 'install_sink_limit',
            requiredCountLocator: _item(
              context: limitSection,
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 1,
              expectedText: '- Обязательные: 1 фотография.',
            ),
            optionalCountLocator: _item(
              context: limitSection,
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 2,
              expectedText: '- Дополнительные: до 1 фотографии.',
            ),
            totalMaximumLocator: _item(
              context: limitSection,
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 3,
              expectedText: '- Всего: до 2 из 10 фотографий.',
            ),
          ),
        ],
        clientGuidance: <ServiceIntakeSemanticGuidanceItem>[
          (
            key: 'client_access',
            textLocator: _item(
              context: 'Правила для клиента — Установить и подключить:',
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 1,
              expectedText: '- Подготовьте доступ к месту выполнения работ.',
            ),
          ),
          (
            key: 'client_clear_space',
            textLocator: _item(
              context: 'Правила для клиента — Установить и подключить:',
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 2,
              expectedText: '- Освободите пространство рядом с раковиной.',
            ),
          ),
        ],
        masterGuidance: <ServiceIntakeSemanticGuidanceItem>[
          (
            key: 'master_check',
            textLocator: _item(
              context: '1. Проверка совместимости до начала работ:',
              kind: ServiceIntakeSemanticItemKind.bullet,
              ordinal: 1,
              expectedText:
                  '- Перед распаковкой мастер обязан '
                  'проверить совместимость.',
            ),
          ),
        ],
      ),
    ],
  );
}

ServiceIntakeSemanticLineLocator _line(
  String expectedText, {
  int occurrence = 1,
}) {
  return (expectedText: expectedText, occurrence: occurrence);
}

ServiceIntakeSemanticItemLocator _item({
  required String context,
  int contextOccurrence = 1,
  required ServiceIntakeSemanticItemKind kind,
  required int ordinal,
  required String expectedText,
}) {
  return (
    context: _line(context, occurrence: contextOccurrence),
    kind: kind,
    ordinal: ordinal,
    expectedText: expectedText,
  );
}

const String _faucetId = 'helpy.service_intake.plumbing.faucet';
