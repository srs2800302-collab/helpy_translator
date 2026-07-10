import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/registry_studio/translator/application/translate_phrase.dart';
import 'package:helpy_translator/registry_studio/translator/application/translator_phrase_provider.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/app/registry_studio_translator_app.dart';
import 'package:helpy_translator/registry_studio/translator/presentation/screens/translator_phrase_screen.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_result.dart';
import 'package:helpy_translator/registry_studio/translator/translator_phrase_status.dart';

void main() {
  testWidgets('wires clean TranslatorPhraseScreen runtime', (
    WidgetTester tester,
  ) async {
    final TranslatorPhraseResult result = TranslatorPhraseResult(
      sourceLanguage: 'ru',
      sourceText: 'Проверить формулировку.',
      status: TranslatorPhraseStatus.equivalent,
      ru: 'Проверить формулировку.',
      en: 'Check wording.',
      th: 'ตรวจสอบถ้อยคำ',
      comment: 'Equivalent wording.',
    );
    final _FakeTranslatorPhraseProvider provider =
        _FakeTranslatorPhraseProvider(result);

    await tester.pumpWidget(
      RegistryStudioTranslatorApp(
        translatePhrase: TranslatePhrase(provider: provider),
      ),
    );

    expect(find.byType(TranslatorPhraseScreen), findsOneWidget);
    expect(find.text('Перевод формулировки'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'Проверить формулировку.',
    );
    await tester.tap(find.text('Перевести'));
    await tester.pump();
    await tester.pump();

    expect(provider.callCount, 1);
    expect(provider.receivedSourceText, 'Проверить формулировку.');
    expect(find.text('Эквивалентная формулировка'), findsOneWidget);
  });
}

final class _FakeTranslatorPhraseProvider implements TranslatorPhraseProvider {
  _FakeTranslatorPhraseProvider(this.result);

  final TranslatorPhraseResult result;
  int callCount = 0;
  String? receivedSourceText;

  @override
  Future<TranslatorPhraseResult> translatePhrase({
    required String sourceText,
    String? sourceLanguageHint,
    String? engineerContext,
  }) async {
    callCount += 1;
    receivedSourceText = sourceText;
    return result;
  }
}
