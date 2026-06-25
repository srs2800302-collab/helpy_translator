import '../../domain/entities/translation_result.dart';
import '../../domain/repositories/translator_repository.dart';
import '../datasources/registry_remote_datasource.dart';
import '../datasources/translator_remote_datasource.dart';

final class TranslatorRepositoryImpl implements TranslatorRepository {
  const TranslatorRepositoryImpl({
    required this.remoteDataSource,
    required this.registryRemoteDataSource,
  });

  final TranslatorRemoteDataSource remoteDataSource;
  final RegistryRemoteDataSource registryRemoteDataSource;

  @override
  Future<TranslationResult> translate(String sentence) {
    return remoteDataSource.translate(sentence);
  }

  @override
  Future<List<String>> loadCanonicalClientRules() {
    return registryRemoteDataSource.loadCanonicalClientRules();
  }
}
