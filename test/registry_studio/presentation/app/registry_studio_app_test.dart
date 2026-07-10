import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_creation/create_registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_creation_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_workspace_screen.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_related_context_preparation_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/app/registry_studio_app.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

import '../../core/fixtures/registry_entity_fixture.dart';

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
    expect(find.text('Перевод формулировки'), findsWidgets);
  });

  testWidgets('switches top-level labels between RU EN and TH', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Перевод формулировки'), findsWidgets);
    expect(find.text('Создание инженерной операции'), findsOneWidget);

    await tester.tap(find.text('RU'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EN').last);
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Phrase translation'), findsWidgets);
    expect(find.text('Create engineering operation'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('TH').last);
    await tester.pumpAndSettle();

    expect(find.text('ภาษา'), findsOneWidget);
    expect(find.text('แปลถ้อยคำ'), findsWidgets);
    expect(find.text('สร้างงานวิศวกรรม'), findsOneWidget);
  });

  testWidgets('switches to operation workspace screen', (
    WidgetTester tester,
  ) async {
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(_translatorResult());

    await tester.pumpWidget(_testApp(provider));

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Создание инженерной операции'),
    );
    await tester.pump();

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

    await tester.tap(
      find.byKey(const Key('registry_studio_related_context_screen_button')),
    );
    await tester.pump();

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

  testWidgets(
    'keeps Translator dependency wiring available after switching back',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final _FakeTranslatorPhraseProvider provider =
          _FakeTranslatorPhraseProvider(_translatorResult());

      await tester.pumpWidget(_testApp(provider));

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Создание инженерной операции'),
      );
      await tester.pump();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Перевод формулировки'),
      );
      await tester.pump();

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
}

Widget _testApp(_FakeTranslatorPhraseProvider provider) {
  final RegistryEntity primary = registryEntityFixture(
    id: 'guard-record-primary',
  );

  return RegistryStudioApp(
    translatePhrase: TranslatePhrase(provider: provider),
    createRegistryEngineeringOperation: CreateRegistryEngineeringOperation(),
    transitionRegistryEngineeringOperationStatus:
        TransitionRegistryEngineeringOperationStatus(),
    relatedContextPrimary: primary,
    relatedContextRelations: const <RegistryRelation>[],
    availableRelatedEntities: const <RegistryEntity>[],
    prepareRegistryRelatedContext: PrepareRegistryRelatedContext(),
    prepareRegistryResolvedRelatedContext:
        PrepareRegistryResolvedRelatedContext(),
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
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    callCount += 1;
    receivedSourceText = sourceText;
    return result;
  }
}
