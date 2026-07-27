import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';

final class TranslatorReportDetails extends StatelessWidget {
  const TranslatorReportDetails({required this.report, super.key});

  final TranslatorRunReport report;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationAudit audit = report.audit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DetailsHeading(title: l10n.sourceText),
        const SizedBox(height: 6),
        SelectableText(report.request.sourceText),
        const Divider(height: 32),
        TranslatorBundleDetails(bundle: report.bundle),
        const Divider(height: 32),
        _DetailsHeading(title: l10n.automaticVerdict),
        const SizedBox(height: 8),
        Text(
          verdictLabel(l10n, audit.verdict),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
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
        _DetailsHeading(title: l10n.canonicalDictionary),
        const SizedBox(height: 6),
        Text(
          l10n.notConnected,
          key: const ValueKey<String>('translator-canonical-dictionary-status'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(l10n.canonicalVerdictUnavailable, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(l10n.verdictEngineerNotice, textAlign: TextAlign.center),
        const Divider(height: 32),
        _DetailsHeading(title: l10n.auditAndDiagnostics),
        const SizedBox(height: 12),
        _FindingGroup(title: l10n.meaning, findings: audit.meaningFindings),
        _FindingGroup(
          title: l10n.terminology,
          findings: audit.terminologyFindings,
        ),
        _FindingGroup(title: l10n.style, findings: audit.styleFindings),
        _FindingGroup(title: l10n.ambiguity, findings: audit.ambiguityFindings),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TranslatorBundleDetails(bundle: bundle),
          ),
        ),
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

final class TranslatorBundleDetails extends StatelessWidget {
  const TranslatorBundleDetails({required this.bundle, super.key});

  final TranslationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final ReverseTranslationBundle? reverse = bundle.reverseTranslations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _DetailsHeading(title: l10n.directTranslation),
        const SizedBox(height: 8),
        _LabeledText(
          label: '${bundle.sourceLanguage.code} · SOURCE TEXT',
          value: bundle.sourceText,
        ),
        _LabeledText(label: 'RU', value: bundle.ru),
        _LabeledText(label: 'EN', value: bundle.en),
        _LabeledText(label: 'TH', value: bundle.th, showDivider: false),
        if (reverse != null) ...<Widget>[
          const Divider(height: 32),
          _DetailsHeading(title: l10n.reverseTranslationsForDiagnostics),
          const SizedBox(height: 8),
          _LabeledText(label: 'EN → RU', value: reverse.enToRu),
          _LabeledText(label: 'TH → RU', value: reverse.thToRu),
          _LabeledText(label: 'EN → TH', value: reverse.enToTh),
          _LabeledText(
            label: 'TH → EN',
            value: reverse.thToEn,
            showDivider: false,
          ),
        ],
      ],
    );
  }
}

final class _DetailsHeading extends StatelessWidget {
  const _DetailsHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

final class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        SelectableText(value),
        if (showDivider) const Divider(height: 24),
      ],
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

String verdictLabel(
  RegistryStudioLocalizations l10n,
  TranslationVerdict verdict,
) {
  return switch (verdict) {
    TranslationVerdict.exact => l10n.exactVerdict,
    TranslationVerdict.equivalent => l10n.equivalentVerdict,
    TranslationVerdict.needsReview => l10n.needsReviewVerdict,
    TranslationVerdict.canonicalDrift => l10n.canonicalDriftVerdict,
  };
}
