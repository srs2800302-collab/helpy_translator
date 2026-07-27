import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/registry_studio_localizations.dart';
import '../application/translator_access_key_store.dart';
import '../application/translator_draft_store.dart';
import '../application/translator_provider.dart';
import '../domain/translator_models.dart';
import 'translator_cubit.dart';

final class TranslatorWorkspaceController {
  VoidCallback? _openAccessKeyDialog;

  void openAccessKeyDialog() {
    _openAccessKeyDialog?.call();
  }

  void attachAccessKeyDialog(VoidCallback callback) {
    _openAccessKeyDialog = callback;
  }

  void detachAccessKeyDialog() {
    _openAccessKeyDialog = null;
  }
}

final class TranslatorWorkspaceView extends StatelessWidget {
  const TranslatorWorkspaceView({
    required this.provider,
    required this.draftStore,
    required this.accessKeyStore,
    this.controller,
    super.key,
  });

  final TranslatorProvider provider;
  final TranslatorDraftStore draftStore;
  final TranslatorAccessKeyStore accessKeyStore;
  final TranslatorWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TranslatorCubit>(
      create: (_) =>
          TranslatorCubit(provider: provider, draftStore: draftStore)
            ..restore(),
      child: _TranslatorWorkspaceBody(
        accessKeyStore: accessKeyStore,
        controller: controller,
      ),
    );
  }
}

final class _TranslatorWorkspaceBody extends StatefulWidget {
  const _TranslatorWorkspaceBody({
    required this.accessKeyStore,
    required this.controller,
  });

  final TranslatorAccessKeyStore accessKeyStore;
  final TranslatorWorkspaceController? controller;

  @override
  State<_TranslatorWorkspaceBody> createState() =>
      _TranslatorWorkspaceBodyState();
}

final class _TranslatorWorkspaceBodyState
    extends State<_TranslatorWorkspaceBody> {
  late final TextEditingController _sourceController;
  late final TextEditingController _apiKeyController;

  bool _accessKeyRestoring = true;
  String? _accessKeyStorageWarning;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController();
    _apiKeyController = TextEditingController();
    widget.controller?.attachAccessKeyDialog(_openAccessKeyDialog);
    unawaited(_restoreAccessKey());
  }

  @override
  void didUpdateWidget(covariant _TranslatorWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller?.detachAccessKeyDialog();
    widget.controller?.attachAccessKeyDialog(_openAccessKeyDialog);
  }

  Future<void> _restoreAccessKey() async {
    try {
      final String? accessKey = await widget.accessKeyStore.load();

      if (!mounted) {
        return;
      }

      final String restoredAccessKey = accessKey ?? '';

      _apiKeyController.value = TextEditingValue(
        text: restoredAccessKey,
        selection: TextSelection.collapsed(offset: restoredAccessKey.length),
      );

      setState(() {
        _accessKeyRestoring = false;
        _accessKeyStorageWarning = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accessKeyRestoring = false;
        _accessKeyStorageWarning = context.rsL10n.apiKeyRestoreFailure;
      });
    }
  }

  Future<void> _persistAccessKey(String accessKey) async {
    try {
      if (accessKey.isEmpty) {
        await widget.accessKeyStore.clear();
      } else {
        await widget.accessKeyStore.save(accessKey);
      }

      if (mounted && _accessKeyStorageWarning != null) {
        setState(() {
          _accessKeyStorageWarning = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accessKeyStorageWarning = context.rsL10n.apiKeySaveFailure;
      });
    }
  }

  Future<void> _deleteSavedAccessKey() async {
    try {
      await widget.accessKeyStore.clear();
      _apiKeyController.clear();

      if (mounted) {
        setState(() {
          _accessKeyStorageWarning = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _accessKeyStorageWarning = context.rsL10n.apiKeyDeleteFailure;
      });
    }
  }

  void _openAccessKeyDialog() {
    unawaited(_showAccessKeyDialog());
  }

  Future<void> _showAccessKeyDialog() async {
    if (!mounted) {
      return;
    }

    final RegistryStudioLocalizations l10n = context.rsL10n;
    final _AccessKeyDialogResult? result =
        await showDialog<_AccessKeyDialogResult>(
          context: context,
          builder: (_) {
            return _AccessKeyDialog(
              initialAccessKey: _apiKeyController.text,
              accessKeyRestoring: _accessKeyRestoring,
              accessKeyStorageWarning: _accessKeyStorageWarning,
              l10n: l10n,
            );
          },
        );

    if (!mounted || result == null) {
      return;
    }

    if (result.action == _AccessKeyDialogAction.delete) {
      await _deleteSavedAccessKey();
      return;
    }

    final String accessKey = result.accessKey ?? '';
    _apiKeyController.value = TextEditingValue(
      text: accessKey,
      selection: TextSelection.collapsed(offset: accessKey.length),
    );

    await _persistAccessKey(accessKey);
  }

  @override
  void dispose() {
    widget.controller?.detachAccessKeyDialog();
    _sourceController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return BlocConsumer<TranslatorCubit, TranslatorState>(
      listenWhen: (TranslatorState previous, TranslatorState current) =>
          previous.sourceText != current.sourceText,
      listener: (BuildContext context, TranslatorState state) {
        if (_sourceController.text != state.sourceText) {
          _sourceController.value = TextEditingValue(
            text: state.sourceText,
            selection: TextSelection.collapsed(offset: state.sourceText.length),
          );
        }
      },
      builder: (BuildContext context, TranslatorState state) {
        if (state.status == TranslatorViewStatus.restoring) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: <Widget>[
              _buildSourceCard(context, state, l10n),
              const SizedBox(height: 12),
              _buildActions(context, state, l10n),
              if (_accessKeyStorageWarning != null) ...<Widget>[
                const SizedBox(height: 12),
                _MessageCard(
                  title: l10n.apiKeySettings,
                  message: _accessKeyStorageWarning!,
                  icon: Icons.warning_amber_outlined,
                ),
              ],
              if (state.restoreWarning != null) ...<Widget>[
                const SizedBox(height: 12),
                _MessageCard(
                  title: l10n.restoreWarning,
                  message: state.restoreWarning!,
                  icon: Icons.warning_amber_outlined,
                ),
              ],
              if (state.isRunning) ...<Widget>[
                const SizedBox(height: 16),
                _ProgressCard(stage: state.stage),
              ],
              if (state.failure != null) ...<Widget>[
                const SizedBox(height: 16),
                _FailureCard(failure: state.failure!),
              ],
              if (state.report != null) ...<Widget>[
                const SizedBox(height: 16),
                _TranslationReportView(report: state.report!),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceCard(
    BuildContext context,
    TranslatorState state,
    RegistryStudioLocalizations l10n,
  ) {
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
                  selectedLanguage: state.sourceLanguageHint,
                  enabled: !state.isRunning,
                  onSelected: (TranslationLanguage? selectedLanguage) {
                    context.read<TranslatorCubit>().selectSourceLanguage(
                      selectedLanguage,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('translator-source-text-field'),
              controller: _sourceController,
              enabled: !state.isRunning,
              minLines: 3,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.sourceTextFieldLabel,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (String value) {
                context.read<TranslatorCubit>().updateSourceText(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    TranslatorState state,
    RegistryStudioLocalizations l10n,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        FilledButton(
          key: const ValueKey<String>('translator-run-button'),
          onPressed: state.isRunning || _accessKeyRestoring
              ? null
              : () async {
                  FocusScope.of(context).unfocus();

                  await context.read<TranslatorCubit>().translate(
                    accessKey: _apiKeyController.text,
                  );
                },
          child: Text(
            state.status == TranslatorViewStatus.failure
                ? l10n.retry
                : l10n.translateAndCheck,
          ),
        ),
        if (state.isRunning)
          OutlinedButton.icon(
            onPressed: () {
              context.read<TranslatorCubit>().cancel();
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.cancel),
          ),
        OutlinedButton.icon(
          onPressed: state.isRunning
              ? null
              : () {
                  context.read<TranslatorCubit>().clear();
                },
          icon: const Icon(Icons.clear),
          label: Text(l10n.clearTranslator),
        ),
      ],
    );
  }
}

enum _AccessKeyDialogAction { save, delete }

final class _AccessKeyDialogResult {
  const _AccessKeyDialogResult({required this.action, this.accessKey});

  final _AccessKeyDialogAction action;
  final String? accessKey;
}

final class _AccessKeyDialog extends StatefulWidget {
  const _AccessKeyDialog({
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
  State<_AccessKeyDialog> createState() => _AccessKeyDialogState();
}

final class _AccessKeyDialogState extends State<_AccessKeyDialog> {
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
                    const _AccessKeyDialogResult(
                      action: _AccessKeyDialogAction.delete,
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
                    _AccessKeyDialogResult(
                      action: _AccessKeyDialogAction.save,
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

final class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.stage});

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

final class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure});

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

final class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.icon,
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

final class _TranslationReportView extends StatelessWidget {
  const _TranslationReportView({required this.report});

  final TranslatorRunReport report;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationBundle bundle = report.bundle;
    final TranslationAudit audit = report.audit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _VerdictCard(audit: audit),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.directTranslation,
          entries: <MapEntry<String, String>>[
            MapEntry<String, String>(
              '${bundle.sourceLanguage.code} · SOURCE TEXT',
              bundle.sourceText,
            ),
            MapEntry<String, String>('RU', bundle.ru),
            MapEntry<String, String>('EN', bundle.en),
            MapEntry<String, String>('TH', bundle.th),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: l10n.reverseCheck,
          entries: <MapEntry<String, String>>[
            MapEntry<String, String>('EN → RU', bundle.enToRu),
            MapEntry<String, String>('TH → RU', bundle.thToRu),
            MapEntry<String, String>('EN → TH', bundle.enToTh),
            MapEntry<String, String>('TH → EN', bundle.thToEn),
          ],
        ),
        const SizedBox(height: 12),
        _AuditFindingsCard(audit: audit),
      ],
    );
  }
}

final class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslationVerdict verdict = audit.verdict;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color background = switch (verdict) {
      TranslationVerdict.exact => colors.primaryContainer,
      TranslationVerdict.equivalent => colors.secondaryContainer,
      TranslationVerdict.needsReview => colors.tertiaryContainer,
      TranslationVerdict.canonicalDrift => colors.errorContainer,
    };

    return Card(
      color: background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              l10n.automaticVerdict,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _verdictLabel(verdict),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _BooleanEvidenceRow(
              label: l10n.meaningPreserved,
              value: audit.meaningPreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.terminologyPreserved,
              value: audit.terminologyPreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.canonicalStylePreserved,
              value: audit.canonicalStylePreserved,
            ),
            _BooleanEvidenceRow(
              label: l10n.ambiguousWording,
              value: audit.ambiguousWording,
              positiveMeansGood: false,
            ),
            const SizedBox(height: 8),
            Text(l10n.verdictEngineerNotice, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

final class _BooleanEvidenceRow extends StatelessWidget {
  const _BooleanEvidenceRow({
    required this.label,
    required this.value,
    this.positiveMeansGood = true,
  });

  final String label;
  final bool value;
  final bool positiveMeansGood;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final bool good = positiveMeansGood ? value : !value;

    return Row(
      children: <Widget>[
        Icon(good ? Icons.check_circle_outline : Icons.warning_amber, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value ? l10n.yes : l10n.no),
      ],
    );
  }
}

final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.entries});

  final String title;
  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            for (final MapEntry<String, String> entry in entries) ...<Widget>[
              const Divider(height: 24),
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              SelectableText(entry.value),
            ],
          ],
        ),
      ),
    );
  }
}

final class _AuditFindingsCard extends StatelessWidget {
  const _AuditFindingsCard({required this.audit});

  final TranslationAudit audit;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.auditAndDiagnostics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _FindingGroup(title: l10n.meaning, findings: audit.meaningFindings),
            _FindingGroup(
              title: l10n.terminology,
              findings: audit.terminologyFindings,
            ),
            _FindingGroup(
              title: l10n.canonicalStyle,
              findings: audit.styleFindings,
            ),
            _FindingGroup(
              title: l10n.ambiguity,
              findings: audit.ambiguityFindings,
            ),
          ],
        ),
      ),
    );
  }
}

final class _FindingGroup extends StatelessWidget {
  const _FindingGroup({required this.title, required this.findings});

  final String title;
  final List<String> findings;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (findings.isEmpty)
            Text(l10n.noViolations)
          else
            for (final String finding in findings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $finding'),
              ),
        ],
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

String _verdictLabel(TranslationVerdict verdict) {
  return switch (verdict) {
    TranslationVerdict.exact => 'EXACT',
    TranslationVerdict.equivalent => 'EQUIVALENT',
    TranslationVerdict.needsReview => 'NEEDS REVIEW',
    TranslationVerdict.canonicalDrift => 'CANONICAL DRIFT',
  };
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
