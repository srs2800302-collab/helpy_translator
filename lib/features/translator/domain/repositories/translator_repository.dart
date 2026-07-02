import '../entities/registry_node.dart';
import '../entities/translation_result.dart';

abstract interface class TranslatorRepository {
  Future<TranslationResult> translate(String sentence);

  Future<List<String>> loadCanonicalClientRules();

  Future<RegistryNode> loadRegistryTree();

  Future<RegistryNode> refreshRegistryTree();
}
