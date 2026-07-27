import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';

Future<TranslatorAccessKeyDialogResult?> showTranslatorAccessKeyDialog({
  required BuildContext context,
  required String initialAccessKey,
  required bool accessKeyRestoring,
  required String? accessKeyStorageWarning,
}) {
  final RegistryStudioLocalizations l10n = context.rsL10n;

  return showDialog<TranslatorAccessKeyDialogResult>(
    context: context,
    builder: (_) {
      return _TranslatorAccessKeyDialog(
        initialAccessKey: initialAccessKey,
        accessKeyRestoring: accessKeyRestoring,
        accessKeyStorageWarning: accessKeyStorageWarning,
        l10n: l10n,
      );
    },
  );
}

enum TranslatorAccessKeyDialogAction { save, delete }

final class TranslatorAccessKeyDialogResult {
  const TranslatorAccessKeyDialogResult({required this.action, this.accessKey});

  final TranslatorAccessKeyDialogAction action;
  final String? accessKey;
}

final class _TranslatorAccessKeyDialog extends StatefulWidget {
  const _TranslatorAccessKeyDialog({
    required this.initialAccessKey,
    required this.accessKeyRestoring,
    required this.accessKeyStorageWarning,
    required this.l10n,
  });

  final String initialAccessKey;
  final bool accessKeyRestoring;
  final String? accessKeyStorageWarning;
  final RegistryStudioLocalizations l10n;

  @override
  State<_TranslatorAccessKeyDialog> createState() =>
      _TranslatorAccessKeyDialogState();
}

final class _TranslatorAccessKeyDialogState
    extends State<_TranslatorAccessKeyDialog> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAccessKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey<String>('translator-access-key-dialog'),
      title: Text(widget.l10n.apiKeySettings),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const ValueKey<String>('translator-access-key-dialog-field'),
              controller: _controller,
              enabled: !widget.accessKeyRestoring,
              obscureText: _obscureText,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: widget.l10n.apiKey,
                helperText: widget.accessKeyRestoring
                    ? widget.l10n.restoringSavedKey
                    : widget.l10n.apiKeyEncryptedOnDevice,
                errorText: widget.accessKeyStorageWarning,
                prefixIcon: const Icon(Icons.key_outlined),
                suffixIcon: IconButton(
                  tooltip: _obscureText
                      ? widget.l10n.showKey
                      : widget.l10n.hideKey,
                  onPressed: widget.accessKeyRestoring
                      ? null
                      : () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('translator-access-key-dialog-delete'),
          onPressed: widget.accessKeyRestoring
              ? null
              : () {
                  Navigator.of(context).pop(
                    const TranslatorAccessKeyDialogResult(
                      action: TranslatorAccessKeyDialogAction.delete,
                    ),
                  );
                },
          child: Text(widget.l10n.deleteSavedKey),
        ),
        TextButton(
          key: const ValueKey<String>('translator-access-key-dialog-close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(widget.l10n.close),
        ),
        FilledButton(
          key: const ValueKey<String>('translator-access-key-dialog-save'),
          onPressed: widget.accessKeyRestoring
              ? null
              : () {
                  Navigator.of(context).pop(
                    TranslatorAccessKeyDialogResult(
                      action: TranslatorAccessKeyDialogAction.save,
                      accessKey: _controller.text,
                    ),
                  );
                },
          child: Text(widget.l10n.save),
        ),
      ],
    );
  }
}
