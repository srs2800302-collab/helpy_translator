import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

import '../../fixtures/registry_entity_fixture.dart';

void main() {
  group('PrepareRegistryRelatedContext', () {
    test('returns context for relations that include primary entity', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntityId firstRelatedId = RegistryEntityId('related-001');
      final RegistryEntityId secondRelatedId = RegistryEntityId('related-002');

      final RegistryRelatedContext context = PrepareRegistryRelatedContext()(
        primary: primary,
        relations: <RegistryRelation>[
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
      expect(context.matchedRelations.length, 2);
      expect(context.relatedEntityIds, <RegistryEntityId>[
        firstRelatedId,
        secondRelatedId,
      ]);
    });

    test('ignores relations that do not include primary entity', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntityId relatedId = RegistryEntityId('related-001');

      final RegistryRelatedContext context = PrepareRegistryRelatedContext()(
        primary: primary,
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: relatedId,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: RegistryEntityId('other-source'),
            targetEntityId: RegistryEntityId('other-target'),
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      expect(context.matchedRelations.length, 1);
      expect(context.relatedEntityIds, <RegistryEntityId>[relatedId]);
    });

    test('returns empty context when no relation includes primary entity', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');

      final RegistryRelatedContext context = PrepareRegistryRelatedContext()(
        primary: primary,
        relations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: RegistryEntityId('other-source'),
            targetEntityId: RegistryEntityId('other-target'),
            meaning: RegistryRelationMeaning('depends_on'),
          ),
        ],
      );

      expect(context.primary, primary);
      expect(context.matchedRelations, isEmpty);
      expect(context.relatedEntityIds, isEmpty);
    });
  });
}
