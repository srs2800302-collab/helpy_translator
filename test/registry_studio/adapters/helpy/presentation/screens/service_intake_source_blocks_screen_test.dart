import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/presentation/screens/service_intake_source_blocks_screen.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  testWidgets('shows extracted service intake source block', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceIntakeSourceBlocksScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          sourceBlocks: Future<List<ServiceIntakeSourceBlock>>.value(
            <ServiceIntakeSourceBlock>[_sourceBlock()],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Источник service intake'), findsOneWidget);
    expect(find.text('Загружено записей: 1'), findsOneWidget);
    expect(find.text('Plumbing → Кран'), findsOneWidget);
    expect(
      find.textContaining('helpy.service_intake.plumbing.faucet'),
      findsOneWidget,
    );
    expect(find.textContaining('Строки: 100–110'), findsOneWidget);

    await tester.tap(find.text('Plumbing → Кран'));
    await tester.pumpAndSettle();

    final SelectableText sourceText = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );

    expect(sourceText.data, contains('Что требуется сделать?'));
  });
  testWidgets('filters service intake source and clears search', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ServiceIntakeSourceBlocksScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          sourceBlocks: Future<List<ServiceIntakeSourceBlock>>.value(
            <ServiceIntakeSourceBlock>[_sourceBlock()],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final TextField searchField = tester.widget<TextField>(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
    );

    expect(searchField.decoration?.labelText, 'Поиск по источнику');
    expect(searchField.decoration?.hintText, 'Заголовок, ID, путь или текст');
    expect(searchField.decoration?.border, isA<OutlineInputBorder>());
    expect(find.byIcon(Icons.search), findsOneWidget);

    await tester.enterText(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
      'кран',
    );
    await tester.pump();

    final Text matchedHeading = tester.widget<Text>(
      find.text('Plumbing → Кран'),
    );
    expect(matchedHeading.style?.fontWeight, FontWeight.w700);

    await tester.enterText(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
      'faucet',
    );
    await tester.pump();

    final Text matchedMetadata = tester.widget<Text>(
      find.textContaining('helpy.service_intake.plumbing.faucet'),
    );
    expect(matchedMetadata.style?.fontWeight, FontWeight.w700);

    await tester.enterText(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
      'установить и подключить кран',
    );
    await tester.pump();

    expect(find.text('Plumbing → Кран'), findsOneWidget);
    expect(
      find.byKey(ServiceIntakeSourceBlocksScreen.clearSearchKey),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
      'электрическая розетка',
    );
    await tester.pump();

    expect(find.text('Plumbing → Кран'), findsNothing);
    expect(find.text('Совпадения не найдены'), findsOneWidget);

    await tester.tap(
      find.byKey(ServiceIntakeSourceBlocksScreen.clearSearchKey),
    );
    await tester.pump();

    expect(find.text('Plumbing → Кран'), findsOneWidget);
    expect(find.text('Совпадения не найдены'), findsNothing);
    expect(
      find.byKey(ServiceIntakeSourceBlocksScreen.clearSearchKey),
      findsNothing,
    );
  });
}

ServiceIntakeSourceBlock _sourceBlock() {
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
