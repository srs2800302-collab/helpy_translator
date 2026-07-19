import '../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../core/domain/value_objects/registry_semantic_contract_identity.dart';

final class HelpyRegistrySemanticContract {
  HelpyRegistrySemanticContract._();

  static const String adapterId = 'helpy.registry.adapter.v1';
  static const String contractId = 'helpy.registry.semantic';
  static const String version = '1';
  static const String kindSchemaVersion = '1';

  static final RegistrySemanticContractIdentity identity =
      RegistrySemanticContractIdentity(
        contractId: contractId,
        version: version,
      );

  static final RegistryEntityKind contract = _kind('contract');
  static final RegistryEntityKind architectureGroup = _kind(
    'architectureGroup',
  );
  static final RegistryEntityKind rootCategory = _kind('rootCategory');
  static final RegistryEntityKind category = _kind('category');
  static final RegistryEntityKind subcategory = _kind('subcategory');
  static final RegistryEntityKind scenario = _kind('scenario');
  static final RegistryEntityKind section = _kind('section');
  static final RegistryEntityKind clientRule = _kind('clientRule');
  static final RegistryEntityKind masterRule = _kind('masterRule');
  static final RegistryEntityKind scenarioRule = _kind('scenarioRule');
  static final RegistryEntityKind globalRule = _kind('globalRule');
  static final RegistryEntityKind platformRule = _kind('platformRule');
  static final RegistryEntityKind eligibilityRule = _kind('eligibilityRule');
  static final RegistryEntityKind dependencyRule = _kind('dependencyRule');
  static final RegistryEntityKind translationRule = _kind('translationRule');
  static final RegistryEntityKind question = _kind('question');
  static final RegistryEntityKind answerOption = _kind('answerOption');
  static final RegistryEntityKind structuredScope = _kind('structuredScope');
  static final RegistryEntityKind photoRequirement = _kind('photoRequirement');
  static final RegistryEntityKind photoLimit = _kind('photoLimit');
  static final RegistryEntityKind pricingRule = _kind('pricingRule');
  static final RegistryEntityKind guidance = _kind('guidance');
  static final RegistryEntityKind guidanceTrigger = _kind('guidanceTrigger');
  static final RegistryEntityKind guidanceSlot = _kind('guidanceSlot');
  static final RegistryEntityKind adminDependency = _kind('adminDependency');

  static final List<RegistryEntityKind> kinds =
      List<RegistryEntityKind>.unmodifiable(<RegistryEntityKind>[
        contract,
        architectureGroup,
        rootCategory,
        category,
        subcategory,
        scenario,
        section,
        clientRule,
        masterRule,
        scenarioRule,
        globalRule,
        platformRule,
        eligibilityRule,
        dependencyRule,
        translationRule,
        question,
        answerOption,
        structuredScope,
        photoRequirement,
        photoLimit,
        pricingRule,
        guidance,
        guidanceTrigger,
        guidanceSlot,
        adminDependency,
      ]);

  static final Map<String, RegistryEntityKind> kindsById =
      Map<String, RegistryEntityKind>.unmodifiable(<String, RegistryEntityKind>{
        for (final RegistryEntityKind kind in kinds) kind.kindId: kind,
      });

  static RegistryEntityKind _kind(String kindId) {
    return RegistryEntityKind(
      semanticContract: identity,
      kindId: kindId,
      schemaVersion: kindSchemaVersion,
    );
  }
}
