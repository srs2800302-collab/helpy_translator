abstract interface class RegistryStudioLocaleStore {
  Future<String?> loadLanguageCode();

  Future<void> saveLanguageCode(String languageCode);
}
