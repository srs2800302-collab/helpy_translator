import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';

final class TranslatorSystemComment extends StatelessWidget {
  const TranslatorSystemComment({required this.audit, super.key});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String comment = buildTranslatorSystemCommentText(l10n, audit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.systemComment,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SelectableText(
          comment,
          key: const ValueKey<String>('translator-system-comment'),
        ),
      ],
    );
  }
}

String buildTranslatorSystemCommentText(
  RegistryStudioLocalizations l10n,
  TranslationAudit audit,
) {
  final StringBuffer buffer = StringBuffer(switch (audit.verdict) {
    TranslationVerdict.exact => l10n.systemCommentExact,
    TranslationVerdict.equivalent => l10n.systemCommentEquivalent,
    TranslationVerdict.needsReview => l10n.systemCommentNeedsReview,
    TranslationVerdict.canonicalDrift => l10n.systemCommentDrift,
  });

  final List<MapEntry<String, List<String>>> groups =
      <MapEntry<String, List<String>>>[
        MapEntry<String, List<String>>(l10n.meaning, audit.meaningFindings),
        MapEntry<String, List<String>>(
          l10n.terminology,
          audit.terminologyFindings,
        ),
        MapEntry<String, List<String>>(l10n.style, audit.styleFindings),
        MapEntry<String, List<String>>(l10n.ambiguity, audit.ambiguityFindings),
      ];

  for (final MapEntry<String, List<String>> group in groups) {
    if (group.value.isEmpty) {
      continue;
    }

    buffer
      ..writeln()
      ..writeln();

    for (int index = 0; index < group.value.length; index += 1) {
      if (index == 0) {
        buffer.write('${group.key}: ${group.value[index]}');
      } else {
        buffer.write(' ${group.value[index]}');
      }
    }
  }

  buffer
    ..writeln()
    ..writeln()
    ..write(l10n.systemCommentEvidenceNote);

  return buffer.toString();
}
