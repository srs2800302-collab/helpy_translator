import 'package:equatable/equatable.dart';

import 'translation_route.dart';

final class TranslationRouteResult extends Equatable {
  const TranslationRouteResult({
    required this.route,
    required this.sourceText,
    required this.translatedText,
  });

  final TranslationRoute route;
  final String sourceText;
  final String translatedText;

  @override
  List<Object> get props => <Object>[route, sourceText, translatedText];

  Map<String, Object> toJson() {
    return <String, Object>{
      'route': route.id,
      'role': route.role.name,
      'source_language': route.source.code,
      'target_language': route.target.code,
      'source_text': sourceText,
      'translated_text': translatedText,
    };
  }
}
