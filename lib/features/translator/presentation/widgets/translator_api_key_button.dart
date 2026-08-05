import 'package:flutter/material.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/repositories/translator_api_key_store.dart';

final class TranslatorApiKeyButton extends StatelessWidget {
  const TranslatorApiKeyButton({required this.apiKeyStore, super.key});

  final TranslatorApiKeyStore apiKeyStore;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return IconButton(
      key: const ValueKey<String>('translator-access-key-app-bar-button'),
      tooltip: l10n.apiKeySettings,
      onPressed: () {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return _TranslatorApiKeyDialog(apiKeyStore: apiKeyStore);
          },
        );
      },
      icon: Icon(
        Icons.key_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

final class _TranslatorApiKeyDialog extends StatefulWidget {
  const _TranslatorApiKeyDialog({required this.apiKeyStore});

  final TranslatorApiKeyStore apiKeyStore;

  @override
  State<_TranslatorApiKeyDialog> createState() =>
      _TranslatorApiKeyDialogState();
}

final class _TranslatorApiKeyDialogState
    extends State<_TranslatorApiKeyDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _obscureText = true;
  bool _restoreFailed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    try {
      final String? apiKey = await widget.apiKeyStore.read();

      if (!mounted) {
        return;
      }

      _controller.text = apiKey ?? '';
      setState(() {
        _loading = false;
      });
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _restoreFailed = true;
      });
    }
  }

  Future<void> _save() async {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String apiKey = _controller.text.trim();

    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = l10n.apiKeyRequired;
      });
      return;
    }

    setState(() {
      _saving = true;
      _restoreFailed = false;
      _errorMessage = null;
    });

    try {
      await widget.apiKeyStore.write(apiKey);

      if (!mounted) {
        return;
      }

      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.apiKeySaved)));
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = l10n.apiKeySaveFailure;
      });
    }
  }

  Future<void> _delete() async {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    setState(() {
      _saving = true;
      _restoreFailed = false;
      _errorMessage = null;
    });

    try {
      await widget.apiKeyStore.delete();

      if (!mounted) {
        return;
      }

      _controller.clear();
      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.apiKeyDeleted)));
    } on Object {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = l10n.apiKeyDeleteFailure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String? displayedError = _restoreFailed
        ? l10n.apiKeyRestoreFailure
        : _errorMessage;

    return AlertDialog(
      key: const ValueKey<String>('translator-api-key-dialog'),
      title: Text(l10n.apiKeySettings),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Flexible(child: Text(l10n.restoringSavedKey)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    key: const ValueKey<String>(
                      'translator-api-key-text-field',
                    ),
                    controller: _controller,
                    enabled: !_saving,
                    obscureText: _obscureText,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: l10n.apiKey,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        key: const ValueKey<String>(
                          'translator-api-key-visibility-button',
                        ),
                        tooltip: _obscureText ? l10n.showKey : l10n.hideKey,
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (!_saving) {
                        _save();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.apiKeyEncryptedOnDevice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (displayedError != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      displayedError,
                      key: const ValueKey<String>('translator-api-key-error'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const ValueKey<String>(
                      'translator-api-key-delete-button',
                    ),
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteSavedKey),
                  ),
                ],
              ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('translator-api-key-close-button'),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        FilledButton(
          key: const ValueKey<String>('translator-api-key-save-button'),
          onPressed: _loading || _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
