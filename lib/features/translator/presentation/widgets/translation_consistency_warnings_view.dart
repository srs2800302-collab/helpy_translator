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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '⚠️ Разные статусы у одинаковых фраз',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final _PhraseVerdictConflict conflict in conflicts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${conflict.phrase}\nСтатусы: ${conflict.verdicts.join(', ')}',
                ),
              ),
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
        ),
      );
    }

    return conflicts;
  }
}

final class _PhraseVerdictAccumulator {
  _PhraseVerdictAccumulator({
    required this.phrase,
  });

  final String phrase;
  final Set<String> verdicts = <String>{};
}

final class _PhraseVerdictConflict {
  const _PhraseVerdictConflict({
    required this.phrase,
    required this.verdicts,
  });

  final String phrase;
  final List<String> verdicts;
}
