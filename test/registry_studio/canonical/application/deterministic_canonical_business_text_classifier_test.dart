import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/application/deterministic_canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_approved_equivalent_evidence.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  const DeterministicCanonicalBusinessTextClassifier classifier =
      DeterministicCanonicalBusinessTextClassifier();

  group('DeterministicCanonicalBusinessTextClassifier', () {
    test('uses technical whitespace normalization only', () {
      final CanonicalBusinessTextClassificationIndex index = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(
                identity: 'candidate-exact',
                text:
                    'Фотография   места\n'
                    'установки.',
              ),
              _candidate(
                identity: 'candidate-punctuation',
                text: 'Фотография места установки!',
              ),
              _candidate(
                identity: 'candidate-case',
                text: 'фотография места установки.',
              ),
            ]),
            dictionary: _dictionary(<CanonicalPhraseEntry>[
              _entry(phrase: 'Фотография места установки.'),
            ]),
          );

      expect(
        index.classificationsByCandidateIdentity['candidate-exact']?.status,
        CanonicalBusinessTextClassificationStatus.exact,
      );

      expect(
        index
            .classificationsByCandidateIdentity['candidate-punctuation']
            ?.status,
        CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
      );

      expect(
        index.classificationsByCandidateIdentity['candidate-case']?.status,
        CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
      );
    });

    test('requires review when applicability is unresolved', () {
      final CanonicalBusinessTextClassification classification = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(identity: 'candidate-1', text: 'Подготовьте доступ.'),
            ]),
            dictionary: _dictionary(<CanonicalPhraseEntry>[
              _entry(
                phrase: 'Подготовьте доступ.',
                applicability: const <String>['Только для установки.'],
              ),
            ]),
          )
          .classifications
          .single;

      expect(
        classification.status,
        CanonicalBusinessTextClassificationStatus.review,
      );

      expect(
        classification.reason,
        CanonicalBusinessTextClassificationReason
            .exactTextRequiresApplicabilityReview,
      );
    });

    test('requires review for ambiguous exact text', () {
      final CanonicalBusinessTextClassification classification = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(identity: 'candidate-1', text: 'Подготовьте доступ.'),
            ]),
            dictionary: _dictionary(<CanonicalPhraseEntry>[
              _entry(
                collectionId: 'collection.a',
                phrase: 'Подготовьте доступ.',
              ),
              _entry(
                collectionId: 'collection.b',
                phrase: 'Подготовьте доступ.',
              ),
            ]),
          )
          .classifications
          .single;

      expect(
        classification.status,
        CanonicalBusinessTextClassificationStatus.review,
      );

      expect(
        classification.reason,
        CanonicalBusinessTextClassificationReason
            .ambiguousExactCanonicalTextMatch,
      );

      expect(classification.matchedCanonicalEntries, hasLength(2));
    });

    test('classifies only a path-applicable approved equivalent', () {
      final CanonicalPhraseEntry canonicalEntry = _entry(
        collectionId: 'helpy.canonical.client_labels',
        phrase:
            'Вы не обязаны выполнять опасные действия для предоставления информации.',
      );

      final CanonicalDictionary dictionary = _dictionary(
        <CanonicalPhraseEntry>[canonicalEntry],
        approvedEquivalentEvidence: <CanonicalApprovedEquivalentEvidence>[
          CanonicalApprovedEquivalentEvidence(
            identity:
                'helpy.canonical.approved-equivalent.electrical-safety-boundary.001',
            canonicalEntryIdentity: canonicalEntry.identity,
            equivalentText:
                'Клиент не обязан выполнять опасные действия для предоставления информации.',
            applicability: const <String>[
              'RegistryPath: Registry -> Business Rules',
            ],
            approvalEvidenceId:
                'registry-studio.engineer-approval.2026-07-23.equivalent-001',
            sourceEvidence: <SourceEvidence>[
              SourceEvidence(
                sourceDocumentPath: 'contract.md',
                sourceSnapshotFingerprint: 'sha256:dictionary',
                headingPath: const <String>[
                  'Canonical Dictionary',
                  'Approved equivalent evidence',
                ],
                startLine: 4,
                endLine: 4,
              ),
            ],
          ),
        ],
      );

      final CanonicalBusinessTextClassification classification = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(
                identity: 'candidate-equivalent',
                text:
                    'Клиент не обязан выполнять опасные действия для предоставления информации.',
              ),
            ]),
            dictionary: dictionary,
          )
          .classifications
          .single;

      expect(
        classification.status,
        CanonicalBusinessTextClassificationStatus.equivalent,
      );
      expect(
        classification.reason,
        CanonicalBusinessTextClassificationReason.singleApprovedEquivalentMatch,
      );
      expect(classification.matchedCanonicalEntries, <CanonicalPhraseEntry>[
        canonicalEntry,
      ]);
      expect(classification.matchedApprovedEquivalentEvidence, hasLength(1));
    });

    test('classifies every candidate exactly once', () {
      final CanonicalBusinessTextClassificationIndex index = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(identity: 'candidate-exact', text: 'Exact phrase.'),
              _candidate(
                identity: 'candidate-neutral',
                text: 'Unknown phrase.',
              ),
            ]),
            dictionary: _dictionary(<CanonicalPhraseEntry>[
              _entry(phrase: 'Exact phrase.'),
            ]),
          );

      expect(index.classifications, hasLength(2));

      expect(index.classificationsByCandidateIdentity, hasLength(2));

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.exact),
        1,
      );

      expect(
        index.countFor(
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        ),
        1,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.equivalent),
        0,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.drift),
        0,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.failed),
        0,
      );
    });

    test('classifies exact, applicability, ambiguity and '
        'punctuation cases against the normative dictionary', () async {
      final File contract = File(
        'docs/architecture/registry_studio/'
        'Registry_Studio_Engineering_Change_Propagation_'
        'and_Approval_Contract_v1.md',
      );

      expect(await contract.exists(), isTrue);

      final CanonicalDictionary
      dictionary = const HelpyCanonicalDictionaryDocumentInterpreter().interpret(
        sourceDocumentPath: contract.path,
        sourceRevision: '3ac566fc7779f997ca46325cbf2af78d391d6aac',
        sourceSnapshotFingerprint:
            'sha256:'
            '61ffd614b9d04e83aeeaf89e720dd58ed7788fe44a3e5f27e657a5430c8b329c',
        sourceContent: await contract.readAsString(),
      );

      final CanonicalBusinessTextClassificationIndex index = classifier
          .classify(
            candidates: _candidateIndex(<CanonicalBusinessTextCandidate>[
              _candidate(
                identity: 'candidate-unique',
                text: 'Фотография места установки.',
              ),
              _candidate(
                identity: 'candidate-applicability',
                text:
                    'Подготовьте доступ к месту '
                    'выполнения работ.',
              ),
              _candidate(
                identity: 'candidate-ambiguous',
                text:
                    'Подготовьте доступ к установленному '
                    'оборудованию.',
              ),
              _candidate(
                identity: 'candidate-punctuation',
                text: 'Фотография места установки!',
              ),
            ]),
            dictionary: dictionary,
          );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.exact),
        1,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.review),
        2,
      );

      expect(
        index.countFor(
          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
        ),
        1,
      );

      expect(
        index
            .classificationsByCandidateIdentity['candidate-applicability']
            ?.reason,
        CanonicalBusinessTextClassificationReason
            .exactTextRequiresApplicabilityReview,
      );

      expect(
        index.classificationsByCandidateIdentity['candidate-ambiguous']?.reason,
        CanonicalBusinessTextClassificationReason
            .exactTextRequiresApplicabilityReview,
      );

      expect(
        index
            .classificationsByCandidateIdentity['candidate-ambiguous']
            ?.matchedCanonicalEntries,
        hasLength(1),
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.equivalent),
        0,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.drift),
        0,
      );

      expect(
        index.countFor(CanonicalBusinessTextClassificationStatus.failed),
        0,
      );
    });
  });
}

CanonicalBusinessTextCandidateIndex _candidateIndex(
  Iterable<CanonicalBusinessTextCandidate> candidates,
) {
  return CanonicalBusinessTextCandidateIndex(
    projectId: 'helpy',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: 'git-blob:registry',
    candidates: candidates,
  );
}

CanonicalBusinessTextCandidate _candidate({
  required String identity,
  required String text,
}) {
  final RegistryPath path = RegistryPath(const <String>[
    'Registry',
    'Business Rules',
  ]);

  return CanonicalBusinessTextCandidate(
    identity: identity,
    nodeId: RegistryNodeId('node-$identity'),
    businessScopeOwnerId: RegistryEntityId('owner-1'),
    path: path,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'git-blob:registry',
        headingPath: path.segments,
        startLine: 1,
        endLine: 10,
      ),
    ],
    kind: CanonicalBusinessTextCandidateKind.listItem,
    rawText: '- $text',
    text: text,
    directContentLine: 1,
  );
}

CanonicalDictionary _dictionary(
  Iterable<CanonicalPhraseEntry> entries, {
  Iterable<CanonicalApprovedEquivalentEvidence> approvedEquivalentEvidence =
      const <CanonicalApprovedEquivalentEvidence>[],
}) {
  final Map<String, List<CanonicalPhraseEntry>> entriesByCollectionId =
      <String, List<CanonicalPhraseEntry>>{};

  for (final CanonicalPhraseEntry entry in entries) {
    entriesByCollectionId
        .putIfAbsent(entry.collectionId, () => <CanonicalPhraseEntry>[])
        .add(entry);
  }

  return CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 1000,
    collections: <CanonicalDictionaryCollection>[
      for (final MapEntry<String, List<CanonicalPhraseEntry>> collection
          in entriesByCollectionId.entries)
        CanonicalDictionaryCollection(
          id: collection.key,
          entryType: 'phrase',
          status: 'APPROVED / STORED',
          content: collection.value
              .map((CanonicalPhraseEntry entry) => '- ${entry.phrase}')
              .join('\n'),
          startLine: 2,
          endLine: 999,
          entries: collection.value,
        ),
    ],
    approvedEquivalentEvidence: approvedEquivalentEvidence,
  );
}

CanonicalPhraseEntry _entry({
  required String phrase,
  String collectionId = 'collection',
  Iterable<String> applicability = const <String>[],
}) {
  return CanonicalPhraseEntry(
    dictionaryId: 'DICTIONARY',
    collectionId: collectionId,
    phrase: phrase,
    applicability: applicability,
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 5,
    sourceEndLine: 6,
  );
}
