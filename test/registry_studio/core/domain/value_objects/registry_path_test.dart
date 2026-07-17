import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  group('RegistryPath', () {
    test('normalizes semantic segments and preserves their order', () {
      final RegistryPath path = RegistryPath(<String>[
        ' service_intake ',
        ' plumbing ',
        ' faucet ',
        ' installation ',
      ]);

      expect(path.segments, <String>[
        'service_intake',
        'plumbing',
        'faucet',
        'installation',
      ]);
    });

    test('rejects an empty path and empty normalized segments', () {
      expect(() => RegistryPath(const <String>[]), throwsArgumentError);
      expect(
        () => RegistryPath(<String>['service_intake', '']),
        throwsArgumentError,
      );
      expect(
        () => RegistryPath(<String>['service_intake', '   ']),
        throwsArgumentError,
      );
    });

    test('owns an immutable copy of the supplied segments', () {
      final List<String> sourceSegments = <String>[
        'service_intake',
        'plumbing',
      ];
      final RegistryPath path = RegistryPath(sourceSegments);

      sourceSegments
        ..clear()
        ..add('electrical');

      expect(path.segments, <String>['service_intake', 'plumbing']);
      expect(() => path.segments.add('faucet'), throwsUnsupportedError);
    });

    test('uses normalized ordered segments for equality', () {
      final RegistryPath first = RegistryPath(<String>[
        ' service_intake ',
        ' plumbing ',
        ' faucet ',
      ]);
      final RegistryPath second = RegistryPath(<String>[
        'service_intake',
        'plumbing',
        'faucet',
      ]);
      final RegistryPath differentOrder = RegistryPath(<String>[
        'service_intake',
        'faucet',
        'plumbing',
      ]);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentOrder));
    });

    test('supports arbitrary path depth without fixed levels', () {
      final RegistryPath path = RegistryPath(
        List<String>.generate(
          12,
          (int index) => 'node_$index',
          growable: false,
        ),
      );

      expect(path.segments, hasLength(12));
      expect(path.segments.first, 'node_0');
      expect(path.segments.last, 'node_11');
    });
  });
}
