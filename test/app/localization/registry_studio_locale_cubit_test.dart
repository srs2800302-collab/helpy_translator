import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_locale_cubit.dart';
import 'package:helpy_translator/app/localization/registry_studio_locale_store.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';

void main() {
  test('restores, normalizes and persists supported locale', () async {
    final _MemoryLocaleStore store = _MemoryLocaleStore(languageCode: 'th');
    final RegistryStudioLocaleCubit cubit = RegistryStudioLocaleCubit(
      store: store,
    );
    addTearDown(cubit.close);

    expect(cubit.state, RegistryStudioLocalizations.russian);

    await cubit.restore();

    expect(cubit.state, RegistryStudioLocalizations.thai);

    await cubit.select(const Locale('en', 'US'));

    expect(cubit.state, RegistryStudioLocalizations.english);
    expect(store.languageCode, 'en');
    expect(store.saveCount, 1);
  });

  test('falls back to Russian for unsupported stored locale', () async {
    final _MemoryLocaleStore store = _MemoryLocaleStore(languageCode: 'de');
    final RegistryStudioLocaleCubit cubit = RegistryStudioLocaleCubit(
      store: store,
    );
    addTearDown(cubit.close);

    await cubit.restore();

    expect(cubit.state, RegistryStudioLocalizations.russian);
  });

  test('keeps session locale when persistence fails', () async {
    final RegistryStudioLocaleCubit cubit = RegistryStudioLocaleCubit(
      store: _FailingLocaleStore(),
    );
    addTearDown(cubit.close);

    await cubit.select(RegistryStudioLocalizations.thai);

    expect(cubit.state, RegistryStudioLocalizations.thai);
  });
}

final class _MemoryLocaleStore implements RegistryStudioLocaleStore {
  _MemoryLocaleStore({this.languageCode});

  String? languageCode;
  int saveCount = 0;

  @override
  Future<String?> loadLanguageCode() async => languageCode;

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    saveCount += 1;
    this.languageCode = languageCode;
  }
}

final class _FailingLocaleStore implements RegistryStudioLocaleStore {
  @override
  Future<String?> loadLanguageCode() {
    return Future<String?>.error(StateError('load failed'));
  }

  @override
  Future<void> saveLanguageCode(String languageCode) {
    return Future<void>.error(StateError('save failed'));
  }
}
