import 'package:equatable/equatable.dart';

import 'translation_route.dart';

final class TranslationBatchRequest extends Equatable {
  const TranslationBatchRequest({
    required this.route,
    required this.sourceText,
  });

  final TranslationRoute route;
  final String sourceText;

  @override
  List<Object> get props => <Object>[route, sourceText];

  Map<String, Object> toJson() {
    return <String, Object>{
      'route': route.id,
      'role': route.role.name,
      'source_language': route.source.code,
      'target_language': route.target.code,
      'source_text': sourceText,
    };
  }
}
