import '../../domain/entities/translation_result.dart';

final class TranslationResultModel extends TranslationResult {
  const TranslationResultModel({
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
      ru: sections['RU'] ?? '',
      en: sections['EN'] ?? '',
      th: sections['TH'] ?? '',
      enToRu: sections['EN → RU'] ?? '',
      thToRu: sections['TH → RU'] ?? '',
      enToTh: sections['EN → TH'] ?? '',
      thToEn: sections['TH → EN'] ?? '',
      canonicalVerdict: sections['CANONICAL VERDICT'] ?? 'NEEDS_REVIEW',
      canonicalComment: sections['CANONICAL COMMENT'] ?? '',
    );
  }

  static Map<String, String> _parseSections(String content) {
    const List<String> labels = <String>[
      'RU',
      'EN',
      'TH',
      'EN → RU',
      'TH → RU',
      'EN → TH',
      'TH → EN',
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
