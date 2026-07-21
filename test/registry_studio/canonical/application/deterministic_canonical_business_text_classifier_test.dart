import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_dictionary_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/application/deterministic_canonical_business_text_classifier.dart';
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
              _entry(
                identity: 'dictionary::photo',
                phrase: 'Фотография места установки.',
              ),
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
                identity: 'dictionary::preparation',
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
              _entry(identity: 'dictionary::a', phrase: 'Подготовьте доступ.'),
              _entry(identity: 'dictionary::b', phrase: 'Подготовьте доступ.'),
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
              _entry(identity: 'dictionary::exact', phrase: 'Exact phrase.'),
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
            '73bb98686befe8885e487427537db32d54be7e3443b5d3b4aa192f9d03c976a6',
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
            .ambiguousExactCanonicalTextMatch,
      );

      expect(
        index
            .classificationsByCandidateIdentity['candidate-ambiguous']
            ?.matchedCanonicalEntries,
        hasLength(2),
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

CanonicalDictionary _dictionary(Iterable<CanonicalPhraseEntry> entries) {
  return CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary source',
    beginMarkerLine: 1,
    endMarkerLine: 20,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'collection',
        entryType: 'phrase',
        status: 'APPROVED / STORED',
        content: 'approved phrases',
        startLine: 2,
        endLine: 19,
        entries: entries,
      ),
    ],
  );
}

CanonicalPhraseEntry _entry({
  required String identity,
  required String phrase,
  Iterable<String> applicability = const <String>[],
}) {
  return CanonicalPhraseEntry(
    identity: identity,
    collectionId: 'collection',
    phrase: phrase,
    applicability: applicability,
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceStartLine: 5,
    sourceEndLine: 6,
  );
}
