import 'package:equatable/equatable.dart';

import 'translation_language.dart';

enum TranslationRouteRole { primary, crossCheck }

final class TranslationRoute extends Equatable {
  const TranslationRoute({
    required this.source,
    required this.target,
    required this.role,
  }) : assert(source != target, 'A translation route requires two languages.');

  final TranslationLanguage source;
  final TranslationLanguage target;
  final TranslationRouteRole role;

  String get id => '${source.code}_TO_${target.code}';

  @override
  List<Object> get props => <Object>[source, target, role];
}
