import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/translation_result.dart';

final class TranslationResultView extends StatelessWidget {
  const TranslationResultView({
    required this.result,
    super.key,
  });

  final TranslationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _TranslationBlock(title: 'RU', value: result.ru),
        _TranslationBlock(title: 'EN', value: result.en),
        _TranslationBlock(title: 'TH', value: result.th),
        _TranslationBlock(title: 'EN → RU', value: result.enToRu),
        _TranslationBlock(title: 'TH → RU', value: result.thToRu),
        _TranslationBlock(title: 'EN → TH', value: result.enToTh),
        _TranslationBlock(title: 'TH → EN', value: result.thToEn),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _copyAllText(result)));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Все переводы скопированы')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Копировать всё'),
        ),
      ],
    );
  }

  static String _copyAllText(TranslationResult result) {
    return '''
RU:
${result.ru}

EN:
${result.en}

TH:
${result.th}

EN → RU:
${result.enToRu}

TH → RU:
${result.thToRu}

EN → TH:
${result.enToTh}

TH → EN:
${result.thToEn}
'''.trim();
  }
}

final class _TranslationBlock extends StatelessWidget {
  const _TranslationBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String displayValue = value.isEmpty ? '—' : value;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: value.isEmpty
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$title скопировано')),
                          );
                        },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(displayValue),
          ],
        ),
      ),
    );
  }
}
