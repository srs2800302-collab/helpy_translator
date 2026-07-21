import 'package:flutter/material.dart';

import '../domain/entities/canonical_business_text_candidate.dart';
import '../domain/entities/canonical_business_text_classification.dart';
import '../domain/entities/canonical_business_text_classification_status.dart';

final class CanonicalBusinessTextClassificationDetails extends StatelessWidget {
  const CanonicalBusinessTextClassificationDetails({
    required this.classification,
    super.key,
  });

  static const Key sheetKey = ValueKey<String>(
    'canonical-business-text-classification-details',
  );

  final CanonicalBusinessTextClassification classification;

  @override
  Widget build(BuildContext context) {
    final candidate = classification.candidate;

    return SafeArea(
      child: SizedBox(
        key: sheetKey,
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          children: <Widget>[
            ListTile(
              title: const Text('Подробности классификации'),
              trailing: IconButton(
                tooltip: 'Закрыть',
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Text(
                    'Candidate: ${candidate.text}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Статус: ${switch (classification.status) {
                      CanonicalBusinessTextClassificationStatus.unclassifiedNeutral => 'Unclassified / Neutral',
                      CanonicalBusinessTextClassificationStatus.exact => 'Exact',
                      CanonicalBusinessTextClassificationStatus.equivalent => 'Equivalent',
                      CanonicalBusinessTextClassificationStatus.review => 'Review',
                      CanonicalBusinessTextClassificationStatus.drift => 'Drift',
                      CanonicalBusinessTextClassificationStatus.failed => 'Failed',
                    }}',
                  ),
                  Text(
                    'Причина: ${switch (classification.reason) {
                      CanonicalBusinessTextClassificationReason.noExactCanonicalTextMatch => 'Точное каноническое совпадение не найдено',
                      CanonicalBusinessTextClassificationReason.singleExactUniversalMatch => 'Одно точное универсальное совпадение',
                      CanonicalBusinessTextClassificationReason.exactTextRequiresApplicabilityReview => 'Требуется проверка применимости',
                      CanonicalBusinessTextClassificationReason.ambiguousExactCanonicalTextMatch => 'Обнаружено несколько точных совпадений',
                    }}',
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'Business owner ID: '
                    '${candidate.businessScopeOwnerId.value}',
                  ),
                  SelectableText(
                    'Registry node ID: '
                    '${candidate.nodeId.value}',
                  ),
                  Text(
                    'Registry path: '
                    '${candidate.path.segments.join(' → ')}',
                  ),
                  Text(
                    'Candidate kind: ${switch (candidate.kind) {
                      CanonicalBusinessTextCandidateKind.heading => 'heading',
                      CanonicalBusinessTextCandidateKind.paragraph => 'paragraph',
                      CanonicalBusinessTextCandidateKind.listItem => 'list item',
                      CanonicalBusinessTextCandidateKind.blockquote => 'blockquote',
                      CanonicalBusinessTextCandidateKind.tableRow => 'table row',
                    }}',
                  ),
                  Text(
                    'Direct content line: '
                    '${candidate.directContentLine}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Raw text',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(candidate.rawText),
                  const SizedBox(height: 20),
                  const Text(
                    'Source evidence',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  for (final evidence in candidate.sourceEvidence)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SelectableText(
                              'Документ: '
                              '${evidence.sourceDocumentPath}',
                            ),
                            SelectableText(
                              'Fingerprint: '
                              '${evidence.sourceSnapshotFingerprint}',
                            ),
                            Text(
                              'Heading path: '
                              '${evidence.headingPath.join(' → ')}',
                            ),
                            Text(
                              'Строки: '
                              '${evidence.startLine}–'
                              '${evidence.endLine}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Matched canonical entries',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (classification.matchedCanonicalEntries.isEmpty)
                    const Text(
                      'Подтверждённые канонические '
                      'совпадения отсутствуют.',
                    )
                  else
                    for (final entry in classification.matchedCanonicalEntries)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SelectableText(
                                'Canonical phrase: '
                                '${entry.phrase}',
                              ),
                              SelectableText(
                                'Collection: '
                                '${entry.collectionId}',
                              ),
                              Text(
                                'Применимость: '
                                '${entry.applicability.isEmpty ? 'без ограничений' : entry.applicability}',
                              ),
                              SelectableText(
                                'Документ: '
                                '${entry.sourceDocumentPath}',
                              ),
                              SelectableText(
                                'Revision: '
                                '${entry.sourceRevision}',
                              ),
                              SelectableText(
                                'Fingerprint: '
                                '${entry.sourceSnapshotFingerprint}',
                              ),
                              Text(
                                'Строки: '
                                '${entry.sourceStartLine}–'
                                '${entry.sourceEndLine}',
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
