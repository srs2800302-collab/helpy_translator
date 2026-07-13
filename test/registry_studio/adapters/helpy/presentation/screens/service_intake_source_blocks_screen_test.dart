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
