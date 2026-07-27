import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';

final class TranslatorReportView extends StatelessWidget {
  const TranslatorReportView({required this.report, super.key});

  final TranslatorRunReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TranslationBundleSections(bundle: report.bundle),
        const SizedBox(height: 12),
        _VerdictCard(audit: report.audit),
        const SizedBox(height: 12),
        _AuditFindingsCard(audit: report.audit),
      ],
    );
  }
}

final class TranslatorPartialBundleView extends StatelessWidget {
  const TranslatorPartialBundleView({required this.bundle, super.key});

  final TranslationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _TranslationBundleSections(bundle: bundle),
        const SizedBox(height: 12),
        Card(
          color: colors.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.pending_actions_outlined,
                  color: colors.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.semanticAuditIncomplete,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.canonicalDictionary,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.onTertiaryContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.notConnected,
                        key: const ValueKey<String>(
                          'translator-canonical-dictionary-status',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.canonicalVerdictUnavailable,
                        style: TextStyle(color: colors.onTertiaryContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _TranslationBundleSections extends StatelessWidget {
  const _TranslationBundleSections({required this.bundle});

  final TranslationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final ReverseTranslationBundle? reverse = bundle.reverseTranslations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionCard(
          title: l10n.directTranslation,
          entries: <MapEntry<String, String>>[
            MapEntry<String, String>(
              '${bundle.sourceLanguage.code} · SOURCE TEXT',
              bundle.sourceText,
            ),
            MapEntry<String, String>('RU', bundle.ru),
            MapEntry<String, String>('EN', bundle.en),
            MapEntry<String, String>('TH', bundle.th),
          ],
        ),
        if (reverse != null) ...<Widget>[
          const SizedBox(height: 12),
          _SectionCard(
            title: l10n.reverseTranslationsForDiagnostics,
            entries: <MapEntry<String, String>>[
              MapEntry<String, String>('EN → RU', reverse.enToRu),
              MapEntry<String, String>('TH → RU', reverse.thToRu),
              MapEntry<String, String>('EN → TH', reverse.enToTh),
              MapEntry<String, String>('TH → EN', reverse.thToEn),
            ],
          ),
        ],
      ],
    );
  }
}

final class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationVerdict verdict = audit.verdict;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color background = switch (verdict) {
      TranslationVerdict.exact => colors.primaryContainer,
      TranslationVerdict.equivalent => colors.secondaryContainer,
      TranslationVerdict.needsReview => colors.tertiaryContainer,
      TranslationVerdict.canonicalDrift => colors.errorContainer,
    };

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              l10n.automaticVerdict,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _verdictLabel(verdict),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _BooleanEvidenceRow(
              label: l10n.meaningPreserved,
              value: audit.meaningPreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.terminologyPreserved,
              value: audit.terminologyPreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.stylePreserved,
              value: audit.stylePreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.ambiguousWording,
              value: audit.ambiguousWording,
              positiveMeansGood: false,
            ),
            const Divider(height: 32),
            Text(
              l10n.canonicalDictionary,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.notConnected,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(l10n.canonicalVerdictUnavailable, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.verdictEngineerNotice, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _BooleanEvidenceRow extends StatelessWidget {
  const _BooleanEvidenceRow({
    required this.label,
    required this.value,
    this.positiveMeansGood = true,
  });

  final String label;
  final bool value;
  final bool positiveMeansGood;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final bool good = positiveMeansGood ? value : !value;

    return Row(
      children: <Widget>[
        Icon(good ? Icons.check_circle_outline : Icons.warning_amber, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value ? l10n.yes : l10n.no),
      ],
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            for (final MapEntry<String, String> entry in entries) ...<Widget>[
              const Divider(height: 24),
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              SelectableText(entry.value),
            ],
          ],
        ),
      ),
    );
  }
}

final class _AuditFindingsCard extends StatelessWidget {
  const _AuditFindingsCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.auditAndDiagnostics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _FindingGroup(title: l10n.meaning, findings: audit.meaningFindings),
            _FindingGroup(
              title: l10n.terminology,
              findings: audit.terminologyFindings,
            ),
            _FindingGroup(title: l10n.style, findings: audit.styleFindings),
            _FindingGroup(
              title: l10n.ambiguity,
              findings: audit.ambiguityFindings,
            ),
          ],
        ),
      ),
    );
  }
}

final class _FindingGroup extends StatelessWidget {
  const _FindingGroup({required this.title, required this.findings});

  final String title;
  final List<String> findings;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (findings.isEmpty)
            Text(l10n.noViolations)
          else
            for (final String finding in findings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $finding'),
              ),
        ],
      ),
    );
  }
}

String _verdictLabel(TranslationVerdict verdict) {
  return switch (verdict) {
    TranslationVerdict.exact => 'EXACT',
    TranslationVerdict.equivalent => 'EQUIVALENT',
    TranslationVerdict.needsReview => 'NEEDS REVIEW',
    TranslationVerdict.canonicalDrift => 'CANONICAL DRIFT',
  };
}
