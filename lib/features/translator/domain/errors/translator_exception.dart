enum TranslatorFailureKind {
  validation,
  missingApiKey,
  unsupportedLanguage,
  transport,
  authorization,
  rateLimited,
  provider,
  invalidResponse,
  cancelled,
  persistence,
}

final class TranslatorException implements Exception {
  const TranslatorException(this.kind, this.message);

  final TranslatorFailureKind kind;
  final String message;

  @override
  String toString() => 'TranslatorException(${kind.name}): $message';
}
