import 'package:flutter_test/flutter_test.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_language.dart';
import 'package:helpy_translator/features/translator/domain/entities/translation_route.dart';
import 'package:helpy_translator/features/translator/domain/services/translation_route_planner.dart';

void main() {
  const CompleteThreeLanguageRoutePlanner planner =
      CompleteThreeLanguageRoutePlanner();

  for (final TranslationLanguage source in TranslationLanguage.values) {
    test('builds a symmetric current matrix for ${source.code}', () {
      final List<TranslationRoute> routes = planner.build(source);

      expect(routes, hasLength(6));
      expect(routes.map((TranslationRoute route) => route.id).toSet(), {
        'RU_TO_EN',
        'RU_TO_TH',
        'EN_TO_RU',
        'EN_TO_TH',
        'TH_TO_RU',
        'TH_TO_EN',
      });
      expect(
        routes
            .where(
              (TranslationRoute route) =>
                  route.role == TranslationRouteRole.primary,
            )
            .map((TranslationRoute route) => route.source)
            .toSet(),
        <TranslationLanguage>{source},
      );
      expect(
        routes.where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.primary,
        ),
        hasLength(2),
      );
      expect(
        routes.where(
          (TranslationRoute route) =>
              route.role == TranslationRouteRole.crossCheck,
        ),
        hasLength(4),
      );
    });
  }
}
