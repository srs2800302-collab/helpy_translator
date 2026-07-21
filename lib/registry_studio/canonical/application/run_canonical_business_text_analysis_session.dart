import '../../registry/application/contracts/registry_snapshot_loader.dart';
import '../../registry/domain/entities/registry_snapshot.dart';
import '../domain/entities/canonical_business_text_analysis_result.dart';
import '../domain/entities/canonical_dictionary.dart';
import 'contracts/canonical_business_text_analysis_session_runner.dart';
import 'contracts/canonical_dictionary_loader.dart';
import 'run_canonical_business_text_analysis.dart';

final class RunCanonicalBusinessTextAnalysisSession
    implements CanonicalBusinessTextAnalysisSessionRunner {
  const RunCanonicalBusinessTextAnalysisSession({
    required this.registrySnapshotLoader,
    required this.canonicalDictionaryLoader,
    required this.analysis,
  });

  final RegistrySnapshotLoader registrySnapshotLoader;
  final CanonicalDictionaryLoader canonicalDictionaryLoader;
  final RunCanonicalBusinessTextAnalysis analysis;

  @override
  Future<CanonicalBusinessTextAnalysisResult> runAnalysis() async {
    final Future<RegistrySnapshot> snapshotFuture = registrySnapshotLoader
        .loadSnapshot();

    final Future<CanonicalDictionary> dictionaryFuture =
        canonicalDictionaryLoader.loadDictionary();

    final RegistrySnapshot snapshot = await snapshotFuture;
    final CanonicalDictionary dictionary = await dictionaryFuture;

    return analysis(snapshot: snapshot, dictionary: dictionary);
  }
}
