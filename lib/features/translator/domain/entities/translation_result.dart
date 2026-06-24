import 'package:equatable/equatable.dart';

base class TranslationResult extends Equatable {
  const TranslationResult({
    required this.ru,
    required this.en,
    required this.th,
    required this.enToRu,
    required this.thToRu,
    required this.enToTh,
    required this.thToEn,
    required this.canonicalVerdict,
    required this.canonicalComment,
  });

  final String ru;
  final String en;
  final String th;
  final String enToRu;
  final String thToRu;
  final String enToTh;
  final String thToEn;
  final String canonicalVerdict;
  final String canonicalComment;

  @override
  List<Object?> get props => <Object?>[
        ru,
        en,
        th,
        enToRu,
        thToRu,
        enToTh,
        thToEn,
        canonicalVerdict,
        canonicalComment,
      ];
}
