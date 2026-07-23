import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/build_canonical_phrase_vocabulary.dart';
import '../domain/entities/canonical_dictionary.dart';
import '../domain/entities/canonical_ordered_block_entry.dart';
import 'canonical_dictionary_cubit.dart';

final class CanonicalDictionaryStatusAction extends StatelessWidget {
  const CanonicalDictionaryStatusAction({super.key});

  static const Key actionKey = ValueKey<String>(
    'canonical-dictionary-status-action',
  );

  static const Key dialogKey = ValueKey<String>(
    'canonical-dictionary-status-dialog',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CanonicalDictionaryCubit, CanonicalDictionaryState>(
      builder: (BuildContext context, CanonicalDictionaryState state) {
        return switch (state) {
          CanonicalDictionaryInitial() => IconButton(
            key: actionKey,
            tooltip: 'Загрузить Canonical Dictionary',
            onPressed: context.read<CanonicalDictionaryCubit>().load,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          CanonicalDictionaryLoading() => const SizedBox(
            width: 48,
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          CanonicalDictionaryLoaded(:final dictionary) => IconButton(
            key: actionKey,
            tooltip:
                'Canonical Dictionary: '
                '${dictionary.dictionaryId}, '
                'версия ${dictionary.version}',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return _CanonicalDictionaryDialog(dictionary: dictionary);
                },
              );
            },
            icon: const Icon(Icons.verified_outlined),
          ),
          CanonicalDictionaryFailed(:final message) => IconButton(
            key: actionKey,
            tooltip: 'Ошибка загрузки Canonical Dictionary',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    key: dialogKey,
                    title: const Text('Canonical Dictionary не загружен'),
                    content: SelectableText(message),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text('Закрыть'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          context.read<CanonicalDictionaryCubit>().load();
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.error_outline),
          ),
        };
      },
    );
  }
}

final class _CanonicalDictionaryDialog extends StatelessWidget {
  const _CanonicalDictionaryDialog({required this.dictionary});

  final CanonicalDictionary dictionary;

  @override
  Widget build(BuildContext context) {
    final int canonicalPhraseCount = const BuildCanonicalPhraseVocabulary()
        .call(dictionary)
        .entries
        .length;

    final int canonicalOrderedBlockCount = dictionary.collections
        .expand((collection) => collection.entries)
        .whereType<CanonicalOrderedBlockEntry>()
        .length;

    return AlertDialog(
      key: CanonicalDictionaryStatusAction.dialogKey,
      title: const Text('Состояние Canonical Dictionary'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            const Text(
              'Назначение: специальный источник канонических '
              'формулировок для проверки текстов Registry.',
              key: ValueKey<String>('canonical-dictionary-purpose'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Сопоставление выполняется только по точному '
              'совпадению. Нечёткий поиск и оценка сходства '
              'не применяются.',
              key: ValueKey<String>('canonical-dictionary-matching-policy'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Режим только чтение: просмотр не изменяет Registry, '
              'Canonical Dictionary, набор изменений или публикацию.',
              key: ValueKey<String>('canonical-dictionary-read-only'),
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Источник: ${dictionary.sourceDocumentPath}',
              key: const ValueKey<String>('canonical-dictionary-source'),
            ),
            SelectableText(
              'Ревизия: ${dictionary.sourceRevision}',
              key: const ValueKey<String>('canonical-dictionary-revision'),
            ),
            Text(
              'Границы словаря: строки '
              '${dictionary.beginMarkerLine}–'
              '${dictionary.endMarkerLine}',
              key: const ValueKey<String>('canonical-dictionary-source-range'),
            ),
            const Divider(height: 24),
            SelectableText('Dictionary ID: ${dictionary.dictionaryId}'),
            const SizedBox(height: 8),
            Text('Версия: ${dictionary.version}'),
            Text('Статус: ${dictionary.status}'),
            Text('Collections: ${dictionary.collections.length}'),
            Text('Канонические фразы: $canonicalPhraseCount'),
            Text(
              'Упорядоченные блоки: $canonicalOrderedBlockCount',
              key: const ValueKey<String>(
                'canonical-dictionary-ordered-block-count',
              ),
            ),
            const SizedBox(height: 12),
            for (final collection in dictionary.collections)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: SelectableText(collection.id),
                subtitle: Text(
                  '${collection.entryType} · '
                  'entries: ${collection.entries.length}',
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
