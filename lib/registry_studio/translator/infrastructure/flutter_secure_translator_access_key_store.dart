import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../application/translator_access_key_store.dart';

final class FlutterSecureTranslatorAccessKeyStore
    implements TranslatorAccessKeyStore {
  FlutterSecureTranslatorAccessKeyStore({
    required this.storageKey,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? FlutterSecureStorage();

  final String storageKey;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> load() {
    return _storage.read(key: storageKey);
  }

  @override
  Future<void> save(String accessKey) {
    return _storage.write(key: storageKey, value: accessKey);
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: storageKey);
  }
}
