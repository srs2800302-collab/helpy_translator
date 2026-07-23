import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_approved_equivalent_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  group('CanonicalApprovedEquivalentEvidence', () {
    test(
      'preserves approved equivalent identity, applicability and evidence',
      () {
        final List<String> applicability = <String>['Install only.'];

        final List<SourceEvidence> evidence = <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'docs/contract.md',
            sourceSnapshotFingerprint: 'git-blob:contract',
            headingPath: const <String>['Canonical Dictionary'],
            startLine: 10,
            endLine: 11,
          ),
        ];

        final CanonicalApprovedEquivalentEvidence approvedEquivalent =
            CanonicalApprovedEquivalentEvidence(
              identity: ' equivalent.install ',
              canonicalEntryIdentity: ' canonical.entry.install ',
              equivalentText: ' Approved equivalent. ',
              applicability: applicability,
              approvalEvidenceId: ' decision-42 ',
              sourceEvidence: evidence,
            );

        expect(approvedEquivalent.identity, 'equivalent.install');
        expect(
          approvedEquivalent.canonicalEntryIdentity,
          'canonical.entry.install',
        );
        expect(approvedEquivalent.equivalentText, 'Approved equivalent.');
        expect(approvedEquivalent.applicability, <String>['Install only.']);
        expect(approvedEquivalent.approvalEvidenceId, 'decision-42');

        expect(
          () => approvedEquivalent.applicability.add('Other.'),
          throwsUnsupportedError,
        );

        expect(
          () => approvedEquivalent.sourceEvidence.clear(),
          throwsUnsupportedError,
        );

        applicability.add('Replacement only.');
        evidence.clear();

        expect(approvedEquivalent.applicability, <String>['Install only.']);
        expect(approvedEquivalent.sourceEvidence, hasLength(1));
      },
    );

    test('rejects duplicate applicability values', () {
      expect(
        () => CanonicalApprovedEquivalentEvidence(
          identity: 'equivalent.install',
          canonicalEntryIdentity: 'canonical.entry.install',
          equivalentText: 'Approved equivalent.',
          applicability: const <String>['Install only.', 'Install only.'],
          approvalEvidenceId: 'decision-42',
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'docs/contract.md',
              sourceSnapshotFingerprint: 'git-blob:contract',
              headingPath: const <String>['Canonical Dictionary'],
              startLine: 10,
              endLine: 11,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects missing approval evidence', () {
      expect(
        () => CanonicalApprovedEquivalentEvidence(
          identity: 'equivalent.install',
          canonicalEntryIdentity: 'canonical.entry.install',
          equivalentText: 'Approved equivalent.',
          approvalEvidenceId: ' ',
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: 'docs/contract.md',
              sourceSnapshotFingerprint: 'git-blob:contract',
              headingPath: const <String>['Canonical Dictionary'],
              startLine: 10,
              endLine: 11,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
