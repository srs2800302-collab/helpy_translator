import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/operation_status/transition_registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';
import 'package:helpy_translator/registry_studio/operation/presentation/screens/registry_engineering_operation_status_transition_screen.dart';
import 'package:helpy_translator/registry_studio/presentation/language/registry_studio_ui_language.dart';

void main() {
  group('RegistryEngineeringOperationStatusTransitionScreen', () {
    testWidgets('renders isolated operation status transition form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      expect(find.text('Смена статуса инженерной операции'), findsOneWidget);
      expect(find.text('Текущая операция'), findsOneWidget);
      expect(find.text('ID операции:\nregistry-operation-001'), findsOneWidget);
      expect(
        find.text(
          'Постановка проблемы:\nCheck possible canonical wording drift.',
        ),
        findsOneWidget,
      );
      expect(find.text('Текущий статус:\nopen'), findsOneWidget);
      expect(find.text('Запрошенный статус'), findsOneWidget);
      expect(find.text('Сменить статус'), findsOneWidget);
    });

    testWidgets('transitions in-memory operation through existing use case', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_requested_status_dropdown'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_status_transition_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Статус изменён'), findsOneWidget);
      expect(find.text('Текущий статус:\nreadyForDecision'), findsWidgets);
      expect(find.text('Ошибка смены статуса'), findsNothing);
    });

    testWidgets('shows presentation error for invalid transition', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_testApp());

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_status_transition_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ошибка смены статуса'), findsOneWidget);
      expect(
        find.textContaining(
          'Invalid registry engineering operation status transition',
        ),
        findsOneWidget,
      );
      expect(find.text('Статус изменён'), findsNothing);
    });

    testWidgets('renders operation status transition labels in TH', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _testApp(uiLanguage: RegistryStudioUiLanguage.th),
      );

      expect(find.text('เปลี่ยนสถานะงานวิศวกรรม'), findsOneWidget);
      expect(find.text('งานปัจจุบัน'), findsOneWidget);
      expect(find.text('สถานะที่ต้องการ'), findsOneWidget);
      expect(find.text('เปลี่ยนสถานะ'), findsOneWidget);
    });

    testWidgets('reports transitioned operation through optional callback', (
      WidgetTester tester,
    ) async {
      RegistryEngineeringOperationStatus? receivedStatus;

      await tester.pumpWidget(
        _testApp(
          onOperationTransitioned: (operation) {
            receivedStatus = operation.status;
          },
        ),
      );

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_requested_status_dropdown'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('readyForDecision').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const Key('registry_engineering_operation_status_transition_button'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        receivedStatus,
        RegistryEngineeringOperationStatus.readyForDecision,
      );
    });
  });
}

Widget _testApp({
  RegistryStudioUiLanguage uiLanguage = RegistryStudioUiLanguage.ru,
  ValueChanged<RegistryEngineeringOperation>? onOperationTransitioned,
}) {
  return MaterialApp(
    home: RegistryEngineeringOperationStatusTransitionScreen(
      uiLanguage: uiLanguage,
      operation: _operationWith(RegistryEngineeringOperationStatus.open),
      transitionRegistryEngineeringOperationStatus:
          TransitionRegistryEngineeringOperationStatus(),
      onOperationTransitioned: onOperationTransitioned,
    ),
  );
}

RegistryEngineeringOperation _operationWith(
  RegistryEngineeringOperationStatus status,
) {
  return RegistryEngineeringOperation(
    id: RegistryEngineeringOperationId('registry-operation-001'),
    status: status,
    problemStatement: 'Check possible canonical wording drift.',
  );
}
