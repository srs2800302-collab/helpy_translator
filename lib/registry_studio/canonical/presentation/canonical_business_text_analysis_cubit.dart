import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../registry/domain/entities/registry_snapshot.dart';
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

  RegistrySnapshot? _latestSnapshot;
  int _analysisSequence = 0;

  Future<void> acceptSnapshot(RegistrySnapshot snapshot) async {
    _latestSnapshot = snapshot;

    final int analysisSequence = ++_analysisSequence;

    emit(const CanonicalBusinessTextAnalysisRunning());

    try {
      final CanonicalBusinessTextAnalysisResult result = await _sessionRunner
          .runAnalysis(snapshot);

      if (isClosed || analysisSequence != _analysisSequence) {
        return;
      }

      emit(CanonicalBusinessTextAnalysisReady(result: result));
    } on Object catch (error) {
      if (isClosed || analysisSequence != _analysisSequence) {
        return;
      }

      emit(CanonicalBusinessTextAnalysisFailed(message: error.toString()));
    }
  }

  Future<void> retry() {
    final RegistrySnapshot? snapshot = _latestSnapshot;

    if (snapshot == null) {
      return Future<void>.value();
    }

    return acceptSnapshot(snapshot);
  }
}
