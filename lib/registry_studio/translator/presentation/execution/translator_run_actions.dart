import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../application/translator_state.dart';

final class TranslatorRunActions extends StatelessWidget {
  const TranslatorRunActions({
    required this.status,
    required this.isRunning,
    required this.accessKeyRestoring,
    required this.retryAuditOnly,
    required this.onRun,
    super.key,
  });

  final TranslatorViewStatus status;
  final bool isRunning;
  final bool accessKeyRestoring;
  final bool retryAuditOnly;
  final Future<void> Function() onRun;

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
            retryAuditOnly
                ? l10n.retrySemanticAudit
                : status == TranslatorViewStatus.failure
                ? l10n.retry
                : l10n.translateAndCheck,
          ),
        ),
      ],
    );
  }
}
