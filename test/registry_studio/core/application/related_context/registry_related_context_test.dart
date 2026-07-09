import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

import '../../fixtures/registry_entity_fixture.dart';

void main() {
  group('RegistryRelatedContext', () {
    test('derives related entity ids from matched relations', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntityId firstRelatedId = RegistryEntityId('related-001');
      final RegistryEntityId secondRelatedId = RegistryEntityId('related-002');

      final RegistryRelatedContext context = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: firstRelatedId,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: secondRelatedId,
            targetEntityId: primary.id,
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      expect(context.primary, primary);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        firstRelatedId,
        secondRelatedId,
      ]);
      expect(context.matchedRelations.length, 2);
    });

    test('rejects matched relation that does not include primary entity', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');

      expect(
        () => RegistryRelatedContext(
          primary: primary,
          matchedRelations: <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: RegistryEntityId('other-source'),
              targetEntityId: RegistryEntityId('other-target'),
              meaning: RegistryRelationMeaning('depends_on'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('keeps result collections immutable', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');

      final RegistryRelatedContext context = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: RegistryEntityId('related-001'),
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
      );

      expect(
        () => context.matchedRelations.add(
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: RegistryEntityId('related-002'),
            meaning: RegistryRelationMeaning('supports'),
          ),
        ),
        throwsUnsupportedError,
      );

      expect(
        () => context.relatedEntityIds.add(RegistryEntityId('related-002')),
        throwsUnsupportedError,
      );
    });
  });
}
