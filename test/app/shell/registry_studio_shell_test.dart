import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/bootstrap/registry_studio_application.dart';
import 'package:helpy_translator/app/shell/registry_studio_shell.dart';

void main() {
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

  testWidgets('shows exactly two workspaces and switches to Translator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RegistryStudioApplication());

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

    expect(
      find.text('Просмотр и сопровождение структурного Registry'),
      findsOneWidget,
    );

    final Finder translatorNavigationLabel = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Translator'),
    );

    expect(translatorNavigationLabel, findsOneWidget);

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
  });
}
