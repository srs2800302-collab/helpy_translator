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
    return Card(
      color: _statusColor(result.canonicalVerdict),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Text(
          _statusIcon(result.canonicalVerdict),
          style: const TextStyle(fontSize: 26),
        ),
        title: Text(_statusLabel(result.canonicalVerdict)),
        subtitle: Text(result.ru),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _copyAllText(result)));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Все варианты скопированы')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Копировать всё'),
            ),
          ),
          _TextRow(label: 'Исходная формулировка (${result.sourceLanguage})', value: result.sourceText),
          const Divider(),
          _TextRow(label: 'RU → EN', value: result.en),
          _TextRow(label: 'RU → TH', value: result.th),
          const Divider(),
          _TextRow(label: 'EN → RU', value: result.enToRu),
          _TextRow(label: 'TH → RU', value: result.thToRu),
          const Divider(),
          _TextRow(label: 'EN → TH', value: result.enToTh),
          _TextRow(label: 'TH → EN', value: result.thToEn),
          const Divider(),
          _TextRow(label: 'Вердикт', value: result.canonicalVerdict),
          _TextRow(label: 'Комментарий', value: result.canonicalComment),
        ],
      ),
    );
  }

  static String _copyAllText(TranslationResult result) {
    return '''
Исходная формулировка (${result.sourceLanguage}):
${result.sourceText}

RU → EN:
${result.en}

RU → TH:
${result.th}

EN → RU:
${result.enToRu}

TH → RU:
${result.thToRu}

EN → TH:
${result.enToTh}

TH → EN:
${result.thToEn}

Вердикт:
${result.canonicalVerdict}

Комментарий:
${result.canonicalComment}
'''.trim();
  }

  static String _statusIcon(String verdict) {
    return switch (verdict.trim().toUpperCase()) {
      'EXACT' => '✅',
      'EQUIVALENT' => '🟢',
      'NEEDS_REVIEW' => '🟡',
      'CANONICAL_DRIFT' => '🔴',
      _ => '❌',
    };
  }

  static String _statusLabel(String verdict) {
    return switch (verdict.trim().toUpperCase()) {
      'EXACT' => 'Exact',
      'EQUIVALENT' => 'Equivalent',
      'NEEDS_REVIEW' => 'Needs Review',
      'CANONICAL_DRIFT' => 'Canonical Drift',
      _ => 'Failed',
    };
  }

  static Color _statusColor(String verdict) {
    return switch (verdict.trim().toUpperCase()) {
      'EXACT' => Colors.green.shade50,
      'EQUIVALENT' => Colors.lightGreen.shade50,
      'NEEDS_REVIEW' => Colors.yellow.shade50,
      'CANONICAL_DRIFT' => Colors.red.shade50,
      _ => Colors.red.shade50,
    };
  }
}

final class _TextRow extends StatelessWidget {
  const _TextRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final String normalizedValue = value.isEmpty ? '—' : value;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(normalizedValue),
        ],
      ),
    );
  }
}
