import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/app/localization/registry_studio_localizations.dart';
import 'package:helpy_translator/features/translator/domain/entities/matrix_assessment.dart';
import 'package:helpy_translator/features/translator/domain/entities/primary_linguist_report.dart';
import 'package:helpy_translator/features/translator/domain/entities/semantic_observation.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_matrix_result.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route_result.dart';
import 'package:helpy_translator/features/translator/presentation/widgets/translation_matrix_result_view.dart';

void main() {
  const RegistryStudioLocalizations englishL10n = RegistryStudioLocalizations(
    RegistryStudioLocalizations.english,
  );

  final Map<MatrixVerdict, Color> expectedColors = <MatrixVerdict, Color>{
    MatrixVerdict.noCriticalDriftDetected: Colors.green.shade50,
    MatrixVerdict.acceptableVariation: Colors.lightGreen.shade50,
    MatrixVerdict.reviewRequired: Colors.yellow.shade50,
    MatrixVerdict.unreliable: Colors.red.shade50,
    MatrixVerdict.indeterminate: Colors.blueGrey.shade50,
  };

  for (final MapEntry<MatrixVerdict, Color> entry in expectedColors.entries) {
    testWidgets('keeps the legacy card color for ${entry.key.name}', (
      WidgetTester tester,
    ) async {
      final TranslationMatrixResult result = TranslationMatrixResult(
        sourceText: 'Source',
        sourceLanguage: TranslationLanguage.english,
        routes: const <TranslationRouteResult>[],
        assessment: MatrixAssessment(
          verdict: entry.key,
          observations: const <SemanticObservation>[],
          limitations: const <String>[],
        ),
        createdAt: DateTime.utc(2026, 8, 5),
      );

      await tester.pumpWidget(
        _TestApp(child: TranslationMatrixResultView(result: result)),
      );

      final Finder resultCard = find.byKey(
        ValueKey<String>(
          'translator-result-${result.createdAt.microsecondsSinceEpoch}',
        ),
      );

      expect(tester.widget<Card>(resultCard).color, entry.value);
    });
  }

  testWidgets('starts collapsed and restores the user-selected state', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Source',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 1),
    );
    final PageStorageBucket bucket = PageStorageBucket();

    Widget buildResult() {
      return _TestApp(
        child: PageStorage(
          bucket: bucket,
          child: TranslationMatrixResultView(result: result),
        ),
      );
    }

    await tester.pumpWidget(buildResult());

    expect(find.text('Source'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsNothing,
    );

    await _toggleResultCard(tester, result);

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _TestApp(
        child: PageStorage(bucket: bucket, child: const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildResult());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsOneWidget,
    );

    await _toggleResultCard(tester, result);

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsNothing,
    );

    await tester.pumpWidget(
      _TestApp(
        child: PageStorage(bucket: bucket, child: const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(buildResult());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsNothing,
    );
  });

  testWidgets('keeps expansion state independent for every result', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult firstResult = TranslationMatrixResult(
      sourceText: 'First source',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 2),
    );
    final TranslationMatrixResult secondResult = TranslationMatrixResult(
      sourceText: 'Second source',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 3),
    );

    await tester.pumpWidget(
      _TestApp(
        child: Column(
          children: <Widget>[
            TranslationMatrixResultView(result: firstResult),
            TranslationMatrixResultView(result: secondResult),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsNothing,
    );

    await _toggleResultCard(tester, firstResult);

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsOneWidget,
    );

    await _toggleResultCard(tester, secondResult);

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsNWidgets(2),
    );

    await _toggleResultCard(tester, firstResult);

    expect(
      find.byKey(const ValueKey<String>('translator-copy-all-button')),
      findsOneWidget,
    );
  });

  testWidgets('localizes audit section labels without global claims', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Исходный текст',
      sourceLanguage: TranslationLanguage.russian,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: <SemanticObservation>[
          SemanticObservation(
            routeId: 'RU_TO_EN',
            routeRole: TranslationRouteRole.primary,
            relation: SemanticRelation.wordingVariation,
            dimension: SemanticDimension.lexicalChoice,
            preservation: MeaningPreservation.preserved,
            verificationStatus: ObservationVerificationStatus.confirmed,
            sourceExcerpt: 'панель',
            targetExcerpt: 'cooktop',
          ),
        ],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 4),
    );

    await tester.pumpWidget(
      _TestApp(
        locale: RegistryStudioLocalizations.russian,
        child: TranslationMatrixResultView(result: result),
      ),
    );
    await _toggleResultCard(tester, result);

    expect(find.text('Итоговая оценка матрицы'), findsOneWidget);
    expect(
      find.text('Автоматические проверки согласованы для маршрутов: 1'),
      findsOneWidget,
    );
    expect(find.text('Final matrix assessment'), findsNothing);
    expect(find.text('Смысл сохранён: 1'), findsNothing);
  });

  testWidgets('shows honest base and expanded audit coverage labels', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult baseResult = TranslationMatrixResult(
      sourceText: 'Базовый результат',
      sourceLanguage: TranslationLanguage.russian,
      routes: const <TranslationRouteResult>[
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.russian,
            target: TranslationLanguage.english,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'Базовый результат',
          translatedText: 'Base result',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.russian,
            target: TranslationLanguage.thai,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'Базовый результат',
          translatedText: 'ผลลัพธ์พื้นฐาน',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'Base result',
          translatedText: 'Базовый результат',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.thai,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'ผลลัพธ์พื้นฐาน',
          translatedText: 'Базовый результат',
        ),
      ],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 5),
      auditCoverage: TranslationAuditCoverage.base,
    );

    await tester.pumpWidget(
      _TestApp(
        locale: RegistryStudioLocalizations.russian,
        child: TranslationMatrixResultView(result: baseResult),
      ),
    );
    await _toggleResultCard(tester, baseResult);

    expect(find.text('Базовая проверка — 4 маршрута'), findsOneWidget);

    final TranslationMatrixResult expandedResult = TranslationMatrixResult(
      sourceText: 'Expanded result',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'Expanded result',
          translatedText: 'Расширенный результат',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.english,
            target: TranslationLanguage.thai,
            role: TranslationRouteRole.primary,
          ),
          sourceText: 'Expanded result',
          translatedText: 'ผลลัพธ์แบบขยาย',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.russian,
            target: TranslationLanguage.english,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'Расширенный результат',
          translatedText: 'Expanded result',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.thai,
            target: TranslationLanguage.english,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'ผลลัพธ์แบบขยาย',
          translatedText: 'Expanded result',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.russian,
            target: TranslationLanguage.thai,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'Расширенный результат',
          translatedText: 'ผลลัพธ์แบบขยาย',
        ),
        TranslationRouteResult(
          route: TranslationRoute(
            source: TranslationLanguage.thai,
            target: TranslationLanguage.russian,
            role: TranslationRouteRole.crossCheck,
          ),
          sourceText: 'ผลลัพธ์แบบขยาย',
          translatedText: 'Расширенный результат',
        ),
      ],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5, 6),
      auditCoverage: TranslationAuditCoverage.expanded,
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: expandedResult)),
    );
    await _toggleResultCard(tester, expandedResult);

    expect(
      find.text(englishL10n.auditCoverageLabel('expanded', 6)),
      findsOneWidget,
    );
  });

  testWidgets('shows current route-local call disclosure', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Source',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.acceptableVariation,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 6),
      auditCoverage: TranslationAuditCoverage.expanded,
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: result)),
    );
    await _toggleResultCard(tester, result);

    expect(find.text('Independent route audit — 0 routes'), findsOneWidget);
    expect(find.text('Automated checks agree'), findsOneWidget);
    expect(find.textContaining('six separate translations'), findsOneWidget);
    expect(find.textContaining('13 base API calls'), findsOneWidget);
    expect(find.textContaining('maximum is 19 API calls'), findsOneWidget);
    expect(find.textContaining('six independent route audits'), findsOneWidget);
    expect(
      find.textContaining('same model from the same API provider'),
      findsOneWidget,
    );
  });

  testWidgets('does not describe an empty observation list as proof', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Source',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.noCriticalDriftDetected,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5),
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: result)),
    );
    await _toggleResultCard(tester, result);

    expect(
      find.text('This is not proof of absolute equivalence.'),
      findsOneWidget,
    );
    expect(find.textContaining('not an independent review'), findsOneWidget);
  });

  testWidgets(
    'shows attention compactly and keeps preserved observations collapsed',
    (WidgetTester tester) async {
      final TranslationMatrixResult result = TranslationMatrixResult(
        sourceText: 'Source statement.',
        sourceLanguage: TranslationLanguage.english,
        routes: const <TranslationRouteResult>[],
        assessment: const MatrixAssessment(
          verdict: MatrixVerdict.reviewRequired,
          observations: <SemanticObservation>[
            SemanticObservation(
              routeId: 'RU_TO_EN',
              routeRole: TranslationRouteRole.crossCheck,
              relation: SemanticRelation.scopeChange,
              dimension: SemanticDimension.specificity,
              preservation: MeaningPreservation.altered,
              verificationStatus: ObservationVerificationStatus.confirmed,
              sourceExcerpt: 'source-token',
              targetExcerpt: 'target-token',
            ),
            SemanticObservation(
              routeId: 'EN_TO_RU',
              routeRole: TranslationRouteRole.primary,
              relation: SemanticRelation.wordingVariation,
              dimension: SemanticDimension.lexicalChoice,
              preservation: MeaningPreservation.preserved,
              verificationStatus: ObservationVerificationStatus.confirmed,
              sourceExcerpt: 'appointment',
              targetExcerpt: 'встреча',
            ),
          ],
          limitations: <String>[],
        ),
        createdAt: DateTime.utc(2026, 8, 5),
      );

      await tester.pumpWidget(
        _TestApp(child: TranslationMatrixResultView(result: result)),
      );
      await _toggleResultCard(tester, result);

      expect(find.text('Requires attention: 1'), findsOneWidget);
      expect(find.text('Automated checks agree for routes: 1'), findsOneWidget);
      expect(find.text('RU_TO_EN · Cross-check translation'), findsOneWidget);
      expect(find.text('source-token → target-token'), findsOneWidget);
      expect(find.textContaining('does not by itself prove'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'translator-observation-group-preserved-EN_TO_RU',
          ),
        ),
        findsNothing,
      );

      final Finder attentionTile = find.byKey(
        const ValueKey<String>('translator-observation-attention-RU_TO_EN-0'),
      );
      await tester.ensureVisible(attentionTile);
      await tester.tap(attentionTile);
      await tester.pumpAndSettle();

      expect(find.textContaining('does not by itself prove'), findsOneWidget);

      final Finder preservedSection = find.byKey(
        const ValueKey<String>('translator-preserved-observations'),
      );
      await tester.ensureVisible(preservedSection);
      await tester.tap(preservedSection);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'translator-observation-group-preserved-EN_TO_RU',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('appointment → встреча'), findsOneWidget);
    },
  );

  testWidgets('groups multiple observations by route', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Source statement.',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: <SemanticObservation>[
          SemanticObservation(
            routeId: 'EN_TO_TH',
            routeRole: TranslationRouteRole.primary,
            relation: SemanticRelation.substitution,
            dimension: SemanticDimension.object,
            preservation: MeaningPreservation.altered,
            verificationStatus: ObservationVerificationStatus.confirmed,
            sourceExcerpt: 'object-a',
            targetExcerpt: 'object-b',
          ),
          SemanticObservation(
            routeId: 'EN_TO_TH',
            routeRole: TranslationRouteRole.primary,
            relation: SemanticRelation.omission,
            dimension: SemanticDimension.condition,
            preservation: MeaningPreservation.unknown,
            verificationStatus: ObservationVerificationStatus.unverifiable,
            sourceExcerpt: 'condition-a',
            targetExcerpt: null,
          ),
        ],
        limitations: <String>[],
      ),
      createdAt: DateTime.utc(2026, 8, 5),
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: result)),
    );
    await _toggleResultCard(tester, result);

    expect(find.text('Requires attention: 2'), findsOneWidget);
    expect(find.text('EN_TO_TH · Primary translation'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'translator-observation-group-attention-EN_TO_TH',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('object-a → object-b'), findsOneWidget);
    expect(find.text('condition-a'), findsOneWidget);
  });

  testWidgets('shows primary Linguist evidence separately and copies it', (
    WidgetTester tester,
  ) async {
    String? copiedText;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            copiedText = arguments['text'] as String?;
          }

          return null;
        });

    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'The bank closes tomorrow.',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.reviewRequired,
        observations: <SemanticObservation>[],
        limitations: <String>[],
      ),
      linguistReport: const PrimaryLinguistReport(
        assessments: <PrimaryLinguistAssessment>[
          PrimaryLinguistAssessment(
            routeId: 'EN_TO_RU',
            targetLanguage: TranslationLanguage.russian,
            status: PrimaryLinguistStatus.incompatible,
            sourceExcerpt: 'bank',
            targetExcerpt: 'берег',
            limitations: <String>['CANDIDATE_SENSE_RISK'],
          ),
          PrimaryLinguistAssessment(
            routeId: 'EN_TO_TH',
            targetLanguage: TranslationLanguage.thai,
            status: PrimaryLinguistStatus.compatible,
            sourceExcerpt: null,
            targetExcerpt: null,
            limitations: <String>[],
          ),
        ],
        limitations: <String>['LINGUIST_SCOPE_LIMITED'],
      ),
      createdAt: DateTime.utc(2026, 8, 8),
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: result)),
    );

    await _toggleResultCard(tester, result);

    expect(
      find.byKey(const ValueKey<String>('translator-primary-linguist-section')),
      findsOneWidget,
    );
    expect(find.text('Separate Linguist review'), findsOneWidget);
    expect(
      find.textContaining('COMPATIBLE is not proof of equivalence'),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('translator-primary-linguist-EN_TO_RU'),
      ),
      findsOneWidget,
    );
    expect(find.text('EN_TO_RU · RU · Incompatible'), findsOneWidget);
    expect(find.text('EN_TO_TH · TH · Compatible — not proof'), findsOneWidget);
    expect(find.text('bank'), findsOneWidget);
    expect(find.text('берег'), findsOneWidget);
    expect(find.text('• Limitation: CANDIDATE_SENSE_RISK'), findsOneWidget);
    expect(find.text('• Limitation: LINGUIST_SCOPE_LIMITED'), findsOneWidget);

    final Finder copyButton = find.byKey(
      const ValueKey<String>('translator-copy-all-button'),
    );

    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pump();

    expect(copiedText, isNotNull);
    expect(copiedText, contains('PRIMARY LINGUIST:'));
    expect(copiedText, contains('EN_TO_RU [RU]'));
    expect(copiedText, contains('STATUS: INCOMPATIBLE'));
    expect(copiedText, contains('SOURCE: bank'));
    expect(copiedText, contains('TARGET: берег'));
    expect(copiedText, contains('CANDIDATE_SENSE_RISK'));
    expect(copiedText, contains('LINGUIST_SCOPE_LIMITED'));
  });

  testWidgets('shows pass-specific failure as neutral attention', (
    WidgetTester tester,
  ) async {
    final TranslationMatrixResult result = TranslationMatrixResult(
      sourceText: 'Source statement.',
      sourceLanguage: TranslationLanguage.english,
      routes: const <TranslationRouteResult>[],
      assessment: const MatrixAssessment(
        verdict: MatrixVerdict.indeterminate,
        observations: <SemanticObservation>[],
        limitations: <String>['AUDIT_PASS_A_PROVIDER_FAILURE'],
      ),
      createdAt: DateTime.utc(2026, 8, 7),
    );

    await tester.pumpWidget(
      _TestApp(child: TranslationMatrixResultView(result: result)),
    );

    expect(find.text('Audit needs attention'), findsOneWidget);
    expect(find.text('Result cannot be confirmed'), findsNothing);

    await _toggleResultCard(tester, result);

    expect(
      find.textContaining(
        'Isolated pass A did not complete: the provider failed the request',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _toggleResultCard(
  WidgetTester tester,
  TranslationMatrixResult result,
) async {
  final Finder header = find.byKey(
    ValueKey<String>(
      'translator-result-header-'
      '${result.createdAt.microsecondsSinceEpoch}',
    ),
  );

  expect(header, findsOneWidget);
  await tester.ensureVisible(header);
  await tester.tap(header);
  await tester.pumpAndSettle();
}

final class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.locale = RegistryStudioLocalizations.english,
  });

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      supportedLocales: RegistryStudioLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        RegistryStudioLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }
}
