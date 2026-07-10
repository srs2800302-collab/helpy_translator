import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helpy_translator/core/persistence/registry_work_session_persistence.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists and restores operation with revisions', () async {
    const RegistryWorkSessionPersistence persistence =
        RegistryWorkSessionPersistence();

    final RegistryEngineeringOperation operation = RegistryEngineeringOperation(
      id: RegistryEngineeringOperationId('operation-1'),
      status: RegistryEngineeringOperationStatus.open,
      problemStatement: 'Original problem.',
    );

    final RegistryEngineeringOperationRevision revision =
        RegistryEngineeringOperationRevision(
          id: 'revision-1',
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: 1,
          workingContent: 'Complete working version.',
          previousRevisionId: null,
          primaryEntityId: RegistryEntityId('primary'),
          relatedEntityIds: <RegistryEntityId>[RegistryEntityId('related')],
        );

    await persistence.saveEngineeringOperationWorkspace(
      operation: operation,
      revisions: <RegistryEngineeringOperationRevision>[revision],
    );

    final RegistryEngineeringOperation? restoredOperation = await persistence
        .loadEngineeringOperation();
    final List<RegistryEngineeringOperationRevision> restoredRevisions =
        await persistence.loadEngineeringOperationRevisions();

    expect(restoredOperation, isNotNull);
    expect(restoredOperation!.id, operation.id);
    expect(restoredOperation.status, operation.status);
    expect(restoredOperation.problemStatement, operation.problemStatement);

    expect(restoredRevisions, hasLength(1));
    expect(restoredRevisions.single.id, revision.id);
    expect(restoredRevisions.single.operationId, revision.operationId);
    expect(restoredRevisions.single.workingContent, revision.workingContent);
    expect(restoredRevisions.single.primaryEntityId, revision.primaryEntityId);
    expect(
      restoredRevisions.single.relatedEntityIds,
      revision.relatedEntityIds,
    );

    await persistence.clearEngineeringOperationWorkspace();

    expect(await persistence.loadEngineeringOperation(), isNull);
    expect(await persistence.loadEngineeringOperationRevisions(), isEmpty);
  });
}
