typedef HelpyCanonicalDictionaryDocument = ({
  String content,
  String documentPath,
  String sourceRevision,
  String sourceSnapshotFingerprint,
});

abstract interface class HelpyCanonicalDictionarySource {
  String get documentPath;

  Future<HelpyCanonicalDictionaryDocument> loadExactRevision(
    String sourceRevision,
  );
}
