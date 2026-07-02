import '../entities/registry_node.dart';
import '../repositories/translator_repository.dart';

final class LoadRegistryTree {
  const LoadRegistryTree(this.repository);

  final TranslatorRepository repository;

  Future<RegistryNode> call() {
    return repository.loadRegistryTree();
  }

  Future<RegistryNode> refresh() {
    return repository.refreshRegistryTree();
  }
}
