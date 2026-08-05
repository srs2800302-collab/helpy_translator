import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../application/translator_progress.dart';

final class TranslatorProgressCard extends StatelessWidget {
  const TranslatorProgressCard({required this.progress, super.key});

  final TranslatorProgress? progress;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslatorProgress? current = progress;
    final String title;

    if (current == null ||
        current.stage == TranslatorProgressStage.validating) {
      title = l10n.preparingTranslation;
    } else if (current.stage == TranslatorProgressStage.auditing) {
      title = l10n.auditingMatrix;
    } else if (current.currentRouteId != null) {
      title = l10n.translatingRoute(current.currentRouteId!);
    } else {
      title = l10n.preparingTranslation;
    }

    final int completed = current?.completedSteps ?? 0;
    final int total = current?.totalSteps ?? 0;

    return Card(
      key: const ValueKey<String>('translator-progress-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total <= 0 ? null : current?.fraction,
            ),
            if (total > 0) ...<Widget>[
              const SizedBox(height: 8),
              Text(l10n.progressCount(completed, total)),
            ],
          ],
        ),
      ),
    );
  }
}
