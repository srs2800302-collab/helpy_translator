import 'package:flutter/material.dart';

import '../../domain/entities/canonical_audit_result.dart';
import '../../domain/entities/translation_result.dart';

final class StatusSummaryView extends StatelessWidget {
  const StatusSummaryView({
    required this.exactCount,
    required this.equivalentCount,
    required this.reviewCount,
    required this.driftCount,
    required this.failedCount,
    super.key,
  });


  factory StatusSummaryView.fromTranslationResults({
    required List<TranslationResult> results,
  }) {
    return StatusSummaryView(
      exactCount: _countTranslations(results, 'EXACT'),
      equivalentCount: _countTranslations(results, 'EQUIVALENT'),
      reviewCount: _countTranslations(results, 'NEEDS_REVIEW'),
      driftCount: _countTranslations(results, 'CANONICAL_DRIFT'),
      failedCount: results.where((TranslationResult result) {
        final String verdict = result.canonicalVerdict.trim().toUpperCase();
        return verdict.isEmpty ||
            !<String>{
              'EXACT',
              'EQUIVALENT',
              'NEEDS_REVIEW',
              'CANONICAL_DRIFT',
            }.contains(verdict);
      }).length,
    );
  }

  factory StatusSummaryView.fromAuditResults({
    required List<CanonicalAuditResult> results,
  }) {
    return StatusSummaryView(
      exactCount: _count(results, CanonicalAuditStatus.exact),
      equivalentCount: _count(results, CanonicalAuditStatus.equivalent),
      reviewCount: _count(results, CanonicalAuditStatus.needsReview),
      driftCount: _count(results, CanonicalAuditStatus.drift),
      failedCount: _count(results, CanonicalAuditStatus.failed),
    );
  }

  factory StatusSummaryView.fromVerdict(String verdict) {
    final String normalized = verdict.trim().toUpperCase();

    return StatusSummaryView(
      exactCount: normalized == 'EXACT' ? 1 : 0,
      equivalentCount: normalized == 'EQUIVALENT' ? 1 : 0,
      reviewCount: normalized == 'NEEDS_REVIEW' ? 1 : 0,
      driftCount: normalized == 'CANONICAL_DRIFT' ? 1 : 0,
      failedCount: <String>{
        'EXACT',
        'EQUIVALENT',
        'NEEDS_REVIEW',
        'CANONICAL_DRIFT',
      }.contains(normalized)
          ? 0
          : 1,
    );
  }

  final int exactCount;
  final int equivalentCount;
  final int reviewCount;
  final int driftCount;
  final int failedCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _StatusChip(icon: '✅', label: 'Exact', count: exactCount),
        _StatusChip(icon: '🟢', label: 'Eq', count: equivalentCount),
        _StatusChip(icon: '🟡', label: 'Review', count: reviewCount),
        _StatusChip(icon: '🔴', label: 'Drift', count: driftCount),
        _StatusChip(icon: '❌', label: 'Failed', count: failedCount),
      ],
    );
  }

  static int _count(
    List<CanonicalAuditResult> results,
    CanonicalAuditStatus status,
  ) {
    return results
        .where((CanonicalAuditResult result) => result.status == status)
        .length;
  }
}

final class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$icon $label: $count',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
