import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/registry_studio_localizations.dart';
import '../application/translator_access_key_cubit.dart';
import '../application/translator_cubit.dart';
import '../domain/translator_models.dart';
import 'access_key/translator_access_key_dialog.dart';
import 'execution/translator_run_actions.dart';
import 'history/translator_history_card.dart';
import 'report/translator_report_view.dart';
import 'source/translator_source_panel.dart';
import 'status/translator_status_cards.dart';
import 'translator_workspace_controller.dart';

final class TranslatorWorkspaceBody extends StatefulWidget {
  const TranslatorWorkspaceBody({required this.controller, super.key});

  final TranslatorWorkspaceController? controller;

  @override
  State<TranslatorWorkspaceBody> createState() =>
      _TranslatorWorkspaceBodyState();
}

final class _TranslatorWorkspaceBodyState
    extends State<TranslatorWorkspaceBody> {
  late final TextEditingController _sourceController;
  String? _expandedHistoryEntryId;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController();
    widget.controller?.attachAccessKeyDialog(_openAccessKeyDialog);
  }

  @override
  void didUpdateWidget(covariant TranslatorWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller?.detachAccessKeyDialog();
    widget.controller?.attachAccessKeyDialog(_openAccessKeyDialog);
  }

  void _openAccessKeyDialog() {
    unawaited(_showAccessKeyDialog());
  }

  Future<void> _showAccessKeyDialog() async {
    if (!mounted) {
      return;
    }

    final TranslatorAccessKeyCubit accessKeyCubit = context
        .read<TranslatorAccessKeyCubit>();
    final TranslatorAccessKeyState accessKeyState = accessKeyCubit.state;
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final TranslatorAccessKeyDialogResult? result =
        await showTranslatorAccessKeyDialog(
          context: context,
          initialAccessKey: accessKeyState.accessKey,
          accessKeyRestoring: accessKeyState.isRestoring,
          accessKeyStorageWarning: _accessKeyFailureMessage(
            l10n,
            accessKeyState.failure,
          ),
        );

    if (!mounted || result == null) {
      return;
    }

    if (result.action == TranslatorAccessKeyDialogAction.save) {
      await accessKeyCubit.save(result.accessKey ?? '');
      return;
    }

    await accessKeyCubit.delete();
  }

  Future<void> _copyHistoryEntry(TranslatorHistoryEntry entry) async {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    await Clipboard.setData(
      ClipboardData(text: buildTranslatorHistoryClipboardText(entry, l10n)),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.translationCopied)));
  }

  Future<void> _deleteHistoryEntry(TranslatorHistoryEntry entry) async {
    await context.read<TranslatorCubit>().deleteHistoryEntry(entry.id);

    if (mounted && _expandedHistoryEntryId == entry.id) {
      setState(() {
        _expandedHistoryEntryId = null;
      });
    }
  }

  Future<void> _confirmClearHistory() async {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteAllTranslationsTitle),
          content: Text(l10n.deleteAllTranslationsMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const ValueKey<String>(
                'translator-history-clear-all-confirm',
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<TranslatorCubit>().clearHistory();

    if (mounted) {
      setState(() {
        _expandedHistoryEntryId = null;
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.detachAccessKeyDialog();
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TranslatorCubit, TranslatorState>(
      listenWhen: (TranslatorState previous, TranslatorState current) =>
          previous.sourceText != current.sourceText,
      listener: (BuildContext context, TranslatorState state) {
        if (_sourceController.text == state.sourceText) {
          return;
        }

        _sourceController.value = TextEditingValue(
          text: state.sourceText,
          selection: TextSelection.collapsed(offset: state.sourceText.length),
        );
      },
      builder: (BuildContext context, TranslatorState state) {
        if (state.status == TranslatorViewStatus.restoring) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<TranslatorAccessKeyCubit, TranslatorAccessKeyState>(
          builder:
              (BuildContext context, TranslatorAccessKeyState accessKeyState) {
                return _buildWorkspace(context, state, accessKeyState);
              },
        );
      },
    );
  }

  Widget _buildWorkspace(
    BuildContext context,
    TranslatorState state,
    TranslatorAccessKeyState accessKeyState,
  ) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String? accessKeyWarning = _accessKeyFailureMessage(
      l10n,
      accessKeyState.failure,
    );
    final List<Widget> top = <Widget>[
      TranslatorSourcePanel(
        controller: _sourceController,
        enabled: !state.isRunning,
        onSourceTextChanged: (String value) {
          context.read<TranslatorCubit>().updateSourceText(value);
        },
      ),
      const SizedBox(height: 12),
      TranslatorRunActions(
        status: state.status,
        isRunning: state.isRunning,
        accessKeyRestoring: accessKeyState.isRestoring,
        retryAuditOnly: state.canRetryAudit,
        onRun: () {
          final TranslatorCubit cubit = context.read<TranslatorCubit>();

          if (state.canRetryAudit) {
            return cubit.retryAudit(accessKey: accessKeyState.accessKey);
          }

          return cubit.translate(accessKey: accessKeyState.accessKey);
        },
        onCancel: () {
          context.read<TranslatorCubit>().cancel();
        },
        onClear: () {
          context.read<TranslatorCubit>().clear();
        },
      ),
      if (accessKeyWarning != null) ...<Widget>[
        const SizedBox(height: 12),
        TranslatorMessageCard(
          title: l10n.apiKeySettings,
          message: accessKeyWarning,
          icon: Icons.warning_amber_outlined,
        ),
      ],
      if (state.restoreWarning != null) ...<Widget>[
        const SizedBox(height: 12),
        TranslatorMessageCard(
          title: l10n.restoreWarning,
          message: state.restoreWarning!,
          icon: Icons.warning_amber_outlined,
        ),
      ],
      if (state.historyWarning != null) ...<Widget>[
        const SizedBox(height: 12),
        TranslatorMessageCard(
          title: l10n.historyWarning,
          message: state.historyWarning!,
          icon: Icons.warning_amber_outlined,
        ),
      ],
      if (state.isRunning) ...<Widget>[
        const SizedBox(height: 16),
        TranslatorProgressCard(stage: state.stage),
      ],
      if (state.partialBundle != null && state.report == null) ...<Widget>[
        const SizedBox(height: 16),
        TranslatorPartialBundleView(bundle: state.partialBundle!),
      ],
      if (state.failure != null) ...<Widget>[
        const SizedBox(height: 16),
        TranslatorFailureCard(failure: state.failure!),
      ],
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(delegate: SliverChildListDelegate.fixed(top)),
          ),
          if (state.history.isNotEmpty) ...<Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: TranslatorHistoryHeader(
                  entryCount: state.history.length,
                  onClearAll: _confirmClearHistory,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((
                  BuildContext context,
                  int index,
                ) {
                  final TranslatorHistoryEntry entry = state.history[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TranslatorHistoryCard(
                      entry: entry,
                      expanded: _expandedHistoryEntryId == entry.id,
                      onToggle: () {
                        setState(() {
                          _expandedHistoryEntryId =
                              _expandedHistoryEntryId == entry.id
                              ? null
                              : entry.id;
                        });
                      },
                      onCopy: () {
                        unawaited(_copyHistoryEntry(entry));
                      },
                      onDelete: () {
                        unawaited(_deleteHistoryEntry(entry));
                      },
                    ),
                  );
                }, childCount: state.history.length),
              ),
            ),
          ] else
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

String? _accessKeyFailureMessage(
  RegistryStudioLocalizations l10n,
  TranslatorAccessKeyFailure? failure,
) {
  return switch (failure) {
    TranslatorAccessKeyFailure.restore => l10n.apiKeyRestoreFailure,
    TranslatorAccessKeyFailure.save => l10n.apiKeySaveFailure,
    TranslatorAccessKeyFailure.delete => l10n.apiKeyDeleteFailure,
    null => null,
  };
}
