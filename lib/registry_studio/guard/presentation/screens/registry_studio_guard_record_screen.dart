import 'package:flutter/material.dart';

import '../../../core/domain/entities/registry_entity.dart';
import '../../../core/domain/evidence/source_evidence.dart';
import '../../../presentation/language/registry_studio_ui_labels.dart';
import '../../../presentation/language/registry_studio_ui_language.dart';
import '../../domain/registry_studio_guard_record_payload.dart';

final class RegistryStudioGuardRecordScreen extends StatelessWidget {
  factory RegistryStudioGuardRecordScreen({
    required RegistryStudioUiLanguage uiLanguage,
    required RegistryEntity entity,
    Key? key,
  }) {
    final payload = entity.payload;

    if (payload is! RegistryStudioGuardRecordPayload) {
      throw ArgumentError.value(
        entity,
        'entity',
        'Registry Studio Guard record screen requires '
            'RegistryStudioGuardRecordPayload.',
      );
    }

    return RegistryStudioGuardRecordScreen._(
      uiLanguage: uiLanguage,
      entity: entity,
      payload: payload,
      key: key,
    );
  }

  const RegistryStudioGuardRecordScreen._({
    required this.uiLanguage,
    required this.entity,
    required this.payload,
    super.key,
  });

  static const Key recordCardKey = Key('registry_studio_guard_record_card');

  final RegistryStudioUiLanguage uiLanguage;
  final RegistryEntity entity;
  final RegistryStudioGuardRecordPayload payload;

  @override
  Widget build(BuildContext context) {
    final RegistryStudioGuardRecordLabels labels =
        RegistryStudioUiLabels.forLanguage(uiLanguage).guardRecord;

    return Scaffold(
      appBar: AppBar(title: Text(labels.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _GuardRecordCard(
            key: recordCardKey,
            labels: labels,
            entity: entity,
            payload: payload,
          ),
          for (final SourceEvidence evidence in entity.sourceEvidence) ...[
            const SizedBox(height: 16),
            _SourceEvidenceCard(labels: labels, evidence: evidence),
          ],
        ],
      ),
    );
  }
}

final class _GuardRecordCard extends StatelessWidget {
  const _GuardRecordCard({
    required this.labels,
    required this.entity,
    required this.payload,
    super.key,
  });

  final RegistryStudioGuardRecordLabels labels;
  final RegistryEntity entity;
  final RegistryStudioGuardRecordPayload payload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labels.entityTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(label: labels.entityIdLabel, value: entity.id.value),
            _TextValueRow(
              label: labels.pathLabel,
              value: entity.path.segments.join(' / '),
            ),
            _TextValueRow(label: labels.kindLabel, value: entity.kind.kindId),
            _TextValueRow(
              label: labels.recordTypeLabel,
              value: payload.recordType.name,
            ),
            _TextValueRow(label: labels.headingLabel, value: payload.heading),
            _TextValueRow(label: labels.summaryLabel, value: payload.summary),
          ],
        ),
      ),
    );
  }
}

final class _SourceEvidenceCard extends StatelessWidget {
  const _SourceEvidenceCard({required this.labels, required this.evidence});

  final RegistryStudioGuardRecordLabels labels;
  final SourceEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              labels.sourceEvidenceTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _TextValueRow(
              label: labels.sourceDocumentPathLabel,
              value: evidence.sourceDocumentPath,
            ),
            _TextValueRow(
              label: labels.sourceSnapshotFingerprintLabel,
              value: evidence.sourceSnapshotFingerprint,
            ),
            _TextValueRow(
              label: labels.headingPathLabel,
              value: evidence.headingPath.join(' / '),
            ),
            _TextValueRow(
              label: labels.lineRangeLabel,
              value: '${evidence.startLine}–${evidence.endLine}',
            ),
          ],
        ),
      ),
    );
  }
}

final class _TextValueRow extends StatelessWidget {
  const _TextValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label:\n$value'),
    );
  }
}
