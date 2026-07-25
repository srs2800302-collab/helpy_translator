import 'dart:io';

import '../../../canonical/application/project_canonical_adapter.dart';
import '../../../canonical/domain/canonical_analysis_package.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../application/contracts/helpy_canonical_dictionary_source.dart';
import 'helpy_canonical_dictionary_reader.dart';
import 'helpy_canonical_registry_projector.dart';

final class HelpyCanonicalAdapter implements ProjectCanonicalAdapter {
  factory HelpyCanonicalAdapter({
    required HelpyCanonicalDictionarySource dictionarySource,
    HelpyCanonicalDictionaryReader dictionaryReader =
        const HelpyCanonicalDictionaryReader(),
    HelpyCanonicalRegistryProjector registryProjector =
        const HelpyCanonicalRegistryProjector(),
  }) {
    if (dictionarySource.documentPath != contractDocumentPath) {
      throw ArgumentError.value(
        dictionarySource.documentPath,
        'dictionarySource',
        'Helpy canonical adapter requires the exact Registry Studio '
            'contract document.',
      );
    }

    return HelpyCanonicalAdapter._(
      dictionarySource: dictionarySource,
      dictionaryReader: dictionaryReader,
      registryProjector: registryProjector,
    );
  }

  const HelpyCanonicalAdapter._({
    required this.dictionarySource,
    required this.dictionaryReader,
    required this.registryProjector,
  });

  static const String projectId = 'helpy';
  static const String projectAdapterId = 'helpy.canonical.adapter.v1';
  static const String contractDocumentPath =
      'docs/architecture/registry_studio/'
      'Registry_Studio_Engineering_Change_Propagation_and_Approval_'
      'Contract_v1.md';

  final HelpyCanonicalDictionarySource dictionarySource;
  final HelpyCanonicalDictionaryReader dictionaryReader;
  final HelpyCanonicalRegistryProjector registryProjector;

  @override
  Future<CanonicalAnalysisPackage> prepareAnalysis({
    required RegistrySnapshot snapshot,
  }) async {
    if (snapshot.projectId != projectId) {
      return CanonicalAnalysisPackage(
        projectId: snapshot.projectId,
        projectAdapterId: projectAdapterId,
        registrySourceDocumentPath: snapshot.sourceDocumentPath,
        registryRevision: snapshot.sourceRevision,
        registrySourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        dictionary: null,
        businessEntities: const <CanonicalBusinessEntity>[],
        orderedBusinessBlocks: const <CanonicalOrderedBusinessBlock>[],
        adapterFailures: <CanonicalAdapterFailure>[
          CanonicalAdapterFailure(
            identity: 'helpy.canonical.adapter.failure.project',
            source: CanonicalAdapterFailureSource.adapter,
            severity: CanonicalAdapterFailureSeverity.fatal,
            code: 'project_id_mismatch',
            explanation:
                'Helpy canonical adapter получил RegistrySnapshot '
                'другого проекта.',
            relatedIdentity: snapshot.projectId,
            path: null,
            sourceEvidence: const [],
          ),
        ],
      );
    }

    final projection = registryProjector.project(snapshot: snapshot);

    CanonicalAnalysisPackage failurePackage({
      required String identity,
      required String code,
      required String explanation,
      required String? relatedIdentity,
    }) {
      return CanonicalAnalysisPackage(
        projectId: snapshot.projectId,
        projectAdapterId: projectAdapterId,
        registrySourceDocumentPath: snapshot.sourceDocumentPath,
        registryRevision: snapshot.sourceRevision,
        registrySourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
        dictionary: null,
        businessEntities: projection.businessEntities,
        orderedBusinessBlocks: projection.orderedBusinessBlocks,
        adapterFailures: <CanonicalAdapterFailure>[
          ...projection.failures,
          CanonicalAdapterFailure(
            identity: identity,
            source: CanonicalAdapterFailureSource.adapter,
            severity: CanonicalAdapterFailureSeverity.fatal,
            code: code,
            explanation: explanation,
            relatedIdentity: relatedIdentity,
            path: null,
            sourceEvidence: const [],
          ),
        ],
      );
    }

    CanonicalAnalysisPackage sourceLoadFailure(Object error) {
      return failurePackage(
        identity: 'helpy.canonical.adapter.failure.dictionary-load',
        code: 'dictionary_source_load_failed',
        explanation:
            'Не удалось загрузить exact Canonical Dictionary source: '
            '$error',
        relatedIdentity: snapshot.sourceRevision,
      );
    }

    late final HelpyCanonicalDictionaryDocument contractSource;

    try {
      contractSource = await dictionarySource.loadExactRevision(
        snapshot.sourceRevision,
      );
    } on IOException catch (error) {
      return sourceLoadFailure(error);
    } on FormatException catch (error) {
      return sourceLoadFailure(error);
    }

    if (contractSource.documentPath != contractDocumentPath) {
      return failurePackage(
        identity: 'helpy.canonical.adapter.failure.dictionary-source-path',
        code: 'dictionary_source_path_mismatch',
        explanation:
            'Загруженный Canonical Dictionary source имеет другой '
            'document path: ${contractSource.documentPath}.',
        relatedIdentity: contractSource.documentPath,
      );
    }

    if (contractSource.sourceRevision != snapshot.sourceRevision) {
      return failurePackage(
        identity: 'helpy.canonical.adapter.failure.dictionary-source-revision',
        code: 'dictionary_source_revision_mismatch',
        explanation:
            'Загруженный Canonical Dictionary source не соответствует '
            'запрошенной Registry revision.',
        relatedIdentity: contractSource.sourceRevision,
      );
    }

    final dictionaryResult = dictionaryReader.read(
      sourceContent: contractSource.content,
      sourceDocumentPath: contractSource.documentPath,
      sourceRevision: contractSource.sourceRevision,
      sourceSnapshotFingerprint: contractSource.sourceSnapshotFingerprint,
    );

    return CanonicalAnalysisPackage(
      projectId: snapshot.projectId,
      projectAdapterId: projectAdapterId,
      registrySourceDocumentPath: snapshot.sourceDocumentPath,
      registryRevision: snapshot.sourceRevision,
      registrySourceSnapshotFingerprint: snapshot.sourceSnapshotFingerprint,
      dictionary: dictionaryResult.dictionary,
      businessEntities: projection.businessEntities,
      orderedBusinessBlocks: projection.orderedBusinessBlocks,
      adapterFailures: <CanonicalAdapterFailure>[
        ...dictionaryResult.failures,
        ...projection.failures,
      ],
    );
  }
}
