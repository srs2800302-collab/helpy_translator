import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'registry_studio_locale_store.dart';

final class FlutterSecureRegistryStudioLocaleStore
    implements RegistryStudioLocaleStore {
  const FlutterSecureRegistryStudioLocaleStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    this.storageKey = 'registry_studio.ui.locale.v1',
  }) : _storage = storage;

  final FlutterSecureStorage _storage;
  final String storageKey;

  @override
  Future<String?> loadLanguageCode() {
    return _storage.read(key: storageKey);
  }

  @override
  Future<void> saveLanguageCode(String languageCode) {
    return _storage.write(key: storageKey, value: languageCode);
  }
}
