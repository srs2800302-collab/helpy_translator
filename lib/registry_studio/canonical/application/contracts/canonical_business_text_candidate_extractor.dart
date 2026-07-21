import '../../../registry/domain/entities/registry_snapshot.dart';
import '../../domain/entities/canonical_business_text_candidate_index.dart';

abstract interface class CanonicalBusinessTextCandidateExtractor {
  CanonicalBusinessTextCandidateIndex extractCandidates(
    RegistrySnapshot snapshot,
  );
}
