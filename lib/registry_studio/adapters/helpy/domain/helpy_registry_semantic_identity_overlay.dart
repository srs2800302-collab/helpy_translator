import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/evidence/source_evidence.dart';
import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/entities/registry_node.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'helpy_registry_entity_payload.dart';
import 'helpy_registry_semantic_contract.dart';

final class HelpyRegistrySemanticIdentity {
  factory HelpyRegistrySemanticIdentity({
    required int sequence,
    required RegistryEntityKind kind,
    required RegistryPath evidencePath,
    required bool ownsBusinessScope,
    Iterable<int> businessScopeRootSequences = const <int>[],
    RegistryEntityId? entityId,
    String? semanticTitle,
    int? evidenceStartLine,
    int? evidenceEndLine,
    bool contributesStructuralKind = true,
  }) {
    if (sequence <= 0) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Helpy Registry semantic identity sequence must be positive.',
      );
    }

    if (kind.semanticContract != HelpyRegistrySemanticContract.identity ||
        HelpyRegistrySemanticContract.kindsById[kind.kindId] != kind) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Helpy Registry semantic identity must use an approved Helpy kind.',
      );
    }

    final String formattedSequence = sequence.toString().padLeft(6, '0');
    final RegistryEntityId normalizedEntityId =
        entityId ??
        RegistryEntityId('helpy.registry.entity.$formattedSequence');
    final String? normalizedSemanticTitle = semanticTitle?.trim();

    if (semanticTitle != null && normalizedSemanticTitle!.isEmpty) {
      throw ArgumentError.value(
        semanticTitle,
        'semanticTitle',
        'Helpy Registry semantic title must not be empty.',
      );
    }

    if ((evidenceStartLine == null) != (evidenceEndLine == null)) {
      throw ArgumentError(
        'Helpy Registry semantic evidence must define both '
        'start and end lines.',
      );
    }

    if (evidenceStartLine != null &&
        (evidenceStartLine <= 0 || evidenceEndLine! < evidenceStartLine)) {
      throw ArgumentError(
        'Helpy Registry semantic evidence line range is invalid.',
      );
    }

    if (!contributesStructuralKind && entityId == null) {
      throw ArgumentError(
        'A supplementary Helpy semantic entity must define '
        'its own stable entity identity.',
      );
    }

    if (!contributesStructuralKind && evidenceStartLine == null) {
      throw ArgumentError(
        'A supplementary Helpy semantic entity must define '
        'an exact source span.',
      );
    }

    final List<int> normalizedBusinessScopeRootSequences =
        businessScopeRootSequences.toList(growable: true);

    if (!ownsBusinessScope && normalizedBusinessScopeRootSequences.isNotEmpty) {
      throw ArgumentError.value(
        businessScopeRootSequences,
        'businessScopeRootSequences',
        'A Helpy Registry identity without business-scope ownership '
            'must not declare scope roots.',
      );
    }

    if (ownsBusinessScope && normalizedBusinessScopeRootSequences.isEmpty) {
      normalizedBusinessScopeRootSequences.add(sequence);
    }

    final Set<int> uniqueBusinessScopeRootSequences = <int>{};

    for (final int rootSequence in normalizedBusinessScopeRootSequences) {
      if (rootSequence <= 0) {
        throw ArgumentError.value(
          rootSequence,
          'businessScopeRootSequences',
          'Helpy Registry business-scope root sequence must be positive.',
        );
      }

      if (!uniqueBusinessScopeRootSequences.add(rootSequence)) {
        throw ArgumentError.value(
          rootSequence,
          'businessScopeRootSequences',
          'Helpy Registry business-scope roots must be unique.',
        );
      }
    }

    return HelpyRegistrySemanticIdentity._(
      nodeId: RegistryNodeId('helpy.registry.node.$formattedSequence'),
      entityId: normalizedEntityId,
      kind: kind,
      evidencePath: evidencePath,
      semanticTitle: normalizedSemanticTitle,
      evidenceStartLine: evidenceStartLine,
      evidenceEndLine: evidenceEndLine,
      contributesStructuralKind: contributesStructuralKind,
      businessScopeRootNodeIds: List<RegistryNodeId>.unmodifiable(
        normalizedBusinessScopeRootSequences.map(
          (int rootSequence) => RegistryNodeId(
            'helpy.registry.node.'
            '${rootSequence.toString().padLeft(6, '0')}',
          ),
        ),
      ),
    );
  }

  const HelpyRegistrySemanticIdentity._({
    required this.nodeId,
    required this.entityId,
    required this.kind,
    required this.evidencePath,
    required this.semanticTitle,
    required this.evidenceStartLine,
    required this.evidenceEndLine,
    required this.contributesStructuralKind,
    required this.businessScopeRootNodeIds,
  });

  final RegistryNodeId nodeId;
  final RegistryEntityId entityId;
  final RegistryEntityKind kind;
  final RegistryPath evidencePath;
  final String? semanticTitle;
  final int? evidenceStartLine;
  final int? evidenceEndLine;
  final bool contributesStructuralKind;
  final List<RegistryNodeId> businessScopeRootNodeIds;

  bool get ownsBusinessScope => businessScopeRootNodeIds.isNotEmpty;

  RegistryEntity materializeEntity(RegistryNode node) {
    if (node.id != nodeId) {
      throw StateError(
        'Helpy Registry semantic identity node does not match '
        '${node.id.value}.',
      );
    }

    if (node.path != evidencePath) {
      throw StateError(
        'Helpy Registry semantic identity path does not match '
        '${node.id.value}.',
      );
    }

    final List<SourceEvidence> entitySourceEvidence;

    if (evidenceStartLine == null) {
      entitySourceEvidence = node.sourceEvidence;
    } else {
      SourceEvidence? containingEvidence;

      for (final SourceEvidence evidence in node.sourceEvidence) {
        if (evidenceStartLine! >= evidence.startLine &&
            evidenceEndLine! <= evidence.endLine) {
          containingEvidence = evidence;
          break;
        }
      }

      if (containingEvidence == null) {
        throw StateError(
          'Helpy Registry semantic source span does not belong '
          'to structural node ${node.id.value}.',
        );
      }

      entitySourceEvidence = List<SourceEvidence>.unmodifiable(<SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: containingEvidence.sourceDocumentPath,
          sourceSnapshotFingerprint:
              containingEvidence.sourceSnapshotFingerprint,
          headingPath: containingEvidence.headingPath,
          startLine: evidenceStartLine!,
          endLine: evidenceEndLine!,
        ),
      ]);
    }

    return RegistryEntity(
      id: entityId,
      path: node.path,
      kind: kind,
      payload: HelpyRegistryEntityPayload(
        kind: kind,
        sourceNodeId: node.id,
        title: semanticTitle ?? node.path.segments.last,
        content: node.content,
        ownsBusinessScope: ownsBusinessScope,
      ),
      sourceEvidence: entitySourceEvidence,
    );
  }
}

final class HelpyRegistrySemanticIdentityOverlay {
  factory HelpyRegistrySemanticIdentityOverlay({
    required String version,
    required String evidenceSourceDocumentPath,
    required String evidenceSourceRevision,
    required String evidenceRegistrySha256,
    required Iterable<HelpyRegistrySemanticIdentity> identities,
  }) {
    final String normalizedVersion = version.trim();
    final String normalizedSourceDocumentPath = evidenceSourceDocumentPath
        .trim();
    final String normalizedSourceRevision = evidenceSourceRevision.trim();
    final String normalizedRegistrySha256 = evidenceRegistrySha256.trim();
    final List<HelpyRegistrySemanticIdentity> normalizedIdentities = identities
        .toList(growable: false);

    if (normalizedVersion.isEmpty) {
      throw ArgumentError.value(
        version,
        'version',
        'Helpy Registry semantic identity overlay version must not be empty.',
      );
    }

    if (normalizedSourceDocumentPath.isEmpty) {
      throw ArgumentError.value(
        evidenceSourceDocumentPath,
        'evidenceSourceDocumentPath',
        'Helpy Registry semantic identity evidence path must not be empty.',
      );
    }

    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(normalizedSourceRevision)) {
      throw ArgumentError.value(
        evidenceSourceRevision,
        'evidenceSourceRevision',
        'Helpy Registry semantic identity evidence revision must be an exact '
            'lowercase commit SHA.',
      );
    }

    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalizedRegistrySha256)) {
      throw ArgumentError.value(
        evidenceRegistrySha256,
        'evidenceRegistrySha256',
        'Helpy Registry semantic identity evidence SHA-256 is invalid.',
      );
    }

    if (normalizedIdentities.isEmpty) {
      throw ArgumentError.value(
        identities,
        'identities',
        'Helpy Registry semantic identity overlay must contain identities.',
      );
    }

    final Map<RegistryNodeId, HelpyRegistrySemanticIdentity>
    identitiesByNodeId = <RegistryNodeId, HelpyRegistrySemanticIdentity>{};
    final Set<RegistryEntityId> entityIds = <RegistryEntityId>{};
    final Set<String> evidenceAnchors = <String>{};

    for (final HelpyRegistrySemanticIdentity identity in normalizedIdentities) {
      if (!entityIds.add(identity.entityId)) {
        throw ArgumentError.value(
          identity.entityId,
          'identities',
          'Helpy Registry semantic identity overlay contains '
              'a duplicate entity identity.',
        );
      }

      final String evidenceAnchor = <Object?>[
        ...identity.evidencePath.segments,
        identity.evidenceStartLine,
        identity.evidenceEndLine,
      ].join('\u0000');

      if (!evidenceAnchors.add(evidenceAnchor)) {
        throw ArgumentError.value(
          identity.evidencePath,
          'identities',
          'Helpy Registry semantic identity overlay contains '
              'a duplicate source evidence anchor.',
        );
      }

      if (identity.contributesStructuralKind) {
        if (identitiesByNodeId.containsKey(identity.nodeId)) {
          throw ArgumentError.value(
            identity.nodeId,
            'identities',
            'Helpy Registry semantic identity overlay contains '
                'multiple structural kind identities for one node.',
          );
        }

        identitiesByNodeId[identity.nodeId] = identity;
      }
    }

    return HelpyRegistrySemanticIdentityOverlay._(
      version: normalizedVersion,
      evidenceSourceDocumentPath: normalizedSourceDocumentPath,
      evidenceSourceRevision: normalizedSourceRevision,
      evidenceRegistrySha256: normalizedRegistrySha256,
      identities: List<HelpyRegistrySemanticIdentity>.unmodifiable(
        normalizedIdentities,
      ),
      identitiesByNodeId:
          Map<RegistryNodeId, HelpyRegistrySemanticIdentity>.unmodifiable(
            identitiesByNodeId,
          ),
    );
  }

  const HelpyRegistrySemanticIdentityOverlay._({
    required this.version,
    required this.evidenceSourceDocumentPath,
    required this.evidenceSourceRevision,
    required this.evidenceRegistrySha256,
    required this.identities,
    required this.identitiesByNodeId,
  });

  static const String sourceDocumentPath =
      'docs/architecture/Helpy_Architecture_Registry_v1.md';

  static final HelpyRegistrySemanticIdentityOverlay v1 =
      HelpyRegistrySemanticIdentityOverlay(
        version: 'v1',
        evidenceSourceDocumentPath: sourceDocumentPath,
        evidenceSourceRevision: '64f45059c6043f2e65165a4a8da053cf3a73c107',
        evidenceRegistrySha256:
            'dbe4e4fbaa934e3e48c0190088421ff93190cda65083352df7cd67ff641010b7',
        identities: <HelpyRegistrySemanticIdentity>[
          HelpyRegistrySemanticIdentity(
            sequence: 1,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 3,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group A — Foundation / Product Identity',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 4,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group B — Service Registry / Categories',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 5,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group C — Admin / Dynamic Forms / Knowledge / Guidance',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 6,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group D — Order Lifecycle / Timeline / Chat / Evidence',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 7,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group E — Offers / Pricing / Payments / Financial Snapshot',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 8,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group F — Reviews / Reputation / Ranking / Language Matching',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 9,
            kind: HelpyRegistrySemanticContract.architectureGroup,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Contract Map / Architecture Groups',
              'Group G — Recovery / Global Rules',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 64,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #1 — Client-Safe Scope Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 65,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #2 — Equipment Packaging Protection Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 66,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #3 — Equipment Compatibility Before Demolition Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 67,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #4 — Structured Scope Before Chat Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 68,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #5 — No Extra Photo Requests In Chat Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 69,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #6 — One-Time Final Price Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 70,
            kind: HelpyRegistrySemanticContract.platformRule,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '16. Global Platform Rules',
              'Rule #7 — Platform Boundary / Ownership Rule',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 21,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Roadmap Decision → '
                  'Appliance Installation & Connection Architecture',
            ]),
            ownsBusinessScope: true,
            businessScopeRootSequences: <int>[21, 22, 26],
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 21,
            entityId: RegistryEntityId(
              'helpy.registry.entity.root-category.'
              'appliance-installation-connection',
            ),
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              'Roadmap Decision → '
                  'Appliance Installation & Connection Architecture',
            ]),
            ownsBusinessScope: false,
            semanticTitle: 'Appliance Installation & Connection',
            evidenceStartLine: 526,
            evidenceEndLine: 536,
            contributesStructuralKind: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 172,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '20. Service Architecture Registry — Furniture Assembly',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 173,
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '20. Service Architecture Registry — Furniture Assembly',
              'Root Category',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 212,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '21. Service Architecture Registry — Cleaning',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 213,
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '21. Service Architecture Registry — Cleaning',
              'Root Category',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 219,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '22. Service Architecture Registry — Air Conditioning',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 220,
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '22. Service Architecture Registry — Air Conditioning',
              'Root Category',
            ]),
            ownsBusinessScope: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 288,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '23. Service Architecture Registry — Electrical',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 288,
            entityId: RegistryEntityId(
              'helpy.registry.entity.root-category.electrical',
            ),
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '23. Service Architecture Registry — Electrical',
            ]),
            ownsBusinessScope: false,
            semanticTitle: 'Electrical',
            evidenceStartLine: 9240,
            evidenceEndLine: 9249,
            contributesStructuralKind: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 303,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '24. Service Architecture Registry — Plumbing',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 304,
            entityId: RegistryEntityId(
              'helpy.registry.entity.root-category.plumbing',
            ),
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '24. Service Architecture Registry — Plumbing',
              'Plumbing Registry Content',
            ]),
            ownsBusinessScope: false,
            semanticTitle: 'Plumbing',
            evidenceStartLine: 9934,
            evidenceEndLine: 9934,
            contributesStructuralKind: false,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 310,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '25. Service Architecture Registry — Locks',
            ]),
            ownsBusinessScope: true,
          ),
          HelpyRegistrySemanticIdentity(
            sequence: 310,
            entityId: RegistryEntityId(
              'helpy.registry.entity.root-category.locks',
            ),
            kind: HelpyRegistrySemanticContract.rootCategory,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '25. Service Architecture Registry — Locks',
            ]),
            ownsBusinessScope: false,
            semanticTitle: 'Locks',
            evidenceStartLine: 10929,
            evidenceEndLine: 10930,
            contributesStructuralKind: false,
          ),
        ],
      );

  bool appliesTo({
    required String sourceDocumentPath,
    required String sourceRevision,
  }) {
    return sourceDocumentPath == evidenceSourceDocumentPath &&
        sourceRevision == evidenceSourceRevision;
  }

  void validateActiveEvidencePaths({
    required Map<RegistryNodeId, RegistryPath> activePathsByNodeId,
  }) {
    for (final HelpyRegistrySemanticIdentity identity in identities) {
      final RegistryPath? activePath = activePathsByNodeId[identity.nodeId];

      if (activePath == null) {
        throw StateError(
          'Helpy Registry semantic identity evidence is missing active node '
          '${identity.nodeId.value}.',
        );
      }

      if (activePath != identity.evidencePath) {
        throw StateError(
          'Helpy Registry semantic identity evidence path does not match '
          'active node ${identity.nodeId.value}.',
        );
      }
    }
  }

  final String version;
  final String evidenceSourceDocumentPath;
  final String evidenceSourceRevision;
  final String evidenceRegistrySha256;
  final List<HelpyRegistrySemanticIdentity> identities;
  final Map<RegistryNodeId, HelpyRegistrySemanticIdentity> identitiesByNodeId;

  Map<RegistryNodeId, RegistryEntityId?> resolveBusinessScopeOwnerIds({
    required Iterable<RegistryNodeId> activeNodeIds,
    required Map<RegistryNodeId, RegistryNodeId?> parentIdByNodeId,
  }) {
    final Set<RegistryNodeId> activeIds = activeNodeIds.toSet();

    if (activeIds.isEmpty) {
      return const <RegistryNodeId, RegistryEntityId?>{};
    }

    final Map<RegistryNodeId, List<RegistryNodeId>> childrenByParentId =
        <RegistryNodeId, List<RegistryNodeId>>{};
    final List<RegistryNodeId> roots = <RegistryNodeId>[];

    for (final RegistryNodeId nodeId in activeIds) {
      if (!parentIdByNodeId.containsKey(nodeId)) {
        throw ArgumentError.value(
          nodeId,
          'parentIdByNodeId',
          'Active Helpy Registry node has no structural parent evidence.',
        );
      }

      final RegistryNodeId? parentId = parentIdByNodeId[nodeId];

      if (parentId == null || !activeIds.contains(parentId)) {
        roots.add(nodeId);
        continue;
      }

      childrenByParentId
          .putIfAbsent(parentId, () => <RegistryNodeId>[])
          .add(nodeId);
    }

    final Map<RegistryNodeId, RegistryEntityId>
    ownerIdByBusinessScopeRootNodeId = <RegistryNodeId, RegistryEntityId>{};

    for (final HelpyRegistrySemanticIdentity identity in identities) {
      for (final RegistryNodeId businessScopeRootNodeId
          in identity.businessScopeRootNodeIds) {
        if (!activeIds.contains(businessScopeRootNodeId)) {
          continue;
        }

        final RegistryEntityId? existingOwnerId =
            ownerIdByBusinessScopeRootNodeId[businessScopeRootNodeId];

        if (existingOwnerId != null && existingOwnerId != identity.entityId) {
          throw StateError(
            'Helpy Registry business-scope root '
            '${businessScopeRootNodeId.value} has conflicting owners.',
          );
        }

        ownerIdByBusinessScopeRootNodeId[businessScopeRootNodeId] =
            identity.entityId;
      }
    }

    final Map<RegistryNodeId, RegistryEntityId?> ownerIdsByNodeId =
        <RegistryNodeId, RegistryEntityId?>{};
    final Set<RegistryNodeId> visitedNodeIds = <RegistryNodeId>{};
    final List<({RegistryNodeId nodeId, RegistryEntityId? inheritedOwnerId})>
    remaining =
        <({RegistryNodeId nodeId, RegistryEntityId? inheritedOwnerId})>[];

    for (final RegistryNodeId root in roots.reversed) {
      remaining.add((nodeId: root, inheritedOwnerId: null));
    }

    while (remaining.isNotEmpty) {
      final current = remaining.removeLast();

      if (!visitedNodeIds.add(current.nodeId)) {
        throw StateError(
          'Helpy Registry structural parent evidence contains a cycle.',
        );
      }

      final RegistryEntityId? explicitOwnerId =
          ownerIdByBusinessScopeRootNodeId[current.nodeId];

      if (explicitOwnerId != null &&
          current.inheritedOwnerId != null &&
          explicitOwnerId != current.inheritedOwnerId) {
        throw StateError(
          'Helpy Registry business-scope evidence overlaps with '
          'different owners at ${current.nodeId.value}.',
        );
      }

      final RegistryEntityId? ownerId =
          explicitOwnerId ?? current.inheritedOwnerId;

      ownerIdsByNodeId[current.nodeId] = ownerId;

      final List<RegistryNodeId> children =
          childrenByParentId[current.nodeId] ?? const <RegistryNodeId>[];

      for (final RegistryNodeId childId in children.reversed) {
        remaining.add((nodeId: childId, inheritedOwnerId: ownerId));
      }
    }

    if (visitedNodeIds.length != activeIds.length) {
      throw StateError(
        'Helpy Registry business-scope ownership did not traverse every '
        'active structural node.',
      );
    }

    return Map<RegistryNodeId, RegistryEntityId?>.unmodifiable(
      ownerIdsByNodeId,
    );
  }
}
