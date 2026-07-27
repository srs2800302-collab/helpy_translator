import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registry_studio/maintenance/analysis/application/registry_snapshot_comparator.dart';
import '../../registry_studio/maintenance/history/application/contracts/registry_analysis_history_store.dart';
import '../../registry_studio/registry/application/contracts/registry_revision_state_store.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_refresh_loader.dart';
import '../../registry_studio/registry/application/contracts/registry_snapshot_revision_loader.dart';
import '../../registry_studio/registry/presentation/registry_explorer_view.dart';
import '../../registry_studio/translator/presentation/translator_workspace_view.dart';
import '../localization/registry_studio_locale_cubit.dart';
import '../localization/registry_studio_localizations.dart';

enum RegistryStudioWorkspace { registryStudio, translator }

final class RegistryStudioWorkspaceCubit
    extends Cubit<RegistryStudioWorkspace> {
  RegistryStudioWorkspaceCubit()
    : super(RegistryStudioWorkspace.registryStudio);

  void select(RegistryStudioWorkspace workspace) {
    if (state == workspace) {
      return;
    }

    emit(workspace);
  }
}

final class RegistryStudioShell extends StatelessWidget {
  const RegistryStudioShell({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
    this.translatorWorkspace,
    this.translatorWorkspaceController,
    super.key,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;
  final Widget? translatorWorkspace;
  final TranslatorWorkspaceController? translatorWorkspaceController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegistryStudioWorkspaceCubit>(
      create: (_) => RegistryStudioWorkspaceCubit(),
      child: _RegistryStudioShellView(
        registrySnapshotLoader: registrySnapshotLoader,
        registrySnapshotRefreshLoader: registrySnapshotRefreshLoader,
        registrySnapshotRevisionLoader: registrySnapshotRevisionLoader,
        registryRevisionStateStore: registryRevisionStateStore,
        registryAnalysisHistoryStore: registryAnalysisHistoryStore,
        registrySnapshotComparator: registrySnapshotComparator,
        translatorWorkspace: translatorWorkspace,
        translatorWorkspaceController: translatorWorkspaceController,
      ),
    );
  }
}

final class _RegistryStudioShellView extends StatelessWidget {
  const _RegistryStudioShellView({
    required this.registrySnapshotLoader,
    required this.registrySnapshotRefreshLoader,
    required this.registrySnapshotRevisionLoader,
    required this.registryRevisionStateStore,
    required this.registryAnalysisHistoryStore,
    required this.registrySnapshotComparator,
    required this.translatorWorkspace,
    required this.translatorWorkspaceController,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final RegistrySnapshotRefreshLoader registrySnapshotRefreshLoader;
  final RegistrySnapshotRevisionLoader registrySnapshotRevisionLoader;
  final RegistryRevisionStateStore registryRevisionStateStore;
  final RegistryAnalysisHistoryStore registryAnalysisHistoryStore;
  final RegistrySnapshotComparator registrySnapshotComparator;
  final Widget? translatorWorkspace;
  final TranslatorWorkspaceController? translatorWorkspaceController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RegistryStudioWorkspaceCubit, RegistryStudioWorkspace>(
      builder: (BuildContext context, RegistryStudioWorkspace workspace) {
        final RegistryStudioLocalizations l10n = context.rsL10n;
        final int selectedIndex = RegistryStudioWorkspace.values.indexOf(
          workspace,
        );

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading:
                workspace == RegistryStudioWorkspace.translator &&
                    translatorWorkspaceController != null
                ? IconButton(
                    key: const ValueKey<String>(
                      'translator-access-key-app-bar-button',
                    ),
                    tooltip: l10n.apiKeySettings,
                    onPressed:
                        translatorWorkspaceController!.openAccessKeyDialog,
                    icon: const Icon(Icons.key_outlined),
                  )
                : null,
            title: Text(_titleFor(workspace, l10n)),
            actions: <Widget>[
              IconButton(
                key: const ValueKey<String>(
                  'registry-studio-language-app-bar-button',
                ),
                tooltip: l10n.changeInterfaceLanguage,
                onPressed: () {
                  _showLanguageDialog(context);
                },
                icon: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: <Widget>[
              RegistryExplorerView(
                snapshotLoader: registrySnapshotLoader,
                snapshotRefreshLoader: registrySnapshotRefreshLoader,
                snapshotRevisionLoader: registrySnapshotRevisionLoader,
                revisionStateStore: registryRevisionStateStore,
                analysisHistoryStore: registryAnalysisHistoryStore,
                snapshotComparator: registrySnapshotComparator,
              ),
              translatorWorkspace ?? const _TranslatorWorkspaceView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              context.read<RegistryStudioWorkspaceCubit>().select(
                RegistryStudioWorkspace.values[index],
              );
            },
            destinations: <NavigationDestination>[
              NavigationDestination(
                icon: const Icon(Icons.account_tree_outlined),
                selectedIcon: const Icon(Icons.account_tree),
                label: l10n.registryStudio,
              ),
              NavigationDestination(
                icon: const Icon(Icons.translate_outlined),
                selectedIcon: const Icon(Icons.translate),
                label: l10n.translator,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final Locale current = Localizations.localeOf(context);

    final Locale? selected = await showDialog<Locale>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          key: const ValueKey<String>('registry-studio-language-dialog'),
          title: Text(l10n.interfaceLanguage),
          children: <Widget>[
            _LanguageDialogOption(
              locale: RegistryStudioLocalizations.russian,
              label: l10n.russianLanguage,
              selected: current.languageCode == 'ru',
            ),
            _LanguageDialogOption(
              locale: RegistryStudioLocalizations.english,
              label: l10n.englishLanguage,
              selected: current.languageCode == 'en',
            ),
            _LanguageDialogOption(
              locale: RegistryStudioLocalizations.thai,
              label: l10n.thaiLanguage,
              selected: current.languageCode == 'th',
            ),
          ],
        );
      },
    );

    if (selected == null || !context.mounted) {
      return;
    }

    await context.read<RegistryStudioLocaleCubit>().select(selected);
  }

  String _titleFor(
    RegistryStudioWorkspace workspace,
    RegistryStudioLocalizations l10n,
  ) {
    return switch (workspace) {
      RegistryStudioWorkspace.registryStudio => l10n.registryStudio,
      RegistryStudioWorkspace.translator => l10n.translator,
    };
  }
}

final class _LanguageDialogOption extends StatelessWidget {
  const _LanguageDialogOption({
    required this.locale,
    required this.label,
    required this.selected,
  });

  final Locale locale;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      key: ValueKey<String>('registry-studio-language-${locale.languageCode}'),
      onPressed: () {
        Navigator.of(context).pop(locale);
      },
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          if (selected)
            Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}

final class _TranslatorWorkspaceView extends StatelessWidget {
  const _TranslatorWorkspaceView();

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.translate_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                l10n.translator,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translatorPlaceholderDescription,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
