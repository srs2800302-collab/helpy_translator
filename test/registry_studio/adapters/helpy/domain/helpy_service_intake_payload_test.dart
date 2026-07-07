import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/helpy_service_intake_payload.dart';

void main() {
  group('HelpyServiceIntakePayload', () {
    test('preserves scenario screen flow and role-specific guidance order', () {
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
        schemaVersion: '1',
        entity: HelpyIntakeEntityContent(
          semanticKey: 'plumbing.faucet',
          displayName: 'Faucet',
        ),
        scenarios: <HelpyIntakeScenario>[installScenario],
      );

      final HelpyIntakeScenario scenario = payload.scenarios.single;

      expect(scenario.entryEvidence.sourceSelectorQuestionKey, 'what_to_do');
      expect(
        scenario.entryEvidence.sourceSelectedAnswerOptionKey,
        'install_connect',
      );
      expect(
        scenario.questions.map((HelpyIntakeQuestion item) => item.key).toList(),
        <String>['location'],
      );
      expect(
        scenario.photoQuestions
            .map((HelpyPhotoQuestion item) => item.key)
            .toList(),
        <String>['installed_faucet'],
      );
      expect(
        scenario.clientGuidance
            .map((HelpyScenarioGuidanceItem item) => item.key)
            .toList(),
        <String>['client_access', 'client_property'],
      );
      expect(
        scenario.masterGuidance
            .map((HelpyScenarioGuidanceItem item) => item.key)
            .toList(),
        <String>['master_compatibility', 'master_test'],
      );
    });

    test(
      'does not require source selector evidence to become a scenario question',
      () {
        expect(
          () => _scenario(
            key: 'replace',
            selectedAnswerKey: 'replace',
            questions: const <HelpyIntakeQuestion>[],
            photoQuestions: const <HelpyPhotoQuestion>[],
            photoLimits: const <HelpyPhotoLimit>[],
            clientGuidance: const <HelpyScenarioGuidanceItem>[],
            masterGuidance: const <HelpyScenarioGuidanceItem>[],
          ),
          returnsNormally,
        );
      },
    );

    test(
      'allows a scenario to reuse a photo question from another scenario',
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
          ],
          photoLimits: <HelpyPhotoLimit>[_photoLimit(key: 'replace_photos')],
          clientGuidance: const <HelpyScenarioGuidanceItem>[],
          masterGuidance: const <HelpyScenarioGuidanceItem>[],
        );

        expect(
          () => HelpyServiceIntakePayload(
            schemaVersion: '1',
            entity: HelpyIntakeEntityContent(
              semanticKey: 'plumbing.faucet',
              displayName: 'Faucet',
            ),
            scenarios: <HelpyIntakeScenario>[installScenario, replaceScenario],
          ),
          returnsNormally,
        );
      },
    );

    test('rejects a reuse reference outside the owning intake entity', () {
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
          schemaVersion: '1',
          entity: HelpyIntakeEntityContent(
            semanticKey: 'plumbing.faucet',
            displayName: 'Faucet',
          ),
          scenarios: <HelpyIntakeScenario>[replaceScenario],
        ),
        throwsArgumentError,
      );
    });

    test(
      'rejects a photo question that references another scenario qualifier',
      () {
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
      },
    );

    test('rejects duplicate guidance keys within one role block', () {
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

    test('rejects an inconsistent photo limit', () {
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
