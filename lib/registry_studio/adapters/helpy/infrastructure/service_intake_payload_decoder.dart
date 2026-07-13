import '../domain/payloads/service_intake_payload.dart';
import 'service_intake_semantic_manifest_source.dart';
import 'service_intake_source_block_extractor.dart';

final class ServiceIntakePayloadDecoder {
  const ServiceIntakePayloadDecoder();

  ServiceIntakePayload decode({
    required ServiceIntakeSourceBlock sourceBlock,
    required ServiceIntakeSemanticManifestEntry manifestEntry,
  }) {
    if (sourceBlock.identity.entityId != manifestEntry.entityId) {
      throw FormatException(
        'Service intake source block identity '
        '"${sourceBlock.identity.entityId.value}" does not match semantic '
        'manifest identity "${manifestEntry.entityId.value}".',
      );
    }

    final _ServiceIntakeSourceIndex sourceIndex = _ServiceIntakeSourceIndex(
      sourceBlock.sourceText,
    );

    return ServiceIntakePayload(
      displayName: sourceIndex.resolveLineText(
        manifestEntry.displayNameLocator,
      ),
      scenarios: <IntakeScenario>[
        for (final ServiceIntakeSemanticScenario scenario
            in manifestEntry.scenarios)
          _decodeScenario(sourceIndex: sourceIndex, scenario: scenario),
      ],
    );
  }

  IntakeScenario _decodeScenario({
    required _ServiceIntakeSourceIndex sourceIndex,
    required ServiceIntakeSemanticScenario scenario,
  }) {
    return IntakeScenario(
      key: scenario.key,
      displayName: sourceIndex.resolveLineText(scenario.displayNameLocator),
      entryEvidence: _decodeEntryEvidence(scenario.entryEvidence),
      questions: <IntakeQuestion>[
        for (final ServiceIntakeSemanticQuestion question in scenario.questions)
          _decodeQuestion(sourceIndex: sourceIndex, question: question),
      ],
      photoQuestions: <PhotoQuestion>[
        for (final ServiceIntakeSemanticPhotoQuestion photoQuestion
            in scenario.photoQuestions)
          PhotoQuestion(
            key: photoQuestion.key,
            prompt: sourceIndex.resolveItemText(photoQuestion.promptLocator),
            isRequired: photoQuestion.isRequired,
            applicabilityQualifierKeys:
                photoQuestion.applicabilityQualifierKeys,
            photoLimitKey: photoQuestion.photoLimitKey,
            source: PhotoQuestionSource(
              mode: photoQuestion.source.mode,
              sourceScenarioKey: photoQuestion.source.sourceScenarioKey,
              sourcePhotoQuestionKey:
                  photoQuestion.source.sourcePhotoQuestionKey,
            ),
          ),
      ],
      photoLimits: <PhotoLimit>[
        for (final ServiceIntakeSemanticPhotoLimit limit
            in scenario.photoLimits)
          PhotoLimit(
            key: limit.key,
            requiredCount: sourceIndex.resolveItemCount(
              limit.requiredCountLocator,
            ),
            optionalCount: sourceIndex.resolveItemCount(
              limit.optionalCountLocator,
            ),
            totalMaximum: sourceIndex.resolveItemCount(
              limit.totalMaximumLocator,
            ),
          ),
      ],
      clientGuidance: <ScenarioGuidanceItem>[
        for (final ServiceIntakeSemanticGuidanceItem item
            in scenario.clientGuidance)
          ScenarioGuidanceItem(
            key: item.key,
            text: sourceIndex.resolveItemText(item.textLocator),
          ),
      ],
      masterGuidance: <ScenarioGuidanceItem>[
        for (final ServiceIntakeSemanticGuidanceItem item
            in scenario.masterGuidance)
          ScenarioGuidanceItem(
            key: item.key,
            text: sourceIndex.resolveItemText(item.textLocator),
          ),
      ],
    );
  }

  IntakeQuestion _decodeQuestion({
    required _ServiceIntakeSourceIndex sourceIndex,
    required ServiceIntakeSemanticQuestion question,
  }) {
    return IntakeQuestion(
      key: question.key,
      prompt: sourceIndex.resolveItemText(question.promptLocator),
      inputMode: question.inputMode,
      isRequired: question.isRequired,
      answerOptions: <AnswerOption>[
        for (final ServiceIntakeSemanticAnswerOption option
            in question.answerOptions)
          AnswerOption(
            key: option.key,
            displayName: sourceIndex.resolveItemText(option.displayNameLocator),
          ),
      ],
      qualifiers: <QuestionQualifier>[
        for (final ServiceIntakeSemanticQuestionQualifier qualifier
            in question.qualifiers)
          QuestionQualifier(
            key: qualifier.key,
            kind: qualifier.kind,
            expression:
                '${qualifier.sourceQuestionKey}='
                '${qualifier.sourceAnswerOptionKey}',
          ),
      ],
    );
  }

  ScenarioEntryEvidence _decodeEntryEvidence(
    ServiceIntakeSemanticScenarioEntryEvidence evidence,
  ) {
    return switch (evidence.mode) {
      ScenarioEntryEvidenceMode.directSelection =>
        const ScenarioEntryEvidence.directSelection(),
      ScenarioEntryEvidenceMode.selectorAnswer =>
        ScenarioEntryEvidence.selectorAnswer(
          sourceSelectorQuestionKey: evidence.sourceSelectorQuestionKey!,
          sourceSelectedAnswerOptionKey:
              evidence.sourceSelectedAnswerOptionKey!,
        ),
    };
  }
}

final class _ServiceIntakeSourceIndex {
  _ServiceIntakeSourceIndex(String source)
    : lines = List<String>.unmodifiable(
        source
            .split('\n')
            .map(
              (String line) => line.endsWith('\r')
                  ? line.substring(0, line.length - 1)
                  : line,
            )
            .toList(growable: false),
      ) {
    if (source.trim().isEmpty) {
      throw const FormatException(
        'Service intake source block must not be empty.',
      );
    }
  }

  static final RegExp _headingPrefix = RegExp(r'^\s*#{1,6}\s+');
  static final RegExp _numberedItemPrefix = RegExp(r'^\s*\d+\.\s+');
  static final RegExp _bulletPrefix = RegExp(r'^\s*-\s+');
  static final RegExp _numberPattern = RegExp(r'\d+');

  final List<String> lines;

  String resolveLineText(ServiceIntakeSemanticLineLocator locator) {
    return _stripStructuralPrefix(lines[_resolveLineIndex(locator)]);
  }

  String resolveItemText(ServiceIntakeSemanticItemLocator locator) {
    return _stripStructuralPrefix(_resolveItemLine(locator));
  }

  int resolveItemCount(ServiceIntakeSemanticItemLocator locator) {
    final String line = _resolveItemLine(locator);
    final RegExpMatch? match = _numberPattern.firstMatch(
      _stripStructuralPrefix(line),
    );

    if (match == null) {
      throw FormatException(
        'Service intake numeric item "${locator.expectedText}" '
        'does not contain an integer value.',
      );
    }

    return int.parse(match.group(0)!);
  }

  int _resolveLineIndex(ServiceIntakeSemanticLineLocator locator) {
    int resolvedOccurrence = 0;

    for (int index = 0; index < lines.length; index += 1) {
      if (lines[index] != locator.expectedText) {
        continue;
      }

      resolvedOccurrence += 1;

      if (resolvedOccurrence == locator.occurrence) {
        return index;
      }
    }

    throw FormatException(
      'Service intake line locator "${locator.expectedText}" '
      'occurrence ${locator.occurrence} did not resolve exactly.',
    );
  }

  String _resolveItemLine(ServiceIntakeSemanticItemLocator locator) {
    final int contextIndex = _resolveLineIndex(locator.context);
    int resolvedOrdinal = 0;

    for (int index = contextIndex + 1; index < lines.length; index += 1) {
      final String line = lines[index];

      if (!_matchesKind(line, locator.kind)) {
        continue;
      }

      resolvedOrdinal += 1;

      if (resolvedOrdinal != locator.ordinal) {
        continue;
      }

      if (line != locator.expectedText) {
        throw FormatException(
          'Service intake item after context '
          '"${locator.context.expectedText}" at ordinal '
          '${locator.ordinal} does not match expected text '
          '"${locator.expectedText}". Found "$line".',
        );
      }

      return line;
    }

    throw FormatException(
      'Service intake item "${locator.expectedText}" after context '
      '"${locator.context.expectedText}" at ordinal '
      '${locator.ordinal} did not resolve exactly.',
    );
  }

  bool _matchesKind(String line, ServiceIntakeSemanticItemKind kind) {
    return switch (kind) {
      ServiceIntakeSemanticItemKind.numberedItem =>
        _numberedItemPrefix.hasMatch(line),
      ServiceIntakeSemanticItemKind.bullet => _bulletPrefix.hasMatch(line),
    };
  }

  String _stripStructuralPrefix(String line) {
    final String withoutHeading = line.replaceFirst(_headingPrefix, '');
    final String withoutNumber = withoutHeading.replaceFirst(
      _numberedItemPrefix,
      '',
    );
    final String withoutBullet = withoutNumber.replaceFirst(_bulletPrefix, '');

    return withoutBullet.trim();
  }
}
