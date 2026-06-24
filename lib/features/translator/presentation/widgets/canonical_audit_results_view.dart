import 'package:flutter/material.dart';

import '../../domain/entities/canonical_audit_result.dart';

final class CanonicalAuditResultsView extends StatelessWidget {
  const CanonicalAuditResultsView({
    required this.results,
    super.key,
  });

  final List<CanonicalAuditResult> results;

  @override
  Widget build(BuildContext context) {
    final int exactCount = results
        .where((CanonicalAuditResult result) {
          return result.status == CanonicalAuditStatus.exact;
        })
        .length;

    final int driftCount = results
        .where((CanonicalAuditResult result) {
          return result.status == CanonicalAuditStatus.drift;
        })
        .length;

    final int failedCount = results
        .where((CanonicalAuditResult result) {
          return result.status == CanonicalAuditStatus.failed;
        })
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Аудит словаря: ${results.length}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text('✅ Exact: $exactCount   ⚠ Drift: $driftCount   ❌ Failed: $failedCount'),
        const SizedBox(height: 12),
        for (int index = 0; index < results.length; index++)
          _CanonicalAuditCard(
            index: index + 1,
            result: results[index],
          ),
      ],
    );
  }
}

final class _CanonicalAuditCard extends StatelessWidget {
  const _CanonicalAuditCard({
    required this.index,
    required this.result,
  });

  final int index;
  final CanonicalAuditResult result;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = switch (result.status) {
      CanonicalAuditStatus.exact => '✅ Exact',
      CanonicalAuditStatus.drift => '⚠ Canonical Drift',
      CanonicalAuditStatus.failed => '❌ Failed',
    };

    final Color? statusColor = switch (result.status) {
      CanonicalAuditStatus.exact => Colors.green.shade50,
      CanonicalAuditStatus.drift => Colors.orange.shade50,
      CanonicalAuditStatus.failed => Colors.red.shade50,
    };

    final translation = result.translation;

    return Card(
      color: statusColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text('$index. $statusLabel'),
        subtitle: Text(result.sourceRu),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _TextRow(label: 'RU original', value: result.sourceRu),
          if (translation != null) ...<Widget>[
            _TextRow(label: 'EN', value: translation.en),
            _TextRow(label: 'TH', value: translation.th),
            _TextRow(label: 'EN → RU', value: translation.enToRu),
            _TextRow(label: 'TH → RU', value: translation.thToRu),
          ],
          if (result.errorMessage.isNotEmpty)
            _TextRow(label: 'Error', value: result.errorMessage),
        ],
      ),
    );
  }
}

final class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String normalizedValue = value.isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          SelectableText(normalizedValue),
        ],
      ),
    );
  }
}
