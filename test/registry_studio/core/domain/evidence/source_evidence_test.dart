import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  group('SourceEvidence', () {
    test('normalizes and preserves exact source coordinates', () {
      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: ' docs/architecture/registry.md ',
        sourceSnapshotFingerprint: ' sha256:abc123 ',
        headingPath: <String>[' Service Intake ', ' Plumbing ', ' Faucet '],
        startLine: 120,
        endLine: 136,
      );

      expect(evidence.sourceDocumentPath, 'docs/architecture/registry.md');
      expect(evidence.sourceSnapshotFingerprint, 'sha256:abc123');
      expect(evidence.headingPath, <String>[
        'Service Intake',
        'Plumbing',
        'Faucet',
      ]);
      expect(evidence.startLine, 120);
      expect(evidence.endLine, 136);
    });

    test('rejects empty source document and fingerprint values', () {
      expect(
        () => SourceEvidence(
          sourceDocumentPath: '',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: '   ',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: '',
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: '   ',
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty heading path and empty normalized segments', () {
      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>[],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry', ''],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry', '   '],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid source line ranges', () {
      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry'],
          startLine: 0,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry'],
          startLine: -1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: const <String>['Registry'],
          startLine: 10,
          endLine: 9,
        ),
        throwsArgumentError,
      );
    });

    test('owns an immutable copy of the heading path', () {
      final List<String> sourceHeadingPath = <String>[
        'Registry',
        'Service Intake',
      ];

      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: sourceHeadingPath,
        startLine: 10,
        endLine: 20,
      );

      sourceHeadingPath
        ..clear()
        ..add('Another Branch');

      expect(evidence.headingPath, <String>['Registry', 'Service Intake']);
      expect(
        () => evidence.headingPath.add('Plumbing'),
        throwsUnsupportedError,
      );
    });

    test('uses all normalized source coordinates for equality', () {
      final SourceEvidence first = SourceEvidence(
        sourceDocumentPath: ' registry.md ',
        sourceSnapshotFingerprint: ' sha256:abc123 ',
        headingPath: const <String>[' Registry ', ' Plumbing '],
        startLine: 10,
        endLine: 20,
      );

      final SourceEvidence second = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: const <String>['Registry', 'Plumbing'],
        startLine: 10,
        endLine: 20,
      );

      final SourceEvidence differentSnapshot = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:def456',
        headingPath: const <String>['Registry', 'Plumbing'],
        startLine: 10,
        endLine: 20,
      );

      final SourceEvidence differentRange = SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: const <String>['Registry', 'Plumbing'],
        startLine: 11,
        endLine: 20,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentSnapshot));
      expect(first, isNot(differentRange));
    });
  });
}
