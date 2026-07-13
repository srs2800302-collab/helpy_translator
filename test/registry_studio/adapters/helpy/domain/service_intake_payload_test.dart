import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/service_intake_payload.dart';

void main() {
  group('ServiceIntakePayload', () {
    test('exposes the current typed RegistryEntityKind contract', () {
      final ServiceIntakePayload payload = ServiceIntakePayload(
        displayName: '  Faucet  ',
        scenarios: const <IntakeScenario>[],
      );

      expect(payload.displayName, 'Faucet');
      expect(payload.kind.semanticContract.contractId, 'helpy.service_intake');
      expect(payload.kind.semanticContract.version, '1');
      expect(payload.kind.kindId, 'helpy.service_intake');
      expect(payload.kind.schemaVersion, '1');
      expect(payload.kind, same(ServiceIntakePayload.entityKind));
    });

    test('supports selector-answer and direct scenario entry evidence', () {
      final ScenarioEntryEvidence selector =
          ScenarioEntryEvidence.selectorAnswer(
            sourceSelectorQuestionKey: '  what_to_do  ',
            sourceSelectedAnswerOptionKey: '  install_connect  ',
          );
      const ScenarioEntryEvidence direct =
          ScenarioEntryEvidence.directSelection();

      expect(selector.mode, ScenarioEntryEvidenceMode.selectorAnswer);
      expect(selector.sourceSelectorQuestionKey, 'what_to_do');
      expect(selector.sourceSelectedAnswerOptionKey, 'install_connect');

      expect(direct.mode, ScenarioEntryEvidenceMode.directSelection);
      expect(direct.sourceSelectorQuestionKey, isNull);
      expect(direct.sourceSelectedAnswerOptionKey, isNull);
    });

    test('preserves scenario content order and immutable collections', () {
      final IntakeScenario scenario = _scenario(
        key: 'install_connect',
        selectedAnswerKey: 'install_connect',
        questions: <IntakeQuestion>[_locationQuestion()],
        photoQuestions: <PhotoQuestion>[
          _photoQuestion(
            key: 'installed_faucet',
            qualifierKeys: <String>['location_sink'],
            limitKey: 'install_photos',
            source: _source(PhotoSourceMode.direct),
          ),
        ],
        photoLimits: <PhotoLimit>[_photoLimit(key: 'install_photos')],
        clientGuidance: <ScenarioGuidanceItem>[
          _guidance('client_access', 'Подготовьте доступ к месту работ.'),
          _guidance('client_property', 'Уберите личные вещи.'),
        ],
        masterGuidance: <ScenarioGuidanceItem>[
          _guidance('master_compatibility', 'Проверьте совместимость.'),
          _guidance('master_test', 'Проведите проверку после работ.'),
        ],
      );

      final ServiceIntakePayload payload = ServiceIntakePayload(
        displayName: 'Faucet',
        scenarios: <IntakeScenario>[scenario],
      );

      expect(
        payload.scenarios.single.questions
            .map((IntakeQuestion item) => item.key)
            .toList(),
        <String>['location'],
      );
      expect(
        payload.scenarios.single.photoQuestions
            .map((PhotoQuestion item) => item.key)
            .toList(),
        <String>['installed_faucet'],
      );
      expect(
        payload.scenarios.single.clientGuidance
            .map((ScenarioGuidanceItem item) => item.key)
            .toList(),
        <String>['client_access', 'client_property'],
      );
      expect(
        payload.scenarios.single.masterGuidance
            .map((ScenarioGuidanceItem item) => item.key)
            .toList(),
        <String>['master_compatibility', 'master_test'],
      );
      expect(() => payload.scenarios.add(scenario), throwsUnsupportedError);
      expect(
        () => scenario.questions.add(_locationQuestion()),
        throwsUnsupportedError,
      );
    });

    test(
      'allows one scenario to reuse a photo question inside the payload',
      () {
        final IntakeScenario installScenario = _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: <IntakeQuestion>[_locationQuestion()],
          photoQuestions: <PhotoQuestion>[
            _photoQuestion(
              key: 'installed_faucet',
              qualifierKeys: <String>['location_sink'],
              limitKey: 'install_photos',
              source: _source(PhotoSourceMode.direct),
            ),
          ],
          photoLimits: <PhotoLimit>[_photoLimit(key: 'install_photos')],
          clientGuidance: const <ScenarioGuidanceItem>[],
          masterGuidance: const <ScenarioGuidanceItem>[],
        );
        final IntakeScenario replaceScenario = _scenario(
          key: 'replace',
          selectedAnswerKey: 'replace',
          questions: const <IntakeQuestion>[],
          photoQuestions: <PhotoQuestion>[
            _photoQuestion(
              key: 'install_context',
              qualifierKeys: const <String>[],
              limitKey: 'replace_photos',
              source: _source(
                PhotoSourceMode.reuse,
                sourceScenarioKey: 'install_connect',
                sourcePhotoQuestionKey: 'installed_faucet',
              ),
            ),
            _photoQuestion(
              key: 'existing_faucet',
              qualifierKeys: const <String>[],
              limitKey: 'replace_photos',
              source: _source(PhotoSourceMode.replacement),
            ),
          ],
          photoLimits: <PhotoLimit>[_photoLimit(key: 'replace_photos')],
          clientGuidance: const <ScenarioGuidanceItem>[],
          masterGuidance: const <ScenarioGuidanceItem>[],
        );

        expect(
          () => ServiceIntakePayload(
            displayName: 'Faucet',
            scenarios: <IntakeScenario>[installScenario, replaceScenario],
          ),
          returnsNormally,
        );
      },
    );

    test('rejects duplicate scenario keys', () {
      final IntakeScenario first = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace',
        questions: const <IntakeQuestion>[],
        photoQuestions: const <PhotoQuestion>[],
        photoLimits: const <PhotoLimit>[],
        clientGuidance: const <ScenarioGuidanceItem>[],
        masterGuidance: const <ScenarioGuidanceItem>[],
      );
      final IntakeScenario second = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace_again',
        questions: const <IntakeQuestion>[],
        photoQuestions: const <PhotoQuestion>[],
        photoLimits: const <PhotoLimit>[],
        clientGuidance: const <ScenarioGuidanceItem>[],
        masterGuidance: const <ScenarioGuidanceItem>[],
      );

      expect(
        () => ServiceIntakePayload(
          displayName: 'Faucet',
          scenarios: <IntakeScenario>[first, second],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a reuse reference outside the owning intake payload', () {
      final IntakeScenario replaceScenario = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace',
        questions: const <IntakeQuestion>[],
        photoQuestions: <PhotoQuestion>[
          _photoQuestion(
            key: 'install_context',
            qualifierKeys: const <String>[],
            limitKey: 'replace_photos',
            source: _source(
              PhotoSourceMode.reuse,
              sourceScenarioKey: 'another_entity.install',
              sourcePhotoQuestionKey: 'installed_faucet',
            ),
          ),
        ],
        photoLimits: <PhotoLimit>[_photoLimit(key: 'replace_photos')],
        clientGuidance: const <ScenarioGuidanceItem>[],
        masterGuidance: const <ScenarioGuidanceItem>[],
      );

      expect(
        () => ServiceIntakePayload(
          displayName: 'Faucet',
          scenarios: <IntakeScenario>[replaceScenario],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a photo question referencing a foreign qualifier', () {
      expect(
        () => _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: <IntakeQuestion>[_locationQuestion()],
          photoQuestions: <PhotoQuestion>[
            _photoQuestion(
              key: 'installed_faucet',
              qualifierKeys: <String>['not_owned_by_scenario'],
              limitKey: 'install_photos',
              source: _source(PhotoSourceMode.direct),
            ),
          ],
          photoLimits: <PhotoLimit>[_photoLimit(key: 'install_photos')],
          clientGuidance: const <ScenarioGuidanceItem>[],
          masterGuidance: const <ScenarioGuidanceItem>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate guidance keys within one role', () {
      expect(
        () => _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: const <IntakeQuestion>[],
          photoQuestions: const <PhotoQuestion>[],
          photoLimits: const <PhotoLimit>[],
          clientGuidance: <ScenarioGuidanceItem>[
            _guidance('client_access', 'Подготовьте доступ.'),
            _guidance('client_access', 'Уберите личные вещи.'),
          ],
          masterGuidance: const <ScenarioGuidanceItem>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects inconsistent photo limits', () {
      expect(
        () => PhotoLimit(
          key: 'invalid_limit',
          requiredCount: 3,
          optionalCount: 2,
          totalMaximum: 4,
        ),
        throwsArgumentError,
      );
    });

    test('rejects source references for non-reuse modes', () {
      expect(
        () => PhotoQuestionSource(
          mode: PhotoSourceMode.direct,
          sourceScenarioKey: 'install_connect',
          sourcePhotoQuestionKey: 'installed_faucet',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty service display name', () {
      expect(
        () => ServiceIntakePayload(
          displayName: '   ',
          scenarios: const <IntakeScenario>[],
        ),
        throwsArgumentError,
      );
    });
  });
}

IntakeScenario _scenario({
  required String key,
  required String selectedAnswerKey,
  required Iterable<IntakeQuestion> questions,
  required Iterable<PhotoQuestion> photoQuestions,
  required Iterable<PhotoLimit> photoLimits,
  required Iterable<ScenarioGuidanceItem> clientGuidance,
  required Iterable<ScenarioGuidanceItem> masterGuidance,
}) {
  return IntakeScenario(
    key: key,
    displayName: key,
    entryEvidence: ScenarioEntryEvidence.selectorAnswer(
      sourceSelectorQuestionKey: 'what_to_do',
      sourceSelectedAnswerOptionKey: selectedAnswerKey,
    ),
    questions: questions,
    photoQuestions: photoQuestions,
    photoLimits: photoLimits,
    clientGuidance: clientGuidance,
    masterGuidance: masterGuidance,
  );
}

IntakeQuestion _locationQuestion() {
  return IntakeQuestion(
    key: 'location',
    prompt: 'Where is the faucet?',
    answerOptions: <AnswerOption>[
      AnswerOption(key: 'sink', displayName: 'Sink'),
    ],
    qualifiers: <QuestionQualifier>[
      QuestionQualifier(
        key: 'location_sink',
        kind: QuestionQualifierKind.answerContext,
        expression: 'location=sink',
      ),
    ],
  );
}

PhotoQuestion _photoQuestion({
  required String key,
  required Iterable<String> qualifierKeys,
  required String limitKey,
  required PhotoQuestionSource source,
}) {
  return PhotoQuestion(
    key: key,
    prompt: key,
    isRequired: true,
    applicabilityQualifierKeys: qualifierKeys,
    photoLimitKey: limitKey,
    source: source,
  );
}

PhotoQuestionSource _source(
  PhotoSourceMode mode, {
  String? sourceScenarioKey,
  String? sourcePhotoQuestionKey,
}) {
  return PhotoQuestionSource(
    mode: mode,
    sourceScenarioKey: sourceScenarioKey,
    sourcePhotoQuestionKey: sourcePhotoQuestionKey,
  );
}

PhotoLimit _photoLimit({required String key}) {
  return PhotoLimit(
    key: key,
    requiredCount: 1,
    optionalCount: 0,
    totalMaximum: 1,
  );
}

ScenarioGuidanceItem _guidance(String key, String text) {
  return ScenarioGuidanceItem(key: key, text: text);
}
