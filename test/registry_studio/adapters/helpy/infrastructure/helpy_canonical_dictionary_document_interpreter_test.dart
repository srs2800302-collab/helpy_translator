import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';

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
