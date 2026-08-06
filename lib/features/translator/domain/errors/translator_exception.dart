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
  const TranslatorException(this.kind, this.message, {this.statusCode});

  final TranslatorFailureKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() {
    final String status = statusCode == null ? '' : ', status=$statusCode';
    return 'TranslatorException(${kind.name}$status): $message';
  }
}
