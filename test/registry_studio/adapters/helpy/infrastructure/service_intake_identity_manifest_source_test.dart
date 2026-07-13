import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_identity_manifest_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceIntakeIdentityManifestSource', () {
    test('loads the actual v1 manifest with 27 stable identities', () async {
      final ServiceIntakeIdentityManifestSource source =
          ServiceIntakeIdentityManifestSource(assetBundle: rootBundle);

      final List<ServiceIntakeIdentityManifestEntry> entries = await source
          .load();

      expect(entries, hasLength(27));
      expect(
        entries.first.entityId.value,
        'helpy.service_intake.appliance.washing_machine',
      );
      expect(
        entries.last.entityId.value,
        'helpy.service_intake.locks.furniture_lock_replacement',
      );

      final ServiceIntakeIdentityManifestEntry faucet = entries.singleWhere(
        (ServiceIntakeIdentityManifestEntry entry) =>
            entry.entityId.value == 'helpy.service_intake.plumbing.faucet',
      );

      expect(faucet.path.segments, <String>[
        'helpy',
        'service_intake',
        'plumbing',
        'faucet',
      ]);
      expect(faucet.ownerHeadingLevel, 2);
      expect(faucet.ownerHeading, 'Plumbing Mini-TZ Standard');
      expect(faucet.headingLevel, 3);
      expect(faucet.heading, 'Plumbing → Кран');

      expect(() => entries.add(entries.first), throwsUnsupportedError);
    });

    test('loads manifest content through the injected AssetBundle', () async {
      final ServiceIntakeIdentityManifestSource source =
          ServiceIntakeIdentityManifestSource(
            assetBundle: _MemoryAssetBundle(
              _manifest(<Map<String, Object?>>[_entry()]),
            ),
            assetPath: 'manifest.json',
          );

      final List<ServiceIntakeIdentityManifestEntry> entries = await source
          .load();

      expect(entries, hasLength(1));
      expect(
        entries.single.entityId.value,
        'helpy.service_intake.plumbing.faucet',
      );
      expect(entries.single.heading, 'Plumbing → Кран');
    });

    test('rejects an unsupported manifest version', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[_entry()], version: 'v2'),
        ),
        throwsFormatException,
      );
    });

    test('rejects an empty entry collection', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(_manifest(const <Map<String, Object?>>[])),
        throwsFormatException,
      );
    });

    test('rejects unknown top-level fields', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(
            <Map<String, Object?>>[_entry()],
            additionalFields: const <String, Object?>{'unknown': true},
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects an incomplete entry', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[
            _entry(includeSourceLocator: false),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate entity identities', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();
      final Map<String, Object?> duplicate = _entry();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[duplicate, duplicate]),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate source locators', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[
            _entry(),
            _entry(
              entityId: 'helpy.service_intake.plumbing.toilet',
              path: const <String>[
                'helpy',
                'service_intake',
                'plumbing',
                'toilet',
              ],
            ),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects a RegistryEntityId that does not match RegistryPath', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[
            _entry(
              path: const <String>[
                'helpy',
                'service_intake',
                'plumbing',
                'toilet',
              ],
            ),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects an identity outside the adapter namespace', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[
            _entry(
              entityId: 'other.service_intake.plumbing.faucet',
              path: const <String>[
                'other',
                'service_intake',
                'plumbing',
                'faucet',
              ],
            ),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects locator levels outside the H2 to H3 contract', () {
      final ServiceIntakeIdentityManifestSource source = _decoder();

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[_entry(ownerHeadingLevel: 3)]),
        ),
        throwsFormatException,
      );

      expect(
        () => source.decode(
          _manifest(<Map<String, Object?>>[_entry(headingLevel: 4)]),
        ),
        throwsFormatException,
      );
    });
  });
}

ServiceIntakeIdentityManifestSource _decoder() {
  return ServiceIntakeIdentityManifestSource(
    assetBundle: _MemoryAssetBundle(''),
  );
}

String _manifest(
  List<Map<String, Object?>> entries, {
  String version = 'v1',
  Map<String, Object?> additionalFields = const <String, Object?>{},
}) {
  return jsonEncode(<String, Object?>{
    'version': version,
    'entries': entries,
    ...additionalFields,
  });
}

Map<String, Object?> _entry({
  String entityId = 'helpy.service_intake.plumbing.faucet',
  List<String> path = const <String>[
    'helpy',
    'service_intake',
    'plumbing',
    'faucet',
  ],
  bool includeSourceLocator = true,
  int ownerHeadingLevel = 2,
  String ownerHeading = 'Plumbing Mini-TZ Standard',
  int headingLevel = 3,
  String heading = 'Plumbing → Кран',
}) {
  return <String, Object?>{
    'entityId': entityId,
    'path': path,
    if (includeSourceLocator)
      'sourceLocator': <String, Object?>{
        'ownerHeadingLevel': ownerHeadingLevel,
        'ownerHeading': ownerHeading,
        'headingLevel': headingLevel,
        'heading': heading,
      },
  };
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.source);

  final String source;

  @override
  Future<ByteData> load(String key) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(source));

    return ByteData.view(bytes.buffer);
  }
}
