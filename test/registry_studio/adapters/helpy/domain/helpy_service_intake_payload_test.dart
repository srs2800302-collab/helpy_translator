import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/helpy_service_intake_payload.dart';

void main() {
  group('HelpyServiceIntakePayload', () {
    test('exposes the current typed RegistryEntityKind contract', () {
      final HelpyServiceIntakePayload payload = HelpyServiceIntakePayload(
        displayName: '  Faucet  ',
        scenarios: const <HelpyIntakeScenario>[],
      );

      expect(payload.displayName, 'Faucet');
      expect(payload.kind.semanticContract.contractId, 'helpy.service_intake');
      expect(payload.kind.semanticContract.version, '1');
      expect(payload.kind.kindId, 'helpy.service_intake');
      expect(payload.kind.schemaVersion, '1');
      expect(payload.kind, same(HelpyServiceIntakePayload.entityKind));
    });

    test('preserves scenario content order and immutable collections', () {
      final HelpyIntakeScenario scenario = _scenario(
        key: 'install_connect',
        selectedAnswerKey: 'install_connect',
        questions: <HelpyIntakeQuestion>[_locationQuestion()],
        photoQuestions: <HelpyPhotoQuestion>[
          _photoQuestion(
            key: 'installed_faucet',
            qualifierKeys: <String>['location_sink'],
            limitKey: 'install_photos',
            source: _source(HelpyPhotoSourceMode.direct),
          ),
        ],
        photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'install_photos')],
        clientGuidance: <HelpyScenarioGuidanceItem>[
          _guidance('client_access', 'Подготовьте доступ к месту работ.'),
          _guidance('client_property', 'Уберите личные вещи.'),
        ],
        masterGuidance: <HelpyScenarioGuidanceItem>[
          _guidance('master_compatibility', 'Проверьте совместимость.'),
          _guidance('master_test', 'Проведите проверку после работ.'),
        ],
      );

      final HelpyServiceIntakePayload payload = HelpyServiceIntakePayload(
        displayName: 'Faucet',
        scenarios: <HelpyIntakeScenario>[scenario],
      );

      expect(
        payload.scenarios.single.questions
            .map((HelpyIntakeQuestion item) => item.key)
            .toList(),
        <String>['location'],
      );
      expect(
        payload.scenarios.single.photoQuestions
            .map((HelpyPhotoQuestion item) => item.key)
            .toList(),
        <String>['installed_faucet'],
      );
      expect(
        payload.scenarios.single.clientGuidance
            .map((HelpyScenarioGuidanceItem item) => item.key)
            .toList(),
        <String>['client_access', 'client_property'],
      );
      expect(
        payload.scenarios.single.masterGuidance
            .map((HelpyScenarioGuidanceItem item) => item.key)
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
        final HelpyIntakeScenario installScenario = _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: <HelpyIntakeQuestion>[_locationQuestion()],
          photoQuestions: <HelpyPhotoQuestion>[
            _photoQuestion(
              key: 'installed_faucet',
              qualifierKeys: <String>['location_sink'],
              limitKey: 'install_photos',
              source: _source(HelpyPhotoSourceMode.direct),
            ),
          ],
          photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'install_photos')],
          clientGuidance: const <HelpyScenarioGuidanceItem>[],
          masterGuidance: const <HelpyScenarioGuidanceItem>[],
        );
        final HelpyIntakeScenario replaceScenario = _scenario(
          key: 'replace',
          selectedAnswerKey: 'replace',
          questions: const <HelpyIntakeQuestion>[],
          photoQuestions: <HelpyPhotoQuestion>[
            _photoQuestion(
              key: 'install_context',
              qualifierKeys: const <String>[],
              limitKey: 'replace_photos',
              source: _source(
                HelpyPhotoSourceMode.reuse,
                sourceScenarioKey: 'install_connect',
                sourcePhotoQuestionKey: 'installed_faucet',
              ),
            ),
            _photoQuestion(
              key: 'existing_faucet',
              qualifierKeys: const <String>[],
              limitKey: 'replace_photos',
              source: _source(HelpyPhotoSourceMode.replacement),
            ),
          ],
          photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'replace_photos')],
          clientGuidance: const <HelpyScenarioGuidanceItem>[],
          masterGuidance: const <HelpyScenarioGuidanceItem>[],
        );

        expect(
          () => HelpyServiceIntakePayload(
            displayName: 'Faucet',
            scenarios: <HelpyIntakeScenario>[installScenario, replaceScenario],
          ),
          returnsNormally,
        );
      },
    );

    test('rejects duplicate scenario keys', () {
      final HelpyIntakeScenario first = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace',
        questions: const <HelpyIntakeQuestion>[],
        photoQuestions: const <HelpyPhotoQuestion>[],
        photoLimits: const <HelpyPhotoLimit>[],
        clientGuidance: const <HelpyScenarioGuidanceItem>[],
        masterGuidance: const <HelpyScenarioGuidanceItem>[],
      );
      final HelpyIntakeScenario second = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace_again',
        questions: const <HelpyIntakeQuestion>[],
        photoQuestions: const <HelpyPhotoQuestion>[],
        photoLimits: const <HelpyPhotoLimit>[],
        clientGuidance: const <HelpyScenarioGuidanceItem>[],
        masterGuidance: const <HelpyScenarioGuidanceItem>[],
      );

      expect(
        () => HelpyServiceIntakePayload(
          displayName: 'Faucet',
          scenarios: <HelpyIntakeScenario>[first, second],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a reuse reference outside the owning intake payload', () {
      final HelpyIntakeScenario replaceScenario = _scenario(
        key: 'replace',
        selectedAnswerKey: 'replace',
        questions: const <HelpyIntakeQuestion>[],
        photoQuestions: <HelpyPhotoQuestion>[
          _photoQuestion(
            key: 'install_context',
            qualifierKeys: const <String>[],
            limitKey: 'replace_photos',
            source: _source(
              HelpyPhotoSourceMode.reuse,
              sourceScenarioKey: 'another_entity.install',
              sourcePhotoQuestionKey: 'installed_faucet',
            ),
          ),
        ],
        photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'replace_photos')],
        clientGuidance: const <HelpyScenarioGuidanceItem>[],
        masterGuidance: const <HelpyScenarioGuidanceItem>[],
      );

      expect(
        () => HelpyServiceIntakePayload(
          displayName: 'Faucet',
          scenarios: <HelpyIntakeScenario>[replaceScenario],
        ),
        throwsArgumentError,
      );
    });

    test('rejects a photo question referencing a foreign qualifier', () {
      expect(
        () => _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: <HelpyIntakeQuestion>[_locationQuestion()],
          photoQuestions: <HelpyPhotoQuestion>[
            _photoQuestion(
              key: 'installed_faucet',
              qualifierKeys: <String>['not_owned_by_scenario'],
              limitKey: 'install_photos',
              source: _source(HelpyPhotoSourceMode.direct),
            ),
          ],
          photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'install_photos')],
          clientGuidance: const <HelpyScenarioGuidanceItem>[],
          masterGuidance: const <HelpyScenarioGuidanceItem>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate guidance keys within one role', () {
      expect(
        () => _scenario(
          key: 'install_connect',
          selectedAnswerKey: 'install_connect',
          questions: const <HelpyIntakeQuestion>[],
          photoQuestions: const <HelpyPhotoQuestion>[],
          photoLimits: const <HelpyPhotoLimit>[],
          clientGuidance: <HelpyScenarioGuidanceItem>[
            _guidance('client_access', 'Подготовьте доступ.'),
            _guidance('client_access', 'Уберите личные вещи.'),
          ],
          masterGuidance: const <HelpyScenarioGuidanceItem>[],
        ),
        throwsArgumentError,
      );
    });

    test('rejects inconsistent photo limits', () {
      expect(
        () => HelpyPhotoLimit(
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
        () => HelpyPhotoQuestionSource(
          mode: HelpyPhotoSourceMode.direct,
          sourceScenarioKey: 'install_connect',
          sourcePhotoQuestionKey: 'installed_faucet',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty service display name', () {
      expect(
        () => HelpyServiceIntakePayload(
          displayName: '   ',
          scenarios: const <HelpyIntakeScenario>[],
        ),
        throwsArgumentError,
      );
    });
  });
}

HelpyIntakeScenario _scenario({
  required String key,
  required String selectedAnswerKey,
  required Iterable<HelpyIntakeQuestion> questions,
  required Iterable<HelpyPhotoQuestion> photoQuestions,
  required Iterable<HelpyPhotoLimit> photoLimits,
  required Iterable<HelpyScenarioGuidanceItem> clientGuidance,
  required Iterable<HelpyScenarioGuidanceItem> masterGuidance,
}) {
  return HelpyIntakeScenario(
    key: key,
    displayName: key,
    entryEvidence: HelpyScenarioEntryEvidence(
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

HelpyIntakeQuestion _locationQuestion() {
  return HelpyIntakeQuestion(
    key: 'location',
    prompt: 'Where is the faucet?',
    answerOptions: <HelpyAnswerOption>[
      HelpyAnswerOption(key: 'sink', displayName: 'Sink'),
    ],
    qualifiers: <HelpyQuestionQualifier>[
      HelpyQuestionQualifier(
        key: 'location_sink',
        kind: HelpyQuestionQualifierKind.answerContext,
        expression: 'location=sink',
      ),
    ],
  );
}

HelpyPhotoQuestion _photoQuestion({
  required String key,
  required Iterable<String> qualifierKeys,
  required String limitKey,
  required HelpyPhotoQuestionSource source,
}) {
  return HelpyPhotoQuestion(
    key: key,
    prompt: key,
    isRequired: true,
    applicabilityQualifierKeys: qualifierKeys,
    photoLimitKey: limitKey,
    source: source,
  );
}

HelpyPhotoQuestionSource _source(
  HelpyPhotoSourceMode mode, {
  String? sourceScenarioKey,
  String? sourcePhotoQuestionKey,
}) {
  return HelpyPhotoQuestionSource(
    mode: mode,
    sourceScenarioKey: sourceScenarioKey,
    sourcePhotoQuestionKey: sourcePhotoQuestionKey,
  );
}

HelpyPhotoLimit _photoLimit({required String key}) {
  return HelpyPhotoLimit(
    key: key,
    requiredCount: 1,
    optionalCount: 0,
    totalMaximum: 1,
  );
}

HelpyScenarioGuidanceItem _guidance(String key, String text) {
  return HelpyScenarioGuidanceItem(key: key, text: text);
}
