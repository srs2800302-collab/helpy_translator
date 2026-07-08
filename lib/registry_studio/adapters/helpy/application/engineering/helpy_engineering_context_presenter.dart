import '../../../../core/application/engineering/engineering_context.dart';
import '../../domain/payloads/helpy_service_intake_payload.dart';

final class HelpyEngineeringContextPresenter {
  const HelpyEngineeringContextPresenter();

  String renderText(EngineeringContext context) {
    return renderLines(context).join('\n');
  }

  List<String> renderLines(EngineeringContext context) {
    final HelpyServiceIntakePayload payload = context
        .requirePayload<HelpyServiceIntakePayload>();

    final List<String> lines = <String>[
      'Entity: ${payload.entity.displayName}',
    ];

    for (int index = 0; index < payload.scenarios.length; index += 1) {
      final HelpyIntakeScenario scenario = payload.scenarios[index];
      final bool isLastScenario = index == payload.scenarios.length - 1;

      _writeScenario(lines, scenario, isLastScenario);
    }

    return List<String>.unmodifiable(lines);
  }

  void _writeScenario(
    List<String> lines,
    HelpyIntakeScenario scenario,
    bool isLastScenario,
  ) {
    final String scenarioBranch = isLastScenario ? '└──' : '├──';
    final String sectionPrefix = isLastScenario ? '    ' : '│   ';

    lines.add('$scenarioBranch Scenario: ${scenario.displayName}');

    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: false,
      title: 'Scenario Entry Evidence',
      items: <String>[
        'selector=${scenario.entryEvidence.sourceSelectorQuestionKey}',
        'selectedAnswer=${scenario.entryEvidence.sourceSelectedAnswerOptionKey}',
      ],
    );
    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: false,
      title: 'Questions',
      items: scenario.questions.map(_questionSummary),
    );
    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: false,
      title: 'Photo Questions',
      items: scenario.photoQuestions.map(_photoQuestionSummary),
    );
    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: false,
      title: 'Photo Limits',
      items: scenario.photoLimits.map(_photoLimitSummary),
    );
    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: false,
      title: 'Client Guidance',
      items: scenario.clientGuidance.map(_guidanceSummary),
    );
    _writeSection(
      lines,
      prefix: sectionPrefix,
      isLast: true,
      title: 'Master Guidance',
      items: scenario.masterGuidance.map(_guidanceSummary),
    );
  }

  void _writeSection(
    List<String> lines, {
    required String prefix,
    required bool isLast,
    required String title,
    required Iterable<String> items,
  }) {
    final String sectionBranch = isLast ? '└──' : '├──';
    final String itemPrefix = prefix + (isLast ? '    ' : '│   ');

    lines.add('$prefix$sectionBranch $title');

    final List<String> normalizedItems = List<String>.unmodifiable(items);

    for (int index = 0; index < normalizedItems.length; index += 1) {
      final bool isLastItem = index == normalizedItems.length - 1;
      final String itemBranch = isLastItem ? '└──' : '├──';

      lines.add('$itemPrefix$itemBranch ${normalizedItems[index]}');
    }
  }

  String _questionSummary(HelpyIntakeQuestion question) {
    final String answers = question.answerOptions
        .map((HelpyAnswerOption item) => '${item.key}: ${item.displayName}')
        .join(', ');
    final String qualifiers = question.qualifiers
        .map(
          (HelpyQuestionQualifier item) =>
              '${item.key}: ${item.kind.name} ${item.expression}',
        )
        .join(', ');

    return '${question.key}: ${question.prompt}; '
        'answers=[$answers]; qualifiers=[$qualifiers]';
  }

  String _photoQuestionSummary(HelpyPhotoQuestion question) {
    final String qualifierKeys = question.applicabilityQualifierKeys.join(', ');

    return '${question.key}: ${question.prompt}; '
        'required=${question.isRequired}; '
        'limit=${question.photoLimitKey}; '
        'qualifiers=[$qualifierKeys]; '
        'source=${_photoSourceSummary(question.source)}';
  }

  String _photoLimitSummary(HelpyPhotoLimit limit) {
    return '${limit.key}: '
        'required=${limit.requiredCount}; '
        'optional=${limit.optionalCount}; '
        'max=${limit.totalMaximum}';
  }

  String _guidanceSummary(HelpyScenarioGuidanceItem item) {
    return '${item.key}: ${item.text}';
  }

  String _photoSourceSummary(HelpyPhotoQuestionSource source) {
    if (source.mode != HelpyPhotoSourceMode.reuse) {
      return source.mode.name;
    }

    return '${source.mode.name}('
        '${source.sourceScenarioKey}.${source.sourcePhotoQuestionKey}'
        ')';
  }
}
