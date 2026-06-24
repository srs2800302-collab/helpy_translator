import '../../domain/entities/translation_result.dart';
import '../../domain/repositories/translator_repository.dart';
import '../datasources/translator_remote_datasource.dart';

final class TranslatorRepositoryImpl implements TranslatorRepository {
  const TranslatorRepositoryImpl(this.remoteDataSource);

  final TranslatorRemoteDataSource remoteDataSource;

  @override
  Future<TranslationResult> translate(String sentence) {
    return remoteDataSource.translate(sentence);
  }
}
