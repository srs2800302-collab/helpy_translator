abstract interface class TranslatorAccessKeyStore {
  Future<String?> load();

  Future<void> save(String accessKey);

  Future<void> clear();
}
