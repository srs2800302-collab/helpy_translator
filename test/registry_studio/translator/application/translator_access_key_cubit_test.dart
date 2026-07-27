import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_access_key_cubit.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_access_key_store.dart';

void main() {
  test('restores a persisted access key', () async {
    final _MemoryAccessKeyStore store = _MemoryAccessKeyStore(
      value: 'saved-key',
    );
    final TranslatorAccessKeyCubit cubit = TranslatorAccessKeyCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state.isRestoring, isFalse);
    expect(cubit.state.accessKey, 'saved-key');
    expect(cubit.state.failure, isNull);
  });

  test('represents restore failures without UI strings', () async {
    final _MemoryAccessKeyStore store = _MemoryAccessKeyStore(failLoad: true);
    final TranslatorAccessKeyCubit cubit = TranslatorAccessKeyCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state.isRestoring, isFalse);
    expect(cubit.state.accessKey, isEmpty);
    expect(cubit.state.failure, TranslatorAccessKeyFailure.restore);
  });

  test('persists non-empty keys and clears empty keys', () async {
    final _MemoryAccessKeyStore store = _MemoryAccessKeyStore();
    final TranslatorAccessKeyCubit cubit = TranslatorAccessKeyCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.save('new-key');

    expect(store.value, 'new-key');
    expect(cubit.state.accessKey, 'new-key');
    expect(cubit.state.failure, isNull);

    await cubit.save('');

    expect(store.value, isNull);
    expect(store.clearCount, 1);
    expect(cubit.state.accessKey, isEmpty);
    expect(cubit.state.failure, isNull);
  });

  test('keeps the session key when persistence fails', () async {
    final _MemoryAccessKeyStore store = _MemoryAccessKeyStore(failSave: true);
    final TranslatorAccessKeyCubit cubit = TranslatorAccessKeyCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    await cubit.save('session-key');

    expect(cubit.state.accessKey, 'session-key');
    expect(cubit.state.failure, TranslatorAccessKeyFailure.save);
  });

  test('keeps the current key when deletion fails', () async {
    final _MemoryAccessKeyStore store = _MemoryAccessKeyStore(
      value: 'saved-key',
    );
    final TranslatorAccessKeyCubit cubit = TranslatorAccessKeyCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();
    store.failClear = true;
    await cubit.delete();

    expect(cubit.state.accessKey, 'saved-key');
    expect(cubit.state.failure, TranslatorAccessKeyFailure.delete);
  });
}

final class _MemoryAccessKeyStore implements TranslatorAccessKeyStore {
  _MemoryAccessKeyStore({
    this.value,
    this.failLoad = false,
    this.failSave = false,
  });

  String? value;
  bool failLoad;
  bool failSave;
  bool failClear = false;
  int clearCount = 0;

  @override
  Future<String?> load() async {
    if (failLoad) {
      throw StateError('load failed');
    }
    return value;
  }

  @override
  Future<void> save(String accessKey) async {
    if (failSave) {
      throw StateError('save failed');
    }
    value = accessKey;
  }

  @override
  Future<void> clear() async {
    if (failClear) {
      throw StateError('clear failed');
    }
    clearCount += 1;
    value = null;
  }
}
