import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import '../../translator_phrase_result.dart';
import '../../translator_phrase_status.dart';
import '../cubit/translator_phrase_cubit.dart';
import '../cubit/translator_phrase_state.dart';

final class TranslatorPhraseScreen extends StatefulWidget {
  const TranslatorPhraseScreen({
    required this.uiLanguage,
    this.onOperationRequested,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final ValueChanged<TranslatorPhraseResult>? onOperationRequested;

  @override
  State<TranslatorPhraseScreen> createState() => _TranslatorPhraseScreenState();
}

final class _TranslatorPhraseScreenState extends State<TranslatorPhraseScreen> {
  static const Key sourceTextFieldKey = Key(
    'translator_phrase_source_text_field',
  );
  static const Key languageHintFieldKey = Key(
    'translator_phrase_language_hint_field',
  );
  static const Key engineerContextFieldKey = Key(
    'translator_phrase_engineer_context_field',
  );
  static const Key advancedOptionsTileKey = Key(
    'translator_phrase_advanced_options_tile',
  );
  static const Key translateButtonKey = Key(
    'translator_phrase_translate_button',
  );
  static const Key clearButtonKey = Key('translator_phrase_clear_button');
  static const Key resultCardKey = Key('translator_phrase_result_card');
  static const Key requestOperationButtonKey = Key(
    'translator_phrase_request_operation_button',
  );
  static const Key errorTextKey = Key('translator_phrase_error_text');

  final TextEditingController _sourceTextController = TextEditingController();
  final TextEditingController _languageHintController = TextEditingController();
  final TextEditingController _engineerContextController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultSectionKey = GlobalKey();

  @override
  void dispose() {
    _sourceTextController.dispose();
    _languageHintController.dispose();
    _engineerContextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _translatePhrase() {
    FocusManager.instance.primaryFocus?.unfocus();

    context.read<TranslatorPhraseCubit>().translatePhrase(
      sourceText: _sourceTextController.text,
      sourceLanguageHint: _languageHintController.text,
      engineerContext: _engineerContextController.text,
    );
  }

  void _clear() {
    FocusManager.instance.primaryFocus?.unfocus();

    _sourceTextController.clear();
    _languageHintController.clear();
    _engineerContextController.clear();
    context.read<TranslatorPhraseCubit>().clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _showResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? resultContext = _resultSectionKey.currentContext;

      if (!mounted || resultContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        resultContext,
        alignment: 0.08,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final RegistryStudioUiLabels uiLabels = RegistryStudioUiLabels.forLanguage(
      widget.uiLanguage,
    );
    final RegistryStudioTranslatorPhraseLabels labels =
        uiLabels.translatorPhrase;

    return BlocConsumer<TranslatorPhraseCubit, TranslatorPhraseState>(
      listenWhen:
          (TranslatorPhraseState previous, TranslatorPhraseState current) {
            return current.result != null &&
                current.status == TranslatorPhrasePresentationStatus.success &&
                (previous.status != current.status ||
                    previous.result != current.result);
          },
      listener: (BuildContext context, TranslatorPhraseState state) {
        _showResult();
      },
      builder: (BuildContext context, TranslatorPhraseState state) {
        final bool isLoading =
            state.status == TranslatorPhrasePresentationStatus.loading;
        final TranslatorPhraseResult? result = state.result;

        return ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            Text(labels.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _StatusSummary(result: result),
            const SizedBox(height: 16),
            TextField(
              key: sourceTextFieldKey,
              controller: _sourceTextController,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: labels.sourceTextLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              key: advancedOptionsTileKey,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              leading: const Icon(Icons.tune),
              title: Text(labels.additionalParametersLabel),
              children: <Widget>[
                TextField(
                  key: languageHintFieldKey,
                  controller: _languageHintController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: labels.sourceLanguageHintLabel,
                    helperText: labels.sourceLanguageHintHelper,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: engineerContextFieldKey,
                  controller: _engineerContextController,
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: labels.engineerContextLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    key: translateButtonKey,
                    onPressed: isLoading ? null : _translatePhrase,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(labels.translateButton),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: clearButtonKey,
                  onPressed: isLoading ? null : _clear,
                  tooltip: labels.clearButton,
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
            if (isLoading) ...<Widget>[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (state.errorMessage.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _ErrorMessage(message: state.errorMessage),
            ],
            if (result != null) ...<Widget>[
              const SizedBox(height: 20),
              Column(
                key: _resultSectionKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    labels.resultsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _TranslatorPhraseResultCard(labels: labels, result: result),
                  if (result.candidateCanonicalPhrase != null &&
                      widget.onOperationRequested != null) ...<Widget>[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        key: requestOperationButtonKey,
                        onPressed: () {
                          widget.onOperationRequested?.call(result);
                        },
                        child: Text(uiLabels.operationCreationScreenTitle),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

final class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.result});

  final TranslatorPhraseResult? result;

  @override
  Widget build(BuildContext context) {
    final TranslatorPhraseStatus? status = result?.status;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _StatusValue(
          icon: '✅',
          label: 'Exact',
          count: status == TranslatorPhraseStatus.exact ? 1 : 0,
        ),
        _StatusValue(
          icon: '🟢',
          label: 'Equivalent',
          count: status == TranslatorPhraseStatus.equivalent ? 1 : 0,
        ),
        _StatusValue(
          icon: '🟡',
          label: 'Review',
          count: status == TranslatorPhraseStatus.needsReview ? 1 : 0,
        ),
        _StatusValue(
          icon: '🔴',
          label: 'Drift',
          count: status == TranslatorPhraseStatus.canonicalDrift ? 1 : 0,
        ),
        _StatusValue(
          icon: '❌',
          label: 'Failed',
          count: status == TranslatorPhraseStatus.failed ? 1 : 0,
        ),
      ],
    );
  }
}

final class _StatusValue extends StatelessWidget {
  const _StatusValue({
    required this.icon,
    required this.label,
    required this.count,
  });

  final String icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text('$icon $label: $count');
  }
}

final class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        key: _TranslatorPhraseScreenState.errorTextKey,
        padding: const EdgeInsets.all(12),
        child: Text(message),
      ),
    );
  }
}

final class _TranslatorPhraseResultCard extends StatelessWidget {
  const _TranslatorPhraseResultCard({
    required this.labels,
    required this.result,
  });

  final RegistryStudioTranslatorPhraseLabels labels;
  final TranslatorPhraseResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _TranslatorPhraseScreenState.resultCardKey,
      color: _statusBackgroundColor(result.status),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Text(
          _statusIcon(result.status),
          style: const TextStyle(fontSize: 26),
        ),
        title: Text(_statusLabel(labels, result.status)),
        subtitle: Text(
          _previewText(result),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          _TextValueRow(
            label: labels.sourceLanguageRow,
            value: result.sourceLanguage,
          ),
          _TextValueRow(label: labels.sourceTextRow, value: result.sourceText),
          _OptionalTextValueRow(label: 'RU', value: result.ru),
          _OptionalTextValueRow(label: 'EN', value: result.en),
          _OptionalTextValueRow(label: 'TH', value: result.th),
          _OptionalTextValueRow(label: 'EN → RU', value: result.enToRu),
          _OptionalTextValueRow(label: 'TH → RU', value: result.thToRu),
          _OptionalTextValueRow(label: 'EN → TH', value: result.enToTh),
          _OptionalTextValueRow(label: 'TH → EN', value: result.thToEn),
          _OptionalTextValueRow(
            label: labels.commentRow,
            value: result.comment,
          ),
          _OptionalTextValueRow(
            label: labels.canonicalCandidateRow,
            value: result.candidateCanonicalPhrase,
          ),
        ],
      ),
    );
  }

  static String _previewText(TranslatorPhraseResult result) {
    return result.ru ?? result.en ?? result.th ?? result.sourceText;
  }

  static String _statusIcon(TranslatorPhraseStatus status) {
    return switch (status) {
      TranslatorPhraseStatus.exact => '✅',
      TranslatorPhraseStatus.equivalent => '🟢',
      TranslatorPhraseStatus.needsReview => '🟡',
      TranslatorPhraseStatus.canonicalDrift => '🔴',
      TranslatorPhraseStatus.failed => '❌',
    };
  }

  static String _statusLabel(
    RegistryStudioTranslatorPhraseLabels labels,
    TranslatorPhraseStatus status,
  ) {
    return switch (status) {
      TranslatorPhraseStatus.exact => labels.exactStatus,
      TranslatorPhraseStatus.equivalent => labels.equivalentStatus,
      TranslatorPhraseStatus.needsReview => labels.needsReviewStatus,
      TranslatorPhraseStatus.canonicalDrift => labels.canonicalDriftStatus,
      TranslatorPhraseStatus.failed => labels.failedStatus,
    };
  }

  static Color _statusBackgroundColor(TranslatorPhraseStatus status) {
    return switch (status) {
      TranslatorPhraseStatus.exact => Colors.green.shade50,
      TranslatorPhraseStatus.equivalent => Colors.lightGreen.shade50,
      TranslatorPhraseStatus.needsReview => Colors.yellow.shade50,
      TranslatorPhraseStatus.canonicalDrift => Colors.red.shade50,
      TranslatorPhraseStatus.failed => Colors.red.shade50,
    };
  }
}

final class _OptionalTextValueRow extends StatelessWidget {
  const _OptionalTextValueRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final String? text = value;

    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    return _TextValueRow(label: label, value: text);
  }
}

final class _TextValueRow extends StatelessWidget {
  const _TextValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
