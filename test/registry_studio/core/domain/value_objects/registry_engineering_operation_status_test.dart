import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_status.dart';

void main() {
  test('defines the complete engineering operation lifecycle in order', () {
    expect(
      RegistryEngineeringOperationStatus.values,
      <RegistryEngineeringOperationStatus>[
        RegistryEngineeringOperationStatus.open,
        RegistryEngineeringOperationStatus.awaitingContext,
        RegistryEngineeringOperationStatus.readyForDecision,
        RegistryEngineeringOperationStatus.decided,
        RegistryEngineeringOperationStatus.cancelled,
      ],
    );

    expect(
      RegistryEngineeringOperationStatus.values
          .map((RegistryEngineeringOperationStatus status) => status.name)
          .toList(growable: false),
      <String>[
        'open',
        'awaitingContext',
        'readyForDecision',
        'decided',
        'cancelled',
      ],
    );
  });
}
