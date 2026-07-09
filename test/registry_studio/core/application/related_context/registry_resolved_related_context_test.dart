import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_related_context.dart';
import 'package:helpy_translator/registry_studio/core/application/related_context/registry_resolved_related_context.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

import '../../fixtures/registry_entity_fixture.dart';

void main() {
  group('RegistryResolvedRelatedContext', () {
    test('derives missing related ids from base context', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntity firstRelated = registryEntityFixture(
        id: 'related-001',
      );
      final RegistryEntityId secondRelatedId = RegistryEntityId('related-002');

      final RegistryRelatedContext base = RegistryRelatedContext(
        primary: primary,
        matchedRelations: <RegistryRelation>[
          RegistryRelation(
            sourceEntityId: primary.id,
            targetEntityId: firstRelated.id,
            meaning: RegistryRelationMeaning('depends_on'),
          ),
          RegistryRelation(
            sourceEntityId: secondRelatedId,
            targetEntityId: primary.id,
            meaning: RegistryRelationMeaning('supports'),
          ),
        ],
      );

      final RegistryResolvedRelatedContext context =
          RegistryResolvedRelatedContext(
            base: base,
            resolvedRelatedEntities: <RegistryEntity>[firstRelated],
          );

      expect(context.base, base);
      expect(context.resolvedRelatedEntities, <RegistryEntity>[firstRelated]);
      expect(context.missingRelatedEntityIds, <RegistryEntityId>[
        secondRelatedId,
      ]);
    });

    test('rejects resolved entity that is not present in base related ids', () {
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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[outside],
        ),
        throwsArgumentError,
      );
    });

    test('rejects primary entity as resolved related entity', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntity related = registryEntityFixture(id: 'related-001');

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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[primary],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate resolved related entity ids', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntity related = registryEntityFixture(id: 'related-001');

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
        () => RegistryResolvedRelatedContext(
          base: base,
          resolvedRelatedEntities: <RegistryEntity>[related, related],
        ),
        throwsArgumentError,
      );
    });

    test('keeps result collections immutable', () {
      final RegistryEntity primary = registryEntityFixture(id: 'primary');
      final RegistryEntity related = registryEntityFixture(id: 'related-001');

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

      final RegistryResolvedRelatedContext context =
          RegistryResolvedRelatedContext(
            base: base,
            resolvedRelatedEntities: <RegistryEntity>[related],
          );

      expect(
        () => context.resolvedRelatedEntities.add(
          registryEntityFixture(id: 'related-002'),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => context.missingRelatedEntityIds.add(
          RegistryEntityId('related-002'),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
