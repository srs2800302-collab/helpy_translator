import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/build_canonical_phrase_vocabulary.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_entry.dart';

void main() {
  const HelpyCanonicalDictionaryDocumentInterpreter interpreter =
      HelpyCanonicalDictionaryDocumentInterpreter();

  group('HelpyCanonicalDictionaryDocumentInterpreter', () {
    test('loads dictionary by stable markers and identities without depending '
        'on visible Markdown heading', () {
      final CanonicalDictionary dictionary = interpreter.interpret(
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: '1111111111111111111111111111111111111111',
        sourceSnapshotFingerprint:
            'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        sourceContent: _validDictionaryDocument,
      );

      expect(
        dictionary.dictionaryId,
        'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
      );
      expect(dictionary.version, '1');
      expect(dictionary.status, 'APPROVED / STORED');
      expect(dictionary.beginMarkerLine, 4);
      expect(dictionary.endMarkerLine, 27);
      expect(dictionary.collections, hasLength(2));

      expect(
        dictionary.collections[0].id,
        'helpy.canonical.general_preparation',
      );
      expect(dictionary.collections[0].entryType, 'phrase');
      expect(
        dictionary.collections[0].content,
        contains('Подготовьте доступ к месту выполнения работ.'),
      );

      final CanonicalDictionaryEntry firstPhrase =
          dictionary.collections[0].entries.first;

      expect(firstPhrase.dictionaryId, dictionary.dictionaryId);

      expect(
        firstPhrase.approvedTextHash,
        'sha256:'
        'cb29f69838be9b811715cb5b0dff96c72ed203e0b9cbc4f1bfbee449faa877a3',
      );

      expect(
        firstPhrase.identity,
        'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1::'
        'helpy.canonical.general_preparation::'
        'sha256:'
        'cb29f69838be9b811715cb5b0dff96c72ed203e0b9cbc4f1bfbee449faa877a3',
      );

      expect(
        dictionary.collections[1].id,
        'helpy.canonical.global_business_rules',
      );
      expect(dictionary.collections[1].entryType, 'ordered_rule_block');
    });

    test('rejects duplicate stable markers', () {
      expect(
        () => interpreter.interpret(
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent:
              '${HelpyCanonicalDictionaryDocumentInterpreter.beginMarker}\n'
              '${HelpyCanonicalDictionaryDocumentInterpreter.beginMarker}\n'
              '${HelpyCanonicalDictionaryDocumentInterpreter.endMarker}\n',
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects duplicate collection identifiers', () {
      const String source =
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
          '\n'
          'Dictionary ID: `DICTIONARY`\n'
          'Версия словаря: `1`\n'
          'Статус: **APPROVED / STORED**\n'
          '\n'
          '### Collection: `duplicate.collection`\n'
          'Тип записи: `phrase`\n'
          'Статус: **APPROVED / STORED**\n'
          '- First.\n'
          '\n'
          '### Collection: `duplicate.collection`\n'
          'Тип записи: `phrase`\n'
          'Статус: **APPROVED / STORED**\n'
          '- Second.\n'
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

      expect(
        () => interpreter.interpret(
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: source,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a collection without approved stored status', () {
      const String source =
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
          '\n'
          'Dictionary ID: `DICTIONARY`\n'
          'Версия словаря: `1`\n'
          'Статус: **APPROVED / STORED**\n'
          '\n'
          '### Collection: `draft.collection`\n'
          'Тип записи: `phrase`\n'
          'Статус: **DRAFT**\n'
          '- Draft phrase.\n'
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

      expect(
        () => interpreter.interpret(
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: source,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'loads the exact approved dictionary from the normative contract',
      () async {
        final File contract = File(
          'docs/architecture/registry_studio/'
          'Registry_Studio_Engineering_Change_Propagation_'
          'and_Approval_Contract_v1.md',
        );

        expect(await contract.exists(), isTrue);

        final CanonicalDictionary dictionary = interpreter.interpret(
          sourceDocumentPath: contract.path,
          sourceRevision: '5863b3f78130d5e9231bde996d6620a1c0ab742e',
          sourceSnapshotFingerprint:
              'sha256:'
              '73bb98686befe8885e487427537db32d54be7e3443b5d3b4aa192f9d03c976a6',
          sourceContent: await contract.readAsString(),
        );

        expect(
          dictionary.dictionaryId,
          'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
        );
        expect(dictionary.version, '1');
        expect(dictionary.status, 'APPROVED / STORED');

        expect(
          dictionary.collections
              .map((collection) => collection.id)
              .toList(growable: false),
          <String>[
            'helpy.canonical.general_preparation',
            'helpy.canonical.photo_labels',
            'helpy.canonical.client_labels',
            'helpy.canonical.master_workflow_blocks',
            'helpy.canonical.global_business_rules',
          ],
        );

        expect(
          dictionary.collections
              .map((collection) => collection.entryType)
              .toList(growable: false),
          <String>[
            'phrase_with_applicability',
            'phrase',
            'phrase',
            'ordered_block',
            'ordered_rule_block',
          ],
        );
      },
    );

    test(
      'builds the complete typed phrase vocabulary from the normative contract',
      () async {
        final File contract = File(
          'docs/architecture/registry_studio/'
          'Registry_Studio_Engineering_Change_Propagation_'
          'and_Approval_Contract_v1.md',
        );

        expect(await contract.exists(), isTrue);

        final CanonicalDictionary dictionary = interpreter.interpret(
          sourceDocumentPath: contract.path,
          sourceRevision: '7f3ff7f90fc8d8802f3fb8fcff851b23a224b920',
          sourceSnapshotFingerprint:
              'sha256:'
              '73bb98686befe8885e487427537db32d54be7e3443b5d3b4aa192f9d03c976a6',
          sourceContent: await contract.readAsString(),
        );

        final vocabulary = const BuildCanonicalPhraseVocabulary().call(
          dictionary,
        );

        expect(vocabulary.entries, hasLength(81));
        expect(vocabulary.uniquePhraseCount, 80);

        expect(
          vocabulary.entriesForCollection(
            HelpyCanonicalDictionaryDocumentInterpreter
                .generalPreparationCollectionId,
          ),
          hasLength(2),
        );

        expect(
          vocabulary.entriesForCollection(
            HelpyCanonicalDictionaryDocumentInterpreter.photoLabelsCollectionId,
          ),
          hasLength(50),
        );

        expect(
          vocabulary.entriesForCollection(
            HelpyCanonicalDictionaryDocumentInterpreter
                .clientLabelsCollectionId,
          ),
          hasLength(29),
        );

        final matchingEntries = vocabulary.entriesForExactPhrase(
          'Подготовьте доступ к установленному оборудованию.',
        );

        expect(matchingEntries, hasLength(2));

        expect(
          matchingEntries
              .where((entry) => entry.applicability.isNotEmpty)
              .single
              .applicability,
          <String>[
            'Используется только для сценариев '
                '«Заменить» и «Перенести».',
          ],
        );

        expect(
          dictionary
              .collectionById('helpy.canonical.master_workflow_blocks')
              ?.entries,
          isEmpty,
        );

        expect(
          dictionary
              .collectionById('helpy.canonical.global_business_rules')
              ?.entries,
          isEmpty,
        );

        expect(
          vocabulary.entries.every(
            (entry) =>
                entry.sourceDocumentPath == contract.path &&
                entry.sourceRevision ==
                    '7f3ff7f90fc8d8802f3fb8fcff851b23a224b920' &&
                entry.sourceSnapshotFingerprint ==
                    'sha256:'
                        '73bb98686befe8885e487427537db32d54be7e3443b5d3b4aa192f9d03c976a6' &&
                entry.sourceStartLine > 0 &&
                entry.sourceEndLine >= entry.sourceStartLine,
          ),
          isTrue,
        );
      },
    );
  });
}

const String _validDictionaryDocument =
    '# Contract\n'
    'Visible heading may change.\n'
    '\n'
    '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
    '\n'
    'Dictionary ID: '
    '`REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1`\n'
    '\n'
    'Версия словаря: `1`\n'
    '\n'
    'Статус: **APPROVED / STORED**\n'
    '\n'
    '### Collection: `helpy.canonical.general_preparation`\n'
    '\n'
    'Тип записи: `phrase`\n'
    '\n'
    'Статус: **APPROVED / STORED**\n'
    '\n'
    '- Подготовьте доступ к месту выполнения работ.\n'
    '\n'
    '### Collection: `helpy.canonical.global_business_rules`\n'
    '\n'
    'Тип записи: `ordered_rule_block`\n'
    '\n'
    'Статус: **APPROVED / STORED**\n'
    '\n'
    '1. Client-Safe Scope Rule.\n'
    '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';
