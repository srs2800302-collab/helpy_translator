import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_relation.dart';
import 'package:helpy_translator/registry_studio/guard/domain/registry_studio_guard_record_payload.dart';
import 'package:helpy_translator/registry_studio/guard/infrastructure/registry_studio_guard_asset_source.dart';

void main() {
  group('RegistryStudioGuardAssetSource', () {
    test(
      'loads one declaration into existing Registry Studio contracts',
      () async {
        final RegistryStudioGuardAssetSource source =
            RegistryStudioGuardAssetSource(
              assetBundle: _MemoryAssetBundle(_validSource),
              assetPath: 'docs/guard.md',
            );

        final ({RegistryEntity entity, List<RegistryRelation> relations})
        result = await source.load();

        final RegistryStudioGuardRecordPayload payload =
            result.entity.payload as RegistryStudioGuardRecordPayload;

        expect(
          result.entity.id.value,
          'registry_studio.guard.source_contract_foundation',
        );
        expect(result.entity.path.segments, <String>[
          'registry_studio',
          'guard',
          'source_contract_foundation',
        ]);
        expect(
          payload.recordType,
          RegistryStudioGuardRecordType.ownershipAudit,
        );
        expect(payload.heading, 'Guard source contract');
        expect(payload.summary, 'Foundation is sufficient.');
        expect(result.relations, isEmpty);

        final evidence = result.entity.sourceEvidence.single;

        expect(evidence.sourceDocumentPath, 'docs/guard.md');
        expect(evidence.sourceSnapshotFingerprint, startsWith('fnv1a64:'));
        expect(evidence.headingPath, <String>['Guard source contract']);
        expect(evidence.startLine, 2);
        expect(evidence.endLine, 15);
      },
    );

    test('loads explicitly declared relations', () async {
      final RegistryStudioGuardAssetSource source =
          RegistryStudioGuardAssetSource(
            assetBundle: _MemoryAssetBundle(_sourceWithRelation),
          );

      final result = await source.load();

      expect(result.relations, hasLength(1));
      expect(result.relations.single.sourceEntityId, result.entity.id);
      expect(
        result.relations.single.targetEntityId.value,
        'registry_studio.guard.related_rule',
      );
      expect(result.relations.single.meaning.value, 'depends_on');
    });

    test('rejects a missing declaration', () {
      final RegistryStudioGuardAssetSource source =
          RegistryStudioGuardAssetSource(
            assetBundle: _MemoryAssetBundle('# Guard'),
          );

      expect(source.load, throwsFormatException);
    });

    test('rejects an unsupported declaration version', () {
      final RegistryStudioGuardAssetSource source =
          RegistryStudioGuardAssetSource(
            assetBundle: _MemoryAssetBundle(
              _validSource.replaceFirst(
                'registry-studio-guard-record:v1',
                'registry-studio-guard-record:v2',
              ),
            ),
          );

      expect(source.load, throwsFormatException);
    });
  });
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

const String _validSource = '''## Guard source contract
<!-- registry-studio-guard-record:v1
{
  "entityId": "registry_studio.guard.source_contract_foundation",
  "path": [
    "registry_studio",
    "guard",
    "source_contract_foundation"
  ],
  "recordType": "ownershipAudit",
  "heading": "Guard source contract",
  "summary": "Foundation is sufficient.",
  "relations": []
}
-->
''';

const String _sourceWithRelation = '''## Guard source contract
<!-- registry-studio-guard-record:v1
{
  "entityId": "registry_studio.guard.source_contract_foundation",
  "path": [
    "registry_studio",
    "guard",
    "source_contract_foundation"
  ],
  "recordType": "ownershipAudit",
  "heading": "Guard source contract",
  "summary": "Foundation is sufficient.",
  "relations": [
    {
      "sourceEntityId": "registry_studio.guard.source_contract_foundation",
      "targetEntityId": "registry_studio.guard.related_rule",
      "meaning": "depends_on"
    }
  ]
}
-->
''';
