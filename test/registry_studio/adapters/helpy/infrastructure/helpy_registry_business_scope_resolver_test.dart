import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/domain/entities/helpy_business_scope_owner_payload.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_business_scope_resolver.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_entity.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  const HelpyRegistryBusinessScopeResolver resolver =
      HelpyRegistryBusinessScopeResolver();

  group('HelpyRegistryBusinessScopeResolver', () {
    test('discovers an unknown future service owner and '
        'inherits it through arbitrary depth', () {
      final RegistrySnapshot resolved = resolver.resolveBusinessScope(
        _syntheticSnapshot(),
      );

      final RegistryStructuralIndex index = RegistryStructuralIndex(resolved);

      final RegistryNode serviceOwner = index.nodes.singleWhere(
        (RegistryNode node) =>
            node.path.segments.last ==
            '99. Service Architecture Registry '
                '— Future Category',
      );

      final RegistryNode deepClientRule = index.nodes.singleWhere(
        (RegistryNode node) =>
            node.path.segments.last == 'Client Rules' &&
            node.path.segments.contains('Arbitrary New Level'),
      );

      final RegistryNode globalRule = index.nodes.singleWhere(
        (RegistryNode node) => node.path.segments.last == 'Rule #1',
      );

      final RegistryNode technicalClientRule = index.nodes.singleWhere(
        (RegistryNode node) =>
            node.path.segments.last == 'Client Rules' &&
            node.path.segments.contains('Technical Architecture'),
      );

      expect(serviceOwner.businessScopeOwnerId, isNotNull);

      expect(
        deepClientRule.businessScopeOwnerId,
        serviceOwner.businessScopeOwnerId,
      );

      expect(globalRule.businessScopeOwnerId, isNotNull);

      expect(
        globalRule.businessScopeOwnerId,
        isNot(serviceOwner.businessScopeOwnerId),
      );

      expect(technicalClientRule.businessScopeOwnerId, isNull);

      expect(resolved.entities, hasLength(2));

      final List<HelpyBusinessScopeOwnerPayload> payloads = resolved.entities
          .map((RegistryEntity entity) => entity.payload)
          .whereType<HelpyBusinessScopeOwnerPayload>()
          .toList(growable: false);

      expect(
        payloads
            .where(
              (HelpyBusinessScopeOwnerPayload payload) =>
                  payload.ownerClassId ==
                  HelpyRegistryBusinessScopeResolver.serviceCatalogOwnerClassId,
            )
            .single
            .title,
        'Future Category',
      );

      expect(
        payloads
            .where(
              (HelpyBusinessScopeOwnerPayload payload) =>
                  payload.ownerClassId ==
                  HelpyRegistryBusinessScopeResolver
                      .globalBusinessRulesOwnerClassId,
            )
            .single
            .title,
        'Global Platform Rules',
      );
    });

    test('is idempotent for an already resolved snapshot', () {
      final RegistrySnapshot first = resolver.resolveBusinessScope(
        _syntheticSnapshot(),
      );

      final RegistrySnapshot second = resolver.resolveBusinessScope(first);

      expect(second.entities, hasLength(2));

      expect(
        RegistryStructuralIndex(second).nodes.every((RegistryNode secondNode) {
          final RegistryNode firstNode = RegistryStructuralIndex(
            first,
          ).nodesById[secondNode.id]!;

          return secondNode.businessScopeOwnerId ==
              firstNode.businessScopeOwnerId;
        }),
        isTrue,
      );
    });

    test('rejects conflicting preassigned ownership', () {
      expect(
        () => resolver.resolveBusinessScope(
          _syntheticSnapshot(
            conflictingOwnerId: RegistryEntityId(
              'helpy.registry.'
              'business-scope-owner.conflict',
            ),
          ),
        ),
        throwsStateError,
      );
    });

    test('discovers current Registry owners without a fixed '
        'category list and preserves technical neutrality', () async {
      final File fixture = File(
        'test/fixtures/registry_studio/source_indexing/'
        'Helpy_Architecture_Registry_v1.md',
      );

      expect(await fixture.exists(), isTrue);

      final String sourceContent = await fixture.readAsString();

      const String fingerprint = 'fixture:helpy-registry-stage3-scope';

      final List<HelpyRegistryDocumentNode> interpretedRoots =
          const HelpyRegistryDocumentInterpreter().interpret(sourceContent);

      int nodeSequence = 0;

      RegistryNode materializeNode(HelpyRegistryDocumentNode interpretedNode) {
        nodeSequence += 1;

        return RegistryNode(
          id: RegistryNodeId(
            'fixture.node.'
            '${nodeSequence.toString().padLeft(6, '0')}',
          ),
          kindId:
              'helpy.registry.markdown.heading.'
              '${interpretedNode.headingLevel}',
          path: interpretedNode.path,
          sourceEvidence: <SourceEvidence>[
            SourceEvidence(
              sourceDocumentPath: fixture.path,
              sourceSnapshotFingerprint: fingerprint,
              headingPath: interpretedNode.path.segments,
              startLine: interpretedNode.startLine,
              endLine: interpretedNode.endLine,
            ),
          ],
          content: interpretedNode.content,
          businessScopeOwnerId: null,
          children: <RegistryNode>[
            for (final HelpyRegistryDocumentNode child
                in interpretedNode.children)
              materializeNode(child),
          ],
        );
      }

      final RegistrySnapshot resolved = resolver.resolveBusinessScope(
        RegistrySnapshot(
          projectId: 'helpy',
          projectAdapterId: 'helpy.registry.adapter.v1',
          sourceDocumentPath: fixture.path,
          sourceRevision: '5138b9639229a2596abdd1e77c06e9856ce3dc4e',
          sourceSnapshotFingerprint: fingerprint,
          sourceContent: sourceContent,
          roots: <RegistryNode>[
            for (final HelpyRegistryDocumentNode root in interpretedRoots)
              materializeNode(root),
          ],
        ),
      );

      final RegistryStructuralIndex index = RegistryStructuralIndex(resolved);

      final List<RegistryEntity> ownerEntities = resolved.entities
          .where(
            (RegistryEntity entity) =>
                entity.payload is HelpyBusinessScopeOwnerPayload,
          )
          .toList(growable: false);

      final List<RegistryEntity> serviceOwners = ownerEntities
          .where((RegistryEntity entity) {
            final HelpyBusinessScopeOwnerPayload payload =
                entity.payload as HelpyBusinessScopeOwnerPayload;

            return payload.ownerClassId ==
                HelpyRegistryBusinessScopeResolver.serviceCatalogOwnerClassId;
          })
          .toList(growable: false);

      final List<RegistryEntity> globalOwners = ownerEntities
          .where((RegistryEntity entity) {
            final HelpyBusinessScopeOwnerPayload payload =
                entity.payload as HelpyBusinessScopeOwnerPayload;

            return payload.ownerClassId ==
                HelpyRegistryBusinessScopeResolver
                    .globalBusinessRulesOwnerClassId;
          })
          .toList(growable: false);

      expect(ownerEntities, hasLength(7));
      expect(serviceOwners, hasLength(6));
      expect(globalOwners, hasLength(1));

      for (final RegistryEntity owner in ownerEntities) {
        final RegistryNode ownerNode = index.nodesByPath[owner.path]!;

        expect(ownerNode.businessScopeOwnerId, owner.id);

        final List<RegistryNode> scopedNodes = index.nodes
            .where(
              (RegistryNode node) =>
                  _isSameOrDescendantPath(owner.path, node.path),
            )
            .toList(growable: false);

        expect(scopedNodes, isNotEmpty);

        expect(
          scopedNodes.every(
            (RegistryNode node) => node.businessScopeOwnerId == owner.id,
          ),
          isTrue,
        );
      }

      final RegistryNode adminPanel = index.nodes.singleWhere(
        (RegistryNode node) =>
            node.path.segments.last.endsWith('Admin Panel Architecture'),
      );

      expect(adminPanel.businessScopeOwnerId, isNull);
    });
  });
}

bool _isSameOrDescendantPath(
  RegistryPath ownerPath,
  RegistryPath candidatePath,
) {
  if (candidatePath.segments.length < ownerPath.segments.length) {
    return false;
  }

  for (int index = 0; index < ownerPath.segments.length; index += 1) {
    if (candidatePath.segments[index] != ownerPath.segments[index]) {
      return false;
    }
  }

  return true;
}

RegistrySnapshot _syntheticSnapshot({RegistryEntityId? conflictingOwnerId}) {
  final RegistryNode technicalClientRule = _node(
    id: 'helpy.registry.node.000008',
    path: const <String>['Registry', 'Technical Architecture', 'Client Rules'],
    startLine: 16,
    endLine: 17,
  );

  final RegistryNode technicalArchitecture = _node(
    id: 'helpy.registry.node.000007',
    path: const <String>['Registry', 'Technical Architecture'],
    startLine: 14,
    endLine: 17,
    children: <RegistryNode>[technicalClientRule],
  );

  final RegistryNode globalRule = _node(
    id: 'helpy.registry.node.000006',
    path: const <String>['Registry', '16. Global Platform Rules', 'Rule #1'],
    startLine: 12,
    endLine: 13,
  );

  final RegistryNode globalRules = _node(
    id: 'helpy.registry.node.000005',
    path: const <String>['Registry', '16. Global Platform Rules'],
    startLine: 10,
    endLine: 13,
    children: <RegistryNode>[globalRule],
  );

  final RegistryNode clientRules = _node(
    id: 'helpy.registry.node.000004',
    path: const <String>[
      'Registry',
      '99. Service Architecture Registry '
          '— Future Category',
      'Arbitrary New Level',
      'Client Rules',
    ],
    startLine: 8,
    endLine: 9,
  );

  final RegistryNode arbitraryLevel = _node(
    id: 'helpy.registry.node.000003',
    path: const <String>[
      'Registry',
      '99. Service Architecture Registry '
          '— Future Category',
      'Arbitrary New Level',
    ],
    startLine: 6,
    endLine: 9,
    children: <RegistryNode>[clientRules],
  );

  final RegistryNode futureCategory = _node(
    id: 'helpy.registry.node.000002',
    path: const <String>[
      'Registry',
      '99. Service Architecture Registry '
          '— Future Category',
    ],
    startLine: 4,
    endLine: 9,
    businessScopeOwnerId: conflictingOwnerId,
    children: <RegistryNode>[arbitraryLevel],
  );

  final RegistryNode root = _node(
    id: 'helpy.registry.node.000001',
    path: const <String>['Registry'],
    startLine: 1,
    endLine: 17,
    children: <RegistryNode>[
      futureCategory,
      globalRules,
      technicalArchitecture,
    ],
  );

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: 'registry.md',
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint:
        'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    sourceContent:
        '# Registry\n'
        '## 99. Service Architecture Registry '
        '— Future Category\n'
        '### Arbitrary New Level\n'
        '#### Client Rules\n'
        '## 16. Global Platform Rules\n'
        '### Rule #1\n'
        '## Technical Architecture\n'
        '### Client Rules\n',
    roots: <RegistryNode>[root],
  );
}

RegistryNode _node({
  required String id,
  required List<String> path,
  required int startLine,
  required int endLine,
  RegistryEntityId? businessScopeOwnerId,
  Iterable<RegistryNode> children = const <RegistryNode>[],
}) {
  const String fingerprint =
      'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  final RegistryPath registryPath = RegistryPath(path);

  return RegistryNode(
    id: RegistryNodeId(id),
    kindId:
        'helpy.registry.markdown.heading.'
        '${path.length}',
    path: registryPath,
    sourceEvidence: <SourceEvidence>[
      SourceEvidence(
        sourceDocumentPath: 'registry.md',
        sourceSnapshotFingerprint: fingerprint,
        headingPath: registryPath.segments,
        startLine: startLine,
        endLine: endLine,
      ),
    ],
    content: '',
    businessScopeOwnerId: businessScopeOwnerId,
    children: children,
  );
}
