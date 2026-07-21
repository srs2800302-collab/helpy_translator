import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'canonical_business_text_analysis_cubit.dart';
import 'canonical_business_text_analysis_view.dart';

final class CanonicalBusinessTextAnalysisStatusAction extends StatelessWidget {
  const CanonicalBusinessTextAnalysisStatusAction({super.key});

  static const Key actionKey = ValueKey<String>(
    'canonical-business-text-analysis-status-action',
  );

  static const Key runningKey = ValueKey<String>(
    'canonical-business-text-analysis-running',
  );

  static const Key failureDialogKey = ValueKey<String>(
    'canonical-business-text-analysis-failure-dialog',
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      CanonicalBusinessTextAnalysisCubit,
      CanonicalBusinessTextAnalysisState
    >(
      builder:
          (BuildContext context, CanonicalBusinessTextAnalysisState state) {
            return switch (state) {
              CanonicalBusinessTextAnalysisInitial() => const IconButton(
                key: actionKey,
                tooltip:
                    'Канонический анализ: '
                    'ожидание Registry',
                onPressed: null,
                icon: Icon(Icons.fact_check_outlined),
              ),
              CanonicalBusinessTextAnalysisRunning() => const SizedBox(
                key: runningKey,
                width: 48,
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              CanonicalBusinessTextAnalysisReady(:final result) => IconButton(
                key: actionKey,
                tooltip:
                    'Канонический анализ: '
                    'Требуют внимания: '
                    '${result.actionRequiredFindingCount} · '
                    'Кандидатов: ${result.totalCandidateCount}',
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (BuildContext routeContext) {
                        return CanonicalBusinessTextAnalysisView(
                          result: result,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check),
              ),
              CanonicalBusinessTextAnalysisFailed(:final message) => IconButton(
                key: actionKey,
                tooltip: 'Ошибка канонического анализа',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        key: failureDialogKey,
                        title: const Text(
                          'Канонический анализ '
                          'не выполнен',
                        ),
                        content: SelectableText(message),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Закрыть'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();

                              context
                                  .read<CanonicalBusinessTextAnalysisCubit>()
                                  .retry();
                            },
                            child: const Text('Повторить'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.error_outline),
              ),
            };
          },
    );
  }
}
