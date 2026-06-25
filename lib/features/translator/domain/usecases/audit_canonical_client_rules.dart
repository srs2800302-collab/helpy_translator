import '../entities/canonical_audit_result.dart';
import '../entities/translation_result.dart';
import '../repositories/translator_repository.dart';

typedef CanonicalAuditProgress = void Function({
  required int completed,
  required int total,
  required String currentPhrase,
  required List<CanonicalAuditResult> results,
});

final class AuditCanonicalClientRules {
  const AuditCanonicalClientRules(this.repository);

  static const int _passesPerRule = 3;

  final TranslatorRepository repository;

  Future<List<CanonicalAuditResult>> call({
    CanonicalAuditProgress? onProgress,
  }) async {
    final List<String> rules = await repository.loadCanonicalClientRules();
    final List<CanonicalAuditResult> results = <CanonicalAuditResult>[];

    final int total = rules.length * _passesPerRule;
    int completed = 0;

    onProgress?.call(
      completed: completed,
      total: total,
      currentPhrase: rules.isEmpty ? '' : rules.first,
      results: const <CanonicalAuditResult>[],
    );

    for (final String rule in rules) {
      final List<CanonicalAuditResult> passResults = <CanonicalAuditResult>[];

      for (int pass = 1; pass <= _passesPerRule; pass++) {
        onProgress?.call(
          completed: completed,
          total: total,
          currentPhrase: '$rule\nПрогон $pass / $_passesPerRule',
          results: List<CanonicalAuditResult>.unmodifiable(results),
        );

        try {
          final TranslationResult translation = await repository.translate(rule);

          passResults.add(
            CanonicalAuditResult(
              sourceRu: rule,
              translation: translation,
              status: _resolveStatus(rule, translation),
              errorMessage: '',
            ),
          );
        } catch (error) {
          passResults.add(
            CanonicalAuditResult(
              sourceRu: rule,
              translation: null,
              status: CanonicalAuditStatus.failed,
              errorMessage: error.toString(),
            ),
          );
        }

        completed++;

        onProgress?.call(
          completed: completed,
          total: total,
          currentPhrase: '$rule\nПрогон $pass / $_passesPerRule',
          results: List<CanonicalAuditResult>.unmodifiable(results),
        );
      }

      results.add(_mergePassResults(rule, passResults));

      onProgress?.call(
        completed: completed,
        total: total,
        currentPhrase: rule,
        results: List<CanonicalAuditResult>.unmodifiable(results),
      );
    }

    return results;
  }

  static CanonicalAuditResult _mergePassResults(
    String rule,
    List<CanonicalAuditResult> passResults,
  ) {
    final CanonicalAuditResult worst = passResults.reduce(
      (CanonicalAuditResult previous, CanonicalAuditResult current) {
        return _severity(current.status) > _severity(previous.status)
            ? current
            : previous;
      },
    );

    final String comment = passResults
        .map((CanonicalAuditResult result) {
          final String verdict = result.translation?.canonicalVerdict ?? 'FAILED';
          final String reason = result.translation?.canonicalComment ??
              result.errorMessage;
          return '${result.status.name}: $verdict — $reason';
        })
        .join('\n');

    final TranslationResult? translation = worst.translation;

    if (translation == null) {
      return worst;
    }

    return CanonicalAuditResult(
      sourceRu: rule,
      translation: TranslationResult(
        sourceLanguage: translation.sourceLanguage,
        sourceText: translation.sourceText,
        ru: translation.ru,
        en: translation.en,
        th: translation.th,
        enToRu: translation.enToRu,
        thToRu: translation.thToRu,
        enToTh: translation.enToTh,
        thToEn: translation.thToEn,
        canonicalVerdict: translation.canonicalVerdict,
        canonicalComment: 'Итог по 3 прогонам: выбран худший статус.\n$comment',
      ),
      status: worst.status,
      errorMessage: worst.errorMessage,
    );
  }

  static CanonicalAuditStatus _resolveStatus(
    String sourceRu,
    TranslationResult translation,
  ) {
    final String normalizedSource = _normalize(sourceRu);
    final String normalizedEnToRu = _normalize(translation.enToRu);
    final String normalizedThToRu = _normalize(translation.thToRu);

    if (normalizedSource == normalizedEnToRu &&
        normalizedSource == normalizedThToRu) {
      return CanonicalAuditStatus.exact;
    }

    final String verdict = translation.canonicalVerdict.trim().toUpperCase();

    if (verdict == 'EXACT') {
      return CanonicalAuditStatus.exact;
    }

    if (verdict == 'EQUIVALENT') {
      return CanonicalAuditStatus.equivalent;
    }

    if (verdict == 'NEEDS_REVIEW') {
      return CanonicalAuditStatus.needsReview;
    }

    return CanonicalAuditStatus.drift;
  }

  static int _severity(CanonicalAuditStatus status) {
    return switch (status) {
      CanonicalAuditStatus.exact => 0,
      CanonicalAuditStatus.equivalent => 1,
      CanonicalAuditStatus.needsReview => 2,
      CanonicalAuditStatus.drift => 3,
      CanonicalAuditStatus.failed => 4,
    };
  }

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .toLowerCase();
  }
}
