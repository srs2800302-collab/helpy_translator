import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../translator_phrase_result.dart';
import '../../translator_phrase_status.dart';
import '../cubit/translator_phrase_cubit.dart';
import '../cubit/translator_phrase_state.dart';

final class TranslatorPhraseScreen extends StatefulWidget {
  const TranslatorPhraseScreen({super.key});

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
  static const Key translateButtonKey = Key(
    'translator_phrase_translate_button',
  );
  static const Key clearButtonKey = Key('translator_phrase_clear_button');
  static const Key resultCardKey = Key('translator_phrase_result_card');
  static const Key errorTextKey = Key('translator_phrase_error_text');

  final TextEditingController _sourceTextController = TextEditingController();
  final TextEditingController _languageHintController = TextEditingController();
  final TextEditingController _engineerContextController =
      TextEditingController();

  @override
  void dispose() {
    _sourceTextController.dispose();
    _languageHintController.dispose();
    _engineerContextController.dispose();
    super.dispose();
  }

  void _translatePhrase() {
    FocusScope.of(context).unfocus();

    context.read<TranslatorPhraseCubit>().translatePhrase(
      sourceText: _sourceTextController.text,
      sourceLanguageHint: _languageHintController.text,
      engineerContext: _engineerContextController.text,
    );
  }

  void _clear() {
    _sourceTextController.clear();
    _languageHintController.clear();
    _engineerContextController.clear();
    context.read<TranslatorPhraseCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Перевод формулировки')),
      body: BlocBuilder<TranslatorPhraseCubit, TranslatorPhraseState>(
        builder: (BuildContext context, TranslatorPhraseState state) {
          final bool isLoading =
              state.status == TranslatorPhrasePresentationStatus.loading;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              TextField(
                key: sourceTextFieldKey,
                controller: _sourceTextController,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Формулировка или текст',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: languageHintFieldKey,
                controller: _languageHintController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Подсказка языка',
                  helperText: 'Например: ru, en, th',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: engineerContextFieldKey,
                controller: _engineerContextController,
                minLines: 2,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Контекст инженера',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton(
                    key: translateButtonKey,
                    onPressed: isLoading ? null : _translatePhrase,
                    child: const Text('Перевести'),
                  ),
                  OutlinedButton(
                    key: clearButtonKey,
                    onPressed: isLoading ? null : _clear,
                    child: const Text('Очистить'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading) const LinearProgressIndicator(),
              if (state.errorMessage.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ErrorMessage(message: state.errorMessage),
              ],
              if (state.result != null) ...<Widget>[
                const SizedBox(height: 16),
                _TranslatorPhraseResultCard(result: state.result!),
              ],
            ],
          );
        },
      ),
    );
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
  const _TranslatorPhraseResultCard({required this.result});

  final TranslatorPhraseResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: _TranslatorPhraseScreenState.resultCardKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _statusLabel(result.status),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(label: 'Исходный язык', value: result.sourceLanguage),
            _TextValueRow(label: 'Исходный текст', value: result.sourceText),
            _OptionalTextValueRow(label: 'RU', value: result.ru),
            _OptionalTextValueRow(label: 'EN', value: result.en),
            _OptionalTextValueRow(label: 'TH', value: result.th),
            _OptionalTextValueRow(label: 'EN → RU', value: result.enToRu),
            _OptionalTextValueRow(label: 'TH → RU', value: result.thToRu),
            _OptionalTextValueRow(label: 'EN → TH', value: result.enToTh),
            _OptionalTextValueRow(label: 'TH → EN', value: result.thToEn),
            _OptionalTextValueRow(label: 'Комментарий', value: result.comment),
            _OptionalTextValueRow(
              label: 'Кандидат канонической формулировки',
              value: result.candidateCanonicalPhrase,
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(TranslatorPhraseStatus status) {
    return switch (status) {
      TranslatorPhraseStatus.exact => 'Точное совпадение',
      TranslatorPhraseStatus.equivalent => 'Эквивалентная формулировка',
      TranslatorPhraseStatus.needsReview => 'Нужна проверка',
      TranslatorPhraseStatus.canonicalDrift => 'Отклонение от канона',
      TranslatorPhraseStatus.failed => 'Ошибка',
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
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText('$label:\n$value'),
    );
  }
}
