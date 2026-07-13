import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_source_block_extractor.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';

void main() {
  const ServiceIntakeSourceBlockExtractor extractor =
      ServiceIntakeSourceBlockExtractor();

  group('ServiceIntakeSourceBlockExtractor', () {
    test(
      'extracts exact H3 blocks in manifest order and includes nested headings',
      () {
        const String source =
            '# Registry\n'
            '## Owner A\n'
            'Owner introduction\n'
            '### Entity A\n'
            'A line\n'
            '#### Scenario\n'
            '- nested\n'
            '\n'
            '### Entity B\n'
            'B line\n'
            '## Owner B\n'
            '### Entity C\n'
            'C line\n';

        final List<ServiceIntakeSourceBlock> blocks = extractor.extract(
          source: source,
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(
              entityId: 'helpy.service_intake.test.entity_b',
              ownerHeading: 'Owner A',
              heading: 'Entity B',
            ),
            _identity(
              entityId: 'helpy.service_intake.test.entity_a',
              ownerHeading: 'Owner A',
              heading: 'Entity A',
            ),
          ],
        );

        expect(blocks, hasLength(2));

        expect(
          blocks.first.identity.entityId.value,
          'helpy.service_intake.test.entity_b',
        );
        expect(blocks.first.startLine, 9);
        expect(blocks.first.endLine, 10);
        expect(
          blocks.first.sourceText,
          '### Entity B\n'
          'B line\n',
        );

        expect(
          blocks.last.identity.entityId.value,
          'helpy.service_intake.test.entity_a',
        );
        expect(blocks.last.startLine, 4);
        expect(blocks.last.endLine, 8);
        expect(
          blocks.last.sourceText,
          '### Entity A\n'
          'A line\n'
          '#### Scenario\n'
          '- nested\n'
          '\n',
        );

        expect(() => blocks.add(blocks.first), throwsUnsupportedError);
      },
    );

    test('preserves CRLF source text without normalization', () {
      const String source =
          '## Owner\r\n'
          '### Entity\r\n'
          'line\r\n'
          '## Next\r\n';

      final ServiceIntakeSourceBlock block = extractor
          .extract(
            source: source,
            identities: <ServiceIntakeIdentityManifestEntry>[
              _identity(entityId: 'helpy.service_intake.test.entity'),
            ],
          )
          .single;

      expect(block.startLine, 2);
      expect(block.endLine, 3);
      expect(
        block.sourceText,
        '### Entity\r\n'
        'line\r\n',
      );
    });

    test('rejects a missing owner heading', () {
      expect(
        () => extractor.extract(
          source: '## Other\n### Entity\n',
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(entityId: 'helpy.service_intake.test.entity'),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects a duplicated owner heading', () {
      expect(
        () => extractor.extract(
          source:
              '## Owner\n'
              '### Entity\n'
              'first\n'
              '## Owner\n'
              '### Entity\n'
              'second\n',
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(entityId: 'helpy.service_intake.test.entity'),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects a duplicated entity heading inside its owner', () {
      expect(
        () => extractor.extract(
          source:
              '## Owner\n'
              '### Entity\n'
              'first\n'
              '### Entity\n'
              'second\n',
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(entityId: 'helpy.service_intake.test.entity'),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects locator levels outside the H2 to H3 contract', () {
      const String source =
          '## Owner\n'
          '### Entity\n'
          'content\n';

      expect(
        () => extractor.extract(
          source: source,
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(
              entityId: 'helpy.service_intake.test.owner_level',
              ownerHeadingLevel: 3,
            ),
          ],
        ),
        throwsFormatException,
      );

      expect(
        () => extractor.extract(
          source: source,
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(
              entityId: 'helpy.service_intake.test.entity_level',
              headingLevel: 4,
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicated or overlapping resolved ranges', () {
      const String source =
          '## Owner\n'
          '### Entity\n'
          'content\n';

      expect(
        () => extractor.extract(
          source: source,
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(entityId: 'helpy.service_intake.test.first'),
            _identity(entityId: 'helpy.service_intake.test.second'),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects empty source and empty manifest entries', () {
      expect(
        () => extractor.extract(
          source: ' \n ',
          identities: <ServiceIntakeIdentityManifestEntry>[
            _identity(entityId: 'helpy.service_intake.test.entity'),
          ],
        ),
        throwsFormatException,
      );

      expect(
        () => extractor.extract(
          source: '## Owner\n### Entity\n',
          identities: const <ServiceIntakeIdentityManifestEntry>[],
        ),
        throwsArgumentError,
      );
    });
  });
}

ServiceIntakeIdentityManifestEntry _identity({
  required String entityId,
  int ownerHeadingLevel = 2,
  String ownerHeading = 'Owner',
  int headingLevel = 3,
  String heading = 'Entity',
}) {
  return (
    entityId: RegistryEntityId(entityId),
    path: RegistryPath(entityId.split('.')),
    ownerHeadingLevel: ownerHeadingLevel,
    ownerHeading: ownerHeading,
    headingLevel: headingLevel,
    heading: heading,
  );
}
