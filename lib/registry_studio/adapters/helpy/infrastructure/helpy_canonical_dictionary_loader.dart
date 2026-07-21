import '../../../canonical/application/contracts/canonical_dictionary_loader.dart';
import '../../../canonical/domain/entities/canonical_dictionary.dart';
import 'github_registry_document_source.dart';
import 'helpy_canonical_dictionary_document_interpreter.dart';

final class HelpyCanonicalDictionaryLoader
    implements CanonicalDictionaryLoader {
  const HelpyCanonicalDictionaryLoader({
    required this.documentSource,
    this.documentInterpreter =
        const HelpyCanonicalDictionaryDocumentInterpreter(),
  });

  final GitHubRegistryDocumentSource documentSource;
  final HelpyCanonicalDictionaryDocumentInterpreter documentInterpreter;

  @override
  Future<CanonicalDictionary> loadDictionary() async {
    final ({
      String content,
      String documentPath,
      String sourceRevision,
      String sourceSnapshotFingerprint,
    })
    sourceDocument = await documentSource.load();

    return documentInterpreter.interpret(
      sourceDocumentPath: sourceDocument.documentPath,
      sourceRevision: sourceDocument.sourceRevision,
      sourceSnapshotFingerprint: sourceDocument.sourceSnapshotFingerprint,
      sourceContent: sourceDocument.content,
    );
  }
}
