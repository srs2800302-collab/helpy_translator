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
        home: Scaffold(
          body: RegistryDocumentExplorerScreen(
            uiLanguage: RegistryStudioUiLanguage.ru,
            sourceRevision: Future<String>.value(_sourceRevision),
            nodes: Future<List<RegistryDocumentNode>>.value(
              <RegistryDocumentNode>[root],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Корневых разделов: 1'), findsOneWidget);
    expect(find.text('Registry'), findsOneWidget);
    expect(find.text('Исходная ревизия: $_sourceRevision'), findsOneWidget);
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
    expect(
      find.widgetWithText(SelectableText, '## Child\nChild source\n'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('searches all nodes without matching ancestor descendant text', (
    WidgetTester tester,
  ) async {
    final RegistryDocumentNode target = RegistryDocumentNode(
      title: 'Canonical target',
      headingLevel: 3,
      headingPath: const <String>[
        'Registry',
        'Hidden domain',
        'Canonical target',
      ],
      startLine: 3,
      endLine: 4,
      sourceText:
          '### Canonical target\n'
          'Unique searchable wording\n',
      children: const <RegistryDocumentNode>[],
    );

    final RegistryDocumentNode domain = RegistryDocumentNode(
      title: 'Hidden domain',
      headingLevel: 2,
      headingPath: const <String>['Registry', 'Hidden domain'],
      startLine: 2,
      endLine: 4,
      sourceText:
          '## Hidden domain\n'
          '### Canonical target\n'
          'Unique searchable wording\n',
      children: <RegistryDocumentNode>[target],
    );

    final RegistryDocumentNode root = RegistryDocumentNode(
      title: 'Registry',
      headingLevel: 1,
      headingPath: const <String>['Registry'],
      startLine: 1,
      endLine: 4,
      sourceText:
          '# Registry\n'
          '## Hidden domain\n'
          '### Canonical target\n'
          'Unique searchable wording\n',
      children: <RegistryDocumentNode>[domain],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegistryDocumentExplorerScreen(
            uiLanguage: RegistryStudioUiLanguage.ru,
            sourceRevision: Future<String>.value(_sourceRevision),
            nodes: Future<List<RegistryDocumentNode>>.value(
              <RegistryDocumentNode>[root],
            ),
            nodeSearchTextBuilder: (RegistryDocumentNode node) {
              if (node != target) {
                return null;
              }

              return 'overlay.identity.target\n'
                  'helpy / service_intake / plumbing / faucet';
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    Finder searchField() =>
        find.byKey(RegistryDocumentExplorerScreen.searchKey);

    expect(searchField(), findsOneWidget);
    expect(find.text('Canonical target'), findsNothing);

    await tester.enterText(searchField(), 'unique SEARCHABLE wording');
    await tester.pump();

    expect(find.text('Показано: 1 из 3'), findsOneWidget);
    expect(find.text('Canonical target'), findsOneWidget);
    expect(find.text('Registry'), findsNothing);
    expect(find.text('Hidden domain'), findsNothing);
    expect(
      find.textContaining('Путь: Registry / Hidden domain / Canonical target'),
      findsOneWidget,
    );
    expect(find.textContaining('Строки: 3–4'), findsOneWidget);

    await tester.enterText(searchField(), 'hidden domain');
    await tester.pump();

    expect(find.text('Показано: 2 из 3'), findsOneWidget);
    expect(find.text('Hidden domain'), findsOneWidget);
    expect(find.text('Canonical target'), findsOneWidget);

    await tester.enterText(searchField(), 'overlay.identity.target');
    await tester.pump();

    expect(find.text('Показано: 1 из 3'), findsOneWidget);
    expect(find.text('Canonical target'), findsOneWidget);
    expect(find.text('Registry'), findsNothing);
    expect(find.text('Hidden domain'), findsNothing);

    await tester.enterText(
      searchField(),
      'helpy / service_intake / plumbing / faucet',
    );
    await tester.pump();

    expect(find.text('Показано: 1 из 3'), findsOneWidget);
    expect(find.text('Canonical target'), findsOneWidget);

    await tester.enterText(searchField(), 'missing section');
    await tester.pump();

    expect(find.text('Показано: 0 из 3'), findsOneWidget);
    expect(find.text('Совпадения не найдены'), findsOneWidget);

    await tester.tap(find.byKey(RegistryDocumentExplorerScreen.clearSearchKey));
    await tester.pump();

    expect(find.text('Корневых разделов: 1'), findsOneWidget);
    expect(find.text('Registry'), findsOneWidget);
    expect(find.text('Canonical target'), findsNothing);
    expect(find.text('Совпадения не найдены'), findsNothing);
  });

  testWidgets('shows loading and error states', (WidgetTester tester) async {
    final Completer<List<RegistryDocumentNode>> completer =
        Completer<List<RegistryDocumentNode>>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegistryDocumentExplorerScreen(
            uiLanguage: RegistryStudioUiLanguage.en,
            sourceRevision: Future<String>.value(_sourceRevision),
            nodes: completer.future,
          ),
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

const String _sourceRevision = '0123456789abcdef0123456789abcdef01234567';
