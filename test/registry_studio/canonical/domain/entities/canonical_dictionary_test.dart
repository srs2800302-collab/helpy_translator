import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_approved_equivalent_evidence.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  group('CanonicalDictionary', () {
    test('preserves exact source identity and immutable collections', () {
      final List<CanonicalDictionaryCollection> sourceCollections =
          <CanonicalDictionaryCollection>[
            CanonicalDictionaryCollection(
              id: 'sample.canonical.phrases',
              entryType: 'phrase',
              status: 'APPROVED / STORED',
              content: '- Canonical phrase.',
              startLine: 10,
              endLine: 15,
            ),
          ];

      final CanonicalDictionary dictionary = CanonicalDictionary(
        dictionaryId: ' SAMPLE_DICTIONARY ',
        version: ' 1 ',
        status: ' APPROVED / STORED ',
        sourceDocumentPath: ' docs/contract.md ',
        sourceRevision: ' revision-1 ',
        sourceSnapshotFingerprint: ' git-blob:source ',
        sourceContent: 'source content',
        beginMarkerLine: 5,
        endMarkerLine: 20,
        collections: sourceCollections,
      );

      sourceCollections.clear();

      expect(dictionary.dictionaryId, 'SAMPLE_DICTIONARY');
      expect(dictionary.version, '1');
      expect(dictionary.status, 'APPROVED / STORED');
      expect(dictionary.sourceDocumentPath, 'docs/contract.md');
      expect(dictionary.sourceRevision, 'revision-1');
      expect(dictionary.collections, hasLength(1));
      expect(dictionary.approvedEquivalentEvidence, isEmpty);
      expect(
        dictionary.collectionById('sample.canonical.phrases')?.entryType,
        'phrase',
      );

      expect(
        () => dictionary.collections.add(
          CanonicalDictionaryCollection(
            id: 'other',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: 'Other.',
            startLine: 16,
            endLine: 17,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('rejects duplicate collection identities', () {
      final CanonicalDictionaryCollection collection =
          CanonicalDictionaryCollection(
            id: 'sample.canonical.phrases',
            entryType: 'phrase',
            status: 'APPROVED / STORED',
            content: '- Canonical phrase.',
            startLine: 10,
            endLine: 15,
          );

      expect(
        () => CanonicalDictionary(
          dictionaryId: 'SAMPLE_DICTIONARY',
          version: '1',
          status: 'APPROVED / STORED',
          sourceDocumentPath: 'docs/contract.md',
          sourceRevision: 'revision-1',
          sourceSnapshotFingerprint: 'git-blob:source',
          sourceContent: 'source content',
          beginMarkerLine: 5,
          endMarkerLine: 20,
          collections: <CanonicalDictionaryCollection>[collection, collection],
        ),
        throwsArgumentError,
      );
    });

    test('rejects collections outside stable dictionary markers', () {
      expect(
        () => CanonicalDictionary(
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
              startLine: 5,
              endLine: 15,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test(
      'owns immutable approved-equivalent evidence for canonical phrases',
      () {
        final CanonicalPhraseEntry phrase = _phrase();

        final CanonicalApprovedEquivalentEvidence approvedEquivalent =
            CanonicalApprovedEquivalentEvidence(
              identity: 'equivalent.install',
              canonicalEntryIdentity: phrase.identity,
              equivalentText: 'Approved equivalent.',
              approvalEvidenceId: 'decision-42',
              sourceEvidence: <SourceEvidence>[_sourceEvidence()],
            );

        final List<CanonicalApprovedEquivalentEvidence> sourceEvidence =
            <CanonicalApprovedEquivalentEvidence>[approvedEquivalent];

        final CanonicalDictionary dictionary = _dictionary(
          entries: <CanonicalPhraseEntry>[phrase],
          approvedEquivalentEvidence: sourceEvidence,
        );

        sourceEvidence.clear();

        expect(
          dictionary.approvedEquivalentEvidence,
          <CanonicalApprovedEquivalentEvidence>[approvedEquivalent],
        );

        expect(
          () => dictionary.approvedEquivalentEvidence.clear(),
          throwsUnsupportedError,
        );
      },
    );

    test('rejects an entry from another exact source revision', () {
      final CanonicalPhraseEntry phrase = _phrase(sourceRevision: 'revision-2');

      expect(
        () => _dictionary(entries: <CanonicalPhraseEntry>[phrase]),
        throwsArgumentError,
      );
    });

    test('rejects approved equivalent for an unknown canonical phrase', () {
      final CanonicalApprovedEquivalentEvidence approvedEquivalent =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.install',
            canonicalEntryIdentity: 'unknown-entry',
            equivalentText: 'Approved equivalent.',
            approvalEvidenceId: 'decision-42',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      expect(
        () => _dictionary(
          approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
            approvedEquivalent,
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects approved equivalent from another dictionary fingerprint', () {
      final CanonicalPhraseEntry phrase = _phrase();

      final CanonicalApprovedEquivalentEvidence approvedEquivalent =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.install',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Approved equivalent.',
            approvalEvidenceId: 'decision-42',
            sourceEvidence: <SourceEvidence>[
              _sourceEvidence(sourceSnapshotFingerprint: 'git-blob:other'),
            ],
          );

      expect(
        () => _dictionary(
          entries: <CanonicalPhraseEntry>[phrase],
          approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
            approvedEquivalent,
          ],
        ),
        throwsArgumentError,
      );
    });

    test('allows one equivalent text with distinct applicability evidence', () {
      final CanonicalPhraseEntry phrase = _phrase();

      final CanonicalApprovedEquivalentEvidence installEvidence =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.install',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Approved equivalent.',
            applicability: const <String>['Install only.'],
            approvalEvidenceId: 'decision-install',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      final CanonicalApprovedEquivalentEvidence replacementEvidence =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.replacement',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Approved equivalent.',
            applicability: const <String>['Replacement only.'],
            approvalEvidenceId: 'decision-replacement',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      final CanonicalDictionary dictionary = _dictionary(
        entries: <CanonicalPhraseEntry>[phrase],
        approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
          installEvidence,
          replacementEvidence,
        ],
      );

      expect(
        dictionary.approvedEquivalentEvidence,
        <CanonicalApprovedEquivalentEvidence>[
          installEvidence,
          replacementEvidence,
        ],
      );
    });

    test('rejects duplicate equivalent text with identical applicability', () {
      final CanonicalPhraseEntry phrase = _phrase();

      final CanonicalApprovedEquivalentEvidence firstEvidence =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.first',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Approved equivalent.',
            applicability: const <String>['Install only.'],
            approvalEvidenceId: 'decision-first',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      final CanonicalApprovedEquivalentEvidence duplicateEvidence =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.duplicate',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Approved   equivalent.',
            applicability: const <String>['Install   only.'],
            approvalEvidenceId: 'decision-duplicate',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      expect(
        () => _dictionary(
          entries: <CanonicalPhraseEntry>[phrase],
          approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
            firstEvidence,
            duplicateEvidence,
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects exact canonical text presented as an equivalent', () {
      final CanonicalPhraseEntry phrase = _phrase();

      final CanonicalApprovedEquivalentEvidence approvedEquivalent =
          CanonicalApprovedEquivalentEvidence(
            identity: 'equivalent.install',
            canonicalEntryIdentity: phrase.identity,
            equivalentText: 'Canonical   phrase.',
            approvalEvidenceId: 'decision-42',
            sourceEvidence: <SourceEvidence>[_sourceEvidence()],
          );

      expect(
        () => _dictionary(
          entries: <CanonicalPhraseEntry>[phrase],
          approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
            approvedEquivalent,
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

CanonicalDictionary _dictionary({
  Iterable<CanonicalPhraseEntry> entries = const <CanonicalPhraseEntry>[],
  Iterable<CanonicalApprovedEquivalentEvidence> approvedEquivalentEvidence =
      const <CanonicalApprovedEquivalentEvidence>[],
}) {
  return CanonicalDictionary(
    dictionaryId: 'SAMPLE_DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'docs/contract.md',
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: 'git-blob:source',
    sourceContent: 'source content',
    beginMarkerLine: 5,
    endMarkerLine: 30,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'sample.canonical.phrases',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: '- Canonical phrase.',
        startLine: 10,
        endLine: 15,
        entries: entries,
      ),
    ],
    approvedEquivalentEvidence: approvedEquivalentEvidence,
  );
}

CanonicalPhraseEntry _phrase({String sourceRevision = 'revision-1'}) {
  return CanonicalPhraseEntry(
    dictionaryId: 'SAMPLE_DICTIONARY',
    collectionId: 'sample.canonical.phrases',
    phrase: 'Canonical phrase.',
    sourceDocumentPath: 'docs/contract.md',
    sourceRevision: sourceRevision,
    sourceSnapshotFingerprint: 'git-blob:source',
    sourceStartLine: 12,
    sourceEndLine: 12,
  );
}

SourceEvidence _sourceEvidence({
  String sourceSnapshotFingerprint = 'git-blob:source',
}) {
  return SourceEvidence(
    sourceDocumentPath: 'docs/contract.md',
    sourceSnapshotFingerprint: sourceSnapshotFingerprint,
    headingPath: const <String>['Canonical Dictionary', 'Approved equivalents'],
    startLine: 20,
    endLine: 20,
  );
}
