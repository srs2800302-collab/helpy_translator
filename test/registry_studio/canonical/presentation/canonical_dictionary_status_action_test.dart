import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
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
        endMarkerLine: 20,
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
                identity:
                    'helpy.canonical.phrases::'
                    'phrase::canonical phrase.',
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

      expect(
        find.text(
          'Dictionary ID: '
          'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
        ),
        findsOneWidget,
      );

      expect(find.text('Версия: 1'), findsOneWidget);
      expect(find.text('Collections: 1'), findsOneWidget);

      expect(find.text('Канонические фразы: 1'), findsOneWidget);

      expect(find.text('helpy.canonical.phrases'), findsOneWidget);
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
