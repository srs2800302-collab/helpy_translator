import 'package:flutter/material.dart';

import '../../../../core/persistence/registry_phrase_status_persistence.dart';
import '../../domain/entities/translation_result.dart';

final class TranslationConsistencyWarningsView extends StatelessWidget {
  const TranslationConsistencyWarningsView({
    required this.results,
    super.key,
  });

  final List<TranslationResult> results;

  @override
  Widget build(BuildContext context) {
    final List<_PhraseVerdictConflict> conflicts = _findConflicts(results);

    if (conflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: const Text(
            '⚠️ Разные статусы у одинаковых фраз',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          subtitle: Text('Конфликтов: ${conflicts.length}'),
          children: <Widget>[
            for (final _PhraseVerdictConflict conflict in conflicts)
              _ConflictBlock(conflict: conflict),
          ],
        ),
      ),
    );
  }

  static List<_PhraseVerdictConflict> _findConflicts(
    List<TranslationResult> results,
  ) {
    final Map<String, _PhraseVerdictAccumulator> index =
        <String, _PhraseVerdictAccumulator>{};

    for (final TranslationResult result in results) {
      final String phrase = result.sourceText.trim().isEmpty
          ? result.ru.trim()
          : result.sourceText.trim();

      final String key = RegistryPhraseStatusPersistence.normalizePhrase(phrase);

      if (key.isEmpty) {
        continue;
      }

      index.putIfAbsent(
        key,
        () => _PhraseVerdictAccumulator(phrase: phrase),
      );

      index[key]!.items.add(result);
      index[key]!.verdicts.add(result.canonicalVerdict.trim().toUpperCase());
    }

    final List<_PhraseVerdictConflict> conflicts = <_PhraseVerdictConflict>[];

    for (final _PhraseVerdictAccumulator accumulator in index.values) {
      if (accumulator.verdicts.length < 2) {
        continue;
      }

      conflicts.add(
        _PhraseVerdictConflict(
          phrase: accumulator.phrase,
          verdicts: accumulator.verdicts.toList(growable: false),
          items: accumulator.items.toList(growable: false),
        ),
      );
    }

    return conflicts;
  }
}

final class _ConflictBlock extends StatelessWidget {
  const _ConflictBlock({
    required this.conflict,
  });

  final _PhraseVerdictConflict conflict;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        conflict.phrase,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('Статусы: ${conflict.verdicts.join(', ')}'),
      children: <Widget>[
        for (int index = 0; index < conflict.items.length; index++)
          _ConflictResultBlock(
            index: index + 1,
            result: conflict.items[index],
          ),
      ],
    );
  }
}

final class _ConflictResultBlock extends StatelessWidget {
  const _ConflictResultBlock({
    required this.index,
    required this.result,
  });

  final int index;
  final TranslationResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Версия $index · ${result.canonicalVerdict}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            _Line(label: 'Source language', value: result.sourceLanguage),
            _Line(label: 'Source text', value: result.sourceText),
            _Line(label: 'RU', value: result.ru),
            _Line(label: 'EN', value: result.en),
            _Line(label: 'TH', value: result.th),
            _Line(label: 'EN_TO_RU', value: result.enToRu),
            _Line(label: 'TH_TO_RU', value: result.thToRu),
            _Line(label: 'EN_TO_TH', value: result.enToTh),
            _Line(label: 'TH_TO_EN', value: result.thToEn),
            _Line(label: 'Comment', value: result.canonicalComment),
          ],
        ),
      ),
    );
  }
}

final class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SelectableText('$label: ${value.isEmpty ? '—' : value}'),
    );
  }
}

final class _PhraseVerdictAccumulator {
  _PhraseVerdictAccumulator({
    required this.phrase,
  });

  final String phrase;
  final List<TranslationResult> items = <TranslationResult>[];
  final Set<String> verdicts = <String>{};
}

final class _PhraseVerdictConflict {
  const _PhraseVerdictConflict({
    required this.phrase,
    required this.verdicts,
    required this.items,
  });

  final String phrase;
  final List<String> verdicts;
  final List<TranslationResult> items;
}
