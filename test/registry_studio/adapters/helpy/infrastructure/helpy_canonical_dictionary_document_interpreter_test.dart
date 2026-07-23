import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/build_canonical_phrase_vocabulary.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_entry.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_ordered_block_entry.dart';

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
      expect(dictionary.endMarkerLine, 28);
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
      expect(dictionary.collections[1].entries, hasLength(1));

      final CanonicalOrderedBlockEntry orderedRule =
          dictionary.collections[1].entries.single
              as CanonicalOrderedBlockEntry;

      expect(orderedRule.stableBlockKey, 'Client-Safe Scope Rule');
      expect(orderedRule.approvedOrder, 1);
      expect(
        orderedRule.heading,
        'Правило № 1 — Безопасная область действий клиента',
      );
      expect(orderedRule.items, hasLength(1));
      expect(orderedRule.items.single.text, 'Client-safe statement.');
    });

    test('rejects an unsupported canonical entry type', () {
      const String source =
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
          'Dictionary ID: `DICTIONARY`\n'
          'Версия словаря: `1`\n'
          'Статус: **APPROVED / STORED**\n'
          '### Collection: `unsupported.collection`\n'
          'Тип записи: `unsupported_type`\n'
          'Статус: **APPROVED / STORED**\n'
          'Unsupported content.\n'
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

      expect(
        () => interpreter.interpret(
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: source,
        ),
        throwsA(
          isA<FormatException>().having(
            (FormatException error) => error.message,
            'message',
            contains('unsupported entry type'),
          ),
        ),
      );
    });

    test('does not treat arbitrary inline code as a stable block key', () {
      const String source =
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
          'Dictionary ID: `DICTIONARY`\n'
          'Версия словаря: `1`\n'
          'Статус: **APPROVED / STORED**\n'
          '### Collection: `ordered.collection`\n'
          'Тип записи: `ordered_block`\n'
          'Статус: **APPROVED / STORED**\n'
          '### Metadata `not-a-stable-key`\n'
          'Metadata text.\n'
          '### Rule (`Rule Key`)\n'
          'Approved statement.\n'
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

      final CanonicalDictionary dictionary = interpreter.interpret(
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceContent: source,
      );

      final entries = dictionary.collections.single.entries;

      expect(entries, hasLength(1));

      final CanonicalOrderedBlockEntry entry =
          entries.single as CanonicalOrderedBlockEntry;

      expect(entry.stableBlockKey, 'Rule Key');
      expect(entry.heading, 'Rule');
      expect(entry.items.single.text, 'Approved statement.');
    });

    test('respects non-keyed heading boundaries for terminal blocks', () {
      const String source =
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:BEGIN -->\n'
          'Dictionary ID: `DICTIONARY`\n'
          'Версия словаря: `1`\n'
          'Статус: **APPROVED / STORED**\n'
          '### Collection: `ordered.collection`\n'
          'Тип записи: `ordered_block`\n'
          'Статус: **APPROVED / STORED**\n'
          '### First (`First Key`)\n'
          'First statement.\n'
          '### Wrapper\n'
          '#### Second (`Second Key`)\n'
          'Second statement.\n'
          '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';

      final CanonicalDictionary dictionary = interpreter.interpret(
        sourceDocumentPath: 'docs/contract.md',
        sourceRevision: 'revision-1',
        sourceSnapshotFingerprint: 'git-blob:source',
        sourceContent: source,
      );

      final List<CanonicalOrderedBlockEntry> entries = dictionary
          .collections
          .single
          .entries
          .cast<CanonicalOrderedBlockEntry>();

      expect(entries, hasLength(2));

      expect(
        entries.map((CanonicalOrderedBlockEntry entry) => entry.stableBlockKey),
        <String>['First Key', 'Second Key'],
      );

      expect(
        entries.map((CanonicalOrderedBlockEntry entry) => entry.approvedOrder),
        <int>[1, 2],
      );

      expect(
        entries.map(
          (CanonicalOrderedBlockEntry entry) => entry.items.single.text,
        ),
        <String>['First statement.', 'Second statement.'],
      );
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

    test('loads the exact approved dictionary from the normative contract', () async {
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
            '61ffd614b9d04e83aeeaf89e720dd58ed7788fe44a3e5f27e657a5430c8b329c',
        sourceContent: await contract.readAsString(),
      );

      expect(
        dictionary.dictionaryId,
        'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1',
      );
      expect(dictionary.version, '1');
      expect(dictionary.status, 'APPROVED / STORED');

      expect(dictionary.approvedEquivalentEvidence, hasLength(1));

      final approvedEquivalent = dictionary.approvedEquivalentEvidence.single;

      expect(
        approvedEquivalent.identity,
        'helpy.canonical.approved-equivalent.electrical-safety-boundary.001',
      );
      expect(
        approvedEquivalent.canonicalEntryIdentity,
        'REGISTRY_STUDIO_CANONICAL_BUSINESS_DICTIONARY_V1::helpy.canonical.client_labels::sha256:09bad4adec8d4bc7e0995396df9af95ad197417022f64c04c2ba8301e2d85c99',
      );
      expect(
        approvedEquivalent.equivalentText,
        'Клиент не обязан выполнять опасные действия для предоставления информации.',
      );
      expect(approvedEquivalent.applicability, <String>[
        'RegistryPath: Helpy Architecture Registry v1 Foundation -> 23. Service Architecture Registry — Electrical -> Electrical Point Mini-TZ Standard',
      ]);
      expect(
        approvedEquivalent.approvalEvidenceId,
        'registry-studio.engineer-approval.2026-07-23.equivalent-001',
      );
      expect(
        approvedEquivalent.sourceEvidence.single.sourceDocumentPath,
        contract.path,
      );
      expect(
        approvedEquivalent.sourceEvidence.single.sourceSnapshotFingerprint,
        'sha256:61ffd614b9d04e83aeeaf89e720dd58ed7788fe44a3e5f27e657a5430c8b329c',
      );

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
    });

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
              '61ffd614b9d04e83aeeaf89e720dd58ed7788fe44a3e5f27e657a5430c8b329c',
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
          <String>['Используется только для сценария «Заменить».'],
        );

        final masterWorkflowBlocks = dictionary.collectionById(
          'helpy.canonical.master_workflow_blocks',
        )!;

        expect(masterWorkflowBlocks.entries, hasLength(5));

        final CanonicalOrderedBlockEntry firstMasterWorkflowBlock =
            masterWorkflowBlocks.entries.first as CanonicalOrderedBlockEntry;

        expect(
          firstMasterWorkflowBlock.stableBlockKey,
          'Compatibility Check Before Work',
        );
        expect(firstMasterWorkflowBlock.approvedOrder, 1);
        expect(firstMasterWorkflowBlock.items, hasLength(2));
        expect(
          firstMasterWorkflowBlock.approvedTextHash,
          'sha256:'
          '540753683707c9a42d6a6caf784e9ee79aac45df7836b031cfc5ef4140f5e9bb',
        );

        expect(
          masterWorkflowBlocks.entries
              .cast<CanonicalOrderedBlockEntry>()
              .map((entry) => entry.approvedOrder)
              .toList(growable: false),
          <int>[1, 2, 3, 4, 5],
        );

        final globalBusinessRules = dictionary.collectionById(
          'helpy.canonical.global_business_rules',
        )!;

        expect(globalBusinessRules.entries, hasLength(7));

        final CanonicalOrderedBlockEntry firstGlobalBusinessRule =
            globalBusinessRules.entries.first as CanonicalOrderedBlockEntry;

        expect(
          firstGlobalBusinessRule.stableBlockKey,
          'Client-Safe Scope Rule',
        );
        expect(firstGlobalBusinessRule.approvedOrder, 1);
        expect(firstGlobalBusinessRule.items, hasLength(6));
        expect(
          firstGlobalBusinessRule.approvedTextHash,
          'sha256:'
          '5444b70293b7bb754f330d8a1b9e6f591fea0be2098c918eb134648e5808a0f4',
        );

        expect(
          globalBusinessRules.entries
              .cast<CanonicalOrderedBlockEntry>()
              .map((entry) => entry.approvedOrder)
              .toList(growable: false),
          <int>[1, 2, 3, 4, 5, 6, 7],
        );

        expect(
          vocabulary.entries.every(
            (entry) =>
                entry.sourceDocumentPath == contract.path &&
                entry.sourceRevision ==
                    '7f3ff7f90fc8d8802f3fb8fcff851b23a224b920' &&
                entry.sourceSnapshotFingerprint ==
                    'sha256:'
                        '61ffd614b9d04e83aeeaf89e720dd58ed7788fe44a3e5f27e657a5430c8b329c' &&
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
    '### Правило № 1 — Безопасная область действий клиента '
    '(`Client-Safe Scope Rule`)\n'
    'Client-safe statement.\n'
    '<!-- REGISTRY_STUDIO_CANONICAL_DICTIONARY:END -->';
