import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/presentation/canonical_dictionary_cubit.dart';

void main() {
  group('CanonicalDictionaryCubit', () {
    test('loads one exact dictionary snapshot', () async {
      final CanonicalDictionary dictionary = _dictionary();

      final _CanonicalDictionaryLoader loader = _CanonicalDictionaryLoader(
        result: dictionary,
      );

      final CanonicalDictionaryCubit cubit = CanonicalDictionaryCubit(
        loader: loader,
      );

      final Future<List<CanonicalDictionaryState>> states = cubit.stream
          .toList();

      await cubit.load();
      await cubit.close();

      expect(loader.loadCount, 1);
      expect(await states, <CanonicalDictionaryState>[
        const CanonicalDictionaryLoading(),
        CanonicalDictionaryLoaded(dictionary: dictionary),
      ]);
    });

    test('exposes a deterministic failure state', () async {
      final _CanonicalDictionaryLoader loader = _CanonicalDictionaryLoader(
        error: const FormatException('Invalid Canonical Dictionary.'),
      );

      final CanonicalDictionaryCubit cubit = CanonicalDictionaryCubit(
        loader: loader,
      );

      await cubit.load();

      expect(loader.loadCount, 1);
      expect(
        cubit.state,
        const CanonicalDictionaryFailed(
          message: 'FormatException: Invalid Canonical Dictionary.',
        ),
      );

      await cubit.close();
    });
  });
}

CanonicalDictionary _dictionary() {
  return CanonicalDictionary(
    dictionaryId: 'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'docs/contract.md',
    sourceRevision: '1111111111111111111111111111111111111111',
    sourceSnapshotFingerprint:
        'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
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
      ),
    ],
  );
}

final class _CanonicalDictionaryLoader implements CanonicalDictionaryLoader {
  _CanonicalDictionaryLoader({this.result, this.error});

  final CanonicalDictionary? result;
  final Object? error;

  int loadCount = 0;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    loadCount += 1;

    if (error case final Object loadError) {
      throw loadError;
    }

    final CanonicalDictionary? dictionary = result;

    if (dictionary == null) {
      throw StateError('Dictionary result is missing.');
    }

    return dictionary;
  }
}
