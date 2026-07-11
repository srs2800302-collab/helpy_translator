import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_related_context_preparation_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

import '../../../core/fixtures/registry_entity_fixture.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_resolved_related_context.dart';

void main() {
  group('RegistryRelatedContextPreparationScreen', () {
    testWidgets('renders isolated related context preparation screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(find.text('Подготовка related context'), findsOneWidget);
      expect(find.text('Primary entity'), findsOneWidget);
      expect(find.text('Primary entity ID:\nprimary'), findsOneWidget);
      expect(find.text('Path:\nsample_scope / primary'), findsOneWidget);
      expect(find.text('Kind:\nsample.entity'), findsOneWidget);
      expect(find.text('Подготовить context'), findsOneWidget);
    });

    testWidgets(
      'prepares related and resolved context through existing use cases',
      (WidgetTester tester) async {
        RegistryResolvedRelatedContext? preparedContext;

        await tester.pumpWidget(
          _testApp(
            onContextPrepared: (RegistryResolvedRelatedContext context) {
              preparedContext = context;
            },
          ),
        );

        await tester.tap(
          find.byKey(const Key('registry_related_context_prepare_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Related context подготовлен'), findsOneWidget);
        expect(
          find.text(
            'Matched relations:\n'
            'primary -> related-001 [depends_on]\n'
            'related-002 -> primary [supports]',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Related entity ids:\nrelated-001\nrelated-002'),
          findsOneWidget,
        );
        expect(
          find.text('Resolved related context подготовлен'),
          findsOneWidget,
        );
        expect(
          find.text('Resolved related entities:\nrelated-001'),
          findsOneWidget,
        );
        expect(
          find.text('Missing related entity ids:\nrelated-002'),
          findsOneWidget,
        );
        expect(preparedContext, isNotNull);
        expect(
          preparedContext!.resolvedRelatedEntities.single.id,
          RegistryEntityId('related-001'),
        );
        expect(preparedContext!.missingRelatedEntityIds, <RegistryEntityId>[
          RegistryEntityId('related-002'),
        ]);
        expect(find.textContaining('Ошибка подготовки context'), findsNothing);
      },
    );

    testWidgets('shows presentation error for invalid resolved entity input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(
          availableRelatedEntities: <RegistryEntity>[
            registryEntityFixture(id: 'outside'),
          ],
        ),
      );

      await tester.tap(
        find.byKey(const Key('registry_related_context_prepare_button')),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ошибка подготовки context'), findsOneWidget);
      expect(
        find.textContaining(
          'Resolved related entity id must be present in base related entity ids.',
        ),
        findsOneWidget,
      );
      expect(find.text('Related context подготовлен'), findsNothing);
      expect(find.text('Resolved related context подготовлен'), findsNothing);
    });

    testWidgets('renders related context preparation labels in TH', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(uiLanguage: RegistryStudioUiLanguage.th),
      );

      expect(find.text('เตรียม related context'), findsOneWidget);
      expect(find.text('เตรียม context'), findsOneWidget);
      expect(find.text('รหัส primary entity:\nprimary'), findsOneWidget);
    });
  });
}

Widget _testApp({
  RegistryStudioUiLanguage uiLanguage = RegistryStudioUiLanguage.ru,
  Iterable<RegistryRelation>? relations,
  Iterable<RegistryEntity>? availableRelatedEntities,
  ValueChanged<RegistryResolvedRelatedContext>? onContextPrepared,
}) {
  final RegistryEntity primary = registryEntityFixture(id: 'primary');
  final RegistryEntity related = registryEntityFixture(id: 'related-001');

  return MaterialApp(
    home: RegistryRelatedContextPreparationScreen(
      uiLanguage: uiLanguage,
      primary: primary,
      relations:
          relations ??
          <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: primary.id,
              targetEntityId: related.id,
              meaning: RegistryRelationMeaning('depends_on'),
            ),
            RegistryRelation(
              sourceEntityId: RegistryEntityId('related-002'),
              targetEntityId: primary.id,
              meaning: RegistryRelationMeaning('supports'),
            ),
          ],
      availableRelatedEntities:
          availableRelatedEntities ?? <RegistryEntity>[related],
      prepareRegistryRelatedContext: PrepareRegistryRelatedContext(),
      prepareRegistryResolvedRelatedContext:
          PrepareRegistryResolvedRelatedContext(),
      onContextPrepared: onContextPrepared,
    ),
  );
}
