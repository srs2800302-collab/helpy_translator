import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/source_indexing/registry_document_node.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';
import 'package:helpy_translator/registry_studio/presentation/screens/registry_document_explorer_screen.dart';

void main() {
  testWidgets('shows complete read-only Registry hierarchy and source text', (
    WidgetTester tester,
  ) async {
    final RegistryDocumentNode child = RegistryDocumentNode(
      title: 'Child',
      headingLevel: 2,
      headingPath: const <String>['Registry', 'Child'],
      startLine: 2,
      endLine: 3,
      sourceText: '## Child\nChild source\n',
      children: const <RegistryDocumentNode>[],
    );

    final RegistryDocumentNode root = RegistryDocumentNode(
      title: 'Registry',
      headingLevel: 1,
      headingPath: const <String>['Registry'],
      startLine: 1,
      endLine: 3,
      sourceText: '# Registry\n## Child\nChild source\n',
      children: <RegistryDocumentNode>[child],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RegistryDocumentExplorerScreen(
          uiLanguage: RegistryStudioUiLanguage.ru,
          nodes: Future<List<RegistryDocumentNode>>.value(
            <RegistryDocumentNode>[root],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Корневых разделов: 1'), findsOneWidget);
    expect(find.text('Registry'), findsOneWidget);
    expect(find.textContaining('Уровень: H1'), findsOneWidget);
    expect(find.textContaining('Путь: Registry'), findsOneWidget);
    expect(find.textContaining('Строки: 1–3'), findsOneWidget);
    expect(find.text('Child'), findsNothing);

    await tester.tap(find.text('Registry'));
    await tester.pumpAndSettle();

    expect(find.text('Child'), findsOneWidget);
    expect(find.textContaining('Путь: Registry / Child'), findsOneWidget);

    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Child source'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('shows loading and error states', (WidgetTester tester) async {
    final Completer<List<RegistryDocumentNode>> completer =
        Completer<List<RegistryDocumentNode>>();

    await tester.pumpWidget(
      MaterialApp(
        home: RegistryDocumentExplorerScreen(
          uiLanguage: RegistryStudioUiLanguage.en,
          nodes: completer.future,
        ),
      ),
    );

    expect(
      find.byKey(RegistryDocumentExplorerScreen.loadingKey),
      findsOneWidget,
    );

    completer.completeError(StateError('failed'));
    await tester.pumpAndSettle();

    expect(find.byKey(RegistryDocumentExplorerScreen.errorKey), findsOneWidget);
    expect(
      find.textContaining('Failed to load the complete Registry'),
      findsOneWidget,
    );
  });
}
