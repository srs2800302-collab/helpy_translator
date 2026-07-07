import '../../../core/domain/value_objects/registry_entity_kind.dart';

import 'helpy_adapter_contract.dart';

final class HelpyRegistryEntityKinds {
  HelpyRegistryEntityKinds._();

  static const String serviceStandardKindId = 'helpy.service_standard';
  static const String serviceIntakeKindId = 'helpy.service_intake';

  static final RegistryEntityKind serviceStandard = RegistryEntityKind(
    adapterContract: HelpyAdapterContract.identity,
    kindId: serviceStandardKindId,
    schemaVersion: '1',
  );

  static final RegistryEntityKind serviceIntake = RegistryEntityKind(
    adapterContract: HelpyAdapterContract.identity,
    kindId: serviceIntakeKindId,
    schemaVersion: '1',
  );
}
