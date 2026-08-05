final class TyphoonTranslatorConfig {
  const TyphoonTranslatorConfig({
    this.baseUrl = 'https://api.opentyphoon.ai/v1',
    this.model = 'typhoon-v2.5-30b-a3b-instruct',
    this.requestTimeout = const Duration(seconds: 90),
    this.translationMaxTokens = 2048,
    this.auditMaxTokens = 4096,
    this.auditVerificationMaxTokens = 3072,
  }) : assert(baseUrl != ''),
       assert(model != ''),
       assert(translationMaxTokens > 0),
       assert(auditMaxTokens > 0),
       assert(auditVerificationMaxTokens > 0);

  final String baseUrl;
  final String model;
  final Duration requestTimeout;
  final int translationMaxTokens;
  final int auditMaxTokens;
  final int auditVerificationMaxTokens;

  Uri get chatCompletionsUri {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return Uri.parse('$normalizedBaseUrl/chat/completions');
  }
}
