import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';

void main() {
  group('EngineeringServiceFailure', () {
    test('normalizes failure fields and details', () {
      final EngineeringServiceFailure failure = EngineeringServiceFailure(
        code: ' missing_context ',
        message: ' Missing verified context. ',
        isRetryable: true,
        details: <String>[' entity missing ', ' payload missing '],
      );

      expect(failure.code, 'missing_context');
      expect(failure.message, 'Missing verified context.');
      expect(failure.isRetryable, isTrue);
      expect(failure.details, <String>['entity missing', 'payload missing']);
    });

    test('keeps details immutable', () {
      final EngineeringServiceFailure failure = EngineeringServiceFailure(
        code: 'missing_context',
        message: 'Missing verified context.',
        details: <String>['entity missing'],
      );

      expect(
        () => failure.details.add('payload missing'),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid failure values', () {
      expect(
        () => EngineeringServiceFailure(code: ' ', message: 'Missing.'),
        throwsArgumentError,
      );
      expect(
        () => EngineeringServiceFailure(code: 'missing', message: ' '),
        throwsArgumentError,
      );
      expect(
        () => EngineeringServiceFailure(
          code: 'missing',
          message: 'Missing.',
          details: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('EngineeringServiceContract', () {
    test('normalizes contract identity and exposes typed boundary', () {
      final EngineeringServiceContract<_Input, _Output> contract =
          EngineeringServiceContract<_Input, _Output>(
            contractKey: ' review_intake_context ',
            semanticVersion: ' 1.0.0 ',
            description: ' Review intake context. ',
            preconditions: <String>[' verified context '],
            traceabilityRequirements: <String>[' source evidence '],
          );

      expect(contract.contractKey, 'review_intake_context');
      expect(contract.semanticVersion, '1.0.0');
      expect(contract.description, 'Review intake context.');
      expect(contract.preconditions, <String>['verified context']);
      expect(contract.traceabilityRequirements, <String>['source evidence']);
      expect(contract.inputType, _Input);
      expect(contract.outputType, _Output);
      expect(contract.failureType, EngineeringServiceFailure);
      expect(contract.acceptsInput(const _Input()), isTrue);
      expect(contract.acceptsInput(const _OtherInput()), isFalse);
      expect(contract.acceptsOutput(const _Output()), isTrue);
      expect(contract.acceptsOutput(const _OtherOutput()), isFalse);
    });

    test('keeps preconditions and traceability requirements immutable', () {
      final EngineeringServiceContract<_Input, _Output> contract =
          EngineeringServiceContract<_Input, _Output>(
            contractKey: 'review_intake_context',
            semanticVersion: '1.0.0',
            description: 'Review intake context.',
            preconditions: <String>['verified context'],
            traceabilityRequirements: <String>['source evidence'],
          );

      expect(
        () => contract.preconditions.add('another'),
        throwsUnsupportedError,
      );
      expect(
        () => contract.traceabilityRequirements.add('another'),
        throwsUnsupportedError,
      );
    });

    test('rejects base input or output contracts', () {
      expect(
        () => EngineeringServiceContract<EngineeringServiceInput, _Output>(
          contractKey: 'review_intake_context',
          semanticVersion: '1.0.0',
          description: 'Review intake context.',
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringServiceContract<_Input, EngineeringServiceOutput>(
          contractKey: 'review_intake_context',
          semanticVersion: '1.0.0',
          description: 'Review intake context.',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid contract text fields', () {
      expect(
        () => EngineeringServiceContract<_Input, _Output>(
          contractKey: ' ',
          semanticVersion: '1.0.0',
          description: 'Review intake context.',
        ),
        throwsArgumentError,
      );
      expect(
        () => EngineeringServiceContract<_Input, _Output>(
          contractKey: 'review_intake_context',
          semanticVersion: ' ',
          description: 'Review intake context.',
        ),
        throwsArgumentError,
      );
      expect(
        () => EngineeringServiceContract<_Input, _Output>(
          contractKey: 'review_intake_context',
          semanticVersion: '1.0.0',
          description: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid preconditions and traceability requirements', () {
      expect(
        () => EngineeringServiceContract<_Input, _Output>(
          contractKey: 'review_intake_context',
          semanticVersion: '1.0.0',
          description: 'Review intake context.',
          preconditions: <String>['verified context', ' '],
        ),
        throwsArgumentError,
      );

      expect(
        () => EngineeringServiceContract<_Input, _Output>(
          contractKey: 'review_intake_context',
          semanticVersion: '1.0.0',
          description: 'Review intake context.',
          traceabilityRequirements: <String>[
            'source evidence',
            'source evidence',
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

final class _Input implements EngineeringServiceInput {
  const _Input();
}

final class _OtherInput implements EngineeringServiceInput {
  const _OtherInput();
}

final class _Output implements EngineeringServiceOutput {
  const _Output();
}

final class _OtherOutput implements EngineeringServiceOutput {
  const _OtherOutput();
}
