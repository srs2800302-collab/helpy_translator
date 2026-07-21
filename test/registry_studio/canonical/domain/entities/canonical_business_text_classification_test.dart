import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_classification_status.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_phrase_entry.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  group('CanonicalBusinessTextClassification', () {
    test('accepts one universal canonical entry as exact', () {
      final CanonicalPhraseEntry entry = _entry(
        identity: 'dictionary::photo',
        phrase: 'Фотография места установки.',
      );

      final CanonicalBusinessTextClassification classification =
          CanonicalBusinessTextClassification(
            candidate: _candidate(
              identity: 'candidate-1',
              text: 'Фотография места установки.',
            ),
            status: CanonicalBusinessTextClassificationStatus.exact,
            reason: CanonicalBusinessTextClassificationReason
                .singleExactUniversalMatch,
            matchedCanonicalEntries: <CanonicalPhraseEntry>[entry],
          );

      expect(classification.matchedCanonicalEntries, <CanonicalPhraseEntry>[
        entry,
      ]);

      expect(
        () => classification.matchedCanonicalEntries.clear(),
        throwsUnsupportedError,
      );
    });

    test('rejects exact status when applicability is unresolved', () {
      expect(
        () => CanonicalBusinessTextClassification(
          candidate: _candidate(
            identity: 'candidate-1',
            text: 'Подготовьте доступ.',
          ),
          status: CanonicalBusinessTextClassificationStatus.exact,
          reason: CanonicalBusinessTextClassificationReason
              .singleExactUniversalMatch,
          matchedCanonicalEntries: <CanonicalPhraseEntry>[
            _entry(
              identity: 'dictionary::preparation',
              phrase: 'Подготовьте доступ.',
              applicability: const <String>['Только для установки.'],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an unsupported status and reason combination', () {
      expect(
        () => CanonicalBusinessTextClassification(
          candidate: _candidate(identity: 'candidate-1', text: 'Фраза.'),
          status: CanonicalBusinessTextClassificationStatus.drift,
          reason: CanonicalBusinessTextClassificationReason
              .noExactCanonicalTextMatch,
        ),
        throwsArgumentError,
      );
    });
  });
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
    nodeId: RegistryNodeId('node-1'),
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
    sourceStartLine: 100,
    sourceEndLine: 101,
  );
}
