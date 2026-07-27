import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';

final class TranslatorProgressCard extends StatelessWidget {
  const TranslatorProgressCard({required this.stage, super.key});

  final TranslatorRunStage? stage;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String label = switch (stage) {
      TranslatorRunStage.directTranslation => l10n.directTranslationStage,
      TranslatorRunStage.reverseTranslation => l10n.reverseTranslationStage,
      TranslatorRunStage.audit => l10n.auditStage,
      null => l10n.preparingTranslation,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

final class TranslatorFailureCard extends StatelessWidget {
  const TranslatorFailureCard({required this.failure, super.key});

  final TranslatorFailure failure;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final bool incomplete =
        failure.completeness == TranslationCompleteness.translationIncomplete;

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _failureTitle(l10n, failure, incomplete: incomplete),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(failure.message),
            const SizedBox(height: 8),
            Text(
              l10n.stageLabel(_failureStageLabel(l10n, failure.stage)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (failure.partialBundle != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(l10n.partialResultSaved),
            ],
          ],
        ),
      ),
    );
  }
}

final class TranslatorMessageCard extends StatelessWidget {
  const TranslatorMessageCard({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _failureTitle(
  RegistryStudioLocalizations l10n,
  TranslatorFailure failure, {
  required bool incomplete,
}) {
  if (incomplete) {
    return l10n.incompleteTranslation;
  }
  if (failure.code == TranslatorFailureCode.cancelled) {
    return l10n.translationCancelled;
  }
  if (failure.stage == TranslatorFailureStage.validation) {
    return l10n.checkInput;
  }
  return l10n.translatorTechnicalError;
}

String _failureStageLabel(
  RegistryStudioLocalizations l10n,
  TranslatorFailureStage stage,
) {
  return switch (stage) {
    TranslatorFailureStage.validation => l10n.validationStage,
    TranslatorFailureStage.directTranslation => l10n.directStage,
    TranslatorFailureStage.reverseTranslation => l10n.reverseStage,
    TranslatorFailureStage.audit => l10n.semanticAuditStage,
    TranslatorFailureStage.transport => l10n.typhoonApiStage,
  };
}
