import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';
import '../report/translator_report_view.dart';
import '../report/translator_system_comment.dart';

final class TranslatorHistoryHeader extends StatelessWidget {
  const TranslatorHistoryHeader({
    required this.entryCount,
    required this.onClearAll,
    super.key,
  });

  final int entryCount;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          l10n.translationHistory,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('translator-history-clear-all'),
            onPressed: entryCount == 0 ? null : onClearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(l10n.deleteAllTranslations),
          ),
        ),
      ],
    );
  }
}

final class TranslatorHistoryCard extends StatelessWidget {
  const TranslatorHistoryCard({
    required this.entry,
    required this.expanded,
    required this.onToggle,
    required this.onCopy,
    required this.onDelete,
    super.key,
  });

  final TranslatorHistoryEntry entry;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationVerdict verdict = entry.verdict;
    final Brightness brightness = Theme.of(context).brightness;
    final Color background = _background(brightness, verdict);
    final Color foreground = _foreground(brightness, verdict);

    return Card(
      key: ValueKey<String>('translator-history-card-${entry.id}'),
      color: background,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: true,
            expanded: expanded,
            label: verdictLabel(l10n, verdict),
            child: InkWell(
              key: ValueKey<String>('translator-history-toggle-${entry.id}'),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(_icon(verdict), size: 28, color: foreground),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            verdictLabel(l10n, verdict),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 32,
                          color: foreground,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.sourceText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...<Widget>[
            Divider(height: 1, color: foreground.withValues(alpha: 0.25)),
            Padding(
              key: ValueKey<String>('translator-history-details-${entry.id}'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TranslatorReportDetails(report: entry.report),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        key: ValueKey<String>(
                          'translator-history-copy-${entry.id}',
                        ),
                        onPressed: onCopy,
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(l10n.copyTranslation),
                      ),
                      OutlinedButton.icon(
                        key: ValueKey<String>(
                          'translator-history-delete-${entry.id}',
                        ),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.deleteTranslation),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Color _background(Brightness brightness, TranslationVerdict verdict) {
    final bool dark = brightness == Brightness.dark;

    return switch (verdict) {
      TranslationVerdict.exact =>
        dark ? const Color(0xFF173D21) : const Color(0xFFE7F4E8),
      TranslationVerdict.equivalent =>
        dark ? const Color(0xFF113A37) : const Color(0xFFE0F2F1),
      TranslationVerdict.needsReview =>
        dark ? const Color(0xFF4A3A09) : const Color(0xFFFFF8E1),
      TranslationVerdict.canonicalDrift =>
        dark ? const Color(0xFF4A1818) : const Color(0xFFFFE7E7),
    };
  }

  static Color _foreground(Brightness brightness, TranslationVerdict verdict) {
    final bool dark = brightness == Brightness.dark;

    return switch (verdict) {
      TranslationVerdict.exact =>
        dark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20),
      TranslationVerdict.equivalent =>
        dark ? const Color(0xFF80CBC4) : const Color(0xFF004D40),
      TranslationVerdict.needsReview =>
        dark ? const Color(0xFFFFE082) : const Color(0xFF6D4C00),
      TranslationVerdict.canonicalDrift =>
        dark ? const Color(0xFFFFABAB) : const Color(0xFF8B1A1A),
    };
  }

  static IconData _icon(TranslationVerdict verdict) {
    return switch (verdict) {
      TranslationVerdict.exact => Icons.check_circle,
      TranslationVerdict.equivalent => Icons.circle,
      TranslationVerdict.needsReview => Icons.warning_amber_rounded,
      TranslationVerdict.canonicalDrift => Icons.error,
    };
  }
}

String buildTranslatorHistoryClipboardText(
  TranslatorHistoryEntry entry,
  RegistryStudioLocalizations l10n,
) {
  final TranslatorRunReport report = entry.report;
  final TranslationBundle bundle = report.bundle;
  final ReverseTranslationBundle? reverse = bundle.reverseTranslations;
  final TranslationAudit audit = report.audit;
  final StringBuffer result = StringBuffer()
    ..writeln('${l10n.automaticVerdict}: ${verdictLabel(l10n, audit.verdict)}')
    ..writeln()
    ..writeln('${l10n.sourceText}:')
    ..writeln(report.request.sourceText)
    ..writeln()
    ..writeln('${l10n.directTranslation}:')
    ..writeln('RU:')
    ..writeln(bundle.ru)
    ..writeln('EN:')
    ..writeln(bundle.en)
    ..writeln('TH:')
    ..writeln(bundle.th);

  if (reverse != null) {
    result
      ..writeln()
      ..writeln('${l10n.reverseTranslationsForDiagnostics}:')
      ..writeln('EN_TO_RU:')
      ..writeln(reverse.enToRu)
      ..writeln('TH_TO_RU:')
      ..writeln(reverse.thToRu)
      ..writeln('EN_TO_TH:')
      ..writeln(reverse.enToTh)
      ..writeln('TH_TO_EN:')
      ..writeln(reverse.thToEn);
  }

  result
    ..writeln()
    ..writeln('${l10n.canonicalDictionary}: ${l10n.notConnected}')
    ..writeln()
    ..writeln('${l10n.systemComment}:')
    ..writeln(buildTranslatorSystemCommentText(l10n, audit));

  return result.toString().trimRight();
}
