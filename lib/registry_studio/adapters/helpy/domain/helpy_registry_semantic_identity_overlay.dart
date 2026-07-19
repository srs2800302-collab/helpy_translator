import '../../../core/domain/value_objects/registry_entity_id.dart';
import '../../../core/domain/value_objects/registry_entity_kind.dart';
import '../../../core/domain/value_objects/registry_path.dart';
import '../../../registry/domain/value_objects/registry_node_id.dart';
import 'helpy_registry_semantic_contract.dart';

final class HelpyRegistrySemanticIdentity {
  factory HelpyRegistrySemanticIdentity({
    required int sequence,
    required RegistryEntityKind kind,
    required RegistryPath evidencePath,
    required bool ownsBusinessScope,
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

    return HelpyRegistrySemanticIdentity._(
      nodeId: RegistryNodeId('helpy.registry.node.$formattedSequence'),
      entityId: RegistryEntityId('helpy.registry.entity.$formattedSequence'),
      kind: kind,
      evidencePath: evidencePath,
      ownsBusinessScope: ownsBusinessScope,
    );
  }

  const HelpyRegistrySemanticIdentity._({
    required this.nodeId,
    required this.entityId,
    required this.kind,
    required this.evidencePath,
    required this.ownsBusinessScope,
  });

  final RegistryNodeId nodeId;
  final RegistryEntityId entityId;
  final RegistryEntityKind kind;
  final RegistryPath evidencePath;
  final bool ownsBusinessScope;
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
    final Set<RegistryPath> evidencePaths = <RegistryPath>{};

    for (final HelpyRegistrySemanticIdentity identity in normalizedIdentities) {
      if (identitiesByNodeId.containsKey(identity.nodeId)) {
        throw ArgumentError.value(
          identity.nodeId,
          'identities',
          'Helpy Registry semantic identity overlay contains a duplicate '
              'node identity.',
        );
      }

      if (!entityIds.add(identity.entityId)) {
        throw ArgumentError.value(
          identity.entityId,
          'identities',
          'Helpy Registry semantic identity overlay contains a duplicate '
              'entity identity.',
        );
      }

      if (!evidencePaths.add(identity.evidencePath)) {
        throw ArgumentError.value(
          identity.evidencePath,
          'identities',
          'Helpy Registry semantic identity overlay contains a duplicate '
              'evidence path.',
        );
      }

      identitiesByNodeId[identity.nodeId] = identity;
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
            sequence: 303,
            kind: HelpyRegistrySemanticContract.contract,
            evidencePath: RegistryPath(<String>[
              'Helpy Architecture Registry v1 Foundation',
              '24. Service Architecture Registry — Plumbing',
            ]),
            ownsBusinessScope: true,
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

      final HelpyRegistrySemanticIdentity? identity =
          identitiesByNodeId[current.nodeId];

      final RegistryEntityId? ownerId = identity?.ownsBusinessScope == true
          ? identity!.entityId
          : current.inheritedOwnerId;

      ownerIdsByNodeId[current.nodeId] = ownerId;

      final List<RegistryNodeId> children =
          childrenByParentId[current.nodeId] ?? const <RegistryNodeId>[];

      for (final RegistryNodeId childId in children.reversed) {
        remaining.add((nodeId: childId, inheritedOwnerId: ownerId));
      }
    }

    if (visitedNodeIds.length != activeIds.length) {
      throw StateError(
        'Helpy Registry business-scope ownership did not cover every active '
        'structural node.',
      );
    }

    return Map<RegistryNodeId, RegistryEntityId?>.unmodifiable(
      ownerIdsByNodeId,
    );
  }
}
