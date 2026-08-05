import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/translator_api_key_store.dart';

final class FlutterSecureTranslatorApiKeyStore
    implements TranslatorApiKeyStore {
  const FlutterSecureTranslatorApiKeyStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
    this.storageKey = 'registry_studio.translator.typhoon_api_key.v1',
  }) : _storage = storage;

  final FlutterSecureStorage _storage;
  final String storageKey;

  @override
  Future<String?> read() {
    return _storage.read(key: storageKey);
  }

  @override
  Future<void> write(String apiKey) {
    final String normalizedApiKey = apiKey.trim();

    if (normalizedApiKey.isEmpty) {
      throw ArgumentError.value(apiKey, 'apiKey', 'API key must not be empty.');
    }

    return _storage.write(key: storageKey, value: normalizedApiKey);
  }

  @override
  Future<void> delete() {
    return _storage.delete(key: storageKey);
  }
}
