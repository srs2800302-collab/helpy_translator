import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/helpy_registry_semantic_contract.dart';

void main() {
  group('HelpyRegistrySemanticContract', () {
    test('defines stable adapter and semantic contract identities', () {
      expect(
        HelpyRegistrySemanticContract.adapterId,
        'helpy.registry.adapter.v1',
      );
      expect(
        HelpyRegistrySemanticContract.identity.contractId,
        'helpy.registry.semantic',
      );
      expect(HelpyRegistrySemanticContract.identity.version, '1');
      expect(HelpyRegistrySemanticContract.kindSchemaVersion, '1');
    });

    test('owns the approved Helpy Registry entity kind catalog', () {
      const List<String> expectedKindIds = <String>[
        'contract',
        'architectureGroup',
        'rootCategory',
        'category',
        'subcategory',
        'scenario',
        'section',
        'clientRule',
        'masterRule',
        'scenarioRule',
        'globalRule',
        'platformRule',
        'eligibilityRule',
        'dependencyRule',
        'translationRule',
        'question',
        'answerOption',
        'structuredScope',
        'photoRequirement',
        'photoLimit',
        'pricingRule',
        'guidance',
        'guidanceTrigger',
        'guidanceSlot',
        'adminDependency',
      ];

      expect(
        HelpyRegistrySemanticContract.kinds
            .map((kind) => kind.kindId)
            .toList(growable: false),
        expectedKindIds,
      );
      expect(
        HelpyRegistrySemanticContract.kindsById.keys.toList(growable: false),
        expectedKindIds,
      );
      expect(
        HelpyRegistrySemanticContract.kindsById.length,
        expectedKindIds.length,
      );

      for (final String kindId in expectedKindIds) {
        final kind = HelpyRegistrySemanticContract.kindsById[kindId];

        expect(kind, isNotNull);
        expect(kind!.semanticContract, HelpyRegistrySemanticContract.identity);
        expect(
          kind.schemaVersion,
          HelpyRegistrySemanticContract.kindSchemaVersion,
        );
      }
    });

    test('does not expose mutable kind collections', () {
      expect(
        () => HelpyRegistrySemanticContract.kinds.add(
          HelpyRegistrySemanticContract.contract,
        ),
        throwsUnsupportedError,
      );
      expect(
        () => HelpyRegistrySemanticContract.kindsById.clear(),
        throwsUnsupportedError,
      );
    });
  });
}
