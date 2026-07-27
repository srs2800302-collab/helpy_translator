import '../domain/translator_models.dart';

abstract interface class TranslatorPolicy {
  String buildDirectSystemPrompt();

  String buildDirectUserPrompt(TranslatorWorkRequest request);

  String buildAuditSystemPrompt();

  String buildAuditUserPrompt(TranslationBundle bundle);
}

abstract interface class TranslatorOperation {
  Future<TranslatorRunReport> get result;

  Stream<TranslatorRunStage> get progress;

  void cancel();
}

abstract interface class TranslatorProvider {
  TranslatorOperation start({
    required TranslatorWorkRequest request,
    required String accessKey,
  });
}

final class TranslatorProviderException implements Exception {
  const TranslatorProviderException(this.failure);

  final TranslatorFailure failure;

  @override
  String toString() => 'TranslatorProviderException(${failure.message})';
}
