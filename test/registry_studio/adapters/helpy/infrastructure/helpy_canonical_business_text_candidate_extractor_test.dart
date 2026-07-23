import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_canonical_business_text_candidate_extractor.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_business_scope_resolver.dart';
import 'package:helpy_translator/registry_studio/adapters/helpy/infrastructure/helpy_registry_document_interpreter.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate.dart';
import 'package:helpy_translator/registry_studio/canonical/domain/entities/canonical_business_text_candidate_index.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_structural_index.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  const HelpyCanonicalBusinessTextCandidateExtractor extractor =
      HelpyCanonicalBusinessTextCandidateExtractor();

  group('HelpyCanonicalBusinessTextCandidateExtractor', () {
    test('extracts headings and visible Markdown text only '
        'from confirmed business scope', () {
      final CanonicalBusinessTextCandidateIndex index = extractor
          .extractCandidates(_syntheticSnapshot());

      expect(index.candidateCount, 11);

      expect(
        index.candidates.map(
          (CanonicalBusinessTextCandidate candidate) => candidate.text,
        ),
        containsAll(<String>[
          '99. Service Architecture Registry — Future Category',
          'Client Rules',
          'Обычная фраза.',
          'Элемент списка.',
          'Нумерованный пункт.',
          'Подсказка клиенту.',
          'Kitchen Assembly',
          'Кран',
          'Фото-ТЗ должно формироваться через '
              'approved photo requirements.',
          'Фотография места установки.',
          'Вложенная фраза.',
        ]),
      );

      final List<CanonicalBusinessTextCandidate> headingCandidates = index
          .candidates
          .where(
            (CanonicalBusinessTextCandidate candidate) =>
                candidate.kind == CanonicalBusinessTextCandidateKind.heading,
          )
          .toList(growable: false);

      expect(headingCandidates, hasLength(2));

      expect(
        headingCandidates.every(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.directContentLine == 0,
        ),
        isTrue,
      );

      expect(
        index.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.kind == CanonicalBusinessTextCandidateKind.tableRow,
        ),
        isFalse,
      );

      expect(
        index.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Служебное резюме.' ||
              candidate.text.contains('STORED') ||
              candidate.text.contains('DOCS VERIFIED'),
        ),
        isFalse,
      );

      expect(
        index.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Global Completion Evidence Rule.' ||
              candidate.text == 'Chat Evidence Rules.',
        ),
        isFalse,
      );

      expect(
        index.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text.contains('technicalCall()'),
        ),
        isFalse,
      );

      expect(
        index.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.path.segments.contains('Technical Architecture'),
        ),
        isFalse,
      );

      expect(
        index.candidates.every(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.businessScopeOwnerId ==
              RegistryEntityId('owner.future'),
        ),
        isTrue,
      );
    });

    test('candidate identity does not depend on source lines', () {
      final CanonicalBusinessTextCandidateIndex first = extractor
          .extractCandidates(_syntheticSnapshot(sourceStartLine: 1));

      final CanonicalBusinessTextCandidateIndex second = extractor
          .extractCandidates(_syntheticSnapshot(sourceStartLine: 100));

      expect(
        second.candidates
            .map(
              (CanonicalBusinessTextCandidate candidate) => candidate.identity,
            )
            .toList(growable: false),
        first.candidates
            .map(
              (CanonicalBusinessTextCandidate candidate) => candidate.identity,
            )
            .toList(growable: false),
      );
    });

    test('extracts candidates from every currently resolved '
        'business owner in the pinned Registry', () async {
      final File fixture = File(
        'test/fixtures/registry_studio/source_indexing/'
        'Helpy_Architecture_Registry_v1.md',
      );

      expect(await fixture.exists(), isTrue);

      final String sourceContent = await fixture.readAsString();

      const String fingerprint = 'fixture:helpy-registry-stage3-candidates';

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

      final RegistrySnapshot resolved =
          const HelpyRegistryBusinessScopeResolver().resolveBusinessScope(
            RegistrySnapshot(
              projectId: 'helpy',
              projectAdapterId: 'helpy.registry.adapter.v1',
              sourceDocumentPath: fixture.path,
              sourceRevision: '05fb74b50b50f31c20896710f614c4de6ad7ad15',
              sourceSnapshotFingerprint: fingerprint,
              sourceContent: sourceContent,
              roots: <RegistryNode>[
                for (final HelpyRegistryDocumentNode root in interpretedRoots)
                  materializeNode(root),
              ],
            ),
          );

      final CanonicalBusinessTextCandidateIndex candidateIndex = extractor
          .extractCandidates(resolved);

      final RegistryStructuralIndex structuralIndex = RegistryStructuralIndex(
        resolved,
      );

      expect(candidateIndex.candidates, isNotEmpty);

      final List<RegistryNode> analyzedBusinessNodes = structuralIndex.nodes
          .where(
            (RegistryNode node) =>
                node.businessScopeOwnerId != null &&
                !node.path.segments.any(
                  (String segment) => segment.trim().toLowerCase().endsWith(
                    'admin dependencies',
                  ),
                ),
          )
          .toList(growable: false);

      final List<CanonicalBusinessTextCandidate> headingCandidates =
          candidateIndex.candidates
              .where(
                (CanonicalBusinessTextCandidate candidate) =>
                    candidate.kind ==
                    CanonicalBusinessTextCandidateKind.heading,
              )
              .toList(growable: false);

      expect(headingCandidates, hasLength(analyzedBusinessNodes.length));

      expect(
        headingCandidates.every((CanonicalBusinessTextCandidate candidate) {
          final RegistryNode node =
              structuralIndex.nodesById[candidate.nodeId]!;

          return candidate.directContentLine == 0 &&
              candidate.rawText == node.path.segments.last &&
              candidate.text.isNotEmpty;
        }),
        isTrue,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.kind == CanonicalBusinessTextCandidateKind.tableRow,
        ),
        isFalse,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text.startsWith('Status:') ||
              candidate.text.startsWith('Registry Status:') ||
              candidate.text.startsWith('Decision Summary:') ||
              candidate.text.startsWith('Evidence:'),
        ),
        isFalse,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) => candidate.path.segments
              .any((String segment) => segment.endsWith('Admin Dependencies')),
        ),
        isFalse,
      );

      expect(
        candidateIndex.candidates.map(
          (CanonicalBusinessTextCandidate candidate) => candidate.text,
        ),
        containsAll(<String>['Kitchen Assembly', 'Regular Cleaning', 'Кран']),
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text.contains('STORED') ||
              candidate.text.contains('DOCS VERIFIED'),
        ),
        isFalse,
      );
      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text == 'Global Completion Evidence Rule.' ||
              candidate.text == 'Chat Evidence Rules.',
        ),
        isFalse,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text ==
              'Фото-ТЗ должно формироваться через '
                  'approved photo requirements.',
        ),
        isTrue,
      );

      expect(candidateIndex.candidatesByOwnerId, hasLength(7));

      expect(
        candidateIndex.candidatesByOwnerId.values.every(
          (List<CanonicalBusinessTextCandidate> ownerCandidates) =>
              ownerCandidates.isNotEmpty,
        ),
        isTrue,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.text ==
              'Подготовьте доступ к установленному '
                  'оборудованию.',
        ),
        isTrue,
      );

      expect(
        candidateIndex.candidates.any(
          (CanonicalBusinessTextCandidate candidate) =>
              candidate.path.segments.any(
                (String segment) =>
                    segment.endsWith('Admin Panel Architecture'),
              ),
        ),
        isFalse,
      );

      expect(
        candidateIndex.candidates.every((
          CanonicalBusinessTextCandidate candidate,
        ) {
          final RegistryNode node =
              structuralIndex.nodesById[candidate.nodeId]!;

          return node.businessScopeOwnerId == candidate.businessScopeOwnerId &&
              node.path == candidate.path &&
              candidate.sourceEvidence.every(
                (SourceEvidence evidence) =>
                    evidence.sourceDocumentPath == fixture.path &&
                    evidence.sourceSnapshotFingerprint == fingerprint,
              );
        }),
        isTrue,
      );
    });
  });
}

RegistrySnapshot _syntheticSnapshot({int sourceStartLine = 1}) {
  const String documentPath = 'registry.md';

  const String fingerprint =
      'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  final RegistryEntityId ownerId = RegistryEntityId('owner.future');

  final RegistryNode businessChild = _node(
    id: 'node.business.child',
    path: const <String>[
      'Registry',
      '99. Service Architecture Registry '
          '— Future Category',
      'Client Rules',
    ],
    content: 'Вложенная фраза.',
    ownerId: ownerId,
    startLine: sourceStartLine + 20,
    endLine: sourceStartLine + 25,
  );

  final RegistryNode businessRoot = _node(
    id: 'node.business',
    path: const <String>[
      'Registry',
      '99. Service Architecture Registry '
          '— Future Category',
    ],
    content:
        'Status: APPROVED / STORED\n'
        'Decision Summary:\n'
        '- Служебное резюме.\n'
        'Наследуемые правила:\n'
        '- Global Completion Evidence Rule.\n'
        '#### Наследуемые правила\n'
        '- Chat Evidence Rules.\n'
        'Business Rules:\n'
        'Обычная фраза.\n'
        'Фото-ТЗ должно формироваться через '
        'approved photo requirements.\n'
        '3. Фотография места установки.\n'
        '- Элемент списка.\n'
        '1. Нумерованный пункт.\n'
        '> Подсказка клиенту.\n'
        '- Kitchen Assembly — STORED + DOCS ✅\n'
        '├── Кран\n'
        '| Колонка | Значение |\n'
        '| --- | --- |\n'
        '<!-- Служебный комментарий -->\n'
        '```dart\n'
        'technicalCall();\n'
        '```',
    ownerId: ownerId,
    startLine: sourceStartLine,
    endLine: sourceStartLine + 19,
    children: <RegistryNode>[businessChild],
  );

  final RegistryNode technicalRoot = _node(
    id: 'node.technical',
    path: const <String>['Registry', 'Technical Architecture'],
    content:
        'Технический текст.\n'
        '- technicalCall().',
    ownerId: null,
    startLine: sourceStartLine + 30,
    endLine: sourceStartLine + 35,
  );

  return RegistrySnapshot(
    projectId: 'helpy',
    projectAdapterId: 'helpy.registry.adapter.v1',
    sourceDocumentPath: documentPath,
    sourceRevision: 'revision-1',
    sourceSnapshotFingerprint: fingerprint,
    sourceContent:
        '# Registry\n'
        '## 99. Service Architecture Registry '
        '— Future Category\n'
        '## Technical Architecture\n',
    roots: <RegistryNode>[businessRoot, technicalRoot],
  );
}

RegistryNode _node({
  required String id,
  required List<String> path,
  required String content,
  required RegistryEntityId? ownerId,
  required int startLine,
  required int endLine,
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
    content: content,
    businessScopeOwnerId: ownerId,
    children: children,
  );
}
