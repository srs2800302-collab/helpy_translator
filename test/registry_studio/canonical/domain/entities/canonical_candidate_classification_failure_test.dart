import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_candidate_classification_failure.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  group('CanonicalCandidateClassificationFailure', () {
    test('preserves candidate-scoped parsing failure evidence', () {
      final List<SourceEvidence> evidence = <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'docs/registry.md',
          sourceSnapshotFingerprint: 'git-blob:registry',
          headingPath: const <String>['Services', 'Installation'],
          startLine: 100,
          endLine: 100,
        ),
      ];

      final CanonicalCandidateClassificationFailure failure =
          CanonicalCandidateClassificationFailure(
            identity: ' failure.candidate.install ',
            candidateIdentity: ' candidate.install ',
            kind: CanonicalCandidateClassificationFailureKind.parsing,
            message: ' Candidate text could not be parsed. ',
            sourceEvidence: evidence,
          );

      expect(failure.identity, 'failure.candidate.install');
      expect(failure.candidateIdentity, 'candidate.install');

      expect(failure.kind, CanonicalCandidateClassificationFailureKind.parsing);

      expect(failure.message, 'Candidate text could not be parsed.');

      expect(() => failure.sourceEvidence.clear(), throwsUnsupportedError);

      evidence.clear();

      expect(failure.sourceEvidence, hasLength(1));
    });

    test('preserves validation failure separately from parsing failure', () {
      final CanonicalCandidateClassificationFailure failure =
          CanonicalCandidateClassificationFailure(
            identity: 'failure.candidate.install',
            candidateIdentity: 'candidate.install',
            kind: CanonicalCandidateClassificationFailureKind.validation,
            message: 'Candidate evidence is inconsistent.',
            sourceEvidence: <SourceEvidence>[
              SourceEvidence(
                sourceDocumentPath: 'docs/registry.md',
                sourceSnapshotFingerprint: 'git-blob:registry',
                headingPath: const <String>['Services', 'Installation'],
                startLine: 100,
                endLine: 100,
              ),
            ],
          );

      expect(
        failure.kind,
        CanonicalCandidateClassificationFailureKind.validation,
      );
    });

    test('rejects an empty failure message', () {
      expect(
        () => CanonicalCandidateClassificationFailure(
          identity: 'failure.candidate.install',
          candidateIdentity: 'candidate.install',
          kind: CanonicalCandidateClassificationFailureKind.validation,
          message: ' ',
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'docs/registry.md',
              sourceSnapshotFingerprint: 'git-blob:registry',
              headingPath: const <String>['Services', 'Installation'],
              startLine: 100,
              endLine: 100,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
