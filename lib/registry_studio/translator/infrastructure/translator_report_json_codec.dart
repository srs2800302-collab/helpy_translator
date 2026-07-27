import '../domain/translator_models.dart';

final class TranslatorReportJsonCodec {
  const TranslatorReportJsonCodec._();

  static Map<String, Object?> encode(TranslatorRunReport report) {
    return <String, Object?>{
      'request': <String, Object?>{
        'sourceText': report.request.sourceText,
        'sourceLanguageHint': null,
        'engineerContext': report.request.engineerContext,
      },
      'bundle': encodeBundle(report.bundle),
      'audit': <String, Object?>{
        'meaningFindings': report.audit.meaningFindings,
        'terminologyFindings': report.audit.terminologyFindings,
        'styleFindings': report.audit.styleFindings,
        'ambiguityFindings': report.audit.ambiguityFindings,
      },
      'createdAt': report.createdAt.toUtc().toIso8601String(),
    };
  }

  static TranslatorRunReport decode(Map<String, Object?> value) {
    const Set<String> expectedKeys = <String>{
      'request',
      'bundle',
      'audit',
      'createdAt',
    };
    requireExactKeys(value, expectedKeys, 'Translator report');

    final Map<String, Object?> request = map(
      value['request'],
      'Translator report request',
    );
    final Map<String, Object?> bundle = map(
      value['bundle'],
      'Translator report bundle',
    );
    final Map<String, Object?> audit = map(
      value['audit'],
      'Translator report audit',
    );
    final Object? createdAt = value['createdAt'];

    if (createdAt is! String) {
      throw const FormatException(
        'Translator report createdAt must be a string.',
      );
    }

    return TranslatorRunReport(
      request: TranslatorWorkRequest(
        sourceText: string(request['sourceText'], 'request.sourceText'),
        engineerContext: request['engineerContext'] == null
            ? null
            : string(request['engineerContext'], 'request.engineerContext'),
      ),
      bundle: decodeBundle(bundle),
      audit: TranslationAudit(
        meaningFindings: strings(
          audit['meaningFindings'],
          'audit.meaningFindings',
        ),
        terminologyFindings: strings(
          audit['terminologyFindings'],
          'audit.terminologyFindings',
        ),
        styleFindings: strings(audit['styleFindings'], 'audit.styleFindings'),
        ambiguityFindings: strings(
          audit['ambiguityFindings'],
          'audit.ambiguityFindings',
        ),
      ),
      createdAt: DateTime.parse(createdAt).toUtc(),
    );
  }

  static Map<String, Object?> map(Object? value, String name) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((Object? key) => key is! String)) {
      throw FormatException('$name must be a JSON object.');
    }

    return value.cast<String, Object?>();
  }

  static String string(Object? value, String name) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$name must be a nonempty string.');
    }

    return value;
  }

  static List<String> strings(Object? value, String name) {
    if (value is! List<Object?> ||
        value.any((Object? item) => item is! String)) {
      throw FormatException('$name must be an array of strings.');
    }

    return value.cast<String>();
  }

  static void requireExactKeys(
    Map<String, Object?> value,
    Set<String> expected,
    String name,
  ) {
    final Set<String> actual = value.keys.toSet();

    if (actual.length != expected.length || !actual.containsAll(expected)) {
      throw FormatException('$name schema is invalid.');
    }
  }

  static Map<String, Object?> encodeBundle(TranslationBundle bundle) {
    return <String, Object?>{...bundle.allSections};
  }

  static TranslationBundle decodeBundle(Map<String, Object?> bundle) {
    const Set<String> directBundleKeys = <String>{
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
    };
    const Set<String> reverseBundleKeys = <String>{
      'EN_TO_RU',
      'TH_TO_RU',
      'EN_TO_TH',
      'TH_TO_EN',
    };
    final Set<String> allowedBundleKeys = <String>{
      ...directBundleKeys,
      ...reverseBundleKeys,
    };
    final Set<String> presentReverseKeys = bundle.keys.toSet().intersection(
      reverseBundleKeys,
    );

    if (!bundle.keys.toSet().containsAll(directBundleKeys) ||
        bundle.keys.any((String key) => !allowedBundleKeys.contains(key)) ||
        (presentReverseKeys.isNotEmpty &&
            presentReverseKeys.length != reverseBundleKeys.length)) {
      throw const FormatException('Translator bundle schema is invalid.');
    }

    final ReverseTranslationBundle? reverseTranslations =
        presentReverseKeys.isEmpty
        ? null
        : ReverseTranslationBundle(
            enToRu: string(bundle['EN_TO_RU'], 'bundle.EN_TO_RU'),
            thToRu: string(bundle['TH_TO_RU'], 'bundle.TH_TO_RU'),
            enToTh: string(bundle['EN_TO_TH'], 'bundle.EN_TO_TH'),
            thToEn: string(bundle['TH_TO_EN'], 'bundle.TH_TO_EN'),
          );

    return TranslationBundle(
      sourceLanguage: TranslationLanguage.fromCode(
        string(bundle['SOURCE LANGUAGE'], 'bundle.SOURCE LANGUAGE'),
      ),
      sourceText: string(bundle['SOURCE TEXT'], 'bundle.SOURCE TEXT'),
      ru: string(bundle['RU'], 'bundle.RU'),
      en: string(bundle['EN'], 'bundle.EN'),
      th: string(bundle['TH'], 'bundle.TH'),
      reverseTranslations: reverseTranslations,
    );
  }
}
