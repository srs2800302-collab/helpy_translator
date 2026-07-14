import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/presentation/screens/service_intake_source_blocks_screen.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  testWidgets(
    'selects distinct source and target entities by stable identity',
    (WidgetTester tester) async {
      await _useLargeSurface(tester);
      await _pumpScreen(tester, <ServiceIntakeSourceBlock>[
        _sourceBlock(entityId: _sourceId, heading: _sourceHeading),
        _sourceBlock(entityId: _targetId, heading: _targetHeading),
      ]);

      expect(
        find.byKey(ServiceIntakeSourceBlocksScreen.comparisonSelectionKey),
        findsNothing,
      );

      await _openBlock(tester, _sourceHeading);

      expect(find.text('Источник: не выбрано'), findsOneWidget);
      expect(find.text('Цель: не выбрано'), findsOneWidget);

      final Finder sourceButton = _sourceButton(_sourceId);

      expect(sourceButton, findsOneWidget);
      await tester.tap(sourceButton);
      await tester.pumpAndSettle();

      expect(find.text('Источник: $_sourceHeading'), findsOneWidget);
      expect(find.text('Цель: не выбрано'), findsOneWidget);

      await tester.enterText(
        find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
        'цель',
      );
      await tester.pumpAndSettle();

      expect(find.text('Источник: $_sourceHeading'), findsNothing);
      expect(find.text(_sourceHeading), findsNothing);
      expect(find.text(_targetHeading), findsOneWidget);

      await _openBlock(tester, _targetHeading);

      expect(find.text('Источник: $_sourceHeading'), findsOneWidget);
      expect(find.text('Цель: не выбрано'), findsOneWidget);

      final Finder targetButton = _targetButton(_targetId);

      expect(targetButton, findsOneWidget);
      await tester.tap(targetButton);
      await tester.pumpAndSettle();

      expect(find.text('Источник: $_sourceHeading'), findsOneWidget);
      expect(find.text('Цель: $_targetHeading'), findsOneWidget);
    },
  );

  testWidgets('moves one entity from source role to target role', (
    WidgetTester tester,
  ) async {
    await _useLargeSurface(tester);
    await _pumpScreen(tester, <ServiceIntakeSourceBlock>[
      _sourceBlock(entityId: _sourceId, heading: _sourceHeading),
    ]);

    await _openBlock(tester, _sourceHeading);

    final Finder sourceButton = _sourceButton(_sourceId);

    expect(sourceButton, findsOneWidget);
    await tester.tap(sourceButton);
    await tester.pumpAndSettle();

    expect(find.text('Источник: $_sourceHeading'), findsOneWidget);
    expect(find.text('Цель: не выбрано'), findsOneWidget);

    final Finder targetButton = _targetButton(_sourceId);

    expect(targetButton, findsOneWidget);
    await tester.tap(targetButton);
    await tester.pumpAndSettle();

    expect(find.text('Источник: не выбрано'), findsOneWidget);
    expect(find.text('Цель: $_sourceHeading'), findsOneWidget);
  });

  testWidgets('requests comparison for selected source and target', (
    WidgetTester tester,
  ) async {
    await _useLargeSurface(tester);

    ServiceIntakeSourceBlock? requestedSource;
    ServiceIntakeSourceBlock? requestedTarget;

    await _pumpScreen(
      tester,
      <ServiceIntakeSourceBlock>[
        _sourceBlock(entityId: _sourceId, heading: _sourceHeading),
        _sourceBlock(entityId: _targetId, heading: _targetHeading),
      ],
      onComparisonRequested:
          (ServiceIntakeSourceBlock source, ServiceIntakeSourceBlock target) {
            requestedSource = source;
            requestedTarget = target;
          },
    );

    await _openBlock(tester, _sourceHeading);

    final Finder sourceComparisonButton = _comparisonButton(_sourceId);

    expect(sourceComparisonButton, findsOneWidget);
    expect(
      tester.widget<FilledButton>(sourceComparisonButton).onPressed,
      isNull,
    );

    await tester.tap(_sourceButton(_sourceId));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(ServiceIntakeSourceBlocksScreen.searchKey),
      'цель',
    );
    await tester.pumpAndSettle();

    await _openBlock(tester, _targetHeading);

    final Finder targetComparisonButton = _comparisonButton(_targetId);

    expect(targetComparisonButton, findsOneWidget);
    expect(
      tester.widget<FilledButton>(targetComparisonButton).onPressed,
      isNull,
    );

    await tester.tap(_targetButton(_targetId));
    await tester.pumpAndSettle();

    final Finder comparisonButton = find.byKey(
      ServiceIntakeSourceBlocksScreen.comparisonActionKey,
    );

    expect(comparisonButton, findsOneWidget);
    expect(tester.widget<FilledButton>(comparisonButton).onPressed, isNotNull);

    await tester.ensureVisible(comparisonButton);
    await tester.tap(comparisonButton);
    await tester.pumpAndSettle();

    expect(requestedSource?.identity.entityId, RegistryEntityId(_sourceId));
    expect(requestedTarget?.identity.entityId, RegistryEntityId(_targetId));
  });
}

Future<void> _useLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1600));

  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<ServiceIntakeSourceBlock> blocks, {
  void Function(
    ServiceIntakeSourceBlock source,
    ServiceIntakeSourceBlock target,
  )?
  onComparisonRequested,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ServiceIntakeSourceBlocksScreen(
        uiLanguage: RegistryStudioUiLanguage.ru,
        sourceBlocks: Future<List<ServiceIntakeSourceBlock>>.value(blocks),
        onComparisonRequested: onComparisonRequested,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _openBlock(WidgetTester tester, String heading) async {
  final Finder headingFinder = find.text(heading);

  expect(headingFinder, findsOneWidget);
  await tester.ensureVisible(headingFinder);
  await tester.tap(headingFinder);
  await tester.pumpAndSettle();
}

Finder _sourceButton(String entityId) {
  return find.byKey(
    ValueKey<String>('service_intake_compare_source_$entityId'),
  );
}

Finder _targetButton(String entityId) {
  return find.byKey(
    ValueKey<String>('service_intake_compare_target_$entityId'),
  );
}

Finder _comparisonButton(String entityId) {
  return find.byKey(
    ValueKey<String>('service_intake_source_comparison_action_$entityId'),
  );
}

ServiceIntakeSourceBlock _sourceBlock({
  required String entityId,
  required String heading,
}) {
  return (
    identity: _identity(entityId: entityId, heading: heading),
    startLine: 100,
    endLine: 110,
    sourceText:
        '### $heading\n'
        '1. Тестовая строка.\n',
  );
}

ServiceIntakeIdentityManifestEntry _identity({
  required String entityId,
  required String heading,
}) {
  return (
    entityId: RegistryEntityId(entityId),
    path: RegistryPath(<String>[
      'helpy',
      'service_intake',
      entityId == _sourceId ? 'source' : 'target',
    ]),
    ownerHeadingLevel: 2,
    ownerHeading: 'Plumbing',
    headingLevel: 3,
    heading: heading,
  );
}

const String _sourceId = 'helpy.service_intake.plumbing.source';
const String _targetId = 'helpy.service_intake.plumbing.target';

const String _sourceHeading = 'Plumbing → Источник';
const String _targetHeading = 'Plumbing → Цель';
