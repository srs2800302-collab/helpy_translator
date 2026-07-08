import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service.dart';
import 'package:helpy_translator/registry_studio/core/application/engineering/engineering_service_contract.dart';

void main() {
  group('EngineeringServiceResult', () {
    test('creates typed success result', () {
      final EngineeringServiceResult<_Output> result =
          EngineeringServiceResult<_Output>.success(
            output: const _Output('done'),
            traceabilityReferences: <String>[' source:1 '],
          );

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.requireOutput, const _Output('done'));
      expect(result.traceabilityReferences, <String>['source:1']);
      expect(() => result.requireFailure, throwsStateError);
    });

    test('creates typed failure result', () {
      final EngineeringServiceFailure failure = EngineeringServiceFailure(
        code: 'missing_context',
        message: 'Missing context.',
      );

      final EngineeringServiceResult<_Output> result =
          EngineeringServiceResult<_Output>.failure(
            failure: failure,
            traceabilityReferences: <String>[' source:1 '],
          );

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.requireFailure, failure);
      expect(result.traceabilityReferences, <String>['source:1']);
      expect(() => result.requireOutput, throwsStateError);
    });

    test('keeps traceability references immutable and unique', () {
      final EngineeringServiceResult<_Output> result =
          EngineeringServiceResult<_Output>.success(
            output: const _Output('done'),
            traceabilityReferences: <String>['source:1'],
          );

      expect(
        () => result.traceabilityReferences.add('source:2'),
        throwsUnsupportedError,
      );

      expect(
        () => EngineeringServiceResult<_Output>.success(
          output: const _Output('done'),
          traceabilityReferences: <String>['same', 'same'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('EngineeringService', () {
    test('executes typed handler and returns typed output', () async {
      final _Service service = _Service();

      expect(service.validatePreconditions(const _Input('target')), isNull);

      final EngineeringServiceResult<_Output> result = await service.execute(
        const _Input('target'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.requireOutput, const _Output('handled:target'));
    });

    test('returns typed failure when precondition fails', () async {
      final _Service service = _Service(
        preconditionFailure: EngineeringServiceFailure(
          code: 'missing_context',
          message: 'Missing context.',
        ),
      );

      final EngineeringServiceResult<_Output> result = await service.execute(
        const _Input('target'),
      );

      expect(result.isFailure, isTrue);
      expect(result.requireFailure.code, 'missing_context');
    });
  });
}

final class _Service implements EngineeringService<_Input, _Output> {
  _Service({this.preconditionFailure});

  final EngineeringServiceFailure? preconditionFailure;

  @override
  EngineeringServiceContract<_Input, _Output> get contract =>
      EngineeringServiceContract<_Input, _Output>(
        contractKey: 'handle_context',
        semanticVersion: '1.0.0',
        description: 'Handle context.',
      );

  @override
  EngineeringServiceFailure? validatePreconditions(_Input input) {
    return preconditionFailure;
  }

  @override
  Future<EngineeringServiceResult<_Output>> execute(_Input input) async {
    final EngineeringServiceFailure? failure = validatePreconditions(input);

    if (failure != null) {
      return EngineeringServiceResult<_Output>.failure(failure: failure);
    }

    return EngineeringServiceResult<_Output>.success(
      output: _Output('handled:${input.value}'),
    );
  }
}

final class _Input implements EngineeringServiceInput {
  const _Input(this.value);

  final String value;
}

final class _Output implements EngineeringServiceOutput {
  const _Output(this.value);

  final String value;

  @override
  bool operator ==(Object other) {
    return other is _Output && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}
