import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_item.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_dictionary_cubit.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_dictionary_status_action.dart';

void main() {
  testWidgets(
    'shows loaded dictionary identity, collections and typed phrases',
    (WidgetTester tester) async {
      final CanonicalDictionary dictionary = CanonicalDictionary(
        dictionaryId: 'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
        version: '1',
        status: 'APPROVED / STORED',
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: '1111111111111111111111111111111111111111',
        sourceSnapshotFingerprint:
            'git-blob:'
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        sourceContent: 'source content',
        beginMarkerLine: 5,
        endMarkerLine: 30,
        collections: <CanonicalDictionaryCollection>[
          CanonicalDictionaryCollection(
            id: 'helpy.canonical.phrases',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: '- Canonical phrase.',
            startLine: 10,
            endLine: 15,
            entries: <CanonicalPhraseEntry>[
              CanonicalPhraseEntry(
                dictionaryId:
                    'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
                collectionId: 'helpy.canonical.phrases',
                phrase: 'Canonical phrase.',
                sourceDocumentPath: 'docs/contract.md',
                sourceRevision: '1111111111111111111111111111111111111111',
                sourceSnapshotFingerprint:
                    'git-blob:'
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                sourceStartLine: 13,
                sourceEndLine: 13,
              ),
            ],
          ),
          CanonicalDictionaryCollection(
            id: 'helpy.canonical.ordered_blocks',
            entryType: 'ordered_block',
            status: 'APPROVED / STORED',
            content:
                '#### Rule (`Rule Key`)\n'
                '- Ordered statement.',
            startLine: 16,
            endLine: 25,
            entries: <CanonicalOrderedBlockEntry>[
              CanonicalOrderedBlockEntry(
                dictionaryId:
                    'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
                collectionId: 'helpy.canonical.ordered_blocks',
                stableBlockKey: 'Rule Key',
                approvedOrder: 1,
                heading: 'Rule',
                items: <CanonicalOrderedBlockItem>[
                  CanonicalOrderedBlockItem(
                    approvedOrder: 1,
                    text: 'Ordered statement.',
                    sourceStartLine: 18,
                    sourceEndLine: 18,
                  ),
                ],
                sourceDocumentPath: 'docs/contract.md',
                sourceRevision: '1111111111111111111111111111111111111111',
                sourceSnapshotFingerprint:
                    'git-blob:'
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                sourceStartLine: 17,
                sourceEndLine: 18,
              ),
            ],
          ),
        ],
      );

      final _LoadedDictionaryLoader loader = _LoadedDictionaryLoader(
        dictionary,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CanonicalDictionaryCubit>(
            create: (_) => CanonicalDictionaryCubit(loader: loader)..load(),
            child: Scaffold(
              appBar: AppBar(
                actions: const <Widget>[CanonicalDictionaryStatusAction()],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(loader.loadCount, 1);

      expect(
        find.byKey(CanonicalDictionaryStatusAction.actionKey),
        findsOneWidget,
      );

      expect(find.byIcon(Icons.verified_outlined), findsOneWidget);

      await tester.tap(find.byKey(CanonicalDictionaryStatusAction.actionKey));

      await tester.pumpAndSettle();

      expect(
        find.byKey(CanonicalDictionaryStatusAction.dialogKey),
        findsOneWidget,
      );

      expect(find.text('Состояние Canonical Dictionary'), findsOneWidget);

      final Finder canonicalDictionaryPurpose = find.byKey(
        const ValueKey<String>('canonical-dictionary-purpose'),
      );

      final Finder canonicalDictionaryMatchingPolicy = find.byKey(
        const ValueKey<String>('canonical-dictionary-matching-policy'),
      );

      final Finder canonicalDictionaryReadOnly = find.byKey(
        const ValueKey<String>('canonical-dictionary-read-only'),
      );

      final Finder canonicalDictionarySource = find.byKey(
        const ValueKey<String>('canonical-dictionary-source'),
      );

      final Finder canonicalDictionaryRevision = find.byKey(
        const ValueKey<String>('canonical-dictionary-revision'),
      );

      final Finder canonicalDictionarySourceRange = find.byKey(
        const ValueKey<String>('canonical-dictionary-source-range'),
      );

      expect(canonicalDictionaryPurpose, findsOneWidget);
      expect(canonicalDictionaryMatchingPolicy, findsOneWidget);
      expect(canonicalDictionaryReadOnly, findsOneWidget);
      expect(canonicalDictionarySource, findsOneWidget);
      expect(canonicalDictionaryRevision, findsOneWidget);
      expect(canonicalDictionarySourceRange, findsOneWidget);

      expect(
        tester.widget<Text>(canonicalDictionaryPurpose).data,
        'Назначение: специальный источник канонических '
        'формулировок для проверки текстов Registry.',
      );

      expect(
        tester.widget<Text>(canonicalDictionaryMatchingPolicy).data,
        'Сопоставление выполняется только по точному '
        'совпадению. Нечёткий поиск и оценка сходства '
        'не применяются.',
      );

      expect(
        tester.widget<Text>(canonicalDictionaryReadOnly).data,
        'Режим только чтение: просмотр не изменяет Registry, '
        'Canonical Dictionary, набор изменений или публикацию.',
      );

      expect(
        tester.widget<SelectableText>(canonicalDictionarySource).data,
        'Источник: docs/contract.md',
      );

      expect(
        tester.widget<SelectableText>(canonicalDictionaryRevision).data,
        'Ревизия: '
        '1111111111111111111111111111111111111111',
      );

      expect(
        tester.widget<Text>(canonicalDictionarySourceRange).data,
        'Границы словаря: строки 5–30',
      );

      expect(
        find.text(
          'Dictionary ID: '
          'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
        ),
        findsOneWidget,
      );

      expect(find.text('Версия: 1'), findsOneWidget);

      final Finder canonicalDictionaryDialog = find.byKey(
        CanonicalDictionaryStatusAction.dialogKey,
      );

      final Finder canonicalDictionaryList = find.descendant(
        of: canonicalDictionaryDialog,
        matching: find.byType(ListView),
      );

      final Finder canonicalDictionaryCollections = find.text('Collections: 2');

      final Finder canonicalDictionaryPhraseCount = find.text(
        'Канонические фразы: 1',
      );

      final Finder canonicalDictionaryOrderedBlockCount = find.byKey(
        const ValueKey<String>('canonical-dictionary-ordered-block-count'),
      );

      final Finder canonicalDictionaryCollectionId = find.text(
        'helpy.canonical.phrases',
      );

      final Finder canonicalDictionaryOrderedCollectionId = find.text(
        'helpy.canonical.ordered_blocks',
      );

      final Finder canonicalDictionaryOrderedCollectionDetails = find.text(
        'ordered_block · entries: 1',
      );

      expect(canonicalDictionaryList, findsOneWidget);

      await tester.dragUntilVisible(
        canonicalDictionaryCollections,
        canonicalDictionaryList,
        const Offset(0, -160),
      );
      await tester.pumpAndSettle();

      expect(canonicalDictionaryCollections, findsOneWidget);
      expect(canonicalDictionaryPhraseCount, findsOneWidget);
      expect(canonicalDictionaryOrderedBlockCount, findsOneWidget);

      expect(
        tester.widget<Text>(canonicalDictionaryOrderedBlockCount).data,
        'Упорядоченные блоки: 1',
      );

      await tester.dragUntilVisible(
        canonicalDictionaryCollectionId,
        canonicalDictionaryList,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(canonicalDictionaryCollectionId, findsOneWidget);

      await tester.dragUntilVisible(
        canonicalDictionaryOrderedCollectionId,
        canonicalDictionaryList,
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(canonicalDictionaryOrderedCollectionId, findsOneWidget);
      expect(canonicalDictionaryOrderedCollectionDetails, findsOneWidget);
    },
  );
}

final class _LoadedDictionaryLoader implements CanonicalDictionaryLoader {
  _LoadedDictionaryLoader(this.dictionary);

  final CanonicalDictionary dictionary;

  int loadCount = 0;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    loadCount += 1;
    return dictionary;
  }
}
