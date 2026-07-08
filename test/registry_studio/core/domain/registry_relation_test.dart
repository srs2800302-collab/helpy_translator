import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

void main() {
  group('RegistryRelationMeaning', () {
    test('normalizes and preserves semantic relation meaning', () {
      final RegistryRelationMeaning meaning = RegistryRelationMeaning(
        ' depends_on ',
      );

      expect(meaning.value, 'depends_on');
    });

    test('rejects empty relation meaning', () {
      expect(() => RegistryRelationMeaning(''), throwsArgumentError);
      expect(() => RegistryRelationMeaning('   '), throwsArgumentError);
    });
  });

  group('RegistryRelation', () {
    test(
      'creates an atomic directional relation between registry entities',
      () {
        final RegistryEntityId sourceEntityId = RegistryEntityId(
          'registry-entity-source',
        );
        final RegistryEntityId targetEntityId = RegistryEntityId(
          'registry-entity-target',
        );
        final RegistryRelationMeaning meaning = RegistryRelationMeaning(
          'depends_on',
        );

        final RegistryRelation relation = RegistryRelation(
          sourceEntityId: sourceEntityId,
          targetEntityId: targetEntityId,
          meaning: meaning,
        );

        expect(relation.sourceEntityId, sourceEntityId);
        expect(relation.targetEntityId, targetEntityId);
        expect(relation.meaning, meaning);
        expect(
          relation,
          RegistryRelation(
            sourceEntityId: sourceEntityId,
            targetEntityId: targetEntityId,
            meaning: meaning,
          ),
        );
      },
    );

    test('preserves relation direction as part of equality', () {
      final RegistryEntityId firstEntityId = RegistryEntityId(
        'registry-entity-first',
      );
      final RegistryEntityId secondEntityId = RegistryEntityId(
        'registry-entity-second',
      );
      final RegistryRelationMeaning meaning = RegistryRelationMeaning(
        'depends_on',
      );

      final RegistryRelation forward = RegistryRelation(
        sourceEntityId: firstEntityId,
        targetEntityId: secondEntityId,
        meaning: meaning,
      );
      final RegistryRelation reverse = RegistryRelation(
        sourceEntityId: secondEntityId,
        targetEntityId: firstEntityId,
        meaning: meaning,
      );

      expect(forward, isNot(reverse));
    });

    test('rejects self relation', () {
      final RegistryEntityId entityId = RegistryEntityId('registry-entity-001');

      expect(
        () => RegistryRelation(
          sourceEntityId: entityId,
          targetEntityId: entityId,
          meaning: RegistryRelationMeaning('depends_on'),
        ),
        throwsArgumentError,
      );
    });
  });
}
