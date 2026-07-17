import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_kind.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_semantic_contract_identity.dart';

void main() {
  group('RegistryEntityKind', () {
    final RegistrySemanticContractIdentity semanticContract =
        RegistrySemanticContractIdentity(
          contractId: 'registry.node',
          version: '1',
        );

    test('normalizes and preserves its typed identity components', () {
      final RegistryEntityKind kind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: ' project.custom_node ',
        schemaVersion: ' 3 ',
      );

      expect(kind.semanticContract, semanticContract);
      expect(kind.kindId, 'project.custom_node');
      expect(kind.schemaVersion, '3');
    });

    test('rejects an empty kind identifier', () {
      expect(
        () => RegistryEntityKind(
          semanticContract: semanticContract,
          kindId: '',
          schemaVersion: '1',
        ),
        throwsArgumentError,
      );
      expect(
        () => RegistryEntityKind(
          semanticContract: semanticContract,
          kindId: '   ',
          schemaVersion: '1',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty schema version', () {
      expect(
        () => RegistryEntityKind(
          semanticContract: semanticContract,
          kindId: 'project.custom_node',
          schemaVersion: '',
        ),
        throwsArgumentError,
      );
      expect(
        () => RegistryEntityKind(
          semanticContract: semanticContract,
          kindId: 'project.custom_node',
          schemaVersion: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('uses semantic contract, kind identifier and schema for equality', () {
      final RegistryEntityKind first = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: ' project.custom_node ',
        schemaVersion: ' 3 ',
      );
      final RegistryEntityKind second = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.custom_node',
        schemaVersion: '3',
      );
      final RegistryEntityKind differentKind = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.another_node',
        schemaVersion: '3',
      );
      final RegistryEntityKind differentSchema = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'project.custom_node',
        schemaVersion: '4',
      );
      final RegistryEntityKind differentContract = RegistryEntityKind(
        semanticContract: RegistrySemanticContractIdentity(
          contractId: 'registry.another_contract',
          version: '1',
        ),
        kindId: 'project.custom_node',
        schemaVersion: '3',
      );
      final RegistryEntityKind differentCase = RegistryEntityKind(
        semanticContract: semanticContract,
        kindId: 'Project.custom_node',
        schemaVersion: '3',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentKind));
      expect(first, isNot(differentSchema));
      expect(first, isNot(differentContract));
      expect(first, isNot(differentCase));
    });
  });
}
