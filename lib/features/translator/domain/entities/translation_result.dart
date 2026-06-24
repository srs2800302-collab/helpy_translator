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
  });

  final String ru;
  final String en;
  final String th;
  final String enToRu;
  final String thToRu;
  final String enToTh;
  final String thToEn;

  @override
  List<Object?> get props => <Object?>[
        ru,
        en,
        th,
        enToRu,
        thToRu,
        enToTh,
        thToEn,
      ];
}
