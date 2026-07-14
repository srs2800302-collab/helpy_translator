import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/guard/domain/registry_studio_guard_record_payload.dart';
import 'package:helpy_translator/registry_studio/guard/presentation/screens/registry_studio_guard_record_screen.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_related_context_preparation_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/app/registry_studio_app.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

import '../../core/fixtures/registry_entity_fixture.dart';
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
    expect(
      find.byType(RegistryEngineeringOperationCreationScreen),
      findsNothing,
    );
    expect(find.byType(RegistryRelatedContextPreparationScreen), findsNothing);
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
      workspace.initialProblemStatement,
      contains('helpy.service_intake.plumbing.faucet'),
    );
    expect(
      workspace.initialProblemStatement,
      contains('Что требуется сделать?'),
    );
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
      expect(
        workspace.initialProblemStatement,
        contains(source.identity.heading),
      );
      expect(
        workspace.initialProblemStatement,
        contains(source.identity.entityId.value),
      );
      expect(
        workspace.initialProblemStatement,
        contains(target.identity.heading),
      );
      expect(
        workspace.initialProblemStatement,
        contains(target.identity.entityId.value),
      );
      expect(
        workspace.initialProblemStatement,
        contains('Установить и подключить кран.'),
      );
      expect(
        workspace.initialProblemStatement,
        contains('Заменить существующий кран.'),
      );
      expect(
        workspace.initialWorkingContent,
        contains('Полная рабочая версия цели:'),
      );
      expect(
        workspace.initialWorkingContent,
        contains('- ### Plumbing → Кран'),
      );
      expect(
        workspace.initialWorkingContent,
        contains('+ ### Plumbing → Замена крана'),
      );
      expect(workspace.initialWorkingContent, contains(affectedEntityId.value));

      await tester.enterText(
        find.byKey(const Key('registry_engineering_operation_id_field')),
        'service-intake-comparison-001',
      );

      final Finder createButton = find.byKey(
        const Key('registry_engineering_operation_create_button'),
      );

      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      final TextField workingContentEditor = tester.widget<TextField>(
        find.byKey(const Key('registry_operation_revision_content')),
      );

      expect(
        workingContentEditor.controller?.text,
        contains('Полная рабочая версия цели:'),
      );
      expect(
        workingContentEditor.controller?.text,
        contains('- - Установить и подключить кран.'),
      );
      expect(
        workingContentEditor.controller?.text,
        contains('+ - Заменить существующий кран.'),
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
      find.widgetWithText(OutlinedButton, 'Создание инженерной операции'),
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

  testWidgets('switches to operation workspace screen', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await _selectAppScreen(tester, 'Создание инженерной операции');

    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsOneWidget,
    );
    expect(
      find.byType(RegistryEngineeringOperationCreationScreen),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);
    expect(find.byType(RegistryRelatedContextPreparationScreen), findsNothing);
  });

  testWidgets('switches to related context preparation screen', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await _selectAppScreen(tester, 'Подготовка related context');

    expect(
      find.byType(RegistryRelatedContextPreparationScreen),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);
    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsNothing,
    );
  });

  testWidgets('passes prepared related context to operation workspace', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await _selectAppScreen(tester, 'Подготовка related context');

    await tester.tap(
      find.byKey(const Key('registry_related_context_prepare_button')),
    );
    await tester.pumpAndSettle();

    await _selectAppScreen(tester, 'Создание инженерной операции');

    final RegistryEngineeringOperationWorkspaceScreen workspace = tester
        .widget<RegistryEngineeringOperationWorkspaceScreen>(
          find.byType(RegistryEngineeringOperationWorkspaceScreen),
        );

    expect(workspace.revisionRelatedEntityIds?.toList(), <RegistryEntityId>[
      RegistryEntityId('related-001'),
    ]);

    expect(workspace.onWorkSessionCleared, isNotNull);

    workspace.onWorkSessionCleared!();
    await tester.pump();

    final RegistryEngineeringOperationWorkspaceScreen clearedWorkspace = tester
        .widget<RegistryEngineeringOperationWorkspaceScreen>(
          find.byType(RegistryEngineeringOperationWorkspaceScreen),
        );

    expect(clearedWorkspace.revisionRelatedEntityIds, isNull);
  });

  testWidgets('switches to Guard record screen', (WidgetTester tester) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await _selectAppScreen(tester, 'Guard record');

    expect(find.byType(RegistryStudioGuardRecordScreen), findsOneWidget);
    expect(
      find.byKey(RegistryStudioGuardRecordScreen.recordCardKey),
      findsOneWidget,
    );
    expect(
      find.text('Заголовок:\nOwnership-аудит Guard record'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Краткое описание:\n'
        'Guard-specific semantic content.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);
    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsNothing,
    );
    expect(find.byType(RegistryRelatedContextPreparationScreen), findsNothing);
  });

  testWidgets(
    'keeps Translator dependency wiring available after switching back',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(_translatorResult());

      await tester.pumpWidget(_testApp(provider));

      await _selectAppScreen(tester, 'Создание инженерной операции');

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
  testWidgets('starts operation creation from Translator candidate', (
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

    expect(requestButton, findsOneWidget);

    await tester.tap(requestButton);
    await tester.pumpAndSettle();

    expect(
      find.byType(RegistryEngineeringOperationWorkspaceScreen),
      findsOneWidget,
    );
    expect(
      find.byType(RegistryEngineeringOperationCreationScreen),
      findsOneWidget,
    );
    expect(find.byType(TranslatorPhraseScreen), findsNothing);

    final TextField problemStatement = tester.widget<TextField>(
      find.byKey(
        const Key('registry_engineering_operation_problem_statement_field'),
      ),
    );

    expect(problemStatement.controller?.text, contains(result.sourceText));
    expect(
      problemStatement.controller?.text,
      contains(result.candidateCanonicalPhrase!),
    );

    await tester.enterText(
      find.byKey(const Key('registry_engineering_operation_id_field')),
      'operation-from-translator',
    );
    await tester.tap(
      find.byKey(const Key('registry_engineering_operation_create_button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(RegistryEngineeringOperationCreationScreen),
      findsNothing,
    );

    await _selectAppScreen(tester, 'Адаптивный переводчик');

    await _selectAppScreen(tester, 'Создание инженерной операции');

    expect(
      find.byType(RegistryEngineeringOperationCreationScreen),
      findsOneWidget,
    );

    final TextField remountedProblemStatement = tester.widget<TextField>(
      find.byKey(
        const Key('registry_engineering_operation_problem_statement_field'),
      ),
    );

    expect(remountedProblemStatement.controller?.text, isEmpty);
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
  final RegistryEntity primary = registryEntityFixture(
    id: 'guard-record-primary',
  );
  final RegistryEntity related = registryEntityFixture(id: 'related-001');

  return RegistryStudioApp(
    serviceIntakeSourceBlocks: serviceIntakeSourceBlocks,
    translatePhrase: TranslatePhrase(provider: provider),
    createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
    transitionRegistryEngineeringOperationStatus:
        TransitionRegistryEngineeringOperationStatus(),
    guardRecordEntity: _guardRecordEntity(),
    relatedContextPrimary: primary,
    relatedContextRelations:
        relatedContextRelations ??
        <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: related.id,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
    availableRelatedEntities: <RegistryEntity>[related],
    prepareRegistryRelatedContext: PrepareRegistryRelatedContext(),
    prepareRegistryResolvedRelatedContext:
        PrepareRegistryResolvedRelatedContext(),
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

RegistryEntity _guardRecordEntity() {
  return RegistryEntity(
    id: RegistryEntityId('registry-studio-guard-record'),
    path: RegistryPath(const <String>[
      'registry_studio',
      'guard',
      'source_contract_foundation',
    ]),
    payload: RegistryStudioGuardRecordPayload(
      recordType: RegistryStudioGuardRecordType.ownershipAudit,
      heading: 'Ownership-аудит Guard record',
      summary: 'Guard-specific semantic content.',
    ),
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath:
            'docs/architecture/registry_studio/'
            'Registry_Studio_Clean_Rebuild_Guard_v1.md',
        sourceSnapshotFingerprint: 'fnv1a64:0123456789abcdef',
        headingPath: const <String>['Ownership-аудит Guard record'],
        startLine: 4459,
        endLine: 4588,
      ),
    ],
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
