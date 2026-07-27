import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/localization/registry_studio_localizations.dart';
import '../application/translator_access_key_cubit.dart';
import '../application/translator_access_key_store.dart';
import '../application/translator_cubit.dart';
import '../application/translator_draft_store.dart';
import '../application/translator_provider.dart';
import 'access_key/translator_access_key_dialog.dart';
import 'execution/translator_run_actions.dart';
import 'report/translator_report_view.dart';
import 'source/translator_source_panel.dart';
import 'status/translator_status_cards.dart';

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<TranslatorCubit>(
          create: (_) =>
              TranslatorCubit(provider: provider, draftStore: draftStore)
                ..restore(),
        ),
        BlocProvider<TranslatorAccessKeyCubit>(
          create: (_) =>
              TranslatorAccessKeyCubit(store: accessKeyStore)..restore(),
        ),
      ],
      child: _TranslatorWorkspaceBody(controller: controller),
    );
  }
}

final class _TranslatorWorkspaceBody extends StatefulWidget {
  const _TranslatorWorkspaceBody({required this.controller});

  final TranslatorWorkspaceController? controller;

  @override
  State<_TranslatorWorkspaceBody> createState() =>
      _TranslatorWorkspaceBodyState();
}

final class _TranslatorWorkspaceBodyState
    extends State<_TranslatorWorkspaceBody> {
  late final TextEditingController _sourceController;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController();
    widget.controller?.attachAccessKeyDialog(_openAccessKeyDialog);
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
                final RegistryStudioLocalizations l10n = context.rsL10n;
                final String? accessKeyWarning = _accessKeyFailureMessage(
                  l10n,
                  accessKeyState.failure,
                );

                return SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: <Widget>[
                      TranslatorSourcePanel(
                        controller: _sourceController,
                        enabled: !state.isRunning,
                        onSourceTextChanged: (String value) {
                          context.read<TranslatorCubit>().updateSourceText(
                            value,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TranslatorRunActions(
                        status: state.status,
                        isRunning: state.isRunning,
                        accessKeyRestoring: accessKeyState.isRestoring,
                        onRun: () {
                          return context.read<TranslatorCubit>().translate(
                            accessKey: accessKeyState.accessKey,
                          );
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
                      if (state.isRunning) ...<Widget>[
                        const SizedBox(height: 16),
                        TranslatorProgressCard(stage: state.stage),
                      ],
                      if (state.failure != null) ...<Widget>[
                        const SizedBox(height: 16),
                        TranslatorFailureCard(failure: state.failure!),
                      ],
                      if (state.report != null) ...<Widget>[
                        const SizedBox(height: 16),
                        TranslatorReportView(report: state.report!),
                      ],
                    ],
                  ),
                );
              },
        );
      },
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
