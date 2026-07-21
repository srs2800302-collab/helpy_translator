import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_dictionary_loader.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';

void main() {
  test('CanonicalDictionaryLoader allows a project adapter to load one exact '
      'dictionary snapshot', () async {
    final CanonicalDictionary expectedDictionary = CanonicalDictionary(
      dictionaryId: 'SAMPLE_DICTIONARY',
      version: '1',
      status: 'APPROVED / STORED',
      sourceDocumentPath: 'docs/contract.md',
      sourceRevision: 'revision-1',
      sourceSnapshotFingerprint: 'git-blob:source',
      sourceContent: 'source content',
      beginMarkerLine: 5,
      endMarkerLine: 20,
      collections: <CanonicalDictionaryCollection>[
        CanonicalDictionaryCollection(
          id: 'sample.canonical.phrases',
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: '- Canonical phrase.',
          startLine: 10,
          endLine: 15,
        ),
      ],
    );

    final CanonicalDictionaryLoader loader = _SampleCanonicalDictionaryLoader(
      dictionary: expectedDictionary,
    );

    final CanonicalDictionary loadedDictionary = await loader.loadDictionary();

    expect(loadedDictionary, same(expectedDictionary));
    expect(loadedDictionary.sourceRevision, 'revision-1');
  });
}

final class _SampleCanonicalDictionaryLoader
    implements CanonicalDictionaryLoader {
  const _SampleCanonicalDictionaryLoader({required this.dictionary});

  final CanonicalDictionary dictionary;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    return dictionary;
  }
}
