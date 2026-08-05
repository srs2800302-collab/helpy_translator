import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';
import 'package:helpy_translator/features/translator/domain/repositories/translator_api_key_store.dart';
import 'package:helpy_translator/features/translator/presentation/widgets/translator_api_key_button.dart';

void main() {
  testWidgets('restores, replaces, hides, and deletes the saved key', (
    WidgetTester tester,
  ) async {
    final _MemoryApiKeyStore store = _MemoryApiKeyStore('old-secret');

    await tester.pumpWidget(
      _TestApp(child: TranslatorApiKeyButton(apiKeyStore: store)),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('translator-access-key-app-bar-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('translator-api-key-dialog')),
      findsOneWidget,
    );

    final TextField initialField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translator-api-key-text-field')),
    );
    expect(initialField.obscureText, isTrue);
    expect(initialField.controller?.text, 'old-secret');

    await tester.tap(
      find.byKey(
        const ValueKey<String>('translator-api-key-visibility-button'),
      ),
    );
    await tester.pump();

    final TextField visibleField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translator-api-key-text-field')),
    );
    expect(visibleField.obscureText, isFalse);

    await tester.enterText(
      find.byKey(const ValueKey<String>('translator-api-key-text-field')),
      'new-secret',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-api-key-save-button')),
    );
    await tester.pumpAndSettle();

    expect(store.value, 'new-secret');
    expect(
      find.byKey(const ValueKey<String>('translator-api-key-dialog')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('translator-access-key-app-bar-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-api-key-delete-button')),
    );
    await tester.pumpAndSettle();

    expect(store.value, isNull);
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('translator-api-key-text-field')),
          )
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('does not save an empty key', (WidgetTester tester) async {
    final _MemoryApiKeyStore store = _MemoryApiKeyStore(null);

    await tester.pumpWidget(
      _TestApp(child: TranslatorApiKeyButton(apiKeyStore: store)),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('translator-access-key-app-bar-button'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('translator-api-key-save-button')),
    );
    await tester.pump();

    expect(store.value, isNull);
    expect(
      find.byKey(const ValueKey<String>('translator-api-key-error')),
      findsOneWidget,
    );
  });
}

final class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: RegistryStudioLocalizations.english,
      supportedLocales: RegistryStudioLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        RegistryStudioLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(appBar: AppBar(leading: child)),
    );
  }
}

final class _MemoryApiKeyStore implements TranslatorApiKeyStore {
  _MemoryApiKeyStore(this.value);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String apiKey) async {
    value = apiKey;
  }

  @override
  Future<void> delete() async {
    value = null;
  }
}
