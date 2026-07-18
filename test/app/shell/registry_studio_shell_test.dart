import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';
import 'package:helpy_translator/registry_studio/core/domain/evidence/source_evidence.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_path.dart';
import 'package:helpy_translator/registry_studio/registry/application/contracts/registry_snapshot_loader.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_node.dart';
import 'package:helpy_translator/registry_studio/registry/domain/entities/registry_snapshot.dart';
import 'package:helpy_translator/registry_studio/registry/domain/value_objects/registry_node_id.dart';

void main() {
  late RegistrySnapshot snapshot;

  setUp(() {
    const String documentPath = 'registry.md';
    const String fingerprint =
        'git-blob:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    final RegistryNode child = RegistryNode(
      id: RegistryNodeId('project.registry.node.000002'),
      kindId: 'project.registry.heading.2',
      path: RegistryPath(const <String>['Registry', 'Domain']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry', 'Domain'],
          startLine: 3,
          endLine: 4,
        ),
      ],
      content: 'Domain content.',
      businessScopeOwnerId: null,
      children: const <RegistryNode>[],
    );

    final RegistryNode root = RegistryNode(
      id: RegistryNodeId('project.registry.node.000001'),
      kindId: 'project.registry.heading.1',
      path: RegistryPath(const <String>['Registry']),
      sourceEvidence: <SourceEvidence>[
        SourceEvidence(
          sourceDocumentPath: documentPath,
          sourceSnapshotFingerprint: fingerprint,
          headingPath: const <String>['Registry'],
          startLine: 1,
          endLine: 4,
        ),
      ],
      content: 'Root content.',
      businessScopeOwnerId: null,
      children: <RegistryNode>[child],
    );

    snapshot = RegistrySnapshot(
      projectId: 'project',
      projectAdapterId: 'project.registry.adapter.v1',
      sourceDocumentPath: documentPath,
      sourceRevision: '1111111111111111111111111111111111111111',
      sourceSnapshotFingerprint: fingerprint,
      sourceContent:
          '# Registry\n'
          'Root content.\n'
          '## Domain\n'
          'Domain content.\n',
      roots: <RegistryNode>[root],
    );
  });

  group('RegistryStudioWorkspaceCubit', () {
    test('starts in Registry Studio and emits only actual changes', () async {
      final RegistryStudioWorkspaceCubit cubit = RegistryStudioWorkspaceCubit();

      final Future<List<RegistryStudioWorkspace>> emittedStates = cubit.stream
          .toList();

      expect(cubit.state, RegistryStudioWorkspace.registryStudio);

      cubit.select(RegistryStudioWorkspace.translator);
      cubit.select(RegistryStudioWorkspace.translator);

      await cubit.close();

      expect(await emittedStates, <RegistryStudioWorkspace>[
        RegistryStudioWorkspace.translator,
      ]);
    });
  });

  testWidgets(
    'loads the complete Registry, reloads it and preserves workspace navigation',
    (WidgetTester tester) async {
      final Completer<RegistrySnapshot> firstLoad =
          Completer<RegistrySnapshot>();

      final _QueuedRegistrySnapshotLoader loader =
          _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
            () => firstLoad.future,
            () async => snapshot,
          ]);

      await tester.pumpWidget(
        RegistryStudioApplication(registrySnapshotLoader: loader),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Загрузка Registry'), findsOneWidget);

      firstLoad.complete(snapshot);
      await tester.pumpAndSettle();

      expect(find.text('Проект: project'), findsOneWidget);
      expect(find.text('Узлов: 2'), findsOneWidget);
      expect(find.text('Registry'), findsOneWidget);
      expect(find.text('Domain'), findsOneWidget);
      expect(find.byTooltip('Перезагрузить Registry'), findsOneWidget);

      await tester.tap(find.byTooltip('Перезагрузить Registry'));
      await tester.pumpAndSettle();

      expect(loader.loadCount, 2);
      expect(find.text('Узлов: 2'), findsOneWidget);

      expect(find.byType(NavigationBar), findsOneWidget);

      final List<NavigationDestination> destinations = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .toList(growable: false);

      expect(destinations, hasLength(2));
      expect(
        destinations
            .map((NavigationDestination destination) => destination.label)
            .toList(growable: false),
        <String>['Registry Studio', 'Translator'],
      );

      final Finder translatorNavigationLabel = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Translator'),
      );

      await tester.tap(translatorNavigationLabel);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Translator'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Перевод и проверка формулировок RU / EN / TH'),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows Registry failure and retries through the same loader', (
    WidgetTester tester,
  ) async {
    final _QueuedRegistrySnapshotLoader loader =
        _QueuedRegistrySnapshotLoader(<Future<RegistrySnapshot> Function()>[
          () => Future<RegistrySnapshot>.error(StateError('offline')),
          () async => snapshot,
        ]);

    await tester.pumpWidget(
      RegistryStudioApplication(registrySnapshotLoader: loader),
    );

    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить Registry'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.byTooltip('Повторить загрузку Registry'), findsOneWidget);

    await tester.tap(find.byTooltip('Повторить загрузку Registry'));
    await tester.pumpAndSettle();

    expect(loader.loadCount, 2);
    expect(find.text('Узлов: 2'), findsOneWidget);
    expect(find.text('Не удалось загрузить Registry'), findsNothing);
  });
}

final class _QueuedRegistrySnapshotLoader implements RegistrySnapshotLoader {
  _QueuedRegistrySnapshotLoader(this.loads);

  final List<Future<RegistrySnapshot> Function()> loads;

  int loadCount = 0;

  @override
  Future<RegistrySnapshot> loadSnapshot() {
    if (loadCount >= loads.length) {
      return Future<RegistrySnapshot>.error(
        StateError('No configured Registry snapshot load remains.'),
      );
    }

    final Future<RegistrySnapshot> Function() load = loads[loadCount];

    loadCount += 1;

    return load();
  }
}
