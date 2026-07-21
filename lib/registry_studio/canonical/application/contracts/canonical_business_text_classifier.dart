import '../../domain/entities/canonical_business_text_candidate_index.dart';
import '../../domain/entities/canonical_business_text_classification_index.dart';
import '../../domain/entities/canonical_dictionary.dart';

abstract interface class CanonicalBusinessTextClassifier {
  CanonicalBusinessTextClassificationIndex classify({
    required CanonicalBusinessTextCandidateIndex candidates,
    required CanonicalDictionary dictionary,
  });
}
