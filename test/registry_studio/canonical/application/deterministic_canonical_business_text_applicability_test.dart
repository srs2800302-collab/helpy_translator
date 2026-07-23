import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/application/contracts/canonical_phrase_applicability_resolver.dart';
import 'package:helpy_translator/registry_studio/canonical/application/deterministic_canonical_business_text_classifier.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_confirmed_application_evidence.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_dictionary_collection.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  test('resolves applicable, inapplicable, and unresolved exact matches', () {
    for (final decision in CanonicalPhraseApplicabilityDecision.values) {
      final classification =
          DeterministicCanonicalBusinessTextClassifier(
                applicabilityResolver: _Resolver(decision),
              )
              .classify(candidates: _candidates(), dictionary: _dictionary())
              .classifications
              .single;

      switch (decision) {
        case CanonicalPhraseApplicabilityDecision.applicable:
          expect(
            classification.status,
            CanonicalBusinessTextClassificationStatus.exact,
          );
          expect(
            classification.reason,
            CanonicalBusinessTextClassificationReason
                .singleExactApplicableMatch,
          );
          expect(
            classification.matchedConfirmedApplicationEvidence,
            hasLength(1),
          );
        case CanonicalPhraseApplicabilityDecision.notApplicable:
          expect(
            classification.status,
            CanonicalBusinessTextClassificationStatus.unclassifiedNeutral,
          );
        case CanonicalPhraseApplicabilityDecision.unresolved:
          expect(
            classification.reason,
            CanonicalBusinessTextClassificationReason
                .exactTextRequiresApplicabilityReview,
          );
      }
    }
  });
}

final class _Resolver implements CanonicalPhraseApplicabilityResolver {
  const _Resolver(this.decision);
  final CanonicalPhraseApplicabilityDecision decision;

  @override
  CanonicalPhraseApplicabilityResolution resolve({
    required CanonicalBusinessTextCandidate candidate,
    required CanonicalPhraseEntry entry,
    required String registrySourceRevision,
  }) {
    return switch (decision) {
      CanonicalPhraseApplicabilityDecision.applicable =>
        CanonicalPhraseApplicabilityResolution.applicable(
          CanonicalConfirmedApplicationEvidence(
            identity: 'confirmed-1',
            candidateIdentity: candidate.identity,
            canonicalEntryIdentity: entry.identity,
            registrySourceRevision: registrySourceRevision,
            confirmationEvidenceId: 'test.confirmation.v1',
            sourceEvidence: candidate.sourceEvidence,
          ),
        ),
      CanonicalPhraseApplicabilityDecision.notApplicable =>
        const CanonicalPhraseApplicabilityResolution.notApplicable(),
      CanonicalPhraseApplicabilityDecision.unresolved =>
        const CanonicalPhraseApplicabilityResolution.unresolved(),
    };
  }
}

CanonicalBusinessTextCandidateIndex _candidates() {
  final RegistryPath path = RegistryPath(const <String>['Registry', 'Entity']);

  return CanonicalBusinessTextCandidateIndex(
    projectId: 'project',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'registry-revision',
    sourceSnapshotFingerprint: 'git-blob:registry',
    candidates: <CanonicalBusinessTextCandidate>[
      CanonicalBusinessTextCandidate(
        identity: 'candidate-1',
        nodeId: RegistryNodeId('node-1'),
        businessScopeOwnerId: RegistryEntityId('owner-1'),
        path: path,
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: 'git-blob:registry',
            headingPath: path.segments,
            startLine: 10,
            endLine: 10,
          ),
        ],
        kind: CanonicalBusinessTextCandidateKind.listItem,
        rawText: '- Подготовьте доступ.',
        text: 'Подготовьте доступ.',
        directContentLine: 1,
      ),
    ],
  );
}

CanonicalDictionary _dictionary() {
  return CanonicalDictionary(
    dictionaryId: 'DICTIONARY',
    version: '1',
    status: 'APPROVED / STORED',
    sourceDocumentPath: 'contract.md',
    sourceRevision: 'dictionary-revision',
    sourceSnapshotFingerprint: 'sha256:dictionary',
    sourceContent: 'dictionary',
    beginMarkerLine: 1,
    endMarkerLine: 10,
    collections: <CanonicalDictionaryCollection>[
      CanonicalDictionaryCollection(
        id: 'collection',
        entryType: 'phrase_with_applicability',
        status: 'APPROVED / STORED',
        content: '- Подготовьте доступ.',
        startLine: 2,
        endLine: 9,
        entries: <CanonicalPhraseEntry>[
          CanonicalPhraseEntry(
            dictionaryId: 'DICTIONARY',
            collectionId: 'collection',
            phrase: 'Подготовьте доступ.',
            applicability: const <String>['project-specific rule'],
            sourceDocumentPath: 'contract.md',
            sourceRevision: 'dictionary-revision',
            sourceSnapshotFingerprint: 'sha256:dictionary',
            sourceStartLine: 5,
            sourceEndLine: 5,
          ),
        ],
      ),
    ],
  );
}
