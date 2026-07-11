import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/infrastructure/shared_preferences_translator_phrase_history_persistence.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists restores and clears translator phrase history', () async {
    const SharedPreferencesTranslatorPhraseHistoryPersistence persistence =
        SharedPreferencesTranslatorPhraseHistoryPersistence();

    final List<TranslatorPhraseResult> history = <TranslatorPhraseResult>[
      TranslatorPhraseResult(
        sourceLanguage: 'en',
        sourceText: 'Second phrase.',
        status: TranslatorPhraseStatus.equivalent,
        ru: 'Вторая формулировка.',
        comment: 'Equivalent wording.',
      ),
      TranslatorPhraseResult(
        sourceLanguage: 'ru',
        sourceText: 'Первая формулировка.',
        status: TranslatorPhraseStatus.exact,
        en: 'First phrase.',
      ),
    ];

    await persistence.save(history);

    final List<TranslatorPhraseResult> restored = await persistence.load();

    expect(restored, history);
    expect(() => restored.add(history.first), throwsUnsupportedError);

    await persistence.clear();

    expect(await persistence.load(), isEmpty);
  });

  test('returns empty history for malformed or unsupported payload', () async {
    const String key = 'registry_studio_translator_phrase_history_v1';
    const SharedPreferencesTranslatorPhraseHistoryPersistence persistence =
        SharedPreferencesTranslatorPhraseHistoryPersistence();

    SharedPreferences.setMockInitialValues(<String, Object>{
      key: '{"version":1,"history":',
    });

    expect(await persistence.load(), isEmpty);

    SharedPreferences.setMockInitialValues(<String, Object>{
      key: jsonEncode(<String, Object?>{
        'version': 2,
        'history': const <Object?>[],
      }),
    });

    expect(await persistence.load(), isEmpty);
  });
}
