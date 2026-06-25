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

  final TranslatorRepository repository;

  Future<List<CanonicalAuditResult>> call({
    CanonicalAuditProgress? onProgress,
  }) async {
    final List<String> rules = await repository.loadCanonicalClientRules();
    final List<CanonicalAuditResult> results = <CanonicalAuditResult>[];

    onProgress?.call(
      completed: 0,
      total: rules.length,
      currentPhrase: rules.isEmpty ? '' : rules.first,
      results: const <CanonicalAuditResult>[],
    );

    for (final String rule in rules) {
      onProgress?.call(
        completed: results.length,
        total: rules.length,
        currentPhrase: rule,
        results: List<CanonicalAuditResult>.unmodifiable(results),
      );

      try {
        final TranslationResult translation = await repository.translate(rule);

        results.add(
          CanonicalAuditResult(
            sourceRu: rule,
            translation: translation,
            status: _resolveStatus(rule, translation),
            errorMessage: '',
          ),
        );
      } catch (error) {
        results.add(
          CanonicalAuditResult(
            sourceRu: rule,
            translation: null,
            status: CanonicalAuditStatus.failed,
            errorMessage: error.toString(),
          ),
        );
      }

      onProgress?.call(
        completed: results.length,
        total: rules.length,
        currentPhrase: rule,
        results: List<CanonicalAuditResult>.unmodifiable(results),
      );
    }

    return results;
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

  static String _normalize(String value) {
    return value
        .trim()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .toLowerCase();
  }
}
