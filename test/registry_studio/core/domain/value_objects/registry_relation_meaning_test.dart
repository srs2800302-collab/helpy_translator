import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation_meaning.dart';

void main() {
  group('RegistryRelationMeaning', () {
    test('normalizes and preserves semantic relation meaning', () {
      final RegistryRelationMeaning meaning = RegistryRelationMeaning(
        ' depends_on ',
      );

      expect(meaning.value, 'depends_on');
    });

    test('rejects empty and whitespace-only values', () {
      expect(() => RegistryRelationMeaning(''), throwsArgumentError);
      expect(() => RegistryRelationMeaning('   '), throwsArgumentError);
    });

    test('uses the normalized open value for equality', () {
      final RegistryRelationMeaning first = RegistryRelationMeaning(
        ' depends_on ',
      );
      final RegistryRelationMeaning second = RegistryRelationMeaning(
        'depends_on',
      );
      final RegistryRelationMeaning different = RegistryRelationMeaning(
        'supports',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });
  });
}
