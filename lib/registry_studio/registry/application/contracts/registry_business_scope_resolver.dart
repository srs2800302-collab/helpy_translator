import '../../domain/entities/registry_snapshot.dart';

abstract interface class RegistryBusinessScopeResolver {
  RegistrySnapshot resolveBusinessScope(RegistrySnapshot snapshot);
}
