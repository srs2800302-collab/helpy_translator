import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'registry_studio_locale_store.dart';
import 'registry_studio_localizations.dart';

final class RegistryStudioLocaleCubit extends Cubit<Locale> {
  RegistryStudioLocaleCubit({
    required RegistryStudioLocaleStore store,
    Locale fallbackLocale = RegistryStudioLocalizations.russian,
  }) : _store = store,
       super(_normalize(fallbackLocale));

  final RegistryStudioLocaleStore _store;

  Future<void> restore() async {
    try {
      final String? languageCode = await _store.loadLanguageCode();

      if (languageCode == null || languageCode.trim().isEmpty) {
        return;
      }

      final Locale restored = _normalize(Locale(languageCode.trim()));

      if (restored != state) {
        emit(restored);
      }
    } catch (_) {
      // Locale restore must never prevent the application from starting.
    }
  }

  Future<void> select(Locale locale) async {
    final Locale normalized = _normalize(locale);

    if (normalized != state) {
      emit(normalized);
    }

    try {
      await _store.saveLanguageCode(normalized.languageCode);
    } catch (_) {
      // The selected locale remains active for the current session.
    }
  }

  static Locale _normalize(Locale locale) {
    return RegistryStudioLocalizations.supportedLocales.firstWhere(
      (Locale supported) => supported.languageCode == locale.languageCode,
      orElse: () => RegistryStudioLocalizations.russian,
    );
  }
}
