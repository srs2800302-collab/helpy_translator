import '../repositories/translator_repository.dart';

final class LoadCanonicalClientRules {
  const LoadCanonicalClientRules(this.repository);

  final TranslatorRepository repository;

  Future<List<String>> call() {
    return repository.loadCanonicalClientRules();
  }
}
