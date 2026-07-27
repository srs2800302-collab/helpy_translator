import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';

final class TranslatorSourcePanel extends StatelessWidget {
  const TranslatorSourcePanel({
    required this.controller,
    required this.enabled,
    required this.onSourceTextChanged,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSourceTextChanged;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.sourceText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('translator-source-text-field'),
              controller: controller,
              enabled: enabled,
              minLines: 5,
              maxLines: 12,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.sourceTextFieldLabel,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: onSourceTextChanged,
            ),
          ],
        ),
      ),
    );
  }
}
