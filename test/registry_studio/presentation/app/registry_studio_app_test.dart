import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/app/registry_studio_app.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

void main() {
  testWidgets('opens Translator screen by default', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    expect(find.byType(TranslatorPhraseScreen), findsOneWidget);
    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsNothing,
    );
    expect(find.text('Адаптивный переводчик'), findsWidgets);
  });

  testWidgets('starts operation from service intake source block', (
    WidgetTester tester,
  ) async {
    final provider = _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(
      _testApp(
        provider,
        serviceIntakeSourceBlocks: Future<List<ServiceIntakeSourceBlock>>.value(
          <ServiceIntakeSourceBlock>[_serviceIntakeSourceBlock()],
        ),
      ),
    );

    await _selectAppScreen(tester, 'Источник service intake');
    await tester.tap(find.text('Plumbing → Кран'));
    await tester.pumpAndSettle();

    final Finder startOperationButton = find.byKey(
      const ValueKey<String>(
        'service_intake_start_operation_'
        'helpy.service_intake.plumbing.faucet',
      ),
    );
    final Finder sourceListScrollable = find
        .descendant(
          of: find.byKey(const Key('service_intake_source_list')),
          matching: find.byType(Scrollable),
        )
        .first;

    expect(startOperationButton, findsOneWidget);
    expect(sourceListScrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      startOperationButton,
      200,
      scrollable: sourceListScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(startOperationButton);
    await tester.pumpAndSettle();

    final workspace = tester
        .widget<RegistryEngineeringOperationWorkspaceScreen>(
          find.byType(RegistryEngineeringOperationWorkspaceScreen),
        );

    expect(
      find.textContaining('helpy.service_intake.plumbing.faucet'),
      findsOneWidget,
    );
    expect(find.textContaining('Что требуется сделать?'), findsOneWidget);
    expect(
      workspace.revisionPrimaryEntityId,
      RegistryEntityId('helpy.service_intake.plumbing.faucet'),
    );
  });

  testWidgets(
    'starts comparison operation with target primary and source related',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(_translatorResult());
      final ServiceIntakeSourceBlock source = _serviceIntakeSourceBlock();
      final ServiceIntakeSourceBlock target = (
        identity: (
          entityId: RegistryEntityId(
            'helpy.service_intake.plumbing.faucet.replace',
          ),
          path: RegistryPath(const <String>[
            'helpy',
            'service_intake',
            'plumbing',
            'faucet',
            'replace',
          ]),
          ownerHeadingLevel: 2,
          ownerHeading: 'Plumbing',
          headingLevel: 3,
          heading: 'Plumbing → Замена крана',
        ),
        startLine: 120,
        endLine: 130,
        sourceText:
            '### Plumbing → Замена крана\n'
            '1. Что требуется сделать?\n'
            '- Заменить существующий кран.\n',
      );
      final RegistryEntityId affectedEntityId = RegistryEntityId(
        'registry.service_intake.plumbing.faucet.materials',
      );

      await tester.pumpWidget(
        _testApp(
          provider,
          serviceIntakeSourceBlocks:
              Future<List<ServiceIntakeSourceBlock>>.value(
                <ServiceIntakeSourceBlock>[source, target],
              ),
          relatedContextRelations: <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: target.identity.entityId,
              targetEntityId: affectedEntityId,
              meaning: RegistryRelationMeaning('references'),
            ),
          ],
        ),
      );

      await _selectAppScreen(tester, 'Источник service intake');

      final Finder sourceHeading = find.text(source.identity.heading);
      await tester.ensureVisible(sourceHeading);
      await tester.tap(sourceHeading);
      await tester.pumpAndSettle();

      final Finder sourceButton = find.byKey(
        ValueKey<String>(
          'service_intake_compare_source_'
          '${source.identity.entityId.value}',
        ),
      );
      await tester.ensureVisible(sourceButton);
      await tester.tap(sourceButton);
      await tester.pumpAndSettle();

      final Finder targetHeading = find.text(target.identity.heading);
      await tester.ensureVisible(targetHeading);
      await tester.tap(targetHeading);
      await tester.pumpAndSettle();

      final Finder targetButton = find.byKey(
        ValueKey<String>(
          'service_intake_compare_target_'
          '${target.identity.entityId.value}',
        ),
      );
      await tester.ensureVisible(targetButton);
      await tester.tap(targetButton);
      await tester.pumpAndSettle();

      final Finder comparisonButton = find.byKey(
        const Key('service_intake_source_comparison_action'),
      );
      await tester.ensureVisible(comparisonButton);
      await tester.tap(comparisonButton);
      await tester.pumpAndSettle();

      final RegistryEngineeringOperationWorkspaceScreen workspace = tester
          .widget<RegistryEngineeringOperationWorkspaceScreen>(
            find.byType(RegistryEngineeringOperationWorkspaceScreen),
          );

      expect(workspace.revisionPrimaryEntityId, target.identity.entityId);
      expect(workspace.revisionRelatedEntityIds?.toList(), <RegistryEntityId>[
        source.identity.entityId,
        affectedEntityId,
      ]);
      for (final String expectedText in <String>[
        source.identity.heading,
        source.identity.entityId.value,
        target.identity.heading,
        target.identity.entityId.value,
        'Установить и подключить кран.',
        'Заменить существующий кран.',
        '- ### Plumbing → Кран',
        '+ ### Plumbing → Замена крана',
        affectedEntityId.value,
      ]) {
        expect(find.textContaining(expectedText), findsWidgets);
      }
      expect(workspace.initialWorkingContent, target.sourceText.trim());

      final RegistryOperationComparisonViewData comparisonViewData =
          workspace.comparisonViewData!;

      expect(comparisonViewData.sourceHeading, source.identity.heading);
      expect(comparisonViewData.sourceEntityId, source.identity.entityId);
      expect(comparisonViewData.sourceText, source.sourceText.trim());
      expect(comparisonViewData.targetHeading, target.identity.heading);
      expect(comparisonViewData.targetEntityId, target.identity.entityId);
      expect(comparisonViewData.targetText, target.sourceText.trim());
      expect(comparisonViewData.affectedEntityIds, <RegistryEntityId>[
        source.identity.entityId,
        affectedEntityId,
      ]);
      expect(comparisonViewData.lineDiff, contains('- ### Plumbing → Кран'));
      expect(
        comparisonViewData.lineDiff,
        contains('+ ### Plumbing → Замена крана'),
      );

      final Finder comparisonSummary = find.byKey(
        const Key('registry_operation_comparison_summary'),
      );

      expect(comparisonSummary, findsOneWidget);

      await tester.ensureVisible(comparisonSummary);
      await tester.tap(comparisonSummary);
      await tester.pumpAndSettle();

      final Finder comparisonSheet = find.byKey(
        const Key('registry_operation_comparison_sheet'),
      );

      expect(comparisonSheet, findsOneWidget);
      expect(
        find.byKey(const Key('registry_operation_comparison_source')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('registry_operation_comparison_target')),
        findsOneWidget,
      );

      final Finder affectedSection = find.byKey(
        const Key('registry_operation_comparison_affected'),
      );
      await tester.dragUntilVisible(
        affectedSection,
        comparisonSheet,
        const Offset(0, -300),
      );
      expect(affectedSection, findsOneWidget);

      final Finder diffSection = find.byKey(
        const Key('registry_operation_comparison_diff'),
      );
      await tester.dragUntilVisible(
        diffSection,
        comparisonSheet,
        const Offset(0, -300),
      );
      expect(diffSection, findsOneWidget);

      Navigator.of(tester.element(comparisonSheet)).pop();
      await tester.pumpAndSettle();

      final TextField workingContentEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );

      expect(workingContentEditor.controller?.text, target.sourceText.trim());
      expect(
        workingContentEditor.controller?.text,
        isNot(contains('Построчные изменения:')),
      );

      final Finder saveRevisionButton = find.byKey(
        const Key('registry_operation_save_revision'),
      );

      await tester.ensureVisible(saveRevisionButton);
      await tester.tap(saveRevisionButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('registry_operation_revision_1')),
        findsOneWidget,
      );

      final Finder statusDropdown = find.byKey(
        const Key('registry_engineering_operation_requested_status_dropdown'),
      );
      final Finder transitionButton = find.byKey(
        const Key('registry_engineering_operation_status_transition_button'),
      );

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(transitionButton);
      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      expect(find.text('Текущий статус:\nreadyForDecision'), findsWidgets);

      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('decided').last);
      await tester.pumpAndSettle();

      final Finder decisionField = find.byKey(
        const Key('registry_engineering_operation_decision_statement_field'),
      );

      await tester.ensureVisible(decisionField);
      await tester.enterText(
        decisionField,
        'Approve registry source comparison.',
      );

      await tester.ensureVisible(transitionButton);
      await tester.tap(transitionButton);
      await tester.pumpAndSettle();

      expect(find.text('Текущий статус:\ndecided'), findsWidgets);
      expect(
        find.textContaining('Approve registry source comparison.'),
        findsWidgets,
      );

      final TextField lockedWorkingContentEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );
      final FilledButton lockedSaveRevisionButton = tester.widget<FilledButton>(
        saveRevisionButton,
      );

      expect(lockedWorkingContentEditor.readOnly, isTrue);
      expect(lockedSaveRevisionButton.onPressed, isNull);
    },
  );

  testWidgets('switches top-level labels between RU EN and TH', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    expect(
      find.byKey(const Key('registry_studio_language_selector')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('registry_studio_screen_selector')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<RegistryStudioUiLanguage>),
      findsNothing,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Инженерная операция'),
      findsNothing,
    );
    expect(find.text('Адаптивный переводчик'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('registry_studio_language_selector')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('ไทย'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Adaptive translator'), findsWidgets);

    await tester.tap(
      find.byKey(const Key('registry_studio_language_selector')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ไทย'));
    await tester.pumpAndSettle();

    expect(find.text('ตัวแปลแบบปรับตามบริบท'), findsWidgets);
  });

  testWidgets('opens empty engineering operation workspace', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await _selectAppScreen(tester, 'Инженерная операция');

    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsOneWidget,
    );
    expect(
      find.text('Сначала выберите источник и цель изменения.'),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);
  });

  testWidgets(
    'keeps Translator dependency wiring available after switching back',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(_translatorResult());

      await tester.pumpWidget(_testApp(provider));

      await _selectAppScreen(tester, 'Инженерная операция');

      await _selectAppScreen(tester, 'Адаптивный переводчик');

      await tester.enterText(
        find.byType(EditableText).first,
        'Проверить формулировку.',
      );
      await tester.ensureVisible(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.tap(
        find.byKey(const Key('translator_phrase_translate_button')),
      );
      await tester.pump();
      await tester.pump();

      expect(provider.callCount, 1);
      expect(provider.receivedSourceText, 'Проверить формулировку.');
      expect(find.text('Эквивалентная формулировка'), findsOneWidget);
    },
  );
  testWidgets('starts engineering operation from Translator candidate', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final TranslatorPhraseResult result = TranslatorPhraseResult(
      sourceLanguage: 'ru',
      sourceText: 'Проверить формулировку.',
      status: TranslatorPhraseStatus.canonicalDrift,
      comment: 'Требуется проверка канонической формы.',
      candidateCanonicalPhrase: 'Проверить каноническую формулировку.',
    );
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(result);

    await tester.pumpWidget(_testApp(provider));

    await tester.enterText(
      find.byKey(const Key('translator_phrase_source_text_field')),
      result.sourceText,
    );
    await tester.tap(
      find.byKey(const Key('translator_phrase_translate_button')),
    );
    await tester.pumpAndSettle();

    final Finder requestButton = find.byKey(
      const Key('translator_phrase_request_operation_button'),
    );
    final Finder translatorList = find.descendant(
      of: find.byType(TranslatorPhraseScreen),
      matching: find.byType(ListView),
    );

    await tester.dragUntilVisible(
      requestButton,
      translatorList,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(requestButton);
    await tester.pumpAndSettle();

    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);
    expect(find.text('Текущий статус:\nopen'), findsOneWidget);
    expect(find.textContaining(result.sourceText), findsWidgets);
    expect(find.textContaining(result.candidateCanonicalPhrase!), findsWidgets);

    await _selectAppScreen(tester, 'Адаптивный переводчик');
    await _selectAppScreen(tester, 'Инженерная операция');

    expect(
      find.text('Сначала выберите источник и цель изменения.'),
      findsOneWidget,
    );
  });
}

Future<void> _selectAppScreen(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const Key('registry_studio_screen_selector')));
  await tester.pumpAndSettle();

  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Widget _testApp(
  _FakeTranslatorPhraseProvider provider, {
  Future<List<ServiceIntakeSourceBlock>>? serviceIntakeSourceBlocks,
  Iterable<RegistryRelation>? relatedContextRelations,
}) {
  return RegistryStudioApp(
    serviceIntakeSourceBlocks: serviceIntakeSourceBlocks,
    translatePhrase: TranslatePhrase(provider: provider),
    createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
    transitionRegistryEngineeringOperationStatus:
        TransitionRegistryEngineeringOperationStatus(),
    relatedContextRelations:
        relatedContextRelations ?? const <RegistryRelation>[],
  );
}

ServiceIntakeSourceBlock _serviceIntakeSourceBlock() {
  return (
    identity: (
      entityId: RegistryEntityId('helpy.service_intake.plumbing.faucet'),
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
    ),
    startLine: 100,
    endLine: 110,
    sourceText:
        '### Plumbing → Кран\n'
        '1. Что требуется сделать?\n'
        '- Установить и подключить кран.\n',
  );
}

TranslatorPhraseResult _translatorResult() {
  return TranslatorPhraseResult(
    sourceLanguage: 'ru',
    sourceText: 'Проверить формулировку.',
    status: TranslatorPhraseStatus.equivalent,
    ru: 'Проверить формулировку.',
    en: 'Check wording.',
    th: 'ตรวจสอบถ้อยคำ',
    comment: 'Equivalent wording.',
  );
}

final class _FakeTranslatorPhraseProvider implements TranslatorPhraseProvider {
  _FakeTranslatorPhraseProvider(this.result);

  final TranslatorPhraseResult result;
  int callCount = 0;
  String? receivedSourceText;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
  }) async {
    callCount += 1;
    receivedSourceText = sourceText;
    return result;
  }
}
