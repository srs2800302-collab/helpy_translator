import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../application/translator_state.dart';

final class TranslatorRunActions extends StatelessWidget {
  const TranslatorRunActions({
    required this.status,
    required this.isRunning,
    required this.accessKeyRestoring,
    required this.onRun,
    required this.onCancel,
    required this.onClear,
    super.key,
  });

  final TranslatorViewStatus status;
  final bool isRunning;
  final bool accessKeyRestoring;
  final Future<void> Function() onRun;
  final VoidCallback onCancel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        FilledButton(
          key: const ValueKey<String>('translator-run-button'),
          onPressed: isRunning || accessKeyRestoring
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  await onRun();
                },
          child: Text(
            status == TranslatorViewStatus.failure
                ? l10n.retry
                : l10n.translateAndCheck,
          ),
        ),
        if (isRunning)
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.cancel),
          ),
        OutlinedButton.icon(
          onPressed: isRunning ? null : onClear,
          icon: const Icon(Icons.clear),
          label: Text(l10n.clearTranslator),
        ),
      ],
    );
  }
}
