import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/canonical_business_text_analysis_result.dart';
import '../domain/entities/canonical_business_text_classification_status.dart';
import 'canonical_business_text_analysis_cubit.dart';

final class CanonicalBusinessTextAnalysisStatusAction extends StatelessWidget {
  const CanonicalBusinessTextAnalysisStatusAction({super.key});

  static const Key actionKey = ValueKey<String>(
    'canonical-business-text-analysis-status-action',
  );

  static const Key runningKey = ValueKey<String>(
    'canonical-business-text-analysis-running',
  );

  static const Key resultDialogKey = ValueKey<String>(
    'canonical-business-text-analysis-result-dialog',
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
              CanonicalBusinessTextAnalysisInitial() => IconButton(
                key: actionKey,
                tooltip: 'Запустить канонический анализ',
                onPressed: context
                    .read<CanonicalBusinessTextAnalysisCubit>()
                    .run,
                icon: const Icon(Icons.fact_check_outlined),
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
                    '${result.totalCandidateCount} кандидатов',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return _CanonicalBusinessTextAnalysisDialog(
                        result: result,
                      );
                    },
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
                        title: const Text('Канонический анализ не выполнен'),
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
                                  .run();
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

final class _CanonicalBusinessTextAnalysisDialog extends StatelessWidget {
  const _CanonicalBusinessTextAnalysisDialog({required this.result});

  final CanonicalBusinessTextAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: CanonicalBusinessTextAnalysisStatusAction.resultDialogKey,
      title: const Text('Канонический анализ'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              'Кандидаты: '
              '${result.totalCandidateCount}',
            ),
            Text(
              'Business scopes: '
              '${result.classificationsByBusinessScopeOwnerId.length}',
            ),
            const SizedBox(height: 12),
            Text(
              'Exact: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.exact)}',
            ),
            Text(
              'Review: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.review)}',
            ),
            Text(
              'Unclassified / Neutral: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.unclassifiedNeutral)}',
            ),
            Text(
              'Equivalent: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.equivalent)}',
            ),
            Text(
              'Drift: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.drift)}',
            ),
            Text(
              'Failed: '
              '${result.countForStatus(CanonicalBusinessTextClassificationStatus.failed)}',
            ),
            const SizedBox(height: 12),
            SelectableText(
              'Registry revision: '
              '${result.registrySourceRevision}',
            ),
            SelectableText(
              'Registry fingerprint: '
              '${result.registrySourceSnapshotFingerprint}',
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Dictionary ID: '
              '${result.dictionaryId}',
            ),
            Text(
              'Dictionary version: '
              '${result.dictionaryVersion}',
            ),
            SelectableText(
              'Dictionary revision: '
              '${result.dictionarySourceRevision}',
            ),
            SelectableText(
              'Dictionary fingerprint: '
              '${result.dictionarySourceSnapshotFingerprint}',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
