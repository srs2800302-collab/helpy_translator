import '../../domain/entities/translation_result.dart';

final class TranslationResultModel extends TranslationResult {
  const TranslationResultModel({
    required super.sourceLanguage,
    required super.sourceText,
    required super.ru,
    required super.en,
    required super.th,
    required super.enToRu,
    required super.thToRu,
    required super.enToTh,
    required super.thToEn,
    required super.canonicalVerdict,
    required super.canonicalComment,
  });

  factory TranslationResultModel.fromContent(String content) {
    final Map<String, String> sections = _parseSections(content);

    return TranslationResultModel(
      sourceLanguage: sections['SOURCE LANGUAGE'] ?? 'UNKNOWN',
      sourceText: sections['SOURCE TEXT'] ?? '',
      ru: sections['RU'] ?? '',
      en: sections['EN'] ?? '',
      th: sections['TH'] ?? '',
      enToRu: sections['EN_TO_RU'] ?? '',
      thToRu: sections['TH_TO_RU'] ?? '',
      enToTh: sections['EN_TO_TH'] ?? '',
      thToEn: sections['TH_TO_EN'] ?? '',
      canonicalVerdict: sections['CANONICAL VERDICT'] ?? 'NEEDS_REVIEW',
      canonicalComment: sections['CANONICAL COMMENT'] ?? '',
    );
  }

  static Map<String, String> _parseSections(String content) {
    const List<String> labels = <String>[
      'SOURCE LANGUAGE',
      'SOURCE TEXT',
      'RU',
      'EN',
      'TH',
      'EN_TO_RU',
      'TH_TO_RU',
      'EN_TO_TH',
      'TH_TO_EN',
      'CANONICAL VERDICT',
      'CANONICAL COMMENT',
    ];

    final Map<String, String> result = <String, String>{};

    for (int index = 0; index < labels.length; index++) {
      final String label = labels[index];
      final String currentMarker = '$label:';
      final int start = content.indexOf(currentMarker);

      if (start == -1) {
        result[label] = '';
        continue;
      }

      final int valueStart = start + currentMarker.length;
      int valueEnd = content.length;

      for (int nextIndex = index + 1; nextIndex < labels.length; nextIndex++) {
        final int nextStart = content.indexOf('${labels[nextIndex]}:', valueStart);
        if (nextStart != -1) {
          valueEnd = nextStart;
          break;
        }
      }

      result[label] = content.substring(valueStart, valueEnd).trim();
    }

    return result;
  }
}
