import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/payloads/service_intake_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/github_registry_document_source.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/service_intake_registry_source.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceIntakeRegistrySource', () {
    test('loads one synchronized source-backed registry snapshot', () async {
      final List<RequestOptions> requests = <RequestOptions>[];
      final Dio dio = _dioWithResponse(
        statusCode: 200,
        data:
            '## Plumbing Mini-TZ Standard\n'
            '### Plumbing → Кран\n'
            'Описание услуги.\n',
        requests: requests,
      );

      final ServiceIntakeRegistrySource source = ServiceIntakeRegistrySource(
        documentSource: GitHubRegistryDocumentSource(
          dio: dio,
          owner: 'owner',
          repository: 'repository',
          documentPath: 'docs/registry.md',
          ref: 'main',
        ),
        assetBundle: _MemoryAssetBundle(<String, String>{
          _identityManifestPath: _identityManifest(),
          _semanticManifestPath: _semanticManifest(),
        }),
        identityManifestAssetPath: _identityManifestPath,
        semanticManifestAssetPath: _semanticManifestPath,
      );

      final ServiceIntakeRegistrySourceResult result = await source.load();

      expect(requests, hasLength(1));
      expect(result.sourceDocumentPath, 'docs/registry.md');
      expect(result.sourceRevision, startsWith('fnv1a64:'));
      expect(result.sourceSnapshotFingerprint, result.sourceRevision);

      expect(result.sourceBlocks, hasLength(1));
      expect(result.entities, hasLength(1));

      final RegistryEntity entity = result.entities.single;
      expect(entity.id.value, 'helpy.service_intake.plumbing.faucet');

      final ServiceIntakePayload payload =
          entity.payload as ServiceIntakePayload;
      expect(payload.displayName, 'Plumbing → Кран');
      expect(payload.scenarios.single.displayName, 'Описание услуги.');

      final SourceEvidence evidence = entity.sourceEvidence.single;
      expect(evidence.sourceDocumentPath, result.sourceDocumentPath);
      expect(
        evidence.sourceSnapshotFingerprint,
        result.sourceSnapshotFingerprint,
      );
      expect(evidence.headingPath, <String>[
        'Plumbing Mini-TZ Standard',
        'Plumbing → Кран',
      ]);
      expect(evidence.startLine, 2);
      expect(evidence.endLine, 3);

      expect(
        () => result.sourceBlocks.add(result.sourceBlocks.single),
        throwsUnsupportedError,
      );
      expect(() => result.entities.add(entity), throwsUnsupportedError);
    });
  });
}

String _identityManifest() {
  return jsonEncode(<String, Object?>{
    'version': 'v1',
    'entries': <Map<String, Object?>>[
      <String, Object?>{
        'entityId': 'helpy.service_intake.plumbing.faucet',
        'path': <String>['helpy', 'service_intake', 'plumbing', 'faucet'],
        'sourceLocator': <String, Object?>{
          'ownerHeadingLevel': 2,
          'ownerHeading': 'Plumbing Mini-TZ Standard',
          'headingLevel': 3,
          'heading': 'Plumbing → Кран',
        },
      },
    ],
  });
}

String _semanticManifest() {
  return jsonEncode(<String, Object?>{
    'version': 'v1',
    'entries': <Map<String, Object?>>[
      <String, Object?>{
        'entityId': 'helpy.service_intake.plumbing.faucet',
        'displayNameLocator': <String, Object?>{
          'expectedText': '### Plumbing → Кран',
          'occurrence': 1,
        },
        'entrySelectors': <Map<String, Object?>>[],
        'scenarios': <Map<String, Object?>>[
          <String, Object?>{
            'key': 'direct',
            'displayNameLocator': <String, Object?>{
              'expectedText': 'Описание услуги.',
              'occurrence': 1,
            },
            'entryEvidence': <String, Object?>{'mode': 'directSelection'},
            'questions': <Map<String, Object?>>[],
            'photoQuestions': <Map<String, Object?>>[],
            'photoLimits': <Map<String, Object?>>[],
            'clientGuidance': <Map<String, Object?>>[],
            'masterGuidance': <Map<String, Object?>>[],
          },
        ],
      },
    ],
  });
}

Dio _dioWithResponse({
  required int statusCode,
  required Object? data,
  List<RequestOptions>? requests,
}) {
  final Dio dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        requests?.add(options);

        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
        );
      },
    ),
  );

  return dio;
}

final class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.sources);

  final Map<String, String> sources;

  @override
  Future<ByteData> load(String key) async {
    final String? source = sources[key];

    if (source == null) {
      throw StateError('Missing test asset: $key');
    }

    final Uint8List bytes = Uint8List.fromList(utf8.encode(source));

    return ByteData.view(bytes.buffer);
  }
}

const String _identityManifestPath = 'identity.json';
const String _semanticManifestPath = 'semantic.json';
