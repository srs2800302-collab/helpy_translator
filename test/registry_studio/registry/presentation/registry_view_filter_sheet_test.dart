import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';
import 'package:helpy_translator/registry_studio/registry/presentation/registry_analysis_status_entry.dart';
import 'package:helpy_translator/registry_studio/registry/presentation/registry_view_filter_sheet.dart';

void main() {
  testWidgets(
    'keeps selections local and recalculates canonical counts by scope',
    (WidgetTester tester) async {
      const String fingerprint = 'sha256:filter-sheet';

      final RegistryNode leafA = RegistryNode(
        id: RegistryNodeId('leaf-a'),
        kindId: 'leaf',
        path: RegistryPath(const <String>['Root A', 'Branch A', 'Leaf A']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root A', 'Branch A', 'Leaf A'],
            startLine: 3,
            endLine: 3,
          ),
        ],
        content: 'Exact A.',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode branchA = RegistryNode(
        id: RegistryNodeId('branch-a'),
        kindId: 'branch',
        path: RegistryPath(const <String>['Root A', 'Branch A']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root A', 'Branch A'],
            startLine: 2,
            endLine: 3,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: <RegistryNode>[leafA],
      );

      final RegistryNode rootA = RegistryNode(
        id: RegistryNodeId('root-a'),
        kindId: 'root',
        path: RegistryPath(const <String>['Root A']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root A'],
            startLine: 1,
            endLine: 3,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: <RegistryNode>[branchA],
      );

      final RegistryNode leafB = RegistryNode(
        id: RegistryNodeId('leaf-b'),
        kindId: 'leaf',
        path: RegistryPath(const <String>['Root B', 'Branch B', 'Leaf B']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root B', 'Branch B', 'Leaf B'],
            startLine: 6,
            endLine: 6,
          ),
        ],
        content: 'Exact B.',
        businessScopeOwnerId: null,
        children: const <RegistryNode>[],
      );

      final RegistryNode branchB = RegistryNode(
        id: RegistryNodeId('branch-b'),
        kindId: 'branch',
        path: RegistryPath(const <String>['Root B', 'Branch B']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root B', 'Branch B'],
            startLine: 5,
            endLine: 6,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: <RegistryNode>[leafB],
      );

      final RegistryNode rootB = RegistryNode(
        id: RegistryNodeId('root-b'),
        kindId: 'root',
        path: RegistryPath(const <String>['Root B']),
        sourceEvidence: <SourceEvidence>[
          SourceEvidence(
            sourceDocumentPath: 'registry.md',
            sourceSnapshotFingerprint: fingerprint,
            headingPath: const <String>['Root B'],
            startLine: 4,
            endLine: 6,
          ),
        ],
        content: '',
        businessScopeOwnerId: null,
        children: <RegistryNode>[branchB],
      );

      final Map<RegistryNodeId, RegistryNode> nodesById =
          <RegistryNodeId, RegistryNode>{
            rootA.id: rootA,
            branchA.id: branchA,
            leafA.id: leafA,
            rootB.id: rootB,
            branchB.id: branchB,
            leafB.id: leafB,
          };

      final List<RegistryAnalysisStatusEntry> entries =
          <RegistryAnalysisStatusEntry>[
            RegistryAnalysisStatusEntry(
              identity: 'status-leaf-a',
              nodeId: leafA.id,
              statusId: 'exact',
              statusLabel: 'Exact',
              reason: 'Exact match.',
              text: leafA.content,
              directContentLine: 1,
              sourceEvidence: leafA.sourceEvidence,
            ),
            RegistryAnalysisStatusEntry(
              identity: 'status-leaf-b',
              nodeId: leafB.id,
              statusId: 'exact',
              statusLabel: 'Exact',
              reason: 'Exact match.',
              text: leafB.content,
              directContentLine: 1,
              sourceEvidence: leafB.sourceEvidence,
            ),
          ];

      final List<String> structuralSelections = <String>[];
      final List<String> canonicalSelections = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return TextButton(
                  key: const ValueKey<String>('open-filter-sheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return RegistryViewFilterSheet(
                          nodesById: nodesById,
                          analysisStatusEntries: entries,
                          branchScopeNodeId: branchA.id,
                          initialRegistryViewFilter: 'branches',
                          initialCanonicalStatusFilter: 'all',
                          onRegistryViewFilterChanged: (String filter) async {
                            structuralSelections.add(filter);
                          },
                          onCanonicalStatusFilterChanged:
                              (String filter) async {
                                canonicalSelections.add(filter);
                              },
                        );
                      },
                    );
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey<String>('open-filter-sheet')));
      await tester.pumpAndSettle();

      final Finder sheet = find.byKey(
        const ValueKey<String>('registry-view-filter-sheet'),
      );

      final Finder allFilter = find.byKey(
        const ValueKey<String>('registry-view-filter-all'),
      );

      final Finder rootsFilter = find.byKey(
        const ValueKey<String>('registry-view-filter-roots'),
      );

      final Finder branchesFilter = find.byKey(
        const ValueKey<String>('registry-view-filter-branches'),
      );

      final Finder leavesFilter = find.byKey(
        const ValueKey<String>('registry-view-filter-leaves'),
      );

      final Finder exactFilter = find.byKey(
        const ValueKey<String>('registry-canonical-status-filter-exact'),
      );

      final Finder exactCount = find.byKey(
        const ValueKey<String>('registry-canonical-status-count-exact'),
      );

      final Finder filterList = find.descendant(
        of: sheet,
        matching: find.byType(ListView),
      );

      expect(sheet, findsOneWidget);
      expect(filterList, findsOneWidget);
      expect(allFilter, findsOneWidget);
      expect(rootsFilter, findsOneWidget);
      expect(branchesFilter, findsOneWidget);
      expect(leavesFilter, findsOneWidget);

      expect(
        tester.getTopLeft(rootsFilter).dy,
        lessThan(tester.getTopLeft(allFilter).dy),
      );
      expect(
        tester.getTopLeft(allFilter).dy,
        lessThan(tester.getTopLeft(branchesFilter).dy),
      );
      expect(
        tester.getTopLeft(branchesFilter).dy,
        lessThan(tester.getTopLeft(leavesFilter).dy),
      );

      expect(
        find.descendant(
          of: allFilter,
          matching: find.byIcon(Icons.account_tree_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rootsFilter,
          matching: find.byIcon(Icons.home_work_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: branchesFilter,
          matching: find.byIcon(Icons.folder_outlined),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: leavesFilter,
          matching: find.byIcon(Icons.description_outlined),
        ),
        findsOneWidget,
      );

      expect(tester.widget<ListTile>(branchesFilter).selected, isTrue);

      await tester.dragUntilVisible(
        exactFilter,
        filterList,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(exactCount).data,
        'Формулировок: 1 · узлов: 1',
      );

      await tester.dragUntilVisible(
        rootsFilter,
        filterList,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      await tester.tap(rootsFilter);
      await tester.pumpAndSettle();

      expect(structuralSelections, <String>['roots']);
      expect(sheet, findsOneWidget);
      expect(tester.widget<ListTile>(rootsFilter).selected, isTrue);
      expect(tester.widget<ListTile>(branchesFilter).selected, isFalse);

      await tester.dragUntilVisible(
        exactFilter,
        filterList,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<Text>(exactCount).data,
        'Формулировок: 2 · узлов: 2',
      );

      await tester.tap(exactFilter);
      await tester.pumpAndSettle();

      expect(canonicalSelections, <String>['exact']);
      expect(sheet, findsOneWidget);
      expect(tester.widget<ListTile>(exactFilter).selected, isTrue);

      await tester.tap(exactFilter);
      await tester.pumpAndSettle();

      expect(canonicalSelections, <String>['exact']);

      await tester.tap(
        find.byKey(const ValueKey<String>('registry-view-filter-close')),
      );
      await tester.pumpAndSettle();

      expect(sheet, findsNothing);
    },
  );
}
