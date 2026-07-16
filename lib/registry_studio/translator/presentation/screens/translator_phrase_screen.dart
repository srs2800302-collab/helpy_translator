import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.initialSourceText,
    this.sourceContextLabel,
    this.initialSourceVersion = 0,
    this.onOperationRequested,
    super.key,
  });

  final RegistryStudioUiLanguage uiLanguage;
  final String? initialSourceText;
  final String? sourceContextLabel;
  final int initialSourceVersion;
  final ValueChanged<TranslatorPhraseResult>? onOperationRequested;

  @override
  State<TranslatorPhraseScreen> createState() => _TranslatorPhraseScreenState();
}

final class _TranslatorPhraseScreenState extends State<TranslatorPhraseScreen> {
  static const Key sourceTextFieldKey = Key(
    'translator_phrase_source_text_field',
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
  static const Key sourceContextCardKey = Key(
    'translator_phrase_source_context_card',
  );

  final TextEditingController _sourceTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultSectionKey = GlobalKey();

  String? _activeSourceContextLabel;
  int _lastAppliedInitialSourceVersion = -1;

  @override
  void initState() {
    super.initState();
    _applyInitialRegistrySource();
  }

  @override
  void didUpdateWidget(covariant TranslatorPhraseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSourceVersion != widget.initialSourceVersion ||
        oldWidget.initialSourceText != widget.initialSourceText ||
        oldWidget.sourceContextLabel != widget.sourceContextLabel) {
      _applyInitialRegistrySource();
    }
  }

  @override
  void dispose() {
    _sourceTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyInitialRegistrySource() {
    if (_lastAppliedInitialSourceVersion == widget.initialSourceVersion) {
      return;
    }

    _lastAppliedInitialSourceVersion = widget.initialSourceVersion;
    _activeSourceContextLabel = _normalizedOptionalText(
      widget.sourceContextLabel,
    );

    final String? initialSourceText = _normalizedOptionalText(
      widget.initialSourceText,
    );

    if (initialSourceText == null) {
      return;
    }

    _sourceTextController.text = initialSourceText;
    _sourceTextController.selection = TextSelection.collapsed(
      offset: initialSourceText.length,
    );
  }

  String? _normalizedOptionalText(String? value) {
    if (value == null) {
      return null;
    }

    final String normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  void _translatePhrase() {
    FocusManager.instance.primaryFocus?.unfocus();

    context.read<TranslatorPhraseCubit>().translatePhrase(
      sourceText: _sourceTextController.text,
    );
  }

  void _clear() {
    FocusManager.instance.primaryFocus?.unfocus();

    _sourceTextController.clear();
    setState(() {
      _activeSourceContextLabel = null;
    });
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
            return current.history.isNotEmpty &&
                current.status == TranslatorPhrasePresentationStatus.success &&
                previous.history != current.history;
          },
      listener: (BuildContext context, TranslatorPhraseState state) {
        _showResult();
      },
      builder: (BuildContext context, TranslatorPhraseState state) {
        final bool isLoading =
            state.status == TranslatorPhrasePresentationStatus.loading;
        final List<TranslatorPhraseResult> history = state.history;

        return ListView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: <Widget>[
            if (_activeSourceContextLabel != null) ...<Widget>[
              _RegistrySourceContextCard(
                title: _registrySourceContextTitle(widget.uiLanguage),
                contextLabel: _activeSourceContextLabel!,
              ),
              const SizedBox(height: 12),
            ],
            _StatusSummary(history: history),
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
            const SizedBox(height: 12),
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
            if (history.isNotEmpty) ...<Widget>[
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
                  for (
                    int index = 0;
                    index < history.length;
                    index++
                  ) ...<Widget>[
                    _TranslatorPhraseResultCard(
                      key: index == 0
                          ? resultCardKey
                          : ValueKey<String>(
                              'translator_phrase_result_card_$index',
                            ),
                      labels: labels,
                      result: history[index],
                    ),
                    if (history[index].candidateCanonicalPhrase != null &&
                        widget.onOperationRequested != null) ...<Widget>[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          key: index == 0
                              ? requestOperationButtonKey
                              : ValueKey<String>(
                                  'translator_phrase_request_operation_'
                                  'button_$index',
                                ),
                          onPressed: () {
                            widget.onOperationRequested?.call(history[index]);
                          },
                          child: Text(uiLabels.operationWorkspaceScreenTitle),
                        ),
                      ),
                    ],
                    if (index < history.length - 1) const SizedBox(height: 8),
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

final class _RegistrySourceContextCard extends StatelessWidget {
  const _RegistrySourceContextCard({
    required this.title,
    required this.contextLabel,
  });

  final String title;
  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _TranslatorPhraseScreenState.sourceContextCardKey,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SelectableText(contextLabel),
          ],
        ),
      ),
    );
  }
}

String _registrySourceContextTitle(RegistryStudioUiLanguage language) {
  return switch (language) {
    RegistryStudioUiLanguage.ru => 'Источник: Registry',
    RegistryStudioUiLanguage.en => 'Source: Registry',
    RegistryStudioUiLanguage.th => 'แหล่งที่มา: Registry',
  };
}

final class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.history});

  final List<TranslatorPhraseResult> history;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        _StatusValue(
          icon: '✅',
          label: 'Exact',
          count: _count(TranslatorPhraseStatus.exact),
        ),
        _StatusValue(
          icon: '🟢',
          label: 'Equivalent',
          count: _count(TranslatorPhraseStatus.equivalent),
        ),
        _StatusValue(
          icon: '🟡',
          label: 'Review',
          count: _count(TranslatorPhraseStatus.needsReview),
        ),
        _StatusValue(
          icon: '🔴',
          label: 'Drift',
          count: _count(TranslatorPhraseStatus.canonicalDrift),
        ),
        _StatusValue(
          icon: '❌',
          label: 'Failed',
          count: _count(TranslatorPhraseStatus.failed),
        ),
      ],
    );
  }

  int _count(TranslatorPhraseStatus status) {
    return history
        .where((TranslatorPhraseResult result) => result.status == status)
        .length;
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
    super.key,
  });

  final RegistryStudioTranslatorPhraseLabels labels;
  final TranslatorPhraseResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
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
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: _copyAllText(labels, result)),
                );

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(labels.copyAllSuccessMessage)),
                );
              },
              icon: const Icon(Icons.copy),
              label: Text(labels.copyAllButton),
            ),
          ),
          _TextValueRow(
            label: labels.verdictRow,
            value: _statusLabel(labels, result.status),
          ),
          _TextValueRow(
            label: labels.sourceLanguageRow,
            value: result.sourceLanguage,
          ),
          _TextValueRow(label: labels.sourceTextRow, value: result.sourceText),
          _OptionalTextValueRow(label: 'RU', value: result.ru),
          _OptionalTextValueRow(label: 'EN', value: result.en),
          _OptionalTextValueRow(label: 'TH', value: result.th),
          _OptionalTextValueRow(label: 'EN_TO_RU', value: result.enToRu),
          _OptionalTextValueRow(label: 'TH_TO_RU', value: result.thToRu),
          _OptionalTextValueRow(label: 'EN_TO_TH', value: result.enToTh),
          _OptionalTextValueRow(label: 'TH_TO_EN', value: result.thToEn),
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

  static String _copyAllText(
    RegistryStudioTranslatorPhraseLabels labels,
    TranslatorPhraseResult result,
  ) {
    return '''
${labels.sourceLanguageRow}:
${result.sourceLanguage}

${labels.sourceTextRow}:
${result.sourceText}

RU:
${result.ru ?? ''}

EN:
${result.en ?? ''}

TH:
${result.th ?? ''}

EN_TO_RU:
${result.enToRu ?? ''}

TH_TO_RU:
${result.thToRu ?? ''}

EN_TO_TH:
${result.enToTh ?? ''}

TH_TO_EN:
${result.thToEn ?? ''}

${labels.verdictRow}:
${_statusLabel(labels, result.status)}

${labels.commentRow}:
${result.comment ?? ''}

${labels.canonicalCandidateRow}:
${result.candidateCanonicalPhrase ?? ''}
'''
        .trim();
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
