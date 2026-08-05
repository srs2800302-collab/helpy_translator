import 'package:equatable/equatable.dart';

enum TranslatorProgressStage { validating, translating, auditing, completed }

final class TranslatorProgress extends Equatable {
  const TranslatorProgress({
    required this.stage,
    required this.completedSteps,
    required this.totalSteps,
    this.currentRouteId,
  });

  final TranslatorProgressStage stage;
  final int completedSteps;
  final int totalSteps;
  final String? currentRouteId;

  double get fraction {
    if (totalSteps <= 0) {
      return 0;
    }

    return (completedSteps / totalSteps).clamp(0.0, 1.0).toDouble();
  }

  @override
  List<Object?> get props => <Object?>[
    stage,
    completedSteps,
    totalSteps,
    currentRouteId,
  ];
}
