import '../../registry/domain/entities/registry_snapshot.dart';
import '../domain/canonical_analysis_package.dart';

abstract interface class ProjectCanonicalAdapter {
  Future<CanonicalAnalysisPackage> prepareAnalysis({
    required RegistrySnapshot snapshot,
  });
}
