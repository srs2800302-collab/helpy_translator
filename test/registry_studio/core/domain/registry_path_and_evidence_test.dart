import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('RegistryPath', () {
    test('normalizes and preserves semantic segments', () {
      final RegistryPath path = RegistryPath(<String>[
        ' sample_adapter ',
        ' sample_domain ',
        ' sample_entity ',
      ]);

      expect(path.segments, <String>['sample_adapter', 'sample_domain', 'sample_entity']);
      expect(() => path.segments.add('line_10014'), throwsUnsupportedError);
    });

    test('rejects an empty path or an empty semantic segment', () {
      expect(() => RegistryPath(const <String>[]), throwsArgumentError);
      expect(() => RegistryPath(<String>['sample_adapter', '']), throwsArgumentError);
    });
  });

  group('SourceEvidence', () {
    test('stores provenance independently from registry identity', () {
      final SourceEvidence evidence = SourceEvidence(
        sourceDocumentPath:
            'docs/architecture/Registry_Studio_Source_v1.md',
        sourceSnapshotFingerprint: 'sha256:abc123',
        headingPath: <String>['Sample Domain', 'Sample Entity'],
        startLine: 10014,
        endLine: 10314,
      );

      expect(evidence.headingPath, <String>['Sample Domain', 'Sample Entity']);
      expect(evidence.startLine, 10014);
      expect(evidence.endLine, 10314);
    });

    test('rejects invalid provenance coordinates', () {
      expect(
        () => SourceEvidence(
          sourceDocumentPath: '',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: <String>['Sample Domain'],
          startLine: 1,
          endLine: 1,
        ),
        throwsArgumentError,
      );

      expect(
        () => SourceEvidence(
          sourceDocumentPath: 'registry.md',
          sourceSnapshotFingerprint: 'sha256:abc123',
          headingPath: <String>['Sample Domain'],
          startLine: 10,
          endLine: 9,
        ),
        throwsArgumentError,
      );
    });
  });
}
