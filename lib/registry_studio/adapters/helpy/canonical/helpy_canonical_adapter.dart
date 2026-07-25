import '../../../canonical/application/project_canonical_adapter.dart';
import '../../../canonical/domain/canonical_analysis_package.dart';
import '../../../registry/domain/entities/registry_snapshot.dart';
import '../infrastructure/github_registry_document_source.dart';
import 'helpy_canonical_dictionary_reader.dart';
import 'helpy_canonical_registry_projector.dart';

final class HelpyCanonicalAdapter implements ProjectCanonicalAdapter {
  factory HelpyCanonicalAdapter({
    required GitHubRegistryDocumentSource dictionarySource,
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

  final GitHubRegistryDocumentSource dictionarySource;
  final HelpyCanonicalDictionaryReader dictionaryReader;
  final HelpyCanonicalRegistryProjector registryProjector;

  @override
  Future<CanonicalAnalysisPackage> prepareAnalysis({
    required RegistrySnapshot snapshot,
  }) async {
    final projection = registryProjector.project(snapshot: snapshot);

    if (snapshot.projectId != projectId) {
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

    try {
      final contractSource = await dictionarySource.load(
        exactRevision: snapshot.sourceRevision,
      );

      if (contractSource.documentPath != contractDocumentPath) {
        throw FormatException(
          'Canonical Dictionary source path does not match the '
          'approved contract path: ${contractSource.documentPath}.',
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
    } on Object catch (error) {
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
            identity: 'helpy.canonical.adapter.failure.dictionary-load',
            source: CanonicalAdapterFailureSource.adapter,
            severity: CanonicalAdapterFailureSeverity.fatal,
            code: 'dictionary_source_load_failed',
            explanation:
                'Не удалось загрузить exact Canonical Dictionary source: '
                '$error',
            relatedIdentity: snapshot.sourceRevision,
            path: null,
            sourceEvidence: const [],
          ),
        ],
      );
    }
  }
}
