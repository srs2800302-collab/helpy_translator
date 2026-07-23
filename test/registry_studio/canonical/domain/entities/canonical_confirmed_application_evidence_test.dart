import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_confirmed_application_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  group('CanonicalConfirmedApplicationEvidence', () {
    test('preserves the exact candidate, canonical entry and revision', () {
      final List<SourceEvidence> evidence = <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: 'docs/registry.md',
          sourceSnapshotFingerprint: 'git-blob:registry',
          headingPath: const <String>['Services', 'Installation'],
          startLine: 100,
          endLine: 100,
        ),
      ];

      final CanonicalConfirmedApplicationEvidence application =
          CanonicalConfirmedApplicationEvidence(
            identity: ' application.install ',
            candidateIdentity: ' candidate.install ',
            canonicalEntryIdentity: ' canonical.entry.install ',
            registrySourceRevision: ' revision-42 ',
            confirmationEvidenceId: ' confirmation-17 ',
            sourceEvidence: evidence,
          );

      expect(application.identity, 'application.install');
      expect(application.candidateIdentity, 'candidate.install');
      expect(application.canonicalEntryIdentity, 'canonical.entry.install');
      expect(application.registrySourceRevision, 'revision-42');
      expect(application.confirmationEvidenceId, 'confirmation-17');

      expect(() => application.sourceEvidence.clear(), throwsUnsupportedError);

      evidence.clear();

      expect(application.sourceEvidence, hasLength(1));
    });

    test('rejects an empty Registry revision', () {
      expect(
        () => CanonicalConfirmedApplicationEvidence(
          identity: 'application.install',
          candidateIdentity: 'candidate.install',
          canonicalEntryIdentity: 'canonical.entry.install',
          registrySourceRevision: ' ',
          confirmationEvidenceId: 'confirmation-17',
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

    test('rejects missing confirmation evidence', () {
      expect(
        () => CanonicalConfirmedApplicationEvidence(
          identity: 'application.install',
          candidateIdentity: 'candidate.install',
          canonicalEntryIdentity: 'canonical.entry.install',
          registrySourceRevision: 'revision-42',
          confirmationEvidenceId: ' ',
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
