import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../domain/payloads/service_intake_payload.dart';

enum ServiceIntakeSemanticItemKind { numberedItem, bullet }

typedef ServiceIntakeSemanticLineLocator = ({
  String expectedText,
  int occurrence,
});

typedef ServiceIntakeSemanticItemLocator = ({
  ServiceIntakeSemanticLineLocator context,
  ServiceIntakeSemanticItemKind kind,
  int ordinal,
  String expectedText,
});

typedef ServiceIntakeSemanticEntrySelector = ({
  String key,
  List<String> answerOptionKeys,
});

typedef ServiceIntakeSemanticManifestEntry = ({
  RegistryEntityId entityId,
  ServiceIntakeSemanticLineLocator displayNameLocator,
  List<ServiceIntakeSemanticEntrySelector> entrySelectors,
  List<ServiceIntakeSemanticScenario> scenarios,
});

typedef ServiceIntakeSemanticScenario = ({
  String key,
  ServiceIntakeSemanticLineLocator displayNameLocator,
  ServiceIntakeSemanticScenarioEntryEvidence entryEvidence,
  List<ServiceIntakeSemanticQuestion> questions,
  List<ServiceIntakeSemanticPhotoQuestion> photoQuestions,
  List<ServiceIntakeSemanticPhotoLimit> photoLimits,
  List<ServiceIntakeSemanticGuidanceItem> clientGuidance,
  List<ServiceIntakeSemanticGuidanceItem> masterGuidance,
});

typedef ServiceIntakeSemanticScenarioEntryEvidence = ({
  ScenarioEntryEvidenceMode mode,
  String? sourceSelectorQuestionKey,
  String? sourceSelectedAnswerOptionKey,
});

typedef ServiceIntakeSemanticQuestion = ({
  String key,
  ServiceIntakeSemanticItemLocator promptLocator,
  List<ServiceIntakeSemanticAnswerOption> answerOptions,
  List<ServiceIntakeSemanticQuestionQualifier> qualifiers,
});

typedef ServiceIntakeSemanticAnswerOption = ({
  String key,
  ServiceIntakeSemanticItemLocator displayNameLocator,
});

typedef ServiceIntakeSemanticQuestionQualifier = ({
  String key,
  QuestionQualifierKind kind,
  String sourceQuestionKey,
  String sourceAnswerOptionKey,
});

typedef ServiceIntakeSemanticPhotoQuestion = ({
  String key,
  ServiceIntakeSemanticItemLocator promptLocator,
  bool isRequired,
  List<String> applicabilityQualifierKeys,
  String photoLimitKey,
  ServiceIntakeSemanticPhotoSource source,
});

typedef ServiceIntakeSemanticPhotoSource = ({
  PhotoSourceMode mode,
  String? sourceScenarioKey,
  String? sourcePhotoQuestionKey,
});

typedef ServiceIntakeSemanticPhotoLimit = ({
  String key,
  ServiceIntakeSemanticItemLocator requiredCountLocator,
  ServiceIntakeSemanticItemLocator optionalCountLocator,
  ServiceIntakeSemanticItemLocator totalMaximumLocator,
});

typedef ServiceIntakeSemanticGuidanceItem = ({
  String key,
  ServiceIntakeSemanticItemLocator textLocator,
});

final class ServiceIntakeSemanticManifestSource {
  ServiceIntakeSemanticManifestSource({
    required this.assetBundle,
    required Iterable<RegistryEntityId> expectedEntityIds,
    this.assetPath = defaultAssetPath,
  }) : expectedEntityIds = Set<RegistryEntityId>.unmodifiable(
         expectedEntityIds,
       ) {
    if (this.expectedEntityIds.isEmpty) {
      throw ArgumentError.value(
        expectedEntityIds,
        'expectedEntityIds',
        'Expected service intake identities must not be empty.',
      );
    }
  }

  static const String defaultAssetPath =
      'assets/registry_studio/helpy/'
      'service_intake_semantic_manifest_v1.json';

  static const String _supportedVersion = 'v1';

  final AssetBundle assetBundle;
  final String assetPath;
  final Set<RegistryEntityId> expectedEntityIds;

  Future<List<ServiceIntakeSemanticManifestEntry>> load() async {
    final String source = await assetBundle.loadString(assetPath);

    return decode(source);
  }

  List<ServiceIntakeSemanticManifestEntry> decode(String source) {
    final Object? decoded = jsonDecode(source);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Service intake semantic manifest must be a JSON object.',
      );
    }

    _ensureExactKeys(decoded, const <String>{
      'version',
      'entries',
    }, 'Service intake semantic manifest');

    final String version = _requiredString(decoded, 'version');

    if (version != _supportedVersion) {
      throw FormatException(
        'Unsupported service intake semantic manifest version: $version.',
      );
    }

    final List<dynamic> encodedEntries = _requiredList(decoded, 'entries');

    if (encodedEntries.isEmpty) {
      throw const FormatException(
        'Service intake semantic manifest must contain entries.',
      );
    }

    final List<ServiceIntakeSemanticManifestEntry> entries =
        <ServiceIntakeSemanticManifestEntry>[];
    final Set<RegistryEntityId> actualEntityIds = <RegistryEntityId>{};

    for (final Object? encodedEntry in encodedEntries) {
      final ServiceIntakeSemanticManifestEntry entry = _decodeEntry(
        encodedEntry,
      );

      if (!actualEntityIds.add(entry.entityId)) {
        throw FormatException(
          'Duplicate semantic manifest entity identity: '
          '${entry.entityId.value}.',
        );
      }

      entries.add(entry);
    }

    final Set<RegistryEntityId> missingEntityIds = expectedEntityIds.difference(
      actualEntityIds,
    );
    final Set<RegistryEntityId> unknownEntityIds = actualEntityIds.difference(
      expectedEntityIds,
    );

    if (missingEntityIds.isNotEmpty || unknownEntityIds.isNotEmpty) {
      final List<String> missing =
          missingEntityIds.map((RegistryEntityId item) => item.value).toList()
            ..sort();
      final List<String> unknown =
          unknownEntityIds.map((RegistryEntityId item) => item.value).toList()
            ..sort();

      throw FormatException(
        'Service intake semantic manifest coverage mismatch. '
        'Missing: ${missing.join(", ")}. '
        'Unknown: ${unknown.join(", ")}.',
      );
    }

    return List<ServiceIntakeSemanticManifestEntry>.unmodifiable(entries);
  }
}

ServiceIntakeSemanticManifestEntry _decodeEntry(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic manifest entry',
  );

  _ensureExactKeys(source, const <String>{
    'entityId',
    'displayNameLocator',
    'entrySelectors',
    'scenarios',
  }, 'Service intake semantic manifest entry');

  final RegistryEntityId entityId = RegistryEntityId(
    _requiredString(source, 'entityId'),
  );
  final List<ServiceIntakeSemanticEntrySelector> entrySelectors =
      <ServiceIntakeSemanticEntrySelector>[
        for (final Object? item in _requiredList(source, 'entrySelectors'))
          _decodeEntrySelector(item),
      ];
  final List<dynamic> encodedScenarios = _requiredList(source, 'scenarios');

  if (encodedScenarios.isEmpty) {
    throw FormatException(
      'Semantic manifest entry "${entityId.value}" must contain scenarios.',
    );
  }

  final List<ServiceIntakeSemanticScenario> scenarios =
      <ServiceIntakeSemanticScenario>[
        for (final Object? item in encodedScenarios) _decodeScenario(item),
      ];

  _ensureUniqueKeys(
    entrySelectors.map((ServiceIntakeSemanticEntrySelector item) => item.key),
    'entry selector',
    entityId.value,
  );
  _ensureUniqueKeys(
    scenarios.map((ServiceIntakeSemanticScenario item) => item.key),
    'scenario',
    entityId.value,
  );
  _validateScenarioEntryEvidence(entrySelectors, scenarios, entityId);
  _validateReusablePhotoReferences(scenarios, entityId);

  return (
    entityId: entityId,
    displayNameLocator: _decodeLineLocator(source['displayNameLocator']),
    entrySelectors: List<ServiceIntakeSemanticEntrySelector>.unmodifiable(
      entrySelectors,
    ),
    scenarios: List<ServiceIntakeSemanticScenario>.unmodifiable(scenarios),
  );
}

ServiceIntakeSemanticEntrySelector _decodeEntrySelector(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic entry selector',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'answerOptionKeys',
  }, 'Service intake semantic entry selector');

  final String key = _requiredString(source, 'key');
  final List<String> answerOptionKeys = _requiredStringList(
    source,
    'answerOptionKeys',
    allowEmpty: false,
  );

  _ensureUniqueKeys(answerOptionKeys, 'answer option', key);

  return (key: key, answerOptionKeys: answerOptionKeys);
}

ServiceIntakeSemanticScenario _decodeScenario(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic scenario',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'displayNameLocator',
    'entryEvidence',
    'questions',
    'photoQuestions',
    'photoLimits',
    'clientGuidance',
    'masterGuidance',
  }, 'Service intake semantic scenario');

  final String scenarioKey = _requiredString(source, 'key');
  final List<ServiceIntakeSemanticQuestion> questions =
      <ServiceIntakeSemanticQuestion>[
        for (final Object? item in _requiredList(source, 'questions'))
          _decodeQuestion(item),
      ];
  final List<ServiceIntakeSemanticPhotoQuestion> photoQuestions =
      <ServiceIntakeSemanticPhotoQuestion>[
        for (final Object? item in _requiredList(source, 'photoQuestions'))
          _decodePhotoQuestion(item),
      ];
  final List<ServiceIntakeSemanticPhotoLimit> photoLimits =
      <ServiceIntakeSemanticPhotoLimit>[
        for (final Object? item in _requiredList(source, 'photoLimits'))
          _decodePhotoLimit(item),
      ];
  final List<ServiceIntakeSemanticGuidanceItem> clientGuidance =
      <ServiceIntakeSemanticGuidanceItem>[
        for (final Object? item in _requiredList(source, 'clientGuidance'))
          _decodeGuidanceItem(item),
      ];
  final List<ServiceIntakeSemanticGuidanceItem> masterGuidance =
      <ServiceIntakeSemanticGuidanceItem>[
        for (final Object? item in _requiredList(source, 'masterGuidance'))
          _decodeGuidanceItem(item),
      ];

  _ensureUniqueKeys(
    questions.map((ServiceIntakeSemanticQuestion item) => item.key),
    'question',
    scenarioKey,
  );
  _ensureUniqueKeys(
    photoQuestions.map((ServiceIntakeSemanticPhotoQuestion item) => item.key),
    'photo question',
    scenarioKey,
  );
  _ensureUniqueKeys(
    photoLimits.map((ServiceIntakeSemanticPhotoLimit item) => item.key),
    'photo limit',
    scenarioKey,
  );
  _ensureUniqueKeys(
    clientGuidance.map((ServiceIntakeSemanticGuidanceItem item) => item.key),
    'client guidance',
    scenarioKey,
  );
  _ensureUniqueKeys(
    masterGuidance.map((ServiceIntakeSemanticGuidanceItem item) => item.key),
    'master guidance',
    scenarioKey,
  );

  final Map<String, Set<String>> answerKeysByQuestion = <String, Set<String>>{
    for (final ServiceIntakeSemanticQuestion question in questions)
      question.key: <String>{
        for (final ServiceIntakeSemanticAnswerOption option
            in question.answerOptions)
          option.key,
      },
  };
  final Set<String> qualifierKeys = <String>{};

  for (final ServiceIntakeSemanticQuestion question in questions) {
    for (final ServiceIntakeSemanticQuestionQualifier qualifier
        in question.qualifiers) {
      if (!qualifierKeys.add(qualifier.key)) {
        throw FormatException(
          'Duplicate scenario qualifier key "${qualifier.key}" '
          'inside "$scenarioKey".',
        );
      }

      _validateQuestionReference(
        questionKey: qualifier.sourceQuestionKey,
        answerOptionKey: qualifier.sourceAnswerOptionKey,
        answerKeysByQuestion: answerKeysByQuestion,
        context: 'Qualifier "${qualifier.key}"',
      );
    }
  }

  final Set<String> photoLimitKeys = <String>{
    for (final ServiceIntakeSemanticPhotoLimit item in photoLimits) item.key,
  };

  for (final ServiceIntakeSemanticPhotoQuestion photoQuestion
      in photoQuestions) {
    if (!photoLimitKeys.contains(photoQuestion.photoLimitKey)) {
      throw FormatException(
        'Photo question "${photoQuestion.key}" inside "$scenarioKey" '
        'references unknown photo limit "${photoQuestion.photoLimitKey}".',
      );
    }

    for (final String qualifierKey
        in photoQuestion.applicabilityQualifierKeys) {
      if (!qualifierKeys.contains(qualifierKey)) {
        throw FormatException(
          'Photo question "${photoQuestion.key}" inside "$scenarioKey" '
          'references unknown qualifier "$qualifierKey".',
        );
      }
    }
  }

  return (
    key: scenarioKey,
    displayNameLocator: _decodeLineLocator(source['displayNameLocator']),
    entryEvidence: _decodeEntryEvidence(source['entryEvidence']),
    questions: List<ServiceIntakeSemanticQuestion>.unmodifiable(questions),
    photoQuestions: List<ServiceIntakeSemanticPhotoQuestion>.unmodifiable(
      photoQuestions,
    ),
    photoLimits: List<ServiceIntakeSemanticPhotoLimit>.unmodifiable(
      photoLimits,
    ),
    clientGuidance: List<ServiceIntakeSemanticGuidanceItem>.unmodifiable(
      clientGuidance,
    ),
    masterGuidance: List<ServiceIntakeSemanticGuidanceItem>.unmodifiable(
      masterGuidance,
    ),
  );
}

ServiceIntakeSemanticScenarioEntryEvidence _decodeEntryEvidence(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Service intake scenario entry evidence',
  );
  final String encodedMode = _requiredString(source, 'mode');

  switch (encodedMode) {
    case 'directSelection':
      _ensureExactKeys(source, const <String>{
        'mode',
      }, 'Direct-selection scenario entry evidence');

      return (
        mode: ScenarioEntryEvidenceMode.directSelection,
        sourceSelectorQuestionKey: null,
        sourceSelectedAnswerOptionKey: null,
      );

    case 'selectorAnswer':
      _ensureExactKeys(source, const <String>{
        'mode',
        'sourceSelectorQuestionKey',
        'sourceSelectedAnswerOptionKey',
      }, 'Selector-answer scenario entry evidence');

      return (
        mode: ScenarioEntryEvidenceMode.selectorAnswer,
        sourceSelectorQuestionKey: _requiredString(
          source,
          'sourceSelectorQuestionKey',
        ),
        sourceSelectedAnswerOptionKey: _requiredString(
          source,
          'sourceSelectedAnswerOptionKey',
        ),
      );

    default:
      throw FormatException(
        'Unsupported service intake scenario entry mode: $encodedMode.',
      );
  }
}

ServiceIntakeSemanticQuestion _decodeQuestion(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic question',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'promptLocator',
    'answerOptions',
    'qualifiers',
  }, 'Service intake semantic question');

  final String questionKey = _requiredString(source, 'key');
  final List<ServiceIntakeSemanticAnswerOption> answerOptions =
      <ServiceIntakeSemanticAnswerOption>[
        for (final Object? item in _requiredList(source, 'answerOptions'))
          _decodeAnswerOption(item),
      ];
  final List<ServiceIntakeSemanticQuestionQualifier> qualifiers =
      <ServiceIntakeSemanticQuestionQualifier>[
        for (final Object? item in _requiredList(source, 'qualifiers'))
          _decodeQualifier(item),
      ];

  _ensureUniqueKeys(
    answerOptions.map((ServiceIntakeSemanticAnswerOption item) => item.key),
    'answer option',
    questionKey,
  );
  _ensureUniqueKeys(
    qualifiers.map((ServiceIntakeSemanticQuestionQualifier item) => item.key),
    'question qualifier',
    questionKey,
  );

  return (
    key: questionKey,
    promptLocator: _decodeItemLocator(source['promptLocator']),
    answerOptions: List<ServiceIntakeSemanticAnswerOption>.unmodifiable(
      answerOptions,
    ),
    qualifiers: List<ServiceIntakeSemanticQuestionQualifier>.unmodifiable(
      qualifiers,
    ),
  );
}

ServiceIntakeSemanticAnswerOption _decodeAnswerOption(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic answer option',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'displayNameLocator',
  }, 'Service intake semantic answer option');

  return (
    key: _requiredString(source, 'key'),
    displayNameLocator: _decodeItemLocator(source['displayNameLocator']),
  );
}

ServiceIntakeSemanticQuestionQualifier _decodeQualifier(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic qualifier',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'kind',
    'sourceQuestionKey',
    'sourceAnswerOptionKey',
  }, 'Service intake semantic qualifier');

  final String encodedKind = _requiredString(source, 'kind');
  final QuestionQualifierKind kind = switch (encodedKind) {
    'condition' => QuestionQualifierKind.condition,
    'answerContext' => QuestionQualifierKind.answerContext,
    _ => throw FormatException(
      'Unsupported service intake qualifier kind: $encodedKind.',
    ),
  };

  return (
    key: _requiredString(source, 'key'),
    kind: kind,
    sourceQuestionKey: _requiredString(source, 'sourceQuestionKey'),
    sourceAnswerOptionKey: _requiredString(source, 'sourceAnswerOptionKey'),
  );
}

ServiceIntakeSemanticPhotoQuestion _decodePhotoQuestion(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic photo question',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'promptLocator',
    'isRequired',
    'applicabilityQualifierKeys',
    'photoLimitKey',
    'source',
  }, 'Service intake semantic photo question');

  final String key = _requiredString(source, 'key');
  final List<String> applicabilityQualifierKeys = _requiredStringList(
    source,
    'applicabilityQualifierKeys',
  );

  _ensureUniqueKeys(
    applicabilityQualifierKeys,
    'photo applicability qualifier',
    key,
  );

  return (
    key: key,
    promptLocator: _decodeItemLocator(source['promptLocator']),
    isRequired: _requiredBool(source, 'isRequired'),
    applicabilityQualifierKeys: applicabilityQualifierKeys,
    photoLimitKey: _requiredString(source, 'photoLimitKey'),
    source: _decodePhotoSource(source['source']),
  );
}

ServiceIntakeSemanticPhotoSource _decodePhotoSource(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Service intake semantic photo source',
  );
  final String encodedMode = _requiredString(source, 'mode');

  if (encodedMode == 'reuse') {
    _ensureExactKeys(source, const <String>{
      'mode',
      'sourceScenarioKey',
      'sourcePhotoQuestionKey',
    }, 'Reusable service intake photo source');

    return (
      mode: PhotoSourceMode.reuse,
      sourceScenarioKey: _requiredString(source, 'sourceScenarioKey'),
      sourcePhotoQuestionKey: _requiredString(source, 'sourcePhotoQuestionKey'),
    );
  }

  _ensureExactKeys(source, const <String>{
    'mode',
  }, 'Direct service intake photo source');

  final PhotoSourceMode mode = switch (encodedMode) {
    'direct' => PhotoSourceMode.direct,
    'addition' => PhotoSourceMode.addition,
    'replacement' => PhotoSourceMode.replacement,
    _ => throw FormatException(
      'Unsupported service intake photo source mode: $encodedMode.',
    ),
  };

  return (mode: mode, sourceScenarioKey: null, sourcePhotoQuestionKey: null);
}

ServiceIntakeSemanticPhotoLimit _decodePhotoLimit(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic photo limit',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'requiredCountLocator',
    'optionalCountLocator',
    'totalMaximumLocator',
  }, 'Service intake semantic photo limit');

  return (
    key: _requiredString(source, 'key'),
    requiredCountLocator: _decodeItemLocator(source['requiredCountLocator']),
    optionalCountLocator: _decodeItemLocator(source['optionalCountLocator']),
    totalMaximumLocator: _decodeItemLocator(source['totalMaximumLocator']),
  );
}

ServiceIntakeSemanticGuidanceItem _decodeGuidanceItem(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Each service intake semantic guidance item',
  );

  _ensureExactKeys(source, const <String>{
    'key',
    'textLocator',
  }, 'Service intake semantic guidance item');

  return (
    key: _requiredString(source, 'key'),
    textLocator: _decodeItemLocator(source['textLocator']),
  );
}

ServiceIntakeSemanticLineLocator _decodeLineLocator(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Service intake semantic line locator',
  );

  _ensureExactKeys(source, const <String>{
    'expectedText',
    'occurrence',
  }, 'Service intake semantic line locator');

  return (
    expectedText: _requiredString(source, 'expectedText'),
    occurrence: _requiredPositiveInt(source, 'occurrence'),
  );
}

ServiceIntakeSemanticItemLocator _decodeItemLocator(Object? value) {
  final Map<String, dynamic> source = _requiredObject(
    value,
    'Service intake semantic item locator',
  );

  _ensureExactKeys(source, const <String>{
    'context',
    'kind',
    'ordinal',
    'expectedText',
  }, 'Service intake semantic item locator');

  final String encodedKind = _requiredString(source, 'kind');
  final ServiceIntakeSemanticItemKind kind = switch (encodedKind) {
    'numberedItem' => ServiceIntakeSemanticItemKind.numberedItem,
    'bullet' => ServiceIntakeSemanticItemKind.bullet,
    _ => throw FormatException(
      'Unsupported service intake semantic item kind: $encodedKind.',
    ),
  };

  return (
    context: _decodeLineLocator(source['context']),
    kind: kind,
    ordinal: _requiredPositiveInt(source, 'ordinal'),
    expectedText: _requiredString(source, 'expectedText'),
  );
}

void _validateScenarioEntryEvidence(
  List<ServiceIntakeSemanticEntrySelector> entrySelectors,
  List<ServiceIntakeSemanticScenario> scenarios,
  RegistryEntityId entityId,
) {
  final Map<String, Set<String>> answersBySelector = <String, Set<String>>{
    for (final ServiceIntakeSemanticEntrySelector selector in entrySelectors)
      selector.key: selector.answerOptionKeys.toSet(),
  };

  for (final ServiceIntakeSemanticScenario scenario in scenarios) {
    final ServiceIntakeSemanticScenarioEntryEvidence evidence =
        scenario.entryEvidence;

    if (evidence.mode == ScenarioEntryEvidenceMode.directSelection) {
      continue;
    }

    final String selectorKey = evidence.sourceSelectorQuestionKey!;
    final String answerOptionKey = evidence.sourceSelectedAnswerOptionKey!;
    final Set<String>? answerOptionKeys = answersBySelector[selectorKey];

    if (answerOptionKeys == null) {
      throw FormatException(
        'Scenario "${scenario.key}" inside "${entityId.value}" '
        'references unknown entry selector "$selectorKey".',
      );
    }

    if (!answerOptionKeys.contains(answerOptionKey)) {
      throw FormatException(
        'Scenario "${scenario.key}" inside "${entityId.value}" '
        'references unknown entry answer "$answerOptionKey" '
        'inside selector "$selectorKey".',
      );
    }
  }
}

void _validateQuestionReference({
  required String questionKey,
  required String answerOptionKey,
  required Map<String, Set<String>> answerKeysByQuestion,
  required String context,
}) {
  final Set<String>? answerKeys = answerKeysByQuestion[questionKey];

  if (answerKeys == null) {
    throw FormatException(
      '$context references unknown question "$questionKey".',
    );
  }

  if (!answerKeys.contains(answerOptionKey)) {
    throw FormatException(
      '$context references unknown answer option "$answerOptionKey" '
      'inside question "$questionKey".',
    );
  }
}

void _validateReusablePhotoReferences(
  List<ServiceIntakeSemanticScenario> scenarios,
  RegistryEntityId entityId,
) {
  final Map<String, Set<String>> photoKeysByScenario = <String, Set<String>>{
    for (final ServiceIntakeSemanticScenario scenario in scenarios)
      scenario.key: <String>{
        for (final ServiceIntakeSemanticPhotoQuestion photoQuestion
            in scenario.photoQuestions)
          photoQuestion.key,
      },
  };

  for (final ServiceIntakeSemanticScenario scenario in scenarios) {
    for (final ServiceIntakeSemanticPhotoQuestion photoQuestion
        in scenario.photoQuestions) {
      final ServiceIntakeSemanticPhotoSource source = photoQuestion.source;

      if (source.mode != PhotoSourceMode.reuse) {
        continue;
      }

      final String sourceScenarioKey = source.sourceScenarioKey!;
      final String sourcePhotoQuestionKey = source.sourcePhotoQuestionKey!;
      final Set<String>? sourcePhotoKeys =
          photoKeysByScenario[sourceScenarioKey];

      if (sourcePhotoKeys == null ||
          !sourcePhotoKeys.contains(sourcePhotoQuestionKey)) {
        throw FormatException(
          'Reusable photo question "${photoQuestion.key}" inside '
          '"${entityId.value}" references unknown local photo question '
          '"$sourceScenarioKey.$sourcePhotoQuestionKey".',
        );
      }

      if (sourceScenarioKey == scenario.key &&
          sourcePhotoQuestionKey == photoQuestion.key) {
        throw FormatException(
          'Reusable photo question "${photoQuestion.key}" inside '
          '"${entityId.value}" must not reference itself.',
        );
      }
    }
  }
}

Map<String, dynamic> _requiredObject(Object? value, String context) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$context must be a JSON object.');
  }

  return value;
}

List<dynamic> _requiredList(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! List<dynamic>) {
    throw FormatException(
      'Service intake semantic manifest field "$key" must be a list.',
    );
  }

  return value;
}

List<String> _requiredStringList(
  Map<String, dynamic> source,
  String key, {
  bool allowEmpty = true,
}) {
  final List<dynamic> values = _requiredList(source, key);

  if (!allowEmpty && values.isEmpty) {
    throw FormatException(
      'Service intake semantic manifest field "$key" must not be empty.',
    );
  }

  final List<String> result = <String>[];

  for (final Object? value in values) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Service intake semantic manifest field "$key" '
        'must contain only non-empty strings.',
      );
    }

    result.add(value.trim());
  }

  return List<String>.unmodifiable(result);
}

String _requiredString(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException(
      'Service intake semantic manifest field "$key" '
      'must be a non-empty string.',
    );
  }

  return value.trim();
}

bool _requiredBool(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! bool) {
    throw FormatException(
      'Service intake semantic manifest field "$key" must be a boolean.',
    );
  }

  return value;
}

int _requiredPositiveInt(Map<String, dynamic> source, String key) {
  final Object? value = source[key];

  if (value is! int || value <= 0) {
    throw FormatException(
      'Service intake semantic manifest field "$key" '
      'must be a positive integer.',
    );
  }

  return value;
}

void _ensureUniqueKeys(Iterable<String> keys, String scope, String owner) {
  final Set<String> seen = <String>{};

  for (final String key in keys) {
    if (!seen.add(key)) {
      throw FormatException('Duplicate $scope key "$key" inside "$owner".');
    }
  }
}

void _ensureExactKeys(
  Map<String, dynamic> source,
  Set<String> expected,
  String context,
) {
  final Set<String> actual = source.keys.toSet();

  if (actual.length == expected.length && actual.containsAll(expected)) {
    return;
  }

  final List<String> missing = expected.difference(actual).toList()..sort();
  final List<String> unknown = actual.difference(expected).toList()..sort();

  throw FormatException(
    '$context has invalid fields. '
    'Missing: ${missing.join(", ")}. '
    'Unknown: ${unknown.join(", ")}.',
  );
}
