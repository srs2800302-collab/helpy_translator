import '../../../core/domain/value_objects/registry_adapter_contract_identity.dart';

final class HelpyAdapterContract {
  HelpyAdapterContract._();

  static final RegistryAdapterContractIdentity identity =
      RegistryAdapterContractIdentity(
        adapterId: 'helpy',
        semanticContractVersion: '1',
      );
}
