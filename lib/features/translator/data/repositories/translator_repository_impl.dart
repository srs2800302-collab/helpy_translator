import '../../domain/entities/translation_result.dart';
import '../../domain/repositories/translator_repository.dart';
import '../datasources/registry_local_datasource.dart';
import '../datasources/translator_remote_datasource.dart';

final class TranslatorRepositoryImpl implements TranslatorRepository {
  const TranslatorRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final TranslatorRemoteDataSource remoteDataSource;
  final RegistryLocalDataSource localDataSource;

  @override
  Future<TranslationResult> translate(String sentence) {
    return remoteDataSource.translate(sentence);
  }

  @override
  Future<List<String>> loadCanonicalClientRules() {
    return localDataSource.loadCanonicalClientRules();
  }
}
