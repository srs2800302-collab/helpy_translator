import '../domain/translator_models.dart';

abstract interface class ExactCapabilityPolicy {
  String buildReverseDiagnosticsSystemPrompt();

  String buildReverseDiagnosticsUserPrompt({
    required String en,
    required String th,
  });

  String buildAtomVerificationSystemPrompt();

  String buildAtomVerificationUserPrompt({
    required String sourceRu,
    required TranslationLanguage targetLanguage,
    required String targetText,
    required String reverseDiagnostic,
  });
}

abstract interface class TranslatorPolicy {
  String buildDirectSystemPrompt();

  String buildDirectUserPrompt(TranslatorWorkRequest request);

  String buildAuditSystemPrompt();

  String buildAuditUserPrompt({
    required String ru,
    required String en,
    required String th,
  });

  String buildExactChallengerSystemPrompt();

  String buildExactChallengerUserPrompt({
    required String ru,
    required String en,
    required String th,
  });
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
