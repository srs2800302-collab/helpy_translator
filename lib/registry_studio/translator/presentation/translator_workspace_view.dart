import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/translator_access_key_cubit.dart';
import '../application/translator_access_key_store.dart';
import '../application/translator_cubit.dart';
import '../application/translator_draft_store.dart';
import '../application/translator_history_store.dart';
import '../application/translator_provider.dart';
import 'translator_workspace_body.dart';
import 'translator_workspace_controller.dart';

export 'translator_workspace_controller.dart';

final class TranslatorWorkspaceView extends StatelessWidget {
  const TranslatorWorkspaceView({
    required this.provider,
    required this.draftStore,
    required this.historyStore,
    required this.accessKeyStore,
    this.controller,
    super.key,
  });

  final TranslatorProvider provider;
  final TranslatorDraftStore draftStore;
  final TranslatorHistoryStore historyStore;
  final TranslatorAccessKeyStore accessKeyStore;
  final TranslatorWorkspaceController? controller;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TranslatorCubit>(
          create: (_) => TranslatorCubit(
            provider: provider,
            draftStore: draftStore,
            historyStore: historyStore,
          )..restore(),
        ),
        BlocProvider<TranslatorAccessKeyCubit>(
          create: (_) =>
              TranslatorAccessKeyCubit(store: accessKeyStore)..restore(),
        ),
      ],
      child: TranslatorWorkspaceBody(controller: controller),
    );
  }
}
