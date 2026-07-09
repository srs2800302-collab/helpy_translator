import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/prepare_registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

import '../../fixtures/registry_entity_fixture.dart';

void main() {
  group('PrepareRegistryResolvedRelatedContext', () {
    test(
      'returns resolved context from already available related entities',
      () {
        final RegistryEntity primary = registryEntityFixture(id: 'primary');
        final RegistryEntity related = registryEntityFixture(id: 'related-001');
        final RegistryEntityId missingRelatedId = RegistryEntityId(
          'related-002',
        );

        final RegistryRelatedContext base = RegistryRelatedContext(
          primary: primary,
          matchedRelations: <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: primary.id,
              targetEntityId: related.id,
              meaning: RegistryRelationMeaning('depends_on'),
            ),
            RegistryRelation(
              sourceEntityId: missingRelatedId,
              targetEntityId: primary.id,
              meaning: RegistryRelationMeaning('supports'),
            ),
          ],
        );

        final RegistryResolvedRelatedContext context =
            PrepareRegistryResolvedRelatedContext()(
              base: base,
              availableRelatedEntities: <RegistryEntity>[related],
            );

        expect(context.base, base);
        expect(context.resolvedRelatedEntities, <RegistryEntity>[related]);
        expect(context.missingRelatedEntityIds, <RegistryEntityId>[
          missingRelatedId,
        ]);
      },
    );

    test(
      'does not silently accept available entity outside base related ids',
      () {
        final RegistryEntity primary = registryEntityFixture(id: 'primary');
        final RegistryEntity related = registryEntityFixture(id: 'related-001');
        final RegistryEntity outside = registryEntityFixture(id: 'outside');

        final RegistryRelatedContext base = RegistryRelatedContext(
          primary: primary,
          matchedRelations: <RegistryRelation>[
            RegistryRelation(
              sourceEntityId: primary.id,
              targetEntityId: related.id,
              meaning: RegistryRelationMeaning('depends_on'),
            ),
          ],
        );

        expect(
          () => PrepareRegistryResolvedRelatedContext()(
            base: base,
            availableRelatedEntities: <RegistryEntity>[outside],
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
