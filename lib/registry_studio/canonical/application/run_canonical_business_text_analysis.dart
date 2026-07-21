import '../../registry/domain/entities/registry_snapshot.dart';
import '../domain/entities/canonical_business_text_analysis_result.dart';
import '../domain/entities/canonical_business_text_candidate_index.dart';
import '../domain/entities/canonical_business_text_classification_index.dart';
import '../domain/entities/canonical_dictionary.dart';
import 'contracts/canonical_business_text_candidate_extractor.dart';
import 'contracts/canonical_business_text_classifier.dart';

final class RunCanonicalBusinessTextAnalysis {
  const RunCanonicalBusinessTextAnalysis({
    required this.candidateExtractor,
    required this.classifier,
  });

  final CanonicalBusinessTextCandidateExtractor candidateExtractor;

  final CanonicalBusinessTextClassifier classifier;

  CanonicalBusinessTextAnalysisResult call({
    required RegistrySnapshot snapshot,
    required CanonicalDictionary dictionary,
  }) {
    final CanonicalBusinessTextCandidateIndex candidates = candidateExtractor
        .extractCandidates(snapshot);

    if (candidates.projectId != snapshot.projectId ||
        candidates.sourceDocumentPath != snapshot.sourceDocumentPath ||
        candidates.sourceRevision != snapshot.sourceRevision ||
        candidates.sourceSnapshotFingerprint !=
            snapshot.sourceSnapshotFingerprint) {
      throw StateError(
        'Canonical business-text candidate extraction '
        'must preserve the exact Registry snapshot identity.',
      );
    }

    final CanonicalBusinessTextClassificationIndex classifications = classifier
        .classify(candidates: candidates, dictionary: dictionary);

    return CanonicalBusinessTextAnalysisResult(
      candidates: candidates,
      classifications: classifications,
      dictionary: dictionary,
    );
  }
}
