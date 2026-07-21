import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/contracts/canonical_business_text_analysis_session_runner.dart';
import '../domain/entities/canonical_business_text_analysis_result.dart';

sealed class CanonicalBusinessTextAnalysisState extends Equatable {
  const CanonicalBusinessTextAnalysisState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CanonicalBusinessTextAnalysisInitial
    extends CanonicalBusinessTextAnalysisState {
  const CanonicalBusinessTextAnalysisInitial();
}

final class CanonicalBusinessTextAnalysisRunning
    extends CanonicalBusinessTextAnalysisState {
  const CanonicalBusinessTextAnalysisRunning();
}

final class CanonicalBusinessTextAnalysisReady
    extends CanonicalBusinessTextAnalysisState {
  const CanonicalBusinessTextAnalysisReady({required this.result});

  final CanonicalBusinessTextAnalysisResult result;

  @override
  List<Object?> get props => <Object?>[result];
}

final class CanonicalBusinessTextAnalysisFailed
    extends CanonicalBusinessTextAnalysisState {
  const CanonicalBusinessTextAnalysisFailed({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class CanonicalBusinessTextAnalysisCubit
    extends Cubit<CanonicalBusinessTextAnalysisState> {
  CanonicalBusinessTextAnalysisCubit({
    required CanonicalBusinessTextAnalysisSessionRunner sessionRunner,
  }) : _sessionRunner = sessionRunner,
       super(const CanonicalBusinessTextAnalysisInitial());

  final CanonicalBusinessTextAnalysisSessionRunner _sessionRunner;

  Future<void> run() async {
    if (state is CanonicalBusinessTextAnalysisRunning) {
      return;
    }

    emit(const CanonicalBusinessTextAnalysisRunning());

    try {
      final CanonicalBusinessTextAnalysisResult result = await _sessionRunner
          .runAnalysis();

      if (isClosed) {
        return;
      }

      emit(CanonicalBusinessTextAnalysisReady(result: result));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(CanonicalBusinessTextAnalysisFailed(message: error.toString()));
    }
  }
}
