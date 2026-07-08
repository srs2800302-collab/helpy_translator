import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/adapters/helpy/application/engineering/helpy_engineering_context_presenter.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_adapter_contract.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_entity_kinds.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/helpy_service_intake_payload.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('HelpyEngineeringContextPresenter', () {
    test('renders each scenario as a separate full engineering context', () {
      final EngineeringContext context = EngineeringContext(
        targetEntity: _entity(
          HelpyServiceIntakePayload(
            schemaVersion: '1',
            entity: HelpyIntakeEntityContent(
              semanticKey: 'plumbing.faucet',
              displayName: 'Faucet',
            ),
            scenarios: <HelpyIntakeScenario>[
              _scenario(
                key: 'install_connect',
                displayName: 'Install & Connect',
                selectedAnswerKey: 'install_connect',
                questions: <HelpyIntakeQuestion>[_locationQuestion()],
                photoQuestions: <HelpyPhotoQuestion>[
                  _photoQuestion(
                    key: 'installed_faucet',
                    prompt: 'Installed faucet photo',
                    qualifierKeys: <String>['location_sink'],
                    limitKey: 'install_photos',
                    source: _source(HelpyPhotoSourceMode.direct),
                  ),
                ],
                photoLimits: <HelpyPhotoLimit>[
                  _photoLimit(key: 'install_photos'),
                ],
                clientGuidance: <HelpyScenarioGuidanceItem>[
                  _guidance('client_install', 'Подготовьте доступ.'),
                ],
                masterGuidance: <HelpyScenarioGuidanceItem>[
                  _guidance('master_install', 'Проверьте совместимость.'),
                ],
              ),
              _scenario(
                key: 'replace',
                displayName: 'Replace',
                selectedAnswerKey: 'replace',
                questions: <HelpyIntakeQuestion>[_preserveOldQuestion()],
                photoQuestions: <HelpyPhotoQuestion>[
                  _photoQuestion(
                    key: 'install_context',
                    prompt: 'Install context photo',
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
                    prompt: 'Existing faucet photo',
                    qualifierKeys: const <String>[],
                    limitKey: 'replace_photos',
                    source: _source(HelpyPhotoSourceMode.replacement),
                  ),
                ],
                photoLimits: <HelpyPhotoLimit>[
                  _photoLimit(key: 'replace_photos'),
                ],
                clientGuidance: <HelpyScenarioGuidanceItem>[
                  _guidance('client_replace', 'Освободите место замены.'),
                ],
                masterGuidance: <HelpyScenarioGuidanceItem>[
                  _guidance('master_replace', 'Проверьте старый кран.'),
                ],
              ),
            ],
          ),
        ),
      );

      final List<String> lines = const HelpyEngineeringContextPresenter()
          .renderLines(context);

      expect(lines.first, 'Entity: Faucet');
      expect(lines, contains('├── Scenario: Install & Connect'));
      expect(lines, contains('│   ├── Scenario Entry Evidence'));
      expect(lines, contains('│   ├── Questions'));
      expect(lines, contains('│   ├── Photo Questions'));
      expect(lines, contains('│   ├── Photo Limits'));
      expect(lines, contains('│   ├── Client Guidance'));
      expect(lines, contains('│   └── Master Guidance'));
      expect(lines, contains('└── Scenario: Replace'));
      expect(lines, contains('    ├── Scenario Entry Evidence'));
      expect(lines, contains('    ├── Questions'));
      expect(lines, contains('    ├── Photo Questions'));
      expect(lines, contains('    ├── Photo Limits'));
      expect(lines, contains('    ├── Client Guidance'));
      expect(lines, contains('    └── Master Guidance'));

      final String output = lines.join('\n');

      expect(output, contains('client_install: Подготовьте доступ.'));
      expect(output, contains('master_install: Проверьте совместимость.'));
      expect(output, contains('client_replace: Освободите место замены.'));
      expect(output, contains('master_replace: Проверьте старый кран.'));
      expect(
        output,
        contains('source=reuse(install_connect.installed_faucet)'),
      );
      expect(output, contains('source=replacement'));
    });
  });
}

RegistryEntity _entity(HelpyServiceIntakePayload payload) {
  return RegistryEntity(
    id: RegistryEntityId('registry-entity-faucet'),
    path: RegistryPath(<String>['helpy', 'plumbing', 'faucet']),
    kind: RegistryEntityKind(
      adapterContract: HelpyAdapterContract.identity,
      kindId: HelpyRegistryEntityKinds.serviceIntakeKindId,
      schemaVersion: '1',
    ),
    payload: payload,
  );
}

HelpyIntakeScenario _scenario({
  required String key,
  required String displayName,
  required String selectedAnswerKey,
  required Iterable<HelpyIntakeQuestion> questions,
  required Iterable<HelpyPhotoQuestion> photoQuestions,
  required Iterable<HelpyPhotoLimit> photoLimits,
  required Iterable<HelpyScenarioGuidanceItem> clientGuidance,
  required Iterable<HelpyScenarioGuidanceItem> masterGuidance,
}) {
  return HelpyIntakeScenario(
    key: key,
    displayName: displayName,
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

HelpyIntakeQuestion _preserveOldQuestion() {
  return HelpyIntakeQuestion(
    key: 'preserve_old_faucet',
    prompt: 'Preserve old faucet?',
    answerOptions: <HelpyAnswerOption>[
      HelpyAnswerOption(key: 'yes', displayName: 'Yes'),
      HelpyAnswerOption(key: 'no', displayName: 'No'),
    ],
    qualifiers: const <HelpyQuestionQualifier>[],
  );
}

HelpyPhotoQuestion _photoQuestion({
  required String key,
  required String prompt,
  required Iterable<String> qualifierKeys,
  required String limitKey,
  required HelpyPhotoQuestionSource source,
}) {
  return HelpyPhotoQuestion(
    key: key,
    prompt: prompt,
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
