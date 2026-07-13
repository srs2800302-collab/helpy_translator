import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/service_intake_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_semantic_manifest_source.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceIntakeSemanticManifestSource', () {
    test(
      'loads selector-answer and direct scenarios with typed references',
      () async {
        final ServiceIntakeSemanticManifestSource source = _source(
          _manifest(<Map<String, Object?>>[_entry()]),
        );

        final List<ServiceIntakeSemanticManifestEntry> entries = await source
            .load();
        final ServiceIntakeSemanticManifestEntry entry = entries.single;

        expect(entry.entityId.value, _faucetId);
        expect(entry.entrySelectors.single.key, 'what_to_do');
        expect(entry.entrySelectors.single.answerOptionKeys, <String>[
          'install_connect',
          'replace',
        ]);
        expect(
          entry.scenarios.first.entryEvidence.mode,
          ScenarioEntryEvidenceMode.selectorAnswer,
        );
        expect(
          entry.scenarios.first.entryEvidence.sourceSelectorQuestionKey,
          'what_to_do',
        );
        expect(
          entry.scenarios.last.entryEvidence.mode,
          ScenarioEntryEvidenceMode.directSelection,
        );
        expect(
          entry
              .scenarios
              .first
              .questions
              .single
              .qualifiers
              .single
              .sourceAnswerOptionKey,
          'sink',
        );
        expect(
          entry
              .scenarios
              .first
              .photoLimits
              .single
              .requiredCountLocator
              .expectedText,
          '- Обязательные: 1 фотография.',
        );
        expect(() => entries.add(entry), throwsUnsupportedError);
        expect(
          () => entry.scenarios.add(entry.scenarios.first),
          throwsUnsupportedError,
        );
      },
    );

    test('rejects missing identity-manifest coverage', () {
      final ServiceIntakeSemanticManifestSource source = _source(
        _manifest(<Map<String, Object?>>[_entry()]),
        expectedEntityIds: const <String>[_faucetId, _toiletId],
      );

      expect(
        () => source.decode(_manifest(<Map<String, Object?>>[_entry()])),
        throwsFormatException,
      );
    });

    test('rejects duplicate scenario keys', () {
      final Map<String, Object?> entry = _entry();
      final List<Map<String, Object?>> scenarios =
          entry['scenarios']! as List<Map<String, Object?>>;
      scenarios.add(Map<String, Object?>.from(scenarios.first));

      expect(
        () => _source(
          _manifest(<Map<String, Object?>>[entry]),
        ).decode(_manifest(<Map<String, Object?>>[entry])),
        throwsFormatException,
      );
    });

    test('rejects an unknown entity-level selector answer', () {
      final Map<String, Object?> entry = _entry();
      final List<Map<String, Object?>> scenarios =
          entry['scenarios']! as List<Map<String, Object?>>;
      final Map<String, Object?> evidence =
          scenarios.first['entryEvidence']! as Map<String, Object?>;

      evidence['sourceSelectedAnswerOptionKey'] = 'unknown_answer';

      final String manifest = _manifest(<Map<String, Object?>>[entry]);

      expect(() => _source(manifest).decode(manifest), throwsFormatException);
    });

    test('rejects a qualifier referencing a foreign answer option', () {
      final Map<String, Object?> entry = _entry();
      final List<Map<String, Object?>> scenarios =
          entry['scenarios']! as List<Map<String, Object?>>;
      final List<Map<String, Object?>> questions =
          scenarios.first['questions']! as List<Map<String, Object?>>;
      final List<Map<String, Object?>> qualifiers =
          questions.first['qualifiers']! as List<Map<String, Object?>>;

      qualifiers.first['sourceAnswerOptionKey'] = 'unknown_answer';

      final String manifest = _manifest(<Map<String, Object?>>[entry]);

      expect(() => _source(manifest).decode(manifest), throwsFormatException);
    });

    test('rejects a photo question referencing a foreign photo limit', () {
      final Map<String, Object?> entry = _entry();
      final List<Map<String, Object?>> scenarios =
          entry['scenarios']! as List<Map<String, Object?>>;
      final List<Map<String, Object?>> photoQuestions =
          scenarios.first['photoQuestions']! as List<Map<String, Object?>>;

      photoQuestions.first['photoLimitKey'] = 'unknown_limit';

      final String manifest = _manifest(<Map<String, Object?>>[entry]);

      expect(() => _source(manifest).decode(manifest), throwsFormatException);
    });
  });
}

const String _faucetId = 'helpy.service_intake.plumbing.faucet';
const String _toiletId = 'helpy.service_intake.plumbing.toilet';

ServiceIntakeSemanticManifestSource _source(
  String manifest, {
  List<String> expectedEntityIds = const <String>[_faucetId],
}) {
  return ServiceIntakeSemanticManifestSource(
    assetBundle: _MemoryAssetBundle(manifest),
    assetPath: 'manifest.json',
    expectedEntityIds: expectedEntityIds.map(RegistryEntityId.new),
  );
}

String _manifest(List<Map<String, Object?>> entries) {
  return jsonEncode(<String, Object?>{'version': 'v1', 'entries': entries});
}

Map<String, Object?> _entry() {
  return <String, Object?>{
    'entityId': _faucetId,
    'displayNameLocator': _line('### Plumbing → Кран'),
    'entrySelectors': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'what_to_do',
        'answerOptionKeys': <String>['install_connect', 'replace'],
      },
    ],
    'scenarios': <Map<String, Object?>>[_selectorScenario(), _directScenario()],
  };
}

Map<String, Object?> _selectorScenario() {
  const String questionText = '2. Где будет установлен и подключён кран?';
  const String photoSection =
      'Обязательные фотографии — Установить и подключить кран — Раковина:';
  const String limitSection =
      'Лимит фотографий — Установить и подключить кран — Раковина:';

  return <String, Object?>{
    'key': 'install_connect',
    'displayNameLocator': _line('Если выбрано «Установить и подключить кран»:'),
    'entryEvidence': <String, Object?>{
      'mode': 'selectorAnswer',
      'sourceSelectorQuestionKey': 'what_to_do',
      'sourceSelectedAnswerOptionKey': 'install_connect',
    },
    'questions': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'location',
        'promptLocator': _item(
          context: 'Вопросы:',
          kind: 'numberedItem',
          ordinal: 2,
          expectedText: questionText,
        ),
        'answerOptions': <Map<String, Object?>>[
          <String, Object?>{
            'key': 'sink',
            'displayNameLocator': _item(
              context: questionText,
              kind: 'bullet',
              ordinal: 1,
              expectedText: '- Раковина.',
            ),
          },
        ],
        'qualifiers': <Map<String, Object?>>[
          <String, Object?>{
            'key': 'location_sink',
            'kind': 'answerContext',
            'sourceQuestionKey': 'location',
            'sourceAnswerOptionKey': 'sink',
          },
        ],
      },
    ],
    'photoQuestions': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'installed_sink',
        'promptLocator': _item(
          context: photoSection,
          kind: 'numberedItem',
          ordinal: 1,
          expectedText: '1. Фотография установленной раковины.',
        ),
        'isRequired': true,
        'applicabilityQualifierKeys': <String>['location_sink'],
        'photoLimitKey': 'install_sink_limit',
        'source': <String, Object?>{'mode': 'direct'},
      },
    ],
    'photoLimits': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'install_sink_limit',
        'requiredCountLocator': _item(
          context: limitSection,
          kind: 'bullet',
          ordinal: 1,
          expectedText: '- Обязательные: 1 фотография.',
        ),
        'optionalCountLocator': _item(
          context: limitSection,
          kind: 'bullet',
          ordinal: 2,
          expectedText: '- Дополнительные: до 1 фотографии.',
        ),
        'totalMaximumLocator': _item(
          context: limitSection,
          kind: 'bullet',
          ordinal: 3,
          expectedText: '- Всего: до 2 из 10 фотографий.',
        ),
      },
    ],
    'clientGuidance': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'client_access',
        'textLocator': _item(
          context: 'Правила для клиента — Установить и подключить:',
          kind: 'bullet',
          ordinal: 1,
          expectedText: '- Подготовьте доступ к месту выполнения работ.',
        ),
      },
    ],
    'masterGuidance': <Map<String, Object?>>[
      <String, Object?>{
        'key': 'master_check',
        'textLocator': _item(
          context: '1. Проверка совместимости до начала работ:',
          kind: 'bullet',
          ordinal: 1,
          expectedText:
              '- Перед распаковкой мастер обязан проверить совместимость.',
        ),
      },
    ],
  };
}

Map<String, Object?> _directScenario() {
  return <String, Object?>{
    'key': 'direct_review',
    'displayNameLocator': _line('### Plumbing → Кран'),
    'entryEvidence': <String, Object?>{'mode': 'directSelection'},
    'questions': <Map<String, Object?>>[],
    'photoQuestions': <Map<String, Object?>>[],
    'photoLimits': <Map<String, Object?>>[],
    'clientGuidance': <Map<String, Object?>>[],
    'masterGuidance': <Map<String, Object?>>[],
  };
}

Map<String, Object?> _line(String expectedText, {int occurrence = 1}) {
  return <String, Object?>{
    'expectedText': expectedText,
    'occurrence': occurrence,
  };
}

Map<String, Object?> _item({
  required String context,
  required String kind,
  required int ordinal,
  required String expectedText,
}) {
  return <String, Object?>{
    'context': _line(context),
    'kind': kind,
    'ordinal': ordinal,
    'expectedText': expectedText,
  };
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.source);

  final String source;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(source));

    return ByteData.view(bytes.buffer);
  }
}
