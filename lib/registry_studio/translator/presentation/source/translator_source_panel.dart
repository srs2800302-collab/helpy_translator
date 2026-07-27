import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/translator_models.dart';

final class TranslatorSourcePanel extends StatelessWidget {
  const TranslatorSourcePanel({
    required this.controller,
    required this.selectedLanguage,
    required this.enabled,
    required this.onSourceTextChanged,
    required this.onSourceLanguageSelected,
    super.key,
  });

  final TextEditingController controller;
  final TranslationLanguage? selectedLanguage;
  final bool enabled;
  final ValueChanged<String> onSourceTextChanged;
  final ValueChanged<TranslationLanguage?> onSourceLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.sourceText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _SourceLanguageMenu(
                  selectedLanguage: selectedLanguage,
                  enabled: enabled,
                  onSelected: onSourceLanguageSelected,
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('translator-source-text-field'),
              controller: controller,
              enabled: enabled,
              minLines: 3,
              maxLines: 10,
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

enum _SourceLanguageSelection { automatic, ru, en, th }

final class _SourceLanguageMenu extends StatelessWidget {
  const _SourceLanguageMenu({
    required this.selectedLanguage,
    required this.enabled,
    required this.onSelected,
  });

  final TranslationLanguage? selectedLanguage;
  final bool enabled;
  final ValueChanged<TranslationLanguage?> onSelected;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return PopupMenuButton<_SourceLanguageSelection>(
      key: const ValueKey<String>('translator-source-language-menu'),
      enabled: enabled,
      tooltip: l10n.sourceLanguage,
      onSelected: (_SourceLanguageSelection selection) {
        onSelected(switch (selection) {
          _SourceLanguageSelection.automatic => null,
          _SourceLanguageSelection.ru => TranslationLanguage.ru,
          _SourceLanguageSelection.en => TranslationLanguage.en,
          _SourceLanguageSelection.th => TranslationLanguage.th,
        });
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<_SourceLanguageSelection>>[
          PopupMenuItem<_SourceLanguageSelection>(
            value: _SourceLanguageSelection.automatic,
            child: Text(l10n.detectAutomatically),
          ),
          const PopupMenuItem<_SourceLanguageSelection>(
            value: _SourceLanguageSelection.ru,
            child: Text('RU'),
          ),
          const PopupMenuItem<_SourceLanguageSelection>(
            value: _SourceLanguageSelection.en,
            child: Text('EN'),
          ),
          const PopupMenuItem<_SourceLanguageSelection>(
            value: _SourceLanguageSelection.th,
            child: Text('TH'),
          ),
        ];
      },
      child: Semantics(
        button: true,
        label: l10n.sourceLanguage,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.language_outlined),
              const SizedBox(width: 6),
              Text(selectedLanguage?.code ?? l10n.automaticShort),
              const SizedBox(width: 2),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
