import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../domain/entities/canonical_business_text_analysis_result.dart';

abstract interface class CanonicalBusinessTextAnalysisSessionRunner {
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis(
    RegistrySnapshot snapshot,
  );
}
