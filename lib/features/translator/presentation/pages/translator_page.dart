import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/localization/registry_studio_localizations.dart';
import '../../domain/entities/translation_language.dart';
import '../../domain/entities/translation_matrix_result.dart';
import '../cubit/translator_cubit.dart';
import '../cubit/translator_state.dart';
import '../widgets/translation_matrix_result_view.dart';
import '../widgets/translator_progress_card.dart';

final class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

final class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController _sourceController = TextEditingController();

  @override
  void dispose() {
    _sourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<TranslatorCubit, TranslatorState>(
        builder: (BuildContext context, TranslatorState state) {
          final RegistryStudioLocalizations l10n = context.rsL10n;

          return ListView(
            key: const ValueKey<String>('translator-workspace'),
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              DropdownButtonFormField<SourceLanguageSelection>(
                key: const ValueKey<String>('translator-source-language-field'),
                initialValue: state.sourceLanguageSelection,
                decoration: InputDecoration(
                  labelText: l10n.sourceLanguage,
                  border: const OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<SourceLanguageSelection>>[
                  DropdownMenuItem<SourceLanguageSelection>(
                    value: SourceLanguageSelection.automatic,
                    child: Text(l10n.detectAutomatically),
                  ),
                  DropdownMenuItem<SourceLanguageSelection>(
                    value: SourceLanguageSelection.russian,
                    child: Text(l10n.russianLanguage),
                  ),
                  DropdownMenuItem<SourceLanguageSelection>(
                    value: SourceLanguageSelection.english,
                    child: Text(l10n.englishLanguage),
                  ),
                  DropdownMenuItem<SourceLanguageSelection>(
                    value: SourceLanguageSelection.thai,
                    child: Text(l10n.thaiLanguage),
                  ),
                ],
                onChanged: state.isRunning
                    ? null
                    : (SourceLanguageSelection? selection) {
                        if (selection != null) {
                          context.read<TranslatorCubit>().selectSourceLanguage(
                            selection,
                          );
                        }
                      },
              ),
              const SizedBox(height: 8),
              Text(
                l10n.manualLanguageHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('translator-source-text-field'),
                controller: _sourceController,
                minLines: 4,
                maxLines: 12,
                enabled: !state.isRunning,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: l10n.sourceTextFieldLabel,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey<String>(
                        'translator-translate-button',
                      ),
                      onPressed: state.isRunning
                          ? null
                          : () {
                              context.read<TranslatorCubit>().translate(
                                _sourceController.text,
                              );
                            },
                      icon: const Icon(Icons.translate_outlined),
                      label: Text(l10n.translateAndCheck),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (state.isRunning)
                    OutlinedButton.icon(
                      key: const ValueKey<String>('translator-cancel-button'),
                      onPressed: context.read<TranslatorCubit>().cancel,
                      icon: const Icon(Icons.stop_outlined),
                      label: Text(l10n.cancel),
                    )
                  else
                    IconButton.filledTonal(
                      key: const ValueKey<String>('translator-clear-button'),
                      tooltip: l10n.clearTranslator,
                      onPressed: () {
                        _sourceController.clear();
                        context.read<TranslatorCubit>().clearResults();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                ],
              ),
              if (state.isRunning) ...<Widget>[
                const SizedBox(height: 12),
                TranslatorProgressCard(progress: state.progress),
              ],
              if (state.status == TranslatorStatus.failure ||
                  state.status == TranslatorStatus.cancelled) ...<Widget>[
                const SizedBox(height: 12),
                _FailureCard(state: state),
              ],
              if (state.history.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  l10n.results,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                for (final TranslationMatrixResult result in state.history)
                  TranslationMatrixResultView(result: result),
              ],
            ],
          );
        },
      ),
    );
  }
}

final class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.state});

  final TranslatorState state;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioLocalizations l10n = context.rsL10n;
    final String failureKind = state.failureKind?.name ?? 'provider';

    return Card(
      key: const ValueKey<String>('translator-failure-card'),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.failureTitle(failureKind),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (state.failureDetail.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              SelectableText(state.failureDetail),
            ],
          ],
        ),
      ),
    );
  }
}
