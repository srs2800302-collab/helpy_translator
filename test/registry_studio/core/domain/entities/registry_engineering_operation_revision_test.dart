import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/core/domain/entities/registry_engineering_operation_revision.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_engineering_operation_id.dart';
import 'package:helpy_translator/registry_studio/core/domain/value_objects/registry_entity_id.dart';

void main() {
  group('RegistryEngineeringOperationRevision', () {
    test('creates a normalized immutable revision', () {
      final List<RegistryEntityId> sourceRelatedIds = <RegistryEntityId>[
        RegistryEntityId('related-1'),
        RegistryEntityId('related-2'),
      ];

      final RegistryEngineeringOperationRevision revision =
          RegistryEngineeringOperationRevision(
            id: '  revision-2  ',
            operationId: RegistryEngineeringOperationId('operation-1'),
            revisionNumber: 2,
            workingContent: '  Complete current working version.  ',
            previousRevisionId: '  revision-1  ',
            primaryEntityId: RegistryEntityId('primary'),
            relatedEntityIds: sourceRelatedIds,
            semanticCandidateDecisions: const <String, bool>{
              '  candidate-a  ': true,
              'candidate-b': false,
            },
          );

      sourceRelatedIds.add(RegistryEntityId('late'));

      expect(revision.id, 'revision-2');
      expect(
        revision.operationId,
        RegistryEngineeringOperationId('operation-1'),
      );
      expect(revision.revisionNumber, 2);
      expect(revision.workingContent, 'Complete current working version.');
      expect(revision.previousRevisionId, 'revision-1');
      expect(revision.primaryEntityId, RegistryEntityId('primary'));
      expect(revision.relatedEntityIds, <RegistryEntityId>[
        RegistryEntityId('related-1'),
        RegistryEntityId('related-2'),
      ]);
      expect(revision.semanticCandidateDecisions, <String, bool>{
        'candidate-a': true,
        'candidate-b': false,
      });
      expect(
        () => revision.relatedEntityIds.add(RegistryEntityId('forbidden')),
        throwsUnsupportedError,
      );
      expect(
        () => revision.semanticCandidateDecisions['forbidden'] = true,
        throwsUnsupportedError,
      );
    });

    test('stores normalized original and proposed values', () {
      final RegistryEngineeringOperationRevision revision =
          RegistryEngineeringOperationRevision(
            id: 'revision-1',
            operationId: RegistryEngineeringOperationId('operation-1'),
            revisionNumber: 1,
            workingContent: '  Current working version.  ',
            originalValue: '  Original registry value.  ',
            proposedValue: '  Proposed registry value.  ',
            previousRevisionId: null,
            primaryEntityId: RegistryEntityId('primary'),
            relatedEntityIds: const <RegistryEntityId>[],
          );

      expect(revision.workingContent, 'Current working version.');
      expect(revision.originalValue, 'Original registry value.');
      expect(revision.proposedValue, 'Proposed registry value.');
    });

    test('defaults original and proposed values to working content', () {
      final RegistryEngineeringOperationRevision revision =
          RegistryEngineeringOperationRevision(
            id: 'revision-1',
            operationId: RegistryEngineeringOperationId('operation-1'),
            revisionNumber: 1,
            workingContent: '  Current working version.  ',
            previousRevisionId: null,
            primaryEntityId: RegistryEntityId('primary'),
            relatedEntityIds: const <RegistryEntityId>[],
          );

      expect(revision.workingContent, 'Current working version.');
      expect(revision.originalValue, 'Current working version.');
      expect(revision.proposedValue, 'Current working version.');
    });

    test('allows first revision without previous revision', () {
      final RegistryEngineeringOperationRevision revision =
          RegistryEngineeringOperationRevision(
            id: 'revision-1',
            operationId: RegistryEngineeringOperationId('operation-1'),
            revisionNumber: 1,
            workingContent: 'Initial complete working version.',
            previousRevisionId: null,
            primaryEntityId: RegistryEntityId('primary'),
            relatedEntityIds: const <RegistryEntityId>[],
          );

      expect(revision.previousRevisionId, isNull);
    });

    test('rejects invalid identity, number, lineage and content', () {
      RegistryEngineeringOperationRevision create({
        String id = 'revision-1',
        int revisionNumber = 1,
        String workingContent = 'Working content.',
        String? originalValue,
        String? proposedValue,
        String? previousRevisionId,
      }) {
        return RegistryEngineeringOperationRevision(
          id: id,
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: revisionNumber,
          workingContent: workingContent,
          originalValue: originalValue,
          proposedValue: proposedValue,
          previousRevisionId: previousRevisionId,
          primaryEntityId: RegistryEntityId('primary'),
          relatedEntityIds: const <RegistryEntityId>[],
        );
      }

      expect(() => create(id: '   '), throwsArgumentError);
      expect(() => create(revisionNumber: 0), throwsArgumentError);
      expect(() => create(workingContent: '   '), throwsArgumentError);
      expect(() => create(originalValue: '   '), throwsArgumentError);
      expect(() => create(proposedValue: '   '), throwsArgumentError);
      expect(
        () => create(revisionNumber: 1, previousRevisionId: 'revision-0'),
        throwsArgumentError,
      );
      expect(() => create(revisionNumber: 2), throwsArgumentError);
      expect(
        () => create(revisionNumber: 2, previousRevisionId: '   '),
        throwsArgumentError,
      );
    });

    test('rejects invalid related entity ids', () {
      final RegistryEntityId primaryId = RegistryEntityId('primary');
      final RegistryEntityId relatedId = RegistryEntityId('related');

      expect(
        () => RegistryEngineeringOperationRevision(
          id: 'revision-1',
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: 1,
          workingContent: 'Working content.',
          previousRevisionId: null,
          primaryEntityId: primaryId,
          relatedEntityIds: <RegistryEntityId>[relatedId, relatedId],
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEngineeringOperationRevision(
          id: 'revision-1',
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: 1,
          workingContent: 'Working content.',
          previousRevisionId: null,
          primaryEntityId: primaryId,
          relatedEntityIds: <RegistryEntityId>[primaryId],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid semantic candidate decision keys', () {
      expect(
        () => RegistryEngineeringOperationRevision(
          id: 'revision-1',
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: 1,
          workingContent: 'Working content.',
          previousRevisionId: null,
          primaryEntityId: RegistryEntityId('primary'),
          relatedEntityIds: const <RegistryEntityId>[],
          semanticCandidateDecisions: const <String, bool>{'   ': true},
        ),
        throwsArgumentError,
      );

      expect(
        () => RegistryEngineeringOperationRevision(
          id: 'revision-1',
          operationId: RegistryEngineeringOperationId('operation-1'),
          revisionNumber: 1,
          workingContent: 'Working content.',
          previousRevisionId: null,
          primaryEntityId: RegistryEntityId('primary'),
          relatedEntityIds: const <RegistryEntityId>[],
          semanticCandidateDecisions: const <String, bool>{
            'candidate': true,
            ' candidate ': false,
          },
        ),
        throwsArgumentError,
      );
    });

    test('defines equality only by revision identity', () {
      final RegistryEngineeringOperationRevision first =
          RegistryEngineeringOperationRevision(
            id: 'shared',
            operationId: RegistryEngineeringOperationId('operation-1'),
            revisionNumber: 1,
            workingContent: 'First.',
            previousRevisionId: null,
            primaryEntityId: RegistryEntityId('primary-1'),
            relatedEntityIds: const <RegistryEntityId>[],
          );

      final RegistryEngineeringOperationRevision second =
          RegistryEngineeringOperationRevision(
            id: 'shared',
            operationId: RegistryEngineeringOperationId('operation-2'),
            revisionNumber: 2,
            workingContent: 'Second.',
            previousRevisionId: 'previous',
            primaryEntityId: RegistryEntityId('primary-2'),
            relatedEntityIds: const <RegistryEntityId>[],
          );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
