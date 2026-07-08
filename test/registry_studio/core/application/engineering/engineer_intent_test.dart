import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineer_intent.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('EngineerIntent', () {
    test('normalizes objective, scope and constraints', () {
      final EngineerIntent intent = EngineerIntent(
        objective: ' Review intake entity ',
        targetEntityId: RegistryEntityId(' registry-entity-001 '),
        scope: <String>[' scenario ', ' photo questions '],
        constraints: <String>[' read-only ', ' no publication '],
      );

      expect(intent.objective, 'Review intake entity');
      expect(intent.targetEntityId, RegistryEntityId('registry-entity-001'));
      expect(intent.targetPath, isNull);
      expect(intent.hasTarget, isTrue);
      expect(intent.scope, <String>['scenario', 'photo questions']);
      expect(intent.constraints, <String>['read-only', 'no publication']);
    });

    test('allows path target instead of entity identity', () {
      final EngineerIntent intent = EngineerIntent(
        objective: 'Review path',
        targetPath: RegistryPath(<String>[' helpy ', ' plumbing ', ' faucet ']),
      );

      expect(intent.targetEntityId, isNull);
      expect(
        intent.targetPath,
        RegistryPath(<String>['helpy', 'plumbing', 'faucet']),
      );
      expect(intent.hasTarget, isTrue);
    });

    test('allows target-free intent for global engineering tasks', () {
      final EngineerIntent intent = EngineerIntent(
        objective: 'Review registry runtime contracts',
      );

      expect(intent.targetEntityId, isNull);
      expect(intent.targetPath, isNull);
      expect(intent.hasTarget, isFalse);
      expect(intent.scope, isEmpty);
      expect(intent.constraints, isEmpty);
    });

    test('keeps scope and constraints immutable', () {
      final EngineerIntent intent = EngineerIntent(
        objective: 'Review intake entity',
        scope: <String>['scenario'],
        constraints: <String>['read-only'],
      );

      expect(() => intent.scope.add('questions'), throwsUnsupportedError);
      expect(
        () => intent.constraints.add('no publish'),
        throwsUnsupportedError,
      );
    });

    test('rejects empty objective', () {
      expect(() => EngineerIntent(objective: ' '), throwsArgumentError);
    });

    test('rejects ambiguous target locator', () {
      expect(
        () => EngineerIntent(
          objective: 'Review intake entity',
          targetEntityId: RegistryEntityId('registry-entity-001'),
          targetPath: RegistryPath(<String>['helpy', 'plumbing', 'faucet']),
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty scope and constraint values', () {
      expect(
        () => EngineerIntent(
          objective: 'Review intake entity',
          scope: <String>['scenario', ' '],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineerIntent(
          objective: 'Review intake entity',
          constraints: <String>['read-only', ' '],
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate scope and constraint values', () {
      expect(
        () => EngineerIntent(
          objective: 'Review intake entity',
          scope: <String>['scenario', 'scenario'],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineerIntent(
          objective: 'Review intake entity',
          constraints: <String>['read-only', 'read-only'],
        ),
        throwsArgumentError,
      );
    });
  });
}
