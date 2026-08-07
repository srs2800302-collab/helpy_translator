import '../entities/translation_language.dart';
import '../entities/translation_route.dart';

abstract interface class TranslationRoutePlanner {
  List<TranslationRoute> build(TranslationLanguage sourceLanguage);
}

/// Complete three-language route universe.
///
/// The application executes two primary routes from the original source
/// language, then four cross-check routes whose source text is the exact
/// completed primary translation returned by the provider.
final class CompleteThreeLanguageRoutePlanner
    implements TranslationRoutePlanner {
  const CompleteThreeLanguageRoutePlanner();

  @override
  List<TranslationRoute> build(TranslationLanguage sourceLanguage) {
    final List<TranslationLanguage> otherLanguages = TranslationLanguage.values
        .where((TranslationLanguage language) => language != sourceLanguage)
        .toList(growable: false);

    final List<TranslationRoute> primaryRoutes = otherLanguages
        .map(
          (TranslationLanguage target) => TranslationRoute(
            source: sourceLanguage,
            target: target,
            role: TranslationRouteRole.primary,
          ),
        )
        .toList(growable: false);

    final List<TranslationRoute> crossCheckRoutes = <TranslationRoute>[
      for (final TranslationLanguage derivedSource in otherLanguages)
        for (final TranslationLanguage target in TranslationLanguage.values)
          if (target != derivedSource)
            TranslationRoute(
              source: derivedSource,
              target: target,
              role: TranslationRouteRole.crossCheck,
            ),
    ];

    return List<TranslationRoute>.unmodifiable(<TranslationRoute>[
      ...primaryRoutes,
      ...crossCheckRoutes,
    ]);
  }
}
