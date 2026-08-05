abstract interface class TranslatorApiKeyStore {
  Future<String?> read();

  Future<void> write(String apiKey);

  Future<void> delete();
}
