import 'package:flutter/material.dart';

import '../domain/entities/canonical_business_text_analysis_result.dart';
import '../domain/entities/canonical_business_text_candidate.dart';
import '../domain/entities/canonical_business_text_classification.dart';
import '../domain/entities/canonical_business_text_classification_status.dart';
import 'canonical_business_text_classification_details.dart';

final class CanonicalBusinessTextAnalysisView extends StatefulWidget {
  const CanonicalBusinessTextAnalysisView({
    required this.result,
    this.onOpenRegistryCandidate,
    super.key,
  });

  static const Key viewKey = ValueKey<String>(
    'canonical-business-text-analysis-view',
  );

  static const Key emptyKey = ValueKey<String>(
    'canonical-business-text-analysis-empty',
  );

  final CanonicalBusinessTextAnalysisResult result;
  final Future<void> Function(CanonicalBusinessTextCandidate candidate)?
  onOpenRegistryCandidate;

  @override
  State<CanonicalBusinessTextAnalysisView> createState() =>
      _CanonicalBusinessTextAnalysisViewState();
}

final class _CanonicalBusinessTextAnalysisViewState
    extends State<CanonicalBusinessTextAnalysisView> {
  CanonicalBusinessTextClassificationStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final List<CanonicalBusinessTextClassification> visibleClassifications =
        _selectedStatus == null
        ? widget.result.classifications.classifications
        : widget
              .result
              .classifications
              .classificationsByStatus[_selectedStatus]!;

    return Scaffold(
      key: CanonicalBusinessTextAnalysisView.viewKey,
      appBar: AppBar(title: const Text('Канонический анализ')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Кандидаты: '
                        '${widget.result.totalCandidateCount}',
                      ),
                      Text(
                        'Business scopes: '
                        '${widget.result.classificationsByBusinessScopeOwnerId.length}',
                      ),
                      Text(
                        'Показано: '
                        '${visibleClassifications.length}',
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        'Registry revision: '
                        '${widget.result.registrySourceRevision}',
                      ),
                      SelectableText(
                        'Dictionary revision: '
                        '${widget.result.dictionarySourceRevision}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: <Widget>[
                  ChoiceChip(
                    key: const ValueKey<String>(
                      'canonical-business-text-analysis-filter-all',
                    ),
                    label: Text(
                      'Все '
                      '(${widget.result.totalCandidateCount})',
                    ),
                    selected: _selectedStatus == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  for (final status
                      in CanonicalBusinessTextClassificationStatus
                          .values) ...<Widget>[
                    ChoiceChip(
                      key: ValueKey<String>(
                        'canonical-business-text-analysis-filter-'
                        '${status.name}',
                      ),
                      label: Text(
                        '${switch (status) {
                          CanonicalBusinessTextClassificationStatus.unclassifiedNeutral => 'Unclassified / Neutral',
                          CanonicalBusinessTextClassificationStatus.exact => 'Exact',
                          CanonicalBusinessTextClassificationStatus.equivalent => 'Equivalent',
                          CanonicalBusinessTextClassificationStatus.review => 'Review',
                          CanonicalBusinessTextClassificationStatus.drift => 'Drift',
                          CanonicalBusinessTextClassificationStatus.failed => 'Failed',
                        }} '
                        '(${widget.result.countForStatus(status)})',
                      ),
                      selected: _selectedStatus == status,
                      onSelected: (_) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: visibleClassifications.isEmpty
                  ? const Center(
                      key: CanonicalBusinessTextAnalysisView.emptyKey,
                      child: Text(
                        'Для выбранного статуса '
                        'результатов нет.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: visibleClassifications.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final CanonicalBusinessTextClassification
                        classification = visibleClassifications[index];

                        final candidate = classification.candidate;

                        return Card(
                          child: ListTile(
                            key: ValueKey<String>(
                              'canonical-business-text-analysis-row-'
                              '${candidate.identity}',
                            ),
                            title: Text(
                              candidate.text,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  'Статус: '
                                  '${switch (classification.status) {
                                    CanonicalBusinessTextClassificationStatus.unclassifiedNeutral => 'Unclassified / Neutral',
                                    CanonicalBusinessTextClassificationStatus.exact => 'Exact',
                                    CanonicalBusinessTextClassificationStatus.equivalent => 'Equivalent',
                                    CanonicalBusinessTextClassificationStatus.review => 'Review',
                                    CanonicalBusinessTextClassificationStatus.drift => 'Drift',
                                    CanonicalBusinessTextClassificationStatus.failed => 'Failed',
                                  }}',
                                ),
                                Text(
                                  'Причина: '
                                  '${switch (classification.reason) {
                                    CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch => 'Точное совпадение не найдено',
                                    CanonicalBusinessTextClassificationReason.singleExactUniversalMatch => 'Одно точное универсальное совпадение',
                                    CanonicalBusinessTextClassificationReason.singleApprovedEquivalentMatch => 'Утверждённая эквивалентная формулировка',
                                    CanonicalBusinessTextClassificationReason.exactTextRequiresApplicabilityReview => 'Требуется проверка применимости',
                                    CanonicalBusinessTextClassificationReason.ambiguousExactCanonicalTextMatch => 'Несколько точных совпадений',
                                  }}',
                                ),
                                Text(
                                  'Владелец: '
                                  '${candidate.businessScopeOwnerId.value}',
                                ),
                                Text(
                                  'Путь: '
                                  '${candidate.path.segments.join(' → ')}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                builder: (BuildContext sheetContext) {
                                  return CanonicalBusinessTextClassificationDetails(
                                    classification: classification,
                                    onOpenRegistryCandidate:
                                        widget.onOpenRegistryCandidate == null
                                        ? null
                                        : (candidate) async {
                                            try {
                                              await widget
                                                  .onOpenRegistryCandidate!(
                                                candidate,
                                              );
                                            } catch (error) {
                                              if (!context.mounted) {
                                                return;
                                              }

                                              final String message = error
                                                  .toString()
                                                  .trim();

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    message.isEmpty
                                                        ? 'Не удалось открыть Registry block.'
                                                        : message,
                                                  ),
                                                ),
                                              );

                                              return;
                                            }

                                            if (sheetContext.mounted) {
                                              Navigator.of(sheetContext).pop();
                                            }

                                            if (context.mounted) {
                                              Navigator.of(context).pop();
                                            }
                                          },
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
